#!/bin/bash

CONFIGS_TO_RUN="$1"
PROGRAMS_TO_RUN="$2"
RESULT_FILE="$3"

WAIT_ON_PID=$$

CONFIG_NAMES=(
	"Traditional" 
	"Traditional Single-Issue"
	"Single-Path"
	"Single-Path No Pseudo"
	"CET"
	"CET Single-Issue"
	"CET No Pseudo"
	"CET (OPC)"
	"CET (DCC)"
	"CET Permissive Dual-Issue"
	"CET No Equivalence Class Scheduling"
	"CET Single-Issue No Equivalence Class Scheduling"
	"CET Compensation function 1"
	"CET Compensation function 2"
	"CET Compensation function 8"
)
CONFIG_IDS=(
	"trad" 
	"trad-si"
	"sp"
	"sp-noop"
	"cet"
	"cet-si"
	"cet-noop"
	"cet-opc"
	"cet-dcc"
	"cet-pdi"
	"cet-necs"
	"cet-si-necs"
	"cet-comp1"
	"cet-comp2"
	"cet-comp8"
)
CONFIG_PREFIXES=(
	"Trad" 
	"TradSI"
	"SP"
	"SPNOOP"
	"CET"
	"CETSI"
	"CETNOOP"
	"CETOPC"
	"CETDCC"
	"CETPDI"
	"CETNECS"
	"CETSINECS"
	"CETCOMPONE"
	"CETCOMPTWO"
	"CETCOMPEIG"
)

WORKING_DIR=$(pwd)

run_bench(){

	POSTFIX=$1
	ENTRYFN=$2

	# Clean from previous run
	rm -rf "$POSTFIX"

	REPEAT=1

	for i in $(seq 1 $REPEAT); do
		
		FULL_OPTIONS=""
		PASIM_OPTIONS=""
		POSTPROCESSING=""
		if [[ "$POSTFIX" != *"-si"* ]]; then
			FULL_OPTIONS="-mllvm --mpatmos-disable-vliw=false"
		fi
		if [[ "$POSTFIX" == *"-noop"* ]]; then
			FULL_OPTIONS="-mllvm --mpatmos-disable-pseudo-roots"
		fi
		if [[ "$POSTFIX" == *"sp"* || "$POSTFIX" == *"cet"* ]]; then
			FULL_OPTIONS="$FULL_OPTIONS -mllvm --mpatmos-singlepath=$ENTRYFN"
		fi
		if [[ "$POSTFIX" == *"-pdi"* ]]; then
			FULL_OPTIONS="$FULL_OPTIONS -mllvm --mpatmos-enable-permissive-dual-issue"
			PASIM_OPTIONS="$PASIM_OPTIONS --permissive-dual-issue"
		fi
		if [[ "$POSTFIX" == *"-necs"* ]]; then
			FULL_OPTIONS="$FULL_OPTIONS -mllvm --mpatmos-disable-singlepath-scheduler-equivalence-class"
		fi
		if [[ "$POSTFIX" == *"-comp"* ]]; then
			COMP_FN=""
			if [[ "$POSTFIX" == *"-comp1"* ]]; then
				COMP_FN="__patmos_main_mem_access_compensation1_di"
			fi
			if [[ "$POSTFIX" == *"-comp2"* ]]; then
				COMP_FN="__patmos_main_mem_access_compensation2_di"
			fi
			if [[ "$POSTFIX" == *"-comp8"* ]]; then
				COMP_FN="__patmos_main_mem_access_compensation8_di"
			fi
			
			FULL_OPTIONS="$FULL_OPTIONS -mllvm --mpatmos-cet-compensation-function=$COMP_FN"
		fi
		if [[ "$POSTFIX" == *"cet"* ]]; then
			FULL_OPTIONS="$FULL_OPTIONS -mllvm --mpatmos-enable-cet"
			if [[ "$POSTFIX" == *"-opc"* ]]; then
				FULL_OPTIONS="$FULL_OPTIONS=opposite"
			elif [[ "$POSTFIX" == *"-dcc"* ]]; then
				FULL_OPTIONS="$FULL_OPTIONS=counter"
			fi
			POSTPROCESSING="1"
		else
			FULL_OPTIONS="$FULL_OPTIONS -mllvm --mpatmos-serialize=$POSTFIX-$i/a.pml"
			POSTPROCESSING="2"
		fi
		
		# Wait if too many jobs are running
		$WORKING_DIR/wait-jobs.sh "$WAIT_ON_PID"
		
		# Run async
		$WORKING_DIR/checkProgram.sh "$POSTFIX-$i" "$ENTRYFN"  "$FULL_OPTIONS" "$PASIM_OPTIONS" "$POSTPROCESSING" &

	done
	
	wait
	
	# Look for the one with the best results and rename it
	BEST_BOUND_IDX=1
	BEST_BOUND=0
	for i in $(seq 1 $REPEAT); do
		if [ -f "$POSTFIX-$i/wcet.txt" ]; then
			BOUND=$(python3 $WORKING_DIR/find_using_regex.py "$POSTFIX-$i/wcet.txt" "WCET bound: *(\d*)" 1)
			
			# Make sure integer was found
			if [[ "$BOUND" =~ ^[0-9]+$ ]]
			then
				if [ $BOUND -gt $BEST_BOUND ]; then 
					BEST_BOUND_IDX=$i
					BEST_BOUND=$BOUND
				fi
			fi			
		fi
	done
	
	# Keep the best, delete the rest
	for i in $(seq 1 $REPEAT); do
		if [ $i -eq $BEST_BOUND_IDX ]; then
			mv "$POSTFIX-$i" "$POSTFIX"
		else
			rm -rf "$POSTFIX-$i"
		fi
	done
}

