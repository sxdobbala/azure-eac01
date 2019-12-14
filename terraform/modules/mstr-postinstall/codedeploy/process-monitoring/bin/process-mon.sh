#!/bin/bash
# Loop ./config/process-list and add as a metric in cloudwatch by executing ./bin/jsonbuild.sh
j=1
mkdir -p ./temp
while [ $j -le `cat ./config/process-list |wc -l` ]
do
process=`cat ./config/process-list | sed $j'q;d'`
sh ./bin/jsonbuild.sh $process
j=$(( j + 1 ))
done
