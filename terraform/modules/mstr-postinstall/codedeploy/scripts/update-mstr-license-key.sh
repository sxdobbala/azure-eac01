#!/bin/bash
set -e
python3 ./scripts/update-mstr-license-key.py
service mstr iserverrestart