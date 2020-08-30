#!/bin/bash

#COMPILER=gcc # Please adapt this line to your favorite compiler.
COMPILER=patmos-clang

OPTIONS=" -O2 -mpatmos-singlepath=main -Xllc -stats"
OPTIONS_BUNDLING="$OPTIONS -Xllc -mpatmos-disable-vliw=false"

#EXEC= # Adapt if the executable is to be executed via another program
#EXEC=valgrind\ -q
EXEC=pasim

PASS=0
FAIL_COMP=0
FAIL_EXEC=0

for dir in */; do

    cd "$dir"

    printf "Entering ${dir} \n"

    for BENCH in */; do
        cd "$BENCH"
                
        rm -rf *.out
		rm -rf *.o
		rm -rf *.stats
		rm -rf *bench.txt
        rm -rf *.asm
		
		if [ "$1" == "clean" ] 
		then
		    cd ..
			continue
		fi
		
        printf "Checking ${BENCH} ..."
		
        $COMPILER $OPTIONS *.c  &> a.stats
		$COMPILER $OPTIONS_BUNDLING *.c -o a_bundled.out &> a_bundled.stats
        
		patmos-llvm-objdump -d a.out > a.asm
		patmos-llvm-objdump -d a_bundled.out > a_bundled.asm
		
        if [ -f a.out ]; then
            $EXEC ./a.out --print-stats=main &> a_bench.txt
            RETURNVALUE1=$(echo $?)
			$EXEC ./a_bundled.out --print-stats=main &> a_bundled_bench.txt
            RETURNVALUE2=$(echo $?)
			
            if [ $RETURNVALUE1 -eq $RETURNVALUE2 ]; then
                printf "passed. \n"
                ((PASS++))
            else
                printf "failed (wrong return value $RETURNVALUE1 != $RETURNVALUE2). \n"
                ((FAIL_EXEC++))
            fi
        else
            printf "failed (compiled with errors/warnings). \n"
            ((FAIL_COMP++))
        fi 
        
        cd ..
    done

    printf "Leaving ${dir} \n\n"
    
    cd ..
done

echo "PASS: $PASS, FAIL_COMP: $FAIL_COMP, FAIL_EXEC: $FAIL_EXEC"