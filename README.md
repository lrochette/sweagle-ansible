# sweagle-ansible


## Prerequisites:
- Packages Ansible 2.5 or higher + package sshpass
- be sure ansible.cfg knows your inventory folder and authorize non ssh checks
- more /etc/ansible/ansible.cfg

## WARNING
- Copy your SWEAGLE full package zip file to /roles/sweagle/files
- Copy your SWEAGLE license in parameter sweagle_license_key to /inventories/all-in-one/group_vars

## Test with
 ansible-playbook all-in-one-install.yml -i ./inventories/all-in-one/hosts.yml --check

## For full installation (including prerequisites)
ansible-playbook all-in-one-install.yml -i ./inventories/all-in-one/hosts.yml

## For SWEAGLE installation (prerequisites already installed)
- check before that prerequisites are well installed
ansible-playbook all-in-one-install.yml -i ./inventories/all-in-one/hosts.yml--tags sweagle

## To install only a specifif component or prerequisite
ansible-playbook all-in-one-install.yml -i ./inventories/all-in-one/hosts.yml --tags "<COMPONENT>"
- Example to do only mySQL:
ansible-playbook all-in-one-install.yml -i ./inventories/all-in-one/hosts.yml --tags mysql

TESTED ON
- Ubuntu 18.04
- CentOS 7.6.1810
## Todo list

- on MongoDB, when another release is installed, remove it before
  - add a new parameter mongodb_remove_other_releases: false (by default)
  - add tasks to remove other release
  - currently, plays failed and you should remove manually
  - reproduced on centos 7.x where default mongo is 2.6
