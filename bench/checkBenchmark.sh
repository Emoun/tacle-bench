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
	OPTIONS="-O2 -mserialize=a.pml"
fi
if [ $CHOICE -eq 1 ]; then
	echo "Checking Single-path"
	POSTFIX="-sp"
	OPTIONS="-O2 -mllvm --mpatmos-singlepath=main"
fi
if [ $CHOICE -eq 2 ]; then
	echo "Checking CET Opposite"
	POSTFIX="-cet-opposite"
	OPTIONS="-O2 -mllvm --mpatmos-singlepath=main -mllvm --mpatmos-enable-cet=opposite"
fi
if [ $CHOICE -eq 3 ]; then
	echo "Checking CET Counter"
	POSTFIX="-cet-counter"
	OPTIONS="-O2 -mllvm --mpatmos-singlepath=main -mllvm --mpatmos-enable-cet=counter"
fi
if [ $CHOICE -eq 4 ]; then
	echo "Checking CET hybrid"
	POSTFIX="-cet-hybrid"
	OPTIONS="-O2 -mllvm --mpatmos-singlepath=main -mllvm --mpatmos-enable-cet"
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
		((IGNORE--)) # Ensure we don't cound patmos-ignore.txt
	else
		for BENCH in */; do
			cd "$BENCH"
					
			printf "Checking ${BENCH} ..."
			
			if [ -f patmos-ignore.txt ]; then
				cat patmos-ignore.txt
				printf "\n"
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
					
					if [ -z "$POSTFIX" ]; then
						SP_ADD_OPTIONS=""
					else
						SP_ADD_OPTIONS="-mllvm --stats -mllvm --info-output-file=a$POSTFIX.stats"
					fi
					
					#set -x
					# Please remove '&>/dev/null' to identify the warnings (if any)
					$COMPILER $OPTIONS *.c -o "a$POSTFIX.out" $SP_ADD_OPTIONS #&>/dev/null
					
					if [ -f "a$POSTFIX.out" ]; then
						$EXEC "./a$POSTFIX.out" #&>/dev/null
						RETURNVALUE=$(echo $?)
						if [ $RETURNVALUE -eq 0 ]; then 
							if [ -z "$POSTFIX" ]; then
								platin wcet -i a.pml -b a.out -e main --report > a.wcet 2>&1
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