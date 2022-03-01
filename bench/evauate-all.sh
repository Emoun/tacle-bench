#!/bin/bash

for dir in */; do

    cd "$dir"

    printf "Entering ${dir} \n"
	
	for BENCH in */; do
		cd "$BENCH"
				
		printf "Checking ${BENCH} ..."
		
		if [ -f a.out ]; then
			if [ -f a-sp.out ]; then
				if [ -f a-sp-cat.out ]; then
					echo "Traditional:" > cycles.txt
					pasim a.out --print-stats main 2>&1 | grep "Cycles:" >> cycles.txt
					echo "SP:" >> cycles.txt
					pasim a-sp.out --print-stats main 2>&1 | grep "Cycles:" >> cycles.txt
					echo "SP no cache:" >> cycles.txt
					pasim a-sp.out -D no --print-stats main 2>&1 | grep "Cycles:" >> cycles.txt
					echo "CAT:" >> cycles.txt
					pasim a-sp-cat.out --print-stats main 2>&1 | grep "Cycles:" >> cycles.txt
				else
					echo "No CAT"
				fi
			else
				echo "No single-path"
			fi
		else
			echo "No compiles"
		fi 
		echo ""
		cd ..
	done
	
    printf "Leaving ${dir} \n\n"
    
    cd ..
done

echo "PASS: $PASS, FAIL_COMP: $FAIL_COMP, FAIL_EXEC: $FAIL_EXEC, IGNORED: $IGNORE"