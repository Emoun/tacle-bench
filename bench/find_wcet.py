import re
import sys

file_path = sys.argv[1]

main_function = sys.argv[2]

#print(file_path, " ", main_function)

#open text file in read mode
text_file = open(file_path, "r")
 
#read whole file to a string
file_content = text_file.read()
 
#close file
text_file.close()

regex = "<" + main_function + ">\n.*\n\s*1\s*(\d*)"

exec_cycles = re.search(regex, file_content).group(1)

print(exec_cycles)