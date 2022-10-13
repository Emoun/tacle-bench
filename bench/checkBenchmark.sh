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
	OPTIONS="-O2 -mllvm --mpatmos-serialize=a.pml"
fi
if [ $CHOICE -eq 1 ]; then
	echo "Checking Single-path"
	POSTFIX="-sp"
	OPTIONS="-O2"
fi
if [ $CHOICE -eq 2 ]; then
	echo "Checking CET Opposite"
	POSTFIX="-cet-opposite"
	OPTIONS="-O2 -mllvm --mpatmos-enable-cet=opposite"
fi
if [ $CHOICE -eq 3 ]; then
	echo "Checking CET Counter"
	POSTFIX="-cet-counter"
	OPTIONS="-O2 -mllvm --mpatmos-enable-cet=counter"
fi
if [ $CHOICE -eq 4 ]; then
	echo "Checking CET hybrid"
	POSTFIX="-cet-hybrid"
	OPTIONS="-O2 -mllvm --mpatmos-enable-cet"
fi
if [ $CHOICE -eq 5 ]; then
	echo "Checking CET hybrid No-Pseudo"
	POSTFIX="-cet-pseudo"
	OPTIONS="-O2 -mllvm --mpatmos-enable-cet -mllvm --mpatmos-disable-pseudo-roots"
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
				cat patmos-ignore.txt
				printf "\n"
				((IGNORE++))
			else
				for I in {1..1} ; do
					if [ -f "a$POSTFIX.out" ]; then
						rm "a$POSTFIX.out"
						rm -f "a$POSTFIX-1.out"
						rm -f "a$POSTFIX-2.out"
						rm -f "a$POSTFIX-4.out"
						rm -f "a$POSTFIX-8.out"
						rm -f "a$POSTFIX.stats"
						rm -f "a$POSTFIX.pml"
						rm -f "a$POSTFIX.wcet"
					fi
					
					if [ -f *.o ]; then
						rm *.o
					fi
					
					ENTRYFN=$(grep -E "_Pragma[[:space:]]*\([[:space:]]*\"entrypoint\"" -r * | cut -d ")" -f2 | cut -d "(" -f1)
					ENTRYFN=${ENTRYFN//[[:blank:]]/}
					
					if [ -z "$POSTFIX" ]; then
						SP_FUN_OPT=""
						SP_ADD_OPTIONS=""
					else
						SP_FUN_OPT="-mllvm --mpatmos-singlepath=$ENTRYFN"
						SP_ADD_OPTIONS="-mllvm --stats -mllvm --info-output-file=a$POSTFIX.stats"
					fi
					
					#set -x
					# Please remove '&>/dev/null' to identify the warnings (if any)
					$COMPILER $OPTIONS $SP_FUN_OPT *.c -o "a$POSTFIX.out" $SP_ADD_OPTIONS #&>/dev/null
										
					if [ -f "a$POSTFIX.out" ]; then
						$EXEC "./a$POSTFIX.out" -V 2> "./a$POSTFIX.pasim" #&>/dev/null
						RETURNVALUE=$(echo $?)
						if [ $RETURNVALUE -eq 0 ]; then 
							if [ -z "$POSTFIX" ]; then
								platin wcet -i a.pml -b a.out -e $ENTRYFN --report > a.wcet 2>&1
							fi
							if [ "$POSTFIX" == "-cet-hybrid" ]; then
								$COMPILER $OPTIONS $SP_FUN_OPT *.c -o "a$POSTFIX-1.out" -mllvm --mpatmos-cet-compensation-function=__patmos_main_mem_access_compensation1
								$COMPILER $OPTIONS $SP_FUN_OPT *.c -o "a$POSTFIX-2.out" -mllvm --mpatmos-cet-compensation-function=__patmos_main_mem_access_compensation2
								$COMPILER $OPTIONS $SP_FUN_OPT *.c -o "a$POSTFIX-4.out" -mllvm --mpatmos-cet-compensation-function=__patmos_main_mem_access_compensation4
								$COMPILER $OPTIONS $SP_FUN_OPT *.c -o "a$POSTFIX-8.out" -mllvm --mpatmos-cet-compensation-function=__patmos_main_mem_access_compensation8
								
								$EXEC "./a$POSTFIX-1.out" -V 2> "a$POSTFIX-1.pasim"
								$EXEC "./a$POSTFIX-2.out" -V 2> "a$POSTFIX-2.pasim"
								$EXEC "./a$POSTFIX-4.out" -V 2> "a$POSTFIX-4.pasim"
								$EXEC "./a$POSTFIX-8.out" -V 2> "a$POSTFIX-8.pasim"
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