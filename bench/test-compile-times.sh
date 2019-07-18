#!/bin/bash

COMPILER=patmos-clang

OPTIONS=" -Wall -Wno-unknown-pragmas -Werror -mpatmos-singlepath=main "

echo "Testing compile times (in milliseconds):"

for dir in */; do

    cd "$dir"

    for BENCH in */; do
        cd "$BENCH"
                
        if [ -f a.out ]; then
            rm a.out
        fi
        
        if [ -f *.o ]; then
            rm *.o
        fi
        echo "$dir$BENCH"
		
		for i in {1..100}
		do
		    START_TIME=$(date +%s%N | cut -b1-13)
			$COMPILER $OPTIONS *.c -O0
			ELAPSED_TIME=$(($(date +%s%N | cut -b1-13) - $START_TIME))
			
			echo "$ELAPSED_TIME"
		done
		
		
        cd ..
    done
    
    cd ..
done
