#!/bin/bash

rm -f result.txt

EXTRACT_WCET="python3 ../../find_wcet.py"

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
							BENCHNAME=${BENCH::-1} #Remove the last '/'
							
							ENTRYFN=$(grep -E "_Pragma[[:space:]]*\([[:space:]]*\"entrypoint\"" -r * | cut -d ")" -f2 | cut -d "(" -f1)
							ENTRYFN=${ENTRYFN//[[:blank:]]/}
							
							STRING=$($EXTRACT_WCET a.pasim $ENTRYFN)
							echo "${BENCHNAME}Trad: $STRING" >> ../../result.txt 

							cat a.wcet | grep "best WCET bound:" >/dev/null 2>&1
							RET=$(echo $?)
							if [ $RET -eq 0 ]; then 
								STRING=$(cat a.wcet | grep "best WCET bound:")
								echo "${BENCHNAME}TradWcet: ${STRING//[^0-9]/}" >> ../../result.txt 

								STRING=$(cat a.wcet | grep "cache-unknown-address-data:")
								echo "${BENCHNAME}TradCacheMiss: ${STRING//[^0-9]/}" >> ../../result.txt 
							fi

							STRING=$($EXTRACT_WCET a-sp.pasim  $ENTRYFN)
							echo "${BENCHNAME}Sp: $STRING" >> ../../result.txt  

							pasim a-sp.out -D no -V 2> a-sp-nocache.pasim
							STRING=$($EXTRACT_WCET a-sp-nocache.pasim $ENTRYFN)
							echo "${BENCHNAME}SpNoCache: $STRING" >> ../../result.txt  

							STRING=$($EXTRACT_WCET a-cet-opposite.pasim  $ENTRYFN)
							echo "${BENCHNAME}CetOpposite: $STRING" >> ../../result.txt 
							STRING=$(cat a-cet-opposite.stats | grep "patmos-const-exec        - Number of non-phi instructions added by the 'opposite' constant execution time compensation")
							echo "${BENCHNAME}CetOppositeInstrs: ${STRING//[^0-9]/}" >> ../../result.txt 

							STRING=$($EXTRACT_WCET a-cet-counter.pasim  $ENTRYFN)
							echo "${BENCHNAME}CetCounter: $STRING" >> ../../result.txt  
							STRING=$(cat a-cet-counter.stats | grep "patmos-const-exec        - Number of non-phi instructions added by the 'counter' compensation algorithm")
							echo "${BENCHNAME}CetCounterInstrs: ${STRING//[^0-9]/}" >> ../../result.txt 

							STRING=$($EXTRACT_WCET a-cet-hybrid.pasim  $ENTRYFN)
							echo "${BENCHNAME}CetHybrid: $STRING" >> ../../result.txt  
							STRING=$(cat a-cet-hybrid.stats | grep "patmos-const-exec        - Number of functions using 'opposite' algorithm for constant execution time")
							echo "${BENCHNAME}CetHybridOppositeFuns: ${STRING//[^0-9]/}" >> ../../result.txt 
							STRING=$(cat a-cet-hybrid.stats | grep "patmos-const-exec        - Number of non-phi instructions added by the 'opposite' constant execution time compensation")
							echo "${BENCHNAME}CetHybridOppositeInstrs: ${STRING//[^0-9]/}" >> ../../result.txt 
							STRING=$(cat a-cet-hybrid.stats | grep "patmos-const-exec        - Number of functions using 'counter' algorithm for constant execution time")
							echo "${BENCHNAME}CetHybridCounterFuns: ${STRING//[^0-9]/}" >> ../../result.txt 
							STRING=$(cat a-cet-hybrid.stats | grep "patmos-const-exec        - Number of non-phi instructions added by the 'counter' compensation algorithm")
							echo "${BENCHNAME}CetHybridCounterInstrs: ${STRING//[^0-9]/}" >> ../../result.txt 
							STRING=$(cat a-cet-hybrid.stats | grep "patmos-const-exec        - Number of functions not needing any compensation for constant execution time")
							echo "${BENCHNAME}CetHybridNoCompFuns: ${STRING//[^0-9]/}" >> ../../result.txt 
							STRING=$(cat a-cet-hybrid.stats | grep "patmos-singlepath        - Number of functions used in single-path")
							echo "${BENCHNAME}CetHybridSPFuns: ${STRING//[^0-9]/}" >> ../../result.txt 
							STRING=$(cat a-cet-hybrid.stats | grep "patmos-singlepath        - Number of functions marked as pseudo-root")
							echo "${BENCHNAME}CetHybridPseudoFuns: ${STRING//[^0-9]/}" >> ../../result.txt 
							STRING=$($EXTRACT_WCET a-cet-hybrid-1.pasim  $ENTRYFN)
							echo "${BENCHNAME}CetHybridOne: $STRING" >> ../../result.txt  
							STRING=$($EXTRACT_WCET a-cet-hybrid-2.pasim  $ENTRYFN)
							echo "${BENCHNAME}CetHybridTwo: $STRING" >> ../../result.txt  
							STRING=$($EXTRACT_WCET a-cet-hybrid-4.pasim  $ENTRYFN)
							echo "${BENCHNAME}CetHybridFour: $STRING" >> ../../result.txt  
							STRING=$($EXTRACT_WCET a-cet-hybrid-8.pasim  $ENTRYFN)
							echo "${BENCHNAME}CetHybridEight: $STRING" >> ../../result.txt  
																													
							echo "" >> ../../result.txt 
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