Put here all packages files if you want to use force_local_install = true

Create a folder for these components to put their packages

- elasticsearch

- mongodb: you should have at least these packages
      - mongodb-org-server
      - mongodb-org-shell
      - numactl
      - python-bson
      - python-pymongo

- mysql: you should have (in this order)
      - 1-mysql-community-common-5.7.25-1.el7.x86_64.rpm
      - 2-mysql-community-libs-5.7.25-1.el7.x86_64.rpm
      - mysql-community-client-5.7.25-1.el7.x86_64.rpm
      - mysql-community-libs-compat-5.7.25-1.el7.x86_64.rpm
      - mysql-community-server-5.7.25-1.el7.x86_64.rpm
      - MySQL-python-1.2.5-1.el7.x86_64.rpm

- nginx
- system: you should have
      - unzip (required to install vault and jdk)
      - epel (optional, for Red Hat OS family to install jq)
      - jq (required to load data in SWEAGLE )
      - policycoreutils-python (for Red Hat OS Family to manage SELinux)
      - telnet (optional)
      - screen (optional)

- vault
