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
