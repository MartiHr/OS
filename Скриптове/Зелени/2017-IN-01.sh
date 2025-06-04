#!/bin/bash

if [[ $# -ne 3 ]]; then
    echo "There should be exactly 3 arguments"
    exit 1
fi

if [[ ! -f $1 ]]; then
    echo "The first argument should be a file"
    exit 2
fi

if [[ -z $2 ]] || [[ -z $3 ]]; then
    echo "The second and third argument should be non empty"
    exit 3
fi

firstStr=$2
secondStr=$3

firstValues=$(cat "${1}" | awk -F '=' -v firstStr="$firstStr" '$1 == firstStr {print $2}' | tr ' ' '\n')
secondValues=$(cat "${1}" | awk -F '=' -v secondStr="$secondStr" '$1 == secondStr {print $2}' | tr ' ' '\n')

result=''

while read line; do
    echo $firstValues | grep -q -F "${line}"

    if [[ $? -ne 0 ]];then
        result+="${line} "
    fi
done < <(echo "$secondValues")

sed -i -E "s/(${secondStr}=).*/\1${result}/g" "$1"