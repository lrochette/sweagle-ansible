# sweagle-ansible

This is Ansible playbook to install SWEAGLE on-premise.
It supports :
-	Installation with or without prerequisites
-	Independent installation of each component or full install
-	Idem potent, in case of error, correct, then restart script
-	Initialisation of Vault with automatic capture of init token in SWEAGLE config and automatic unseal
-	Full silent install or interactive mode (for example, if you don’t put a license key, it will ask for it)
- All in one server installation or multi-servers splitted by component
- Installation from local package (when no access to Internet from hosts)
  - with full scope for Red Hat family, and limited scope for Debian

## Prerequisites:
- Ansible 2.4 or higher + package sshpass
- be sure ansible.cfg knows your inventory folder and authorize non ssh checks:
more /etc/ansible/ansible.cfg

## WARNING
- Copy your SWEAGLE full package zip file to
  - /roles/sweagle/files
  - /files/sweagle when force_local_installation is set to true
- update /inventories/all-in-one/group_vars/all.yml with:
  - your root password for ansible become to work
  - your SWEAGLE license in parameter sweagle_license_key for silent install
(if you don't put your license, then playbook will ask for it when installing SWEAGLE component)
- if you set force_local_installation to true, be sure to put all required packages files in /files folder (see ./files/README.txt for details)

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
- SWEAGLE (all prerequisites components should be present)
- SWEAGLE-data (load initial data on existing tenant)
- SWEAGLE-web (only install the webserver tier - Nginx must be there !)
- System (install prerequisites libs like unzip, or jq)
- Vault

Tags must be put in lowercase, example to do only MySQL:
ansible-playbook all-install.yml -i ./inventories/all-in-one/hosts.yml --tags mysql


## TESTED ON
- Ansible 2.4.2, 2.5.1, and 2.8.5
- Ubuntu 18.04
- CentOS 7.6.1810
- Sweagle 2.1.9, 3.1.0, 3.5.0


## TROUBLESHOOT
- Vault 1.1.2 and upper are not supported and doesn't work with SWEAGLE (as of SWEAGLE 3.1.x)
- Force_local_installation may not work depending on dependencies present or not on target host
- Settings for ElasticSearch for 3.5.0 requires additional tests


## Todo list

- Check versions for prerequisites before installation
ex: on MongoDB, when another release is installed, remove it before
  - add a new parameter mongodb_remove_other_releases: false (by default)
  - add tasks to remove other release
  - currently, plays failed and you should remove manually
  - reproduced on centos 7.x where default mongo is 2.6

- Add support for SSL
