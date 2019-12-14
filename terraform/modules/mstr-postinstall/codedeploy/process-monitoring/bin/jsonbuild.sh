#!/bin/bash
# Cloudwatch metric definition template and save as ./temp/*.json
jsonfile="./temp/$1.json"
instanceid=`wget -q -O - http://169.254.169.254/latest/meta-data/instance-id`
status=`/bin/sh ./bin/$1.sh`
cat /dev/null > $jsonfile
echo "[" >> $jsonfile
echo "        {" >> $jsonfile
echo "           "\""MetricName""\": "\""Status""\"," >> $jsonfile
echo "            "\""Dimensions""\": [" >> $jsonfile
echo "                {" >> $jsonfile
echo "                    "\""Name""\": "\""Process""\"," >> $jsonfile
echo "                    "\""Value""\": "\""$1""\"" >> $jsonfile
echo "               }," >> $jsonfile
echo "                {" >> $jsonfile
echo "                    "\""Name""\": "\""InstanceId""\"," >> $jsonfile
echo "                    "\""Value""\": "\""$instanceid""\"" >> $jsonfile
echo "               }" >> $jsonfile
echo "            ]," >> $jsonfile
echo "            "\""Unit""\": "\""None""\"," >> $jsonfile
echo "            "\""Value""\": $status" >> $jsonfile
echo "        }" >> $jsonfile
echo "    ]" >> $jsonfile
aws cloudwatch put-metric-data --namespace "CWAgent" --metric-data file://$jsonfile --region us-east-1
