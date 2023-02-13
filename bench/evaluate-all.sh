#!/bin/bash

rm -f result.txt

EXTRACT_WCET="python3 ../../find_wcet.py"

for dir in */; do

    cd "$dir"

    printf "Entering ${dir} \n"
	
	if [ -f patmos-ignore.txt ]; then
		echo "Ignored"
	else
		for BENCH in */; do
			cd "$BENCH"
					
			printf "Checking ${BENCH} ..."
			
			if [ -f patmos-ignore.txt ]; then
				printf "Ignored\n"
			else
				BENCHNAME=${BENCH::-1} #Remove the last '/'
				ENTRYFN=${BENCHNAME}_main
				
				if [ -f a.wcet ]; then
					EXEC_TIME=$(python3 ../../find_wcet.py "./a.pasim" $ENTRYFN )
					echo "${BENCHNAME}TradExec: ${EXEC_TIME//[^0-9]/}" >> ../../result.txt 
					STRING=$(cat a.wcet | grep "best WCET bound:")
					echo "${BENCHNAME}Trad: ${STRING//[^0-9]/}" >> ../../result.txt 
				else
					echo "Missing a.wcet"
				fi
				if [ -f a-sp.wcet ]; then
					EXEC_TIME=$(python3 ../../find_wcet.py "./a-sp.pasim" $ENTRYFN )
					echo "${BENCHNAME}SPExec: ${EXEC_TIME//[^0-9]/}" >> ../../result.txt 
					STRING=$(cat a-sp.wcet | grep "best WCET bound:")
					echo "${BENCHNAME}SP: ${STRING//[^0-9]/}" >> ../../result.txt 
				else
					echo "Missing a-sp.wcet"
				fi
				if [ -f a-sp-noop.wcet ]; then
					EXEC_TIME=$(python3 ../../find_wcet.py "./a-sp-noop.pasim" $ENTRYFN )
					echo "${BENCHNAME}SPNOOPExec: ${EXEC_TIME//[^0-9]/}" >> ../../result.txt 
					STRING=$(cat a-sp-noop.wcet | grep "best WCET bound:")
					echo "${BENCHNAME}SPNOOP: ${STRING//[^0-9]/}" >> ../../result.txt 
				else
					echo "Missing a-sp-noop.wcet"
				fi
				if [ -f a-cet.wcet ]; then
					STRING=$(cat a-cet.wcet | grep "best WCET bound:")
					echo "${BENCHNAME}CET: ${STRING//[^0-9]/}" >> ../../result.txt 
				else
					echo "Missing a-cet.wcet"
				fi
				if [ -f a-cet-noop.wcet ]; then
					STRING=$(cat a-cet-noop.wcet | grep "best WCET bound:")
					echo "${BENCHNAME}CETNOOP: ${STRING//[^0-9]/}" >> ../../result.txt 
				else
					echo "Missing a-cet-noop.wcet"
				fi
				echo "" >> ../../result.txt 
			fi
					
			echo ""
			cd ..
		done
		
	fi
	printf "Leaving ${dir} \n\n"

	cd ..
done
