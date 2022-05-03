#!/bin/bash

for dir in */; do

    cd "$dir"

    printf "Entering ${dir} \n"
	
	for BENCH in */; do
		cd "$BENCH"
				
		printf "Checking ${BENCH} ..."
		
		if [ -f a.out ]; then
			if [ -f a-sp.out ]; then
				if [ -f a-cet-opposite.out ]; then
					if [ -f a-cet-counter.out ]; then
						if [ -f a-cet-hybrid.out ]; then
							echo "Traditional:" > cycles.txt
							pasim a.out --print-stats main 2>&1 | grep "Cycles:" >> cycles.txt
							
							cat a.wcet | grep "best WCET bound:" >/dev/null 2>&1
							RET=$(echo $?)
							if [ $RET -eq 0 ]; then 
								cat a.wcet | grep "best WCET bound:" >> cycles.txt
								cat a.wcet | grep "cache-min-hits-data:" >> cycles.txt
								cat a.wcet | grep "cache-unknown-address-data:" >> cycles.txt
							else
								echo "No WCET Bound" >>cycles.txt
							fi
							
							echo "SP:" >> cycles.txt
							pasim a-sp.out --print-stats main 2>&1 | grep "Cycles:" >> cycles.txt
							echo "SP no cache:" >> cycles.txt
							pasim a-sp.out -D no --print-stats main 2>&1 | grep "Cycles:" >> cycles.txt
							echo "CET-Opposite:" >> cycles.txt
							pasim a-cet-opposite.out --print-stats main 2>&1 | grep "Cycles:" >> cycles.txt
							echo "CET-Counter:" >> cycles.txt
							pasim a-cet-counter.out --print-stats main 2>&1 | grep "Cycles:" >> cycles.txt
							echo "CET-Hybrid:" >> cycles.txt
							pasim a-cet-hybrid.out --print-stats main 2>&1 | grep "Cycles:" >> cycles.txt
						else
							echo "No CET-Hybrid"
						fi
					else
						echo "No CET-Counter"
					fi
				else
					echo "No CET-Instr"
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