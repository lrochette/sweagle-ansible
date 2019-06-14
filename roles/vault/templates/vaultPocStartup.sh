#!/bin/sh
export VAULT_ADDR=http://127.0.0.1:8200

nohup sh /usr/bin/vault server -config=/opt/vault/conf/vaultconfig.hcl & > /dev/null

sleep 15

vault unseal t86a0ZInZGWfpSCnXBR/k7LOs3AyOwHDxjWZARaZQJY8
vault unseal e19ELUYBKXTZkwe1t7KFjDEGueJH2PlZG3121TKOxHpW
vault unseal YFXBlx2q2nUZcltWQYQrgwEdK9HilQvt26A0//bt2bEi
