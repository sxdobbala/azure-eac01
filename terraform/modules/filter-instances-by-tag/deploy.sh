#!/bin/bash

# Exit if any of the intermediate steps fail
set -e

# Setup python virtual environment
# Redirect standard output to a log file except for actual python script execution since terraform only expects result json in stdout
python3 -m venv venv --system-site-packages > filter-instance-by-tag.log
source venv/bin/activate  >> filter-instance-by-tag.log
python3 -m pip install pip -U  >> filter-instance-by-tag.log
python3 -m pip install -r requirements.txt  >> filter-instance-by-tag.log

# Invoke python script that implements terraform_external_data
# Refer: https://www.terraform.io/docs/providers/external/data_source.html
python3 ./filterbytag.py