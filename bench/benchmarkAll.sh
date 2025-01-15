#!/bin/bash

BASEDIR=$(dirname "$0")
WHITELIST=$1

ALL_BENCHMARKS=$(find . -mindepth 2 -maxdepth 2 -type d | sort)

CHOSEN_BENCHES=""

IGNORED_COUNT=0
CHOSEN_COUNT=0

for BENCH in $ALL_BENCHMARKS
do
	DO_IGNORE=0
	for IGN in \
		"bitcount" `#Recursive call` \
		"bitonic" `#Recursive call` \
		"fac" `#Recursive call` \
		"fir2dim" `#Runtime error (GCC)` \
		"isqrt" `#Runtime error (Unknown)` \
		"isqrt" `#Runtime error (Traditional)` \
		"parallel" `#Unsupported build` \
 		"rijndael_dec" `#Invalid loop bounds` \
		"rijndael_enc" `#Invalid loop bounds`\
		"ammunition" `#Recursive call` \
		"anagram" `#Recursive call` \
		"ammunition" `#Recursive call` \
		"anagram" `#Recursive call` \
		"quicksort" `#Recursive call` \
		"recursion" `#Recursive call` \
		"ludcmp" `#Runtime Failure (Traditional)` \
		"huff_enc" `#Failed to get WCET(Traditional)`
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

#$BASEDIR/verifyAndBenchmark.sh "0 1 2 3 4 5" "$CHOSEN_BENCHES" "$RESULT_FILE"
$BASEDIR/verifyAndBenchmark.sh "0 2 4" "$CHOSEN_BENCHES" "$RESULT_FILE"
