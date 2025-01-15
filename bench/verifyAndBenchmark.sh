#!/bin/bash

CONFIGS_TO_RUN="$1"
PROGRAMS_TO_RUN="$2"
RESULT_FILE="$3"

WAIT_ON_PID=$$

CONFIG_NAMES=(
	"Traditional" 
	"Traditional Single-Issue"
	"Local Value Optimization"
	"Local Value Optimization Single-Issue"
	"Array Optimization"
	"Array Optimization Single-Issue"
)
CONFIG_IDS=(
	"trad" 
	"trad-si"
	"loc"
	"loc-si"
	"loc-array"
	"loc-array-si"
)
CONFIG_PREFIXES=(
	"Trad" 
	"TradSI"
	"Loc"
	"LocSI"
	"LocArray"
	"LocArraySI"
)

WORKING_DIR=$(pwd)

run_bench(){

	POSTFIX=$1
	ENTRYFN=$2

	# Clean from previous run
	rm -rf "$POSTFIX"

	REPEAT=1

	for i in $(seq 1 $REPEAT); do
		
		FULL_OPTIONS="-mllvm --mpatmos-serialize=$POSTFIX-$i/a.pml"
		PASIM_OPTIONS=""
		POSTPROCESSING="2"
		if [[ "$POSTFIX" != *"-si"* ]]; then
			FULL_OPTIONS="$FULL_OPTIONS -mllvm --mpatmos-disable-vliw=false"
		fi
		if [[ "$POSTFIX" == *"loc"* ]]; then
			FULL_OPTIONS="$FULL_OPTIONS -mllvm --mpatmos-enable-stack-cache-promotion"
		fi
		if [[ "$POSTFIX" == *"array"* ]]; then
			FULL_OPTIONS="$FULL_OPTIONS -mllvm --mpatmos-enable-array-stack-cache-promotion"
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