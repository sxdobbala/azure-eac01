#!/bin/bash
set -e
cd /opt/opa/deployment/web
ls -alR
python3 -m venv venv --system-site-packages
source venv/bin/activate
pip install pip -U
pip install -r requirements.txt
mkdir -p /var/log/opa/deployment/web
export ANSIBLE_LOG_PATH=/var/log/opa/deployment/web/ansible.log
export ANSIBLE_HASH_BEHAVIOUR=merge
env_hostname=`curl -s 169.254.169.254/latest/meta-data/hostname`
env_id=$(echo $HOSTNAME|grep -o "env-[0-9]*")
env_region=`curl -s 169.254.169.254/latest/meta-data/placement/availability-zone | sed 's/.$//'`
export AWS_DEFAULT_REGION=$env_region
env_name=$(aws ssm get-parameter --region $env_region --name /$env_id/env_name --query '[Parameter][*].[Value]' --output text)
ansible-playbook playbook.yml -verbose -i inventory --extra-vars "host=$env_name"