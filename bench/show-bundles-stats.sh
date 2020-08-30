#!/bin/bash

COMPILER=patmos-clang

OPTIONS=" -Wall -Wno-unknown-pragmas -Werror -mpatmos-singlepath=main "

echo "Testing compile times (in milliseconds):"

for dir in */; do

    cd "$dir"

    for BENCH in */; do
        cd "$BENCH"
        echo "$dir$BENCH"
		
		
		grep "bundle" a_bundled.stats
		
        cd ..
    done
    
    cd ..
done
