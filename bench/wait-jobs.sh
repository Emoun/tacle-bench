#!/bin/bash

PID=$1

if [[ "$PID" == "" ]]; then
	echo "No PID"
	exit
fi

CORES=$(nproc)
MAX_JOBS=$((CORES*4))

RUNNING_JOBS=$(pstree -p $PID 2> /dev/null | grep -o '([0-9]\+)' | grep -o '[0-9]\+' | wc -w)
while [ $RUNNING_JOBS -gt $MAX_JOBS ] 
do
	sleep 10
	RUNNING_JOBS=$(pstree -p $PID 2> /dev/null | grep -o '([0-9]\+)' | grep -o '[0-9]\+' | wc -w)
done