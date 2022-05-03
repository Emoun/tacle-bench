find . -type f -name patmos-ignore.txt -printf "\n%p: " -exec cat {} \;
