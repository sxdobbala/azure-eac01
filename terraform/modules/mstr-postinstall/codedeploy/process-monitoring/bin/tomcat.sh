#!/bin/bash
# Check tomcat status
state=`ps -ef |grep -i tomcat |grep -i latest |grep -v grep |wc -l`

status=`([ $state != "1" ] && echo 0 ) || echo 1`

echo $status
