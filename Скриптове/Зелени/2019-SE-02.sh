#!/bin/bash

if (( $# < 1 )); then
    echo "At least one argument should be passed"
    exit 1
fi

N=10

if [[ "${1}" == "-n" ]]; then
    N=$2
    shift 2
fi

result=$(mktemp)

for file in "$@"; do

    if [[ ! -f $file ]]; then
        continue
    fi

    idf=$(basename $file .log)
    while read -r line; do
        timestamp=$(echo $line | cut -d ' ' -f -2)
        rest=$(echo $line | cut -d ' ' -f 3-)
        printf "%s %s %s\n" "$timestamp" "$idf" "$rest" >> $result
    done < <(tail -n "$N" "$file")
done

sort $result

rm -f $result