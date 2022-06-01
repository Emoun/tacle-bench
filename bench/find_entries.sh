


for dir in */; do

    cd "$dir"

    printf "Entering ${dir} \n"
	
	if [ -f patmos-ignore.txt ]; then
		printf "Ignored\n"
	else
		for BENCH in */; do
			cd "$BENCH"
			
			printf "Checking ${BENCH} ..."
			
			if [ -f patmos-ignore.txt ]; then
				printf "Ignored\n"
			else
				rm -f a-test.out
				STRING=$(grep -E "_Pragma[[:space:]]*\([[:space:]]*\"entrypoint\"" -r * | cut -d ")" -f2 | cut -d "(" -f1)
				STRING=${STRING//[[:blank:]]/}
				
				echo "$STRING"
				
				patmos-clang *.c -O2 -mllvm --mpatmos-singlepath=$STRING -o a-test.out
				RET=$(echo $?)
				if [ $RET -eq 0 ]; then 
					patmos-llvm-objdump -d a-test.out | grep "<$STRING>"
					RET=$(echo $?)
					if [ $RET -eq 0 ]; then
						pasim a-test.out --print-stats $STRING 2>&1 | grep "Cycles:"
						RET=$(echo $?)
					fi
				fi
			fi
						
			echo ""
			cd ..
		done
	fi
    printf "Leaving ${dir} \n\n"
    
    cd ..
done