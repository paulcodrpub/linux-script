#!/bin/bash

_user="john"
_script="$(pwd)/$(basename $0)";
_release=`rpm -q --qf "%{VERSION}" $(rpm -q --whatprovides redhat-release)`  # ex: 6 or 7
_distro=`more /etc/redhat-release | tr '[A-Z]' '[a-z]' | cut -d' ' -f1`  # ex: centos
_os_ver_arch="${_distro}-${_release}"
_dns1="8.8.8.8"

# For self delete of the script.
# Note if the script is in /root/bin/setup01.sh and you execute it from a different directory (ex: /root/), self delete will not work.
function rmScript(){
  rm -f /${_script};
}


# update /etc/skel/.vimrc
function func_skel_vim(){
  _vim_skel_test=`grep set /etc/skel/.vimrc 2> /dev/null | wc -l`

  if [ ${_vim_skel_test} -eq 4 ]; then
    echo -e "\n# /etc/skel/.vimrc already has required settings." | tee -a /${_logger}
  else
cat >>/etc/skel/.vimrc <<EOL
filetype plugin indent on
" show existing tab with 4 spaces width
set tabstop=4
" when indenting with '>', use 4 spaces width
set shiftwidth=4
" On pressing tab, insert 4 spaces
set expandtab

set paste
EOL
    echo -e "/vim/skel/.vimrc updated." | tee -a /${_logger}
  fi
}


# update /root/.vimrc
function func_root_vim(){
  _root_vimrc_test=`grep set /root/.vimrc 2> /dev/null | wc -l`
  if [ ${_root_vimrc_test} -eq 4 ]; then
    echo -e "\n# /root/.vimrc already has required settings." | tee -a /${_logger}
  else
cat >>/root/.vimrc <<EOL
filetype plugin indent on
" show existing tab with 4 spaces width
set tabstop=4
" when indenting with '>', use 4 spaces width
set shiftwidth=4
" On pressing tab, insert 4 spaces
set expandtab

set paste
EOL
    echo -e "/root/.vimrc updated." | tee -a /${_logger}
  fi
}


# Update /etc/resolv.conf with DNS server IP
function func_dns(){
cat >>/etc/resolv.conf <<EOL
nameserver ${_dns1}
EOL
}


# Saves log of this script
function func_log(){
  _today=`date +"%F-%Z"`
  _log_dir="root/logs"
  _logger="${_log_dir}/${_today}.log"

  mkdir /${_log_dir} 2> /dev/null
  echo "#######################" | tee -a /${_logger}
  date -u +"%F--%H-%M-%Z" >> /${_logger}
}


# Change system time zone to UTC
function func_utc(){
  # Variables for verifying OS and version.
  rm /var/cache/yum/timedhosts.txt 2> /dev/null
  yum clean all
  yum --disableplugin=fastestmirror -y install ntp
#  sleep 2  # needed for ntpd service to start
  rm -f /etc/localtime
  ln -sf /usr/share/zoneinfo/UTC /etc/localtime

  rm -f /etc/sysconfig/clock
cat <<EOM >/etc/sysconfig/clock
UTC=true
EOM

  echo -e "\n`date +%Y-%m-%d--%H-%M-%S-%Z` Server set to use UTC time." | tee -a /${_logger}
  if [[ ${_os_ver_arch} == *"centos-6"* ]]; then
    service ntpd restart
    chkconfig ntpd on
    echo -e "ntpd service started" | tee -a /${_logger}
  elif [[ ${_os_ver_arch} == *"centos-7"* ]]; then     # must be centos_
    systemctl restart ntpd
    systemctl enable ntpd
    echo -e "ntpd service started" | tee -a /${_logger}
  fi
}


# Customize shell prompt.
function func_prompt(){
cat >/etc/profile.d/custom-prompt.sh <<EOL
if [ "\$PS1" ]; then
PS1="\n[\u@\h  `hostname`  \W]\\\\$ "
fi
EOL

echo "export PS1='\n\[\e[1;32m\][\u@\h  `hostname`  \W]$\[\e[0m\] '" >> /root/.bashrc
}


# Install epel-release on CentOS 6. This function is used in func_rpms, only on a CentOS 6.
function func_epel(){
  wget https://dl.fedoraproject.org/pub/epel/epel-release-latest-6.noarch.rpm
  rpm -Uvh epel-release-*6*.rpm
}


# Install often used rpms.
function func_rpms(){
  if [[ ${_os_ver_arch} == *"centos-6"* ]]; then
    func_epel    # function for installing epel-release on CentOS 6
    yum -y install vim curl wget man screen bind-utils rsync && echo -e "rpms installed"  >> /${_logger}
  elif [[ ${_os_ver_arch} == *"centos-7"* ]]; then
    yum -y install epel-release vim curl wget man screen bind-utils rsync tmux && echo -e "rpms installed"  >> /${_logger}
  fi
}


# Grant sudo privilege to 'wheel' group.
function func_sudoers(){
  _wheel_test=`grep '^%wheel' /etc/sudoers | grep NOPASSWD | wc -l`
  if [ ${_wheel_test} -ge 1 ]; then
    echo -e '\n# %wheel group already has sudo privilege.' | tee -a /${_logger}
  else
    echo "Updating /etc/sudoers" | tee -a /${_logger}
    sed -i '/NOPASSWD/a %wheel\      ALL=(ALL)\      NOPASSWD:\ ALL' /etc/sudoers && echo "Granted to wheel group sudo root privilege."
  fi
}


