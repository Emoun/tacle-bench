#!/bin/bash

if [ -z "$1" ]; then
	echo "Please choose"
	exit 1
else
	CHOICE=$1
fi

if [ $CHOICE -eq 0 ]; then
	echo "Checking Traditional"
	POSTFIX=""
fi
if [ $CHOICE -eq 1 ]; then
	echo "Checking Traditional Dual-Issue"
	POSTFIX="-di"
fi
if [ $CHOICE -eq 2 ]; then
	echo "Checking Single-Path"
	POSTFIX="-sp"
fi
if [ $CHOICE -eq 3 ]; then
	echo "Checking Single-Path Dual-Issue"
	POSTFIX="-sp-di"
fi
if [ $CHOICE -eq 4 ]; then
	echo "Checking CET"
	POSTFIX="-cet"
fi
if [ $CHOICE -eq 5 ]; then
	echo "Checking CET Dual-Issue"
	POSTFIX="-cet-di"
fi

COMPILER=patmos-clang
EXEC=pasim

PASS=0
FAIL_COMP=0
FAIL_EXEC=0
IGNORE=0

for dir in */; do

    cd "$dir"

    printf "Entering ${dir} \n"
	
	if [ -f patmos-ignore.txt ]; then
		cat patmos-ignore.txt
		printf "\n"
		for BENCH in */; do
			((IGNORE++))
		done
		((IGNORE--)) # Ensure we don't count patmos-ignore.txt
	else
		for BENCH in */; do
			cd "$BENCH"
					
			printf "Checking ${BENCH} ..."
			
			if [ -f patmos-ignore.txt ]; then
				printf "Ignored\n"
				((IGNORE++))
			else
				for I in {1..1} ; do
					if [ -f "a$POSTFIX.out" ]; then
						rm "a$POSTFIX.out"
						rm -f "a$POSTFIX.stats"
						rm -f "a$POSTFIX.pml"
						rm -f "a$POSTFIX.wcet"
					fi
					
					if [ -f *.o ]; then
						rm *.o
					fi
					
					ENTRYFN=$(grep -E "_Pragma[[:space:]]*\([[:space:]]*\"entrypoint\"" -r * | cut -d ")" -f2 | cut -d "(" -f1)
					ENTRYFN=${ENTRYFN//[[:blank:]]/}
					
					FULL_OPTIONS=""
					if [[ "$POSTFIX" == *"-di"* ]]; then
						FULL_OPTIONS="-mllvm --mpatmos-disable-vliw=false"
					fi
					if [[ "$POSTFIX" == *"-sp"* || "$POSTFIX" == *"-cet"* ]]; then
						FULL_OPTIONS="$FULL_OPTIONS -mllvm --mpatmos-singlepath=$ENTRYFN"
					fi
					if [[ "$POSTFIX" == *"-cet"* ]]; then
						FULL_OPTIONS="$FULL_OPTIONS -mllvm --mpatmos-enable-cet"
					else
						FULL_OPTIONS="$FULL_OPTIONS -mllvm --mpatmos-serialize=a$POSTFIX.pml"
					fi
										
					#set -x
					# Please remove '&>/dev/null' to identify the warnings (if any)
					timeout 300 $COMPILER -O2 $FULL_OPTIONS *.c -o "a$POSTFIX.out" -mllvm --stats -mllvm --info-output-file="a$POSTFIX.stats" #&>/dev/null
										
					if [ -f "a$POSTFIX.out" ]; then
						timeout 1800 $EXEC "./a$POSTFIX.out" -V 2> "./a$POSTFIX.pasim" #&>/dev/null
						RETURNVALUE=$(echo $?)
						if [ $RETURNVALUE -eq 0 ]; then 
							if [[ "$POSTFIX" == *"-cet"* ]]; then
								BOUND=$(python3 ../../find_wcet.py "./a$POSTFIX.pasim" $ENTRYFN)
								echo "best WCET bound: $BOUND" > "a$POSTFIX.wcet"
							else
								platin wcet -i "a$POSTFIX.pml" -b "a$POSTFIX.out" -e $ENTRYFN --report > "a$POSTFIX.wcet" 2>&1
							fi
							break
						fi						
					fi
					#set +x
				done
				if [ -f "a$POSTFIX.out" ]; then
					if [ $RETURNVALUE -eq 0 ]; then
						printf "passed. \n"
						((PASS++))
					else
						printf "failed (wrong return value $RETURNVALUE). \n"
						((FAIL_EXEC++))
					fi
				else
					printf "failed (compiled with errors/warnings). \n"
					((FAIL_COMP++))
				fi
			fi
			cd ..
		done
	fi 
	
    printf "Leaving ${dir} \n\n"
    
    cd ..
done

echo "PASS: $PASS, FAIL_COMP: $FAIL_COMP, FAIL_EXEC: $FAIL_EXEC, IGNORED: $IGNORE"