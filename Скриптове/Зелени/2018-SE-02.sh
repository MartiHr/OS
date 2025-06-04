#!/bin/bash

if [[ $# -ne 2 ]]; then
    echo "There should be exactly two arguments"
    exit 1
fi

if [[ ! -f $1 ]]; then
    echo "The input string should be file"
    exit 2
fi

if [[ ! -d $2 ]]; then
    echo "The second argument should be an empty dir"
    exit 3
fi

if [[ -n $(ls -A "$2") ]]; then
    echo "The directory must be empty"
    exit 4
fi

path="${2}/dict.txt"
touch "${path}"

count=0
while read -r name; do
    ((count++))
    printf "%s;%d\n" "${name}" "${count}" >> $path

    numberedPath="${2}/${count}.txt"
    touch $numberedPath

    grep -E "$name" "$1" >> $numberedPath

done < <(cat $1 | cut -d ':' -f 1 | grep -E -o '^[a-zA-Z]+[ ]+[a-zA-Z]+' | sort | uniq)