# Add user account and set up ssh key. Add user to 'wheel' group.
function func_adduser(){
  useradd ${_user} 2> /dev/null
  usermod -a -G wheel ${_user} 2> /dev/null
  mkdir /home/${_user}/.ssh 2> /dev/null
  touch /home/${_user}/.ssh/authorized_keys 2> /dev/null
  #passwd $_user

  if grep --quiet '^ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDQfYTUuey' /home/${_user}/.ssh/authorized_keys; then
    echo -e "\n# SSH key for ${_user} is already in /home/${_user}/.ssh/authorized_keys.\n" | tee -a /${_logger}
  else
    echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDQfYTUueyxGlFb8qT+XNxTJIu6/FCzBes3asN john@PCs.local" >> /home/${_user}/.ssh/authorized_keys && echo -e "Added ${_user} and gave sudo privilege." | tee -a /${_logger}
  fi

  chmod 755 /home/${_user}/.ssh
  chmod 644 /home/${_user}/.ssh/authorized_keys
  chown -R ${_user}: /home/${_user}/.ssh
}


# Disable selinux
function func_selinux_off(){
  sed -i "s/SELINUX=enforcing/SELINUX=disabled/g" /etc/selinux/config && echo -e "SELinux turned off." | tee -a /${_logger}
}


# Install rpm for Ansible client. Add user account for Ansible and set up ssh key. Add user to 'wheel' group.
function func_ansible() {
  _user_ansible="ansible"
  yum install -y ansible
  useradd ${_user_ansible} 2> /dev/null
  usermod -aG wheel ${_user_ansible} 2> /dev/null
  mkdir /home/${_user_ansible}/.ssh 2> /dev/null
  touch /home/${_user_ansible}/.ssh/authorized_keys 2> /dev/null

  if grep --quiet '^ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDFc' /home/${_user_ansible}/.ssh/authorized_keys; then
    echo -e "\n# public key for ${_user_ansible} is already in /home/${_user_ansible}/.ssh/authorized_keys." | tee -a /${_logger}
  else
    echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDFcFcKOi8yNuE05UJbe3RkZdP6mTICX11Vc49zrDfRQx91iLDQRf p@Mac" >> /home/${_user_ansible}/.ssh/authorized_keys && echo -e "Ansible client installed." | tee -a /${_logger}
  fi

  chmod 755 /home/${_user_ansible}
  chmod 644 /home/${_user_ansible}/.ssh/authorized_keys
  chown -R ${_user_ansible}: /home/${_user_ansible}/.ssh
}


# Allow Jenkins server to deploy code to this server. Add user account and set up ssh key. Add user to 'wheel' group.
function func_jenkins() {
  _user_jenkins="jenkins"
  useradd ${_user_jenkins} 2> /dev/null
  usermod -aG wheel ${_user_jenkins} 2> /dev/null
  mkdir /home/${_user_jenkins}/.ssh 2> /dev/null
  touch /home/${_user_jenkins}/.ssh/authorized_keys 2> /dev/null

  if grep --quiet '^ssh-rsa AAAAB3NzaC1yc2EAAAADAQAB' /home/${_user_jenkins}/.ssh/authorized_keys; then
    echo -e "\n# public key for ${_user_jenkins} is already in /home/${_user_jenkins}/.ssh/authorized_keys." | tee -a /${_logger}
  else
    echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDUeBGQNh745bQizNxD43RfmMromfdpZxGZBYTQ== p@gmail.com" >> /home/${_user_jenkins}/.ssh/authorized_keys && echo -e "Jenkins user added." | tee -a /${_logger}
  fi

  chmod 755 /home/${_user_jenkins}
  chmod 644 /home/${_user_jenkins}/.ssh/authorized_keys
  chown -R ${_user_jenkins}: /home/${_user_jenkins}/.ssh
}


# Create group backupadmin for handling backups. Add users john and ansible to the group
function func_backupadmin(){
  _groupname="backupadmin"
  groupadd ${_groupname} 2> /dev/null
  usermod -aG ${_groupname} ${_user} 2> /dev/null
  usermod -aG ${_groupname} ${_user_ansible} 2> /dev/null
}


# Up eth1
function func_ifup(){
  ifup eth1
}


# Stop and disable NetworkManager service on CentOS 7
function func_network_manager(){
if [[ ${_os_ver_arch} == *"centos-7"* ]]; then
  systemctl stop NetworkManager
  systemctl disable NetworkManager
  echo -e "NetworkManager service on CentOS 7 stopped and disabled." | tee -a /${_logger}
fi
}


# Populate /etc/motd.
function func_motd(){
  if grep --quiet '^Installed' /etc/motd; then
    echo -e "\n# Not updating /etc/motd now as it already has content.\n# You can always update it manually later.\\n" | tee -a /${_logger}
  else
    echo -e "\nSetting up MOTD. \n" | tee -a /${_logger}
    echo "==========" >> /etc/motd
    echo "Installed `date +"%F"`" >> /etc/motd
    echo "`hostname -f`" >> /etc/motd
    echo "==========" >> /etc/motd
    echo -e "/etc/motd updated." | tee -a /${_logger}
  fi
}



trap rmScript SIGINT SIGTERM   # for Self deleting of this script.


#func_dns
func_log
func_skel_vim
func_root_vim
func_utc
func_prompt
func_rpms
#func_adduser
#func_sudoers
func_selinux_off
#func_ansible
#func_jenkins
#func_backupadmin
func_ifup
func_network_manager
func_motd
rmScript; bash -c 'sleep 3 && reboot'  # This allows self delete of the script AND OS reboot immediately after.
