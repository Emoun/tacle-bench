#!/bin/bash

# Directory of this file
BASEDIR=$(dirname "$0")
ID="$1"
ENTRYFN="$2"
COMPILE_OPTS="$3"
SIMULATOR_OPTS="$4"
POSTPROCESS="$5"

if [ "$ID" == "" ]; then
	echo "Empty 'ID' argument (1. argument)" > "$ID/fail.txt"
	exit
fi
if [ "$ENTRYFN" == "" ]; then
	echo "Empty 'ENTRYFN' argument (2. argument)" > "$ID/fail.txt"
	exit
fi

COMPILER=patmos-clang
SIMULATOR=pasim

# Clean any previous outputs
rm -rf "$ID"

mkdir "$ID"

TIMEOUT_OPTS="--kill-after=5s 600"

timeout $TIMEOUT_OPTS $COMPILER -O2 $COMPILE_OPTS *.c -o "$ID/a.out" -mllvm --stats -mllvm --info-output-file="$ID/stats.txt" > "$ID/compiler.txt" 2>&1

if [ -f "$ID/a.out" ]; then
	patmos-llvm-objdump -d "$ID/a.out" > "$ID/a.asm"

	timeout --kill-after=5s 1800 $SIMULATOR "$ID/a.out" -V --print-stats $ENTRYFN $SIMULATOR_OPTS > "$ID/pasim.txt" 2>&1
	RETURNVALUE=$(echo $?)
	
	if [ $RETURNVALUE -eq 0 ]; then
		if [ "$POSTPROCESS" == "1" ]; then
			# Get execution time from pasim
			BOUND=$(python3 $BASEDIR/find_using_regex.py "$ID/pasim.txt" "<$ENTRYFN>\n.*\n\s*1\s*(\d*)" 1)
			RETURNVALUE=$(echo $?)
			if [ $RETURNVALUE -eq 0 ]; then
				echo "best WCET bound: $BOUND" > "$ID/wcet.txt"
				echo "Extracted execution time" > "$ID/success.txt"
			else
				echo "Failed to get execution time" > "$ID/fail.txt"
			fi		
		elif [ "$POSTPROCESS" == "2" ]; then
			# Use platin to get WCET
			timeout $TIMEOUT_OPTS platin wcet -i "$ID/a.pml" -b "$ID/a.out" -e $ENTRYFN --target-call-return-costs --report > "$ID/wcet.txt" 2>&1
			RETURNVALUE=$(echo $?)
			if [ $RETURNVALUE -eq 0 ]; then
				echo "Extracted WCET" > "$ID/success.txt"
			else
				echo "Failed to get WCET" > "$ID/fail.txt"
			fi	
		else 
			echo "No postprocessing" > "$ID/success.txt"
		fi
	else
		echo "Runtime Failure" > "$ID/fail.txt"
	fi	
else
	echo "Compile Failure" > "$ID/fail.txt"
fi