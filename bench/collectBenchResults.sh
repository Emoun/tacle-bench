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
	echo "Missing $WCET_FILE"
fi

# Extract Single-path statistics
if [[ "$ID" == *"sp"* || "$ID" == *"cet"* ]]; then
	STRING=$(du -sb $OUT_FILE)
	echo "${PREFIX}Size: ${STRING//[^0-9]/}" >> $RESULT_FILE
	STRING=$(cat $STATS_FILE | grep "patmos-singlepath        - Instruction bytes in single-path code")
	echo "${PREFIX}InstrBytes: ${STRING//[^0-9]/}" >> $RESULT_FILE
	STRING=$(cat $STATS_FILE | grep "patmos-singlepath        - Number of functions used in single-path")
	echo "${PREFIX}SPFuncs: ${STRING//[^0-9]/}" >> $RESULT_FILE
	STRING=$(cat $STATS_FILE | grep "patmos-singlepath        - Number of functions marked as pseudo-root")
	echo "${PREFIX}PseudoRoots: ${STRING//[^0-9]/}" >> $RESULT_FILE
	STRING=$(cat $STATS_FILE | grep "patmos-singlepath        - Number of call instructions from & to single-path functions")
	echo "${PREFIX}Calls: ${STRING//[^0-9]/}" >> $RESULT_FILE
	STRING=$(cat $STATS_FILE | grep "patmos-singlepath        - Number of call instructions from & to pseudo-root functions")
	echo "${PREFIX}PseudoCalls: ${STRING//[^0-9]/}" >> $RESULT_FILE
	STRING=$(cat $STATS_FILE | grep "patmos-singlepath        - Number of single-path loop counters used")
	echo "${PREFIX}Counters: ${STRING//[^0-9]/}" >> $RESULT_FILE
fi

# Extract CET statistics
if [[ "$ID" == *"cet"* ]]; then
	STRING=$(cat $STATS_FILE | grep "patmos-const-exec        - Number of non-phi instructions added by the 'counter' compensation algorithm")
	echo "${PREFIX}DCCInstrs: ${STRING//[^0-9]/}" >> $RESULT_FILE
	STRING=$(cat $STATS_FILE | grep "patmos-const-exec        - Number of non-phi instructions added by the 'opposite' constant execution time compensation")
	echo "${PREFIX}OPCInstrs: ${STRING//[^0-9]/}" >> $RESULT_FILE
	STRING=$(cat $STATS_FILE | grep "patmos-const-exec        - Number of functions using 'counter' algorithm for constant execution time")
	echo "${PREFIX}DCCFuncs: ${STRING//[^0-9]/}" >> $RESULT_FILE
	STRING=$(cat $STATS_FILE | grep "patmos-const-exec        - Number of functions not needing any compensation for constant execution time")
	echo "${PREFIX}NoCompFuncs: ${STRING//[^0-9]/}" >> $RESULT_FILE
	STRING=$(cat $STATS_FILE | grep "patmos-const-exec        - Number of functions using 'opposite' algorithm for constant execution time")
	echo "${PREFIX}OPCFuncs: ${STRING//[^0-9]/}" >> $RESULT_FILE
fi

echo "" >> $RESULT_FILE