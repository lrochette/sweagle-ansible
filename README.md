# sweagle-ansible


## Prerequisites:
- Packages Ansible 2.4 or higher + package sshpass
- be sure ansible.cfg knows your inventory folder and authorize non ssh checks:
more /etc/ansible/ansible.cfg

## WARNING
- Copy your SWEAGLE full package zip file to /roles/sweagle/files
- Copy your SWEAGLE license in parameter sweagle_license_key to /inventories/all-in-one/group_vars for silent install
- If you don't put your license there, then playbook will ask for it when installing SWEAGLE component.

## Test with
ansible-playbook all-install.yml -i ./inventories/all-in-one/hosts.yml --check
(be aware that checks will fail on tasks requiring update to occur)

## For full installation (including prerequisites)
ansible-playbook all-install.yml -i ./inventories/all-in-one/hosts.yml

## For SWEAGLE installation (prerequisites already installed)
- check before that prerequisites are well installed, then:
ansible-playbook all-install.yml -i ./inventories/all-in-one/hosts.yml--tags sweagle

## To install only a specific component or prerequisite
ansible-playbook all-install.yml -i ./inventories/all-in-one/hosts.yml --tags "<COMPONENT>"
Components available are:
- Elasticsearch
- Jdk
- MongoDB
- MySQL
- Nginx
- SWEAGLE
- SWEAGLE-DATA (load initial data on existign tenant)
- System
- Vault

Tags must be put in lowercase, example to do only MySQL:
ansible-playbook all-install.yml -i ./inventories/all-in-one/hosts.yml --tags mysql


## TESTED ON
- Ubuntu 18.04 (All OK, but change mySQL package)
- CentOS 7.6.1810 (OK: system, jdk, mongodb, nginx, elasticsearch)


## TROUBLESHOOT
- Vault 1.1.2 is not supported and doesn't work with SWEAGLE (as of SWEAGLE 3.1.x)


## Todo list

- Add multi-hosts support

- Support full local installation (when no access to Internet from hosts)

- On Vault, unseal during install and setup service to unseal automatically

- Check versions for prerequisites before installation

- ex: on MongoDB, when another release is installed, remove it before
  - add a new parameter mongodb_remove_other_releases: false (by default)
  - add tasks to remove other release
  - currently, plays failed and you should remove manually
  - reproduced on centos 7.x where default mongo is 2.6

- add support for SSL
