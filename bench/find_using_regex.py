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

search_result = re.search(regex, file_content)
if(search_result == None):
    print("Did not find in text.");
    print("File: ", file_path);
    print("Regext: ", regex);
    result = ""
else: 
    result = search_result.group(group_to_return)
print(result)
