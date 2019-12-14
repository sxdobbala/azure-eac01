#!/bin/bash
set -e
cd /opt/opa/deployment/mstr-postinstall
ls -alR
python3 -m venv venv --system-site-packages
source venv/bin/activate
pip install pip -U
pip install -r ./scripts/requirements.txt
mkdir -p /var/log/opa/deployment/mstr-postinstall
export ANSIBLE_LOG_PATH=/var/log/opa/deployment/mstr-postinstall/ansible.log
export ANSIBLE_HASH_BEHAVIOUR=merge
ansible-playbook playbook.yaml -verbose