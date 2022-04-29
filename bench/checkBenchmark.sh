#!/bin/bash

#COMPILER=gcc # Please adapt this line to your favorite compiler.
COMPILER=patmos-clang

#POSTFIX=""
#OPTIONS="-O2"

#POSTFIX="-sp"
#OPTIONS="-O2 -mllvm --mpatmos-singlepath=main"

#POSTFIX="-cet-instr"
#OPTIONS="-O2 -mllvm --mpatmos-singlepath=main -mllvm --mpatmos-enable-cet=instruction"

POSTFIX="-cet-counter"
OPTIONS="-O2 -mllvm --mpatmos-singlepath=main -mllvm --mpatmos-enable-cet=counter"

#EXEC= # Adapt if the executable is to be executed via another program
#EXEC=valgrind\ -q
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
					fi
					
					if [ -f *.o ]; then
						rm *.o
					fi
					
					# Please remove '&>/dev/null' to identify the warnings (if any)
					$COMPILER $OPTIONS *.c -o "a$POSTFIX.out" #&>/dev/null
					
					if [ -f "a$POSTFIX.out" ]; then
						$EXEC "./a$POSTFIX.out" #&>/dev/null
						RETURNVALUE=$(echo $?)
						if [ $RETURNVALUE -eq 0 ]; then
							break
						fi						
					fi 
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