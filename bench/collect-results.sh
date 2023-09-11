#!/bin/bash

rm -f result.txt

function  extract_runtime_stats {
	local PREFIX=$1
	local FILE_NAME=$2
	local STATS_FILE="${FILE_NAME}.stats"
	local OUT_FILE="${FILE_NAME}.out"
	local PASIM_FILE="${FILE_NAME}.pasim"
	local WCET_FILE="${FILE_NAME}.wcet"
	
	if [ -f "$PASIM_FILE" ]; then
		STRING=$(python3 ../../find_using_regex.py "./$PASIM_FILE" "<$ENTRYFN>\n.*\n\s*1\s*(\d*)" 1)
		echo "${PREFIX}Exec: ${STRING//[^0-9]/}" >> ../../result.txt 
		STRING=$(python3 ../../find_using_regex.py "./$PASIM_FILE" "Main Memory Statistics:.*\n(.*\n){6}\s*Stall Cycles\s*:\s*(\d*)" 2)
		echo "${PREFIX}ExecMainMemStall: ${STRING//[^0-9]/}" >> ../../result.txt 
	else
		echo "Missing $PASIM_FILE"
	fi
	
	if [ -f "$WCET_FILE" ]; then
		STRING=$(cat "$WCET_FILE" | grep "best WCET bound:")
		echo "${PREFIX}Wcet: ${STRING//[^0-9]/}" >> ../../result.txt 
	else
		echo "Missing $WCET_FILE"
	fi
}

function  extract_sp_stats {
	local PREFIX=$1
	local FILE_NAME=$2
	local STATS_FILE="${FILE_NAME}.stats"
	local OUT_FILE="${FILE_NAME}.out"
	
	STRING=$(du -sb $OUT_FILE)
	echo "${PREFIX}Size: ${STRING//[^0-9]/}" >> ../../result.txt
	local STRING=$(cat $STATS_FILE | grep "patmos-singlepath        - Instruction bytes in single-path code")
	echo "${PREFIX}Instrs: ${STRING//[^0-9]/}" >> ../../result.txt
	STRING=$(cat $STATS_FILE | grep "patmos-singlepath        - Number of functions used in single-path")
	echo "${PREFIX}Funcs: ${STRING//[^0-9]/}" >> ../../result.txt
	STRING=$(cat $STATS_FILE | grep "patmos-singlepath        - Number of functions marked as pseudo-root")
	echo "${PREFIX}PseudoRoots: ${STRING//[^0-9]/}" >> ../../result.txt
	STRING=$(cat $STATS_FILE | grep "patmos-singlepath        - Number of call instructions from & to single-path functions")
	echo "${PREFIX}Calls: ${STRING//[^0-9]/}" >> ../../result.txt
	STRING=$(cat $STATS_FILE | grep "patmos-singlepath        - Number of call instructions from & to pseudo-root functions")
	echo "${PREFIX}PseudoCalls: ${STRING//[^0-9]/}" >> ../../result.txt
	STRING=$(cat $STATS_FILE | grep "patmos-singlepath        - Number of single-path loop counters used")
	echo "${PREFIX}Counters: ${STRING//[^0-9]/}" >> ../../result.txt
}

function  extract_cet_stats {
	local PREFIX=$1
	local FILE_NAME=$2
	local STATS_FILE="${FILE_NAME}.stats"
	local OUT_FILE="${FILE_NAME}.out"
	
	local STRING=$(cat $STATS_FILE | grep "patmos-const-exec        - Number of non-phi instructions added by the 'counter' compensation algorithm")
	echo "${PREFIX}DCCInstrs: ${STRING//[^0-9]/}" >> ../../result.txt
	STRING=$(cat $STATS_FILE | grep "patmos-const-exec        - Number of non-phi instructions added by the 'opposite' constant execution time compensation")
	echo "${PREFIX}OPCInstrs: ${STRING//[^0-9]/}" >> ../../result.txt
	STRING=$(cat $STATS_FILE | grep "patmos-const-exec        - Number of functions using 'counter' algorithm for constant execution time")
	echo "${PREFIX}DCCFuncs: ${STRING//[^0-9]/}" >> ../../result.txt
	STRING=$(cat $STATS_FILE | grep "patmos-const-exec        - Number of functions not needing any compensation for constant execution time")
	echo "${PREFIX}NoCompFuncs: ${STRING//[^0-9]/}" >> ../../result.txt
	STRING=$(cat $STATS_FILE | grep "patmos-const-exec        - Number of functions using 'opposite' algorithm for constant execution time")
	echo "${PREFIX}OPCFuncs: ${STRING//[^0-9]/}" >> ../../result.txt
}

for dir in */; do

    cd "$dir"

    printf "Entering ${dir} \n"
	
	if [ -f patmos-ignore.txt ]; then
		echo "Ignored"
	else
		for BENCH in */; do
			cd "$BENCH"
					
			printf "Checking ${BENCH} ..."
			
			if [ -f patmos-ignore.txt ]; then
				printf "Ignored\n"
			else
				BENCHNAME=${BENCH::-1} #Remove the last '/'
				ENTRYFN=${BENCHNAME}_main
				
				for i in "Trad " "TradSI -si" "CET -cet" "CETPDI -cet-pdi" "CETSI -cet-si"
				do
					SPLIT=( $i )
					ID="${SPLIT[0]}"
					FILE_POSTFIX="${SPLIT[1]}"
					
					extract_runtime_stats "${BENCHNAME}${ID}" "a$FILE_POSTFIX"
					
					if [[ "$ID" == *"SP"* || "$ID" == *"CET"* ]]; then
						extract_sp_stats "${BENCHNAME}${ID}" "a$FILE_POSTFIX"
					fi
					if [[ "$ID" == *"CET"* ]]; then
						extract_cet_stats "${BENCHNAME}${ID}" "a$FILE_POSTFIX"
					fi
				done
				echo "" >> ../../result.txt 
			fi
					
			echo ""
			cd ..
		done
		
	fi
	printf "Leaving ${dir} \n\n"

	cd ..
done
