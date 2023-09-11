import re
import sys

file_path = sys.argv[1]

regex = sys.argv[2]

group_to_return = int(sys.argv[3])

#open text file in read mode
text_file = open(file_path, "r")
 
#read whole file to a string
file_content = text_file.read()
 
#close file
text_file.close()

result = re.search(regex, file_content).group(group_to_return)

print(result)
