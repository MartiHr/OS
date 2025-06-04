 #!/bin/bash

 if [[ $# -ne 2 ]]; then
     echo "Wrong number of arguments"
     exit 1
 fi

 echo $1 | grep -Eq '^[0-9]+$'
 if [[ "${?}" -ne 0 ]]; then
     echo "The first argument is not a number"
     exit 2
 fi

 echo $2 | grep -Eq '^[0-9]+$'

 if [[ $? -ne 0 ]]; then
     echo "The second argument is not a number"
     exit 3
 fi

 left=$1
 right=$2

 if (( $1 > $2 )); then
     temp=$left
     left=$right
     right=$temp
 fi

 if [[ ! -d 'a' ]]; then
     mkdir a
 fi

 if [[ ! -d 'b' ]]; then
     mkdir b
 fi

 if [[ ! -d 'c' ]]; then
     mkdir c
 fi

 while read -r file; do
     currentLines=$(cat "${file}" | wc -l)

     if (( $currentLines < $left )); then
         mv "${file}" "./a/${file}"
     elif (( $currentLines >= $left && $currentLines <= $right )); then
         mv "${file}" "./b/${file}"
     else
         mv "${file}" "./c/${file}"
     fi
 done < <(find . -maxdepth 1 -type f -printf "%f\n")