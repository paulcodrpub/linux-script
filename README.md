# Intro
Script for preparing a brand new CentOS 6 or 7 instance with user, ssh key, rpms, and other configs.

# Summary of changes made by the shell script.
* All users including root will get ~/.vimrc with following. It adds commonly used settings I have in vim editor.
```
filetype plugin indent on
" show existing tab with 4 spaces width
set tabstop=4
" when indenting with '>', use 4 spaces width
set shiftwidth=4
" On pressing tab, insert 4 spaces
set expandtab

set paste
```
* All changes will be logged in /root/logs/yyyy-dd-mm-hh.log for troubleshooting.
* System time will be set to UTC.
* Customize shell prompt.
* Shell prompt for root is colored green.
* Give 'wheel' group sudo privilege.
* Add username that I always use on my machines.
* Set up my main Mac's public ssh key on the CentOS server. This allows me to ssh log into all my servers without having to set up the SSH key manually.
* Turn off selinux.
* Set up Ansible client, including installing rpm, creating user 'ansible', set up ssh public key, grant sudo privilege to 'ansible' user.
* Add user 'jenkins' which allows deploy builds by remote Jenskins server to deploy files.
* Create backup group and add users to it.
* eth1 is not brought up in CentOS until after first OS reboot. So eth1 will be activated, which will allow installing rpms.
* Stop/disable NetworkManager service on CentOS 7.
* Populate /etc/motd with basic info, such as hostname, date installed.

