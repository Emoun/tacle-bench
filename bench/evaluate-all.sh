#!/bin/bash

rm -f result.txt

EXTRACT_WCET="python3 ../../find_wcet.py"

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
				
				if [ -f a.wcet ]; then
					EXEC_TIME=$(python3 ../../find_wcet.py "./a.pasim" $ENTRYFN )
					echo "${BENCHNAME}TradExec: ${EXEC_TIME//[^0-9]/}" >> ../../result.txt 
					STRING=$(cat a.wcet | grep "best WCET bound:")
					echo "${BENCHNAME}Trad: ${STRING//[^0-9]/}" >> ../../result.txt 
				else
					echo "Missing a.wcet"
				fi
				
				extract_sp_stats "${BENCHNAME}CET" "a-cet"
				if [ -f a-cet.wcet ]; then
					STRING=$(cat a-cet.wcet | grep "best WCET bound:")
					echo "${BENCHNAME}CET: ${STRING//[^0-9]/}" >> ../../result.txt 
				else
					echo "Missing a-cet.wcet"
				fi
				extract_cet_stats "${BENCHNAME}CET" "a-cet"
								
				extract_sp_stats "${BENCHNAME}CETNOOP" "a-cet-noop"
				if [ -f a-cet-noop.wcet ]; then
					STRING=$(cat a-cet-noop.wcet | grep "best WCET bound:")
					echo "${BENCHNAME}CETNOOP: ${STRING//[^0-9]/}" >> ../../result.txt 
				else
					echo "Missing a-cet-noop.wcet"
				fi
				extract_cet_stats "${BENCHNAME}CETNOOP" "a-cet-noop"
				
				echo "" >> ../../result.txt 
			fi
					
			echo ""
			cd ..
		done
		
	fi
	printf "Leaving ${dir} \n\n"

	cd ..
done
