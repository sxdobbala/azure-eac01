#!/bin/bash
# Check iserver status
mstrbin="/opt/mstr/MicroStrategy/bin"
cd $mstrbin
state=`./mstrctl -s IntelligenceServer gs | grep state | cut -f2 -d'>' | cut -f1 -d'<'`

status=`([ $state != "running" ] && echo 0 ) || echo 1`

echo $status
