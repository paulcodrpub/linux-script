# Intro
Script for preparing a brand new CentOS 6 or 7 instance with user with ssh key, Ansible client, rpms, and other configs.

# Summary of changes made by the shell script.
* func_dns: update /etc/resolv.conf
* func_log: creates log file to record changes. All changes by this shell script will be logged in /root/logs/yyyy-mm-dd-UTC.log for troubleshooting.
* func_skel_vim: updates /etc/skel/.vimrc with following. This sets all newly added user accounts to get ~/.vimrc with following. It adds commonly used settings I have in vim editor.
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
* func_root_vim: /root/.vimrc is created for root, with same config text added to /etc/skel/.vimrc
* func_utc: system time will be set to UTC.
* func_prompt: customize shell prompt. Both root and regular users can see custom shell prompt. Shell prompt for root will be colored differently.
* func_rpms: install rpms for commonly used software, such as curl, vim, etc.
* func_adduser: create user, with username of your choice. Add to wheel group for sudo privilege.
* func_sudoers: give 'wheel' group sudo privilege without requiring password.
* func_selinux_off: disable selinux
* func_ansible: install Ansible client. Add 'ansible' user account and add to wheel group.
* func_jenkins: create user 'jenkins' for Jenkins server and add to wheel group.
* func_backupadmin: create user group for backup jobs.
* func_ifup: bring eth1 up.
* func_network_manager: stop/disable NetworkManager in CentOS 7
* func_motd: updatet /etc/motd


# First run of newcentos-6-7.sh
Use non-production CentOS to make sure it works with your environment.

The script calls the functions at the end of the script. I disabled functions that add a user account or install Ansible client or set up for Jenskins build jobs. The functions that are not commented out because they can be executed without requiring any modifications.

Scp or rsync newcentos-6-7.sh to a newly provisioned CentOS 6 or 7 server, set permission, and execute it on the server.
