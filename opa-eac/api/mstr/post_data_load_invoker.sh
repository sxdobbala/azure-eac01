#!/bin/bash
curr_dir=$(dirname "$0")
python3 -m venv postdataloadmstr_venv
source postdataloadmstr_venv/bin/activate
pip install pip -U
pip install -r $curr_dir/requirements.txt
ec2_avail_zone=`curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone`
ec2_region="`echo \"$ec2_avail_zone\" | sed 's/[a-z]$//'`"
export AWS_DEFAULT_REGION=$ec2_region
python3 $curr_dir/post_data_load.py "$@"