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
					EXEC_TIME=$(python3 ../../find_wcet.py "./a.pasim" $ENTRYFN)
					echo "${BENCHNAME}TradExec: ${EXEC_TIME//[^0-9]/}" >> ../../result.txt 
					STRING=$(cat a.wcet | grep "best WCET bound:")
					echo "${BENCHNAME}Trad: ${STRING//[^0-9]/}" >> ../../result.txt 
				else
					echo "Missing a.wcet"
				fi
				if [ -f a-di.wcet ]; then
					EXEC_TIME=$(python3 ../../find_wcet.py "./a-di.pasim" $ENTRYFN )
					echo "${BENCHNAME}TradDIExec: ${EXEC_TIME//[^0-9]/}" >> ../../result.txt 
					STRING=$(cat a-di.wcet | grep "best WCET bound:")
					echo "${BENCHNAME}TradDI: ${STRING//[^0-9]/}" >> ../../result.txt 
				else
					echo "Missing a-di.wcet"
				fi
				if [ -f a-sp.wcet ]; then
					EXEC_TIME=$(python3 ../../find_wcet.py "./a-sp.pasim" $ENTRYFN )
					echo "${BENCHNAME}SPExec: ${EXEC_TIME//[^0-9]/}" >> ../../result.txt 
					STRING=$(cat a-sp.wcet | grep "best WCET bound:")
					echo "${BENCHNAME}SP: ${STRING//[^0-9]/}" >> ../../result.txt 
				else
					echo "Missing a-sp.wcet"
				fi
				if [ -f a-sp-di.wcet ]; then
					EXEC_TIME=$(python3 ../../find_wcet.py "./a-sp-di.pasim" $ENTRYFN )
					echo "${BENCHNAME}SPDIExec: ${EXEC_TIME//[^0-9]/}" >> ../../result.txt 
					STRING=$(cat a-sp-di.wcet | grep "best WCET bound:")
					echo "${BENCHNAME}SPDI: ${STRING//[^0-9]/}" >> ../../result.txt 
				else
					echo "Missing a-sp-di.wcet"
				fi
				if [ -f a-cet.wcet ]; then
					STRING=$(cat a-cet.wcet | grep "best WCET bound:")
					echo "${BENCHNAME}CET: ${STRING//[^0-9]/}" >> ../../result.txt 
				else
					echo "Missing a-cet.wcet"
				fi
				if [ -f a-cet-di.wcet ]; then
					STRING=$(cat a-cet-di.wcet | grep "best WCET bound:")
					echo "${BENCHNAME}CETDI: ${STRING//[^0-9]/}" >> ../../result.txt 
				else
					echo "Missing a-cet-di.wcet"
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