for i in $CONFIGS_TO_RUN
do
	POSTFIX=${CONFIG_IDS[$i]}
	
	for dir in $PROGRAMS_TO_RUN
	do
		cd $dir
	
		ENTRYFN=$(grep -E "_Pragma[[:space:]]*\([[:space:]]*\"entrypoint\"" *.c | cut -d ")" -f2 | cut -d "(" -f1)
		ENTRYFN=${ENTRYFN//[[:blank:]]/}
		
		# Wait if too many jobs are running
		$WORKING_DIR/wait-jobs.sh $WAIT_ON_PID
		
		run_bench $POSTFIX $ENTRYFN &
		
		cd $WORKING_DIR
	done
	
	echo "Done initiating config: $POSTFIX"	
done

# Wait on all checks
wait

for i in $CONFIGS_TO_RUN
do
	SUCCESS=0
	FAIL=0
	UNKNOWN=0
	
	POSTFIX=${CONFIG_IDS[$i]}
	NAME=${CONFIG_NAMES[$i]}
	PREFIX=${CONFIG_PREFIXES[$i]}
	
	echo ""
	echo "vvvvvv $NAME vvvvvv"
	echo ""
	
	for dir in $PROGRAMS_TO_RUN
	do
		cd $dir
		
		BENCH_NAME=$(basename $dir)
		RATING=""
		MSG=""
		
		if [ -f "$POSTFIX/success.txt" ]; then
			if [ -f "$POSTFIX/fail.txt" ]; then
				RATING="-"
				MSG="Ambiguous Result"
				((UNKNOWN++))
			else
				RATING=" " # success
				((SUCCESS++))
				
				if [[ "$RESULT_FILE" != "" ]]; then
					ENTRYFN=$(grep -E "_Pragma[[:space:]]*\([[:space:]]*\"entrypoint\"" *.c | cut -d ")" -f2 | cut -d "(" -f1)
					ENTRYFN=${ENTRYFN//[[:blank:]]/}
					
					$WORKING_DIR/collectBenchResults.sh "$POSTFIX" "$BENCH_NAME$PREFIX" "$ENTRYFN" "$WORKING_DIR/$RESULT_FILE"
				fi
			fi
		elif [ -f "$POSTFIX/fail.txt" ]; then
			FAIL_MSG=$(cat $POSTFIX/fail.txt)
			MSG="$FAIL_MSG"
			RATING="X" # Failure
			((FAIL++))
		else
			MSG="No Result"
			RATING="-"
			((UNKNOWN++))
		fi
		
		echo "$RATING $dir: $MSG"
		
		cd $WORKING_DIR
	done
	echo ""
	echo "------------"
	echo ""
	echo "PASS: $SUCCESS"
	echo "FAIL: $FAIL"
	echo "Unkown: $UNKNOWN"
	echo ""
	echo "^^^^^^ $NAME ^^^^^^"
done