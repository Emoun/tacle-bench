#!/bin/bash

rm -f result.txt

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
							if [ -f a-cet-pseudo.out ]; then
								if [ -f a-trad-12.out ]; then
									BENCHNAME=${BENCH::-1} #Remove the last '/'
									
									ENTRYFN=$(grep -E "_Pragma[[:space:]]*\([[:space:]]*\"entrypoint\"" -r * | cut -d ")" -f2 | cut -d "(" -f1)
									ENTRYFN=${ENTRYFN//[[:blank:]]/}
									
									STRING=$(pasim a.out --print-stats $ENTRYFN 2>&1 | grep "Cycles:")
									echo "${BENCHNAME}Trad: ${STRING//[^0-9]/}" >> ../../result.txt 
									STRING=$(pasim a-trad-12.out --print-stats $ENTRYFN 2>&1 | grep "Cycles:")
									echo "${BENCHNAME}TradNew: ${STRING//[^0-9]/}" >> ../../result.txt 

									cat a.wcet | grep "best WCET bound:" >/dev/null 2>&1
									RET=$(echo $?)
									if [ $RET -eq 0 ]; then 
										STRING=$(cat a.wcet | grep "best WCET bound:")
										echo "${BENCHNAME}TradWcet: ${STRING//[^0-9]/}" >> ../../result.txt 

										STRING=$(cat a.wcet | grep "cache-unknown-address-data:")
										echo "${BENCHNAME}TradCacheMiss: ${STRING//[^0-9]/}" >> ../../result.txt 
									fi

									STRING=$(pasim a-sp.out --print-stats $ENTRYFN 2>&1 | grep "Cycles:")
									echo "${BENCHNAME}Sp: ${STRING//[^0-9]/}" >> ../../result.txt  

									STRING=$(pasim a-sp.out -D no --print-stats $ENTRYFN 2>&1 | grep "Cycles:")
									echo "${BENCHNAME}SpNoCache: ${STRING//[^0-9]/}" >> ../../result.txt  

									STRING=$(pasim a-cet-opposite.out --print-stats $ENTRYFN 2>&1 | grep "Cycles:")
									echo "${BENCHNAME}CetOpposite: ${STRING//[^0-9]/}" >> ../../result.txt 
									STRING=$(cat a-cet-opposite.stats | grep "patmos-const-exec        - Number of non-phi instructions added by the 'opposite' constant execution time compensation")
									echo "${BENCHNAME}CetOppositeInstrs: ${STRING//[^0-9]/}" >> ../../result.txt 

									STRING=$(pasim a-cet-counter.out --print-stats $ENTRYFN 2>&1 | grep "Cycles:")
									echo "${BENCHNAME}CetCounter: ${STRING//[^0-9]/}" >> ../../result.txt  
									STRING=$(cat a-cet-counter.stats | grep "patmos-const-exec        - Number of non-phi instructions added by the 'counter' compensation algorithm")
									echo "${BENCHNAME}CetCounterInstrs: ${STRING//[^0-9]/}" >> ../../result.txt 

									STRING=$(pasim a-cet-hybrid.out --print-stats $ENTRYFN 2>&1 | grep "Cycles:")
									echo "${BENCHNAME}CetHybrid: ${STRING//[^0-9]/}" >> ../../result.txt  
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
									STRING=$(pasim a-cet-hybrid-1.out --print-stats $ENTRYFN 2>&1 | grep "Cycles:")
									echo "${BENCHNAME}CetHybridOne: ${STRING//[^0-9]/}" >> ../../result.txt  
									STRING=$(pasim a-cet-hybrid-2.out --print-stats $ENTRYFN 2>&1 | grep "Cycles:")
									echo "${BENCHNAME}CetHybridTwo: ${STRING//[^0-9]/}" >> ../../result.txt  
									STRING=$(pasim a-cet-hybrid-4.out --print-stats $ENTRYFN 2>&1 | grep "Cycles:")
									echo "${BENCHNAME}CetHybridFour: ${STRING//[^0-9]/}" >> ../../result.txt  
									STRING=$(pasim a-cet-hybrid-8.out --print-stats $ENTRYFN 2>&1 | grep "Cycles:")
									echo "${BENCHNAME}CetHybridEight: ${STRING//[^0-9]/}" >> ../../result.txt  
									
									STRING=$(pasim a-cet-pseudo.out --print-stats $ENTRYFN 2>&1 | grep "Cycles:")
									echo "${BENCHNAME}CetPseudo: ${STRING//[^0-9]/}" >> ../../result.txt  
									STRING=$(cat a-cet-pseudo.stats | grep "patmos-const-exec        - Number of functions using 'opposite' algorithm for constant execution time")
									echo "${BENCHNAME}CetPseudoOppositeFuns: ${STRING//[^0-9]/}" >> ../../result.txt 
									STRING=$(cat a-cet-pseudo.stats | grep "patmos-const-exec        - Number of non-phi instructions added by the 'opposite' constant execution time compensation")
									echo "${BENCHNAME}CetPseudoOppositeInstrs: ${STRING//[^0-9]/}" >> ../../result.txt 
									STRING=$(cat a-cet-pseudo.stats | grep "patmos-const-exec        - Number of functions using 'counter' algorithm for constant execution time")
									echo "${BENCHNAME}CetPseudoCounterFuns: ${STRING//[^0-9]/}" >> ../../result.txt 
									STRING=$(cat a-cet-pseudo.stats | grep "patmos-const-exec        - Number of non-phi instructions added by the 'counter' compensation algorithm")
									echo "${BENCHNAME}CetPseudoCounterInstrs: ${STRING//[^0-9]/}" >> ../../result.txt 
									STRING=$(cat a-cet-pseudo.stats | grep "patmos-const-exec        - Number of functions not needing any compensation for constant execution time")
									echo "${BENCHNAME}CetPseudoNoCompFuns: ${STRING//[^0-9]/}" >> ../../result.txt 
																								
									echo "" >> ../../result.txt 
								else
									echo "No Traiditional LLVM12"
								fi
							else
								echo "No CET-Pseudo"
							fi
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