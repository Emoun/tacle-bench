#!/bin/bash

BASEDIR=$(dirname "$0")
WHITELIST=$1

ALL_BENCHMARKS=$(find . -mindepth 2 -maxdepth 2 -type d)

CHOSEN_BENCHES=""

IGNORED_COUNT=0
CHOSEN_COUNT=0

for BENCH in $ALL_BENCHMARKS
do
	DO_IGNORE=0
	for IGN in \
		"powerwindow" `# missing loop bound` \
		"bitcount" `#Recursive call` \
		"bitonic" `#Recursive call` \
		"fac" `#Recursive call` \
		"filterbank" `#pasim saturate (CET)` \
		"fir2dim" `#Runtime error (Traditional)` \
		"isqrt" `#Runtime error (Traditional)` \
		"lms" `#missing loop bounds` \
		"ludcmp" `# Runtime error (Traditional)` \
		"md5" `#Compile error (Singlepath, "Loop has no bound. Loop bound expected in the following MBB but was not found: 'while.cond'!")` \
		"minver" `#Runtime Failure (CET-OPC)` \
		"pm" `#pasim saturate (CET)` \
		"prime" `#Compile error (Singlepath, "Loop has no bound. Loop bound expected in the following MBB but was not found: 'for.cond'!")` \
		"quicksort" `#Recursive call` \
		"recursion" `#Recursive call` \
		"sha" `##Compile Failure (CET)` \
		"parallel" `#Unsupported build` \
		"ammunition" `#Recursive call` \
		"anagram" `#Recursive call` \
		"audiobeam" `#Runtime Failure (CET)` \
		"dijkstra" `#Timeout (CET)` \
		"epic" `#Timeout (CET)` \
		"g723_enc" `#Runtime Failure (CET)` \
		"gsm_dec" `#Compile Failure (CET)` \
		"gsm_enc" `#Compile Failure (CET, LLVM ERROR: llvm.memset length argument not a constant value)` \
		"huff_dec" `#Runtime Failure (CET)` \
		"huff_enc" `#Recursive call` \
		"mpeg2" `#Compile Failure (CET, IndexedMap.h:51... && index out of bounds!)` \
		"petrinet" `# Compile Failure (CET, manual oom)` \
		"rijndael_dec" `#Invalid loop bounds` \
		"rijndael_enc" `#Invalid loop bounds` \
		"susan" `#Compile Failure (CET)` 		
	do
		if [[ "$BENCH" == *"$IGN"* ]]; then
			DO_IGNORE=1
		fi
	done	
	
	if [[ "$WHITELIST" == "" ]]; then
		DO_WHITELIST=1
	else
		DO_WHITELIST=0
	fi
	for WL in $WHITELIST
	do
		if [[ "$BENCH" == *"$WL"* ]]; then
			DO_WHITELIST=1
		fi
	done
	
	if [ $DO_IGNORE -eq 0 ]; then 
		if [ $DO_WHITELIST -eq 1 ]; then 
			CHOSEN_BENCHES="$CHOSEN_BENCHES $BENCH"
			((CHOSEN_COUNT++))
		else
			echo "Ignoring $BENCH"
			((IGNORED_COUNT++))
		fi
	else
		echo "Ignoring $BENCH"
		((IGNORED_COUNT++))
	fi
done

echo ""
echo "Chosen: $CHOSEN_COUNT"
echo "Ignored: $IGNORED_COUNT"

# Clean previous results
RESULT_FILE="$BASEDIR/results.txt"

rm -f "$RESULT_FILE"

$BASEDIR/verifyAndBenchmark.sh "0 1 4 5 6 7 8 9 10 11 12 13 14" "$CHOSEN_BENCHES" "$RESULT_FILE"
