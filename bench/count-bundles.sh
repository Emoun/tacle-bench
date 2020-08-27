#!/bin/bash

COMPILER=patmos-clang

OPTIONS=" -Wall -Wno-unknown-pragmas -Werror -mpatmos-singlepath=main "

echo "Testing compile times (in milliseconds):"

for dir in */; do

    cd "$dir"

    for BENCH in */; do
        cd "$BENCH"
        echo "$dir$BENCH"
		
		patmos-llvm-objdump -d a.out > a.asm
		
		grep "{" a.asm
		
        cd ..
    done
    
    cd ..
done
