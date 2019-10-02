Put here all packages files if you want to use force_local_install = true

Create a folder for these components to put their packages

- elasticsearch
      - elasticsearch-6.6.1

- jdk: you should have jdk package in gz format

- mongodb: you should have at least these packages
      - /prereqs/* (all packages required for list below)
      - mongodb-org-server
      - mongodb-org-shell
      - policycoreutils-python-2.5-33.el7.x86_64
      - python-pymongo

- mysql: you should have (in this order)
      - /prereqs/net-tools-2.0-0.20150915git.4.mga6.x86_64
      - 1-mysql-community-common-5.7.25-1.el7.x86_64
      - 2-mysql-community-libs-5.7.25-1.el7.x86_64
      - mysql-community-client-5.7.25-1.el7.x86_64
      - mysql-community-libs-compat-5.7.25-1.el7.x86_64
      - mysql-community-server-5.7.25-1.el7.x86_64
      - MySQL-python-1.2.5-1.el7.x86_64

- nginx
      - nginx-1.14.2-1.el7_4.ngx.x86_64

- sweagle: you should have
      /full_{{YOUR VERSION}}.zip
      /sweagleExpert/exporters with cloning of https://github.com/sweagleExpert/exporters.git
      /sweagleExpert/mditypes with cloning of https://github.com/sweagleExpert/mditypes.git
      /sweagleExpert/nodetypes with cloning of https://github.com/sweagleExpert/nodetypes.git
      /sweagleExpert/templates with cloning of https://github.com/sweagleExpert/templates.git
      /sweagleExpert/validators with cloning of https://github.com/sweagleExpert/validators.git

- vault
      - vault_0.7.2_linux_386

- in root folder: you should have
      - unzip (required to install vault and SWEAGLE)
      - epel (optional, for Red Hat OS family to install jq)
      - jq (required to load data in SWEAGLE )
      - policycoreutils-python (for Red Hat OS Family to manage SELinux)
      - telnet (optional)
      - screen (optional)
