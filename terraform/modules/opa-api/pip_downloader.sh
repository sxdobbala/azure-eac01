#!/bin/bash
# Refer: https://www.terraform.io/docs/providers/external/data_source.html#processing-json-in-shell-scripts


# Exit if any of the intermediate steps fail
set -e

# Setup python virtual environment
python3 -m venv venv --system-site-packages >> pip_downloader.log
source venv/bin/activate  >> pip_downloader.log
python3 -m pip install pip -U >> pip_downloader.log
python3 -m pip install -r requirements.txt  >> pip_downloader.log

# We create 2 versions of api due to the psycopg2 version difference: first used by lambdas (need specific psycopg2 version) and second used by mstr scripts on EC2 instances.
python3 -m pip install "https://github.optum.com/opa/opa.psycopg2/archive/master.zip" ../../../api --target "./src" --upgrade >> pip_downloader.log
# We install psycopg2-binary in case we need to make OPA_Master calls from the mstr scripts.
# Mstr scripts will have their own requirements.txt file that installs psycopg2-binary dependency in venv.
python3 -m pip install psycopg2-binary ../../../api --target "./src-mstr" --upgrade >> pip_downloader.log

# Return JSON object required to correctly process result of the data source.
# We return something since we use returned value from here to establish dependency 
# to guarantee that archive is created only after pip_downloader has finished completely.
echo "{\"archive_filename\":\"opa_api\"}"