#!/bin/bash

ID=$1
PREFIX=$2
ENTRYFN=$3
RESULT_FILE=$4


STATS_FILE="$ID/stats.txt"
OUT_FILE="$ID/a.out"
PASIM_FILE="$ID/pasim.txt"
WCET_FILE="$ID/wcet.txt"

# Extract runtime statistics
if [ -f "$PASIM_FILE" ]; then
	STRING=$(python3 ../../find_using_regex.py "./$PASIM_FILE" "<$ENTRYFN>\n.*\n\s*1\s*(\d*)" 1)
	echo "${PREFIX}Exec: ${STRING//[^0-9]/}" >> $RESULT_FILE
	STRING=$(python3 ../../find_using_regex.py "./$PASIM_FILE" "Main Memory Statistics:.*\n(.*\n){6}\s*Stall Cycles\s*:\s*(\d*)" 2)
	echo "${PREFIX}ExecMainMemStall: ${STRING//[^0-9]/}" >> $RESULT_FILE
	STRING=$(python3 ../../find_using_regex.py "./$PASIM_FILE" "Stack Cache Statistics:.*\n(.*\n){6}\s*Bytes Read\s*:\s*(\d*)" 2)
	echo "${PREFIX}ExecStackReadBytes: ${STRING//[^0-9]/}" >> $RESULT_FILE
	STRING=$(python3 ../../find_using_regex.py "./$PASIM_FILE" "Stack Cache Statistics:.*\n(.*\n){8}\s*Bytes Written\s*:\s*(\d*)" 2)
	echo "${PREFIX}ExecStackWriteBytes: ${STRING//[^0-9]/}" >> $RESULT_FILE
else
	echo "Missing $PASIM_FILE for $PREFIX"
fi

# Extract WCET
if [ -f "$WCET_FILE" ]; then
	STRING=$(cat "$WCET_FILE" | grep "best WCET bound:")
	echo "${PREFIX}Wcet: ${STRING//[^0-9]/}" >> $RESULT_FILE
	STRING=$(cat "$WCET_FILE" | grep "cache-max-cycles:")
	echo "${PREFIX}WcetMainMemStall: ${STRING//[^0-9]/}" >> $RESULT_FILE
else
	echo "Missing $WCET_FILE for $PREFIX"
fi

# Extract Stats
if [ -f "$STATS_FILE" ]; then
	STRING=$(cat "$STATS_FILE" | grep "Number of local variables promoted to the stack cache")
	echo "${PREFIX}LocVarPromo: ${STRING//[^0-9]/}" >> $RESULT_FILE
	STRING=$(cat "$STATS_FILE" | grep "Number of Arrays promoted to the stack cache")
	echo "${PREFIX}ArrayPromo: ${STRING//[^0-9]/}" >> $RESULT_FILE
else
	echo "Missing $STATS_FILE for $PREFIX"
fi

echo "" >> $RESULT_FILE