#!/bin/bash

if [[ $# -ne 1 ]]; then
    echo "There should be exactly 1 argument passed"
    exit 1
fi

file=$1

if [[ ! -f $file ]]; then
    echo "The passed argument should be a file"
    exit 2
fi

while read -r site; do

    http2Count=$(grep -E "$site" "$file" | grep -E 'HTTP/2.0' | wc -l)
    httpNot2Count=$(grep -E "$site" "$file" | grep -E -v 'HTTP/2.0' | wc -l)

    echo "$site HTTP/2.0: $http2Count non-HTTP/2.0: $httpNot2Count"

    grep -E "${site}" "$file"| sort -k 1 | awk '$(NF-3) >= 302 {print $1}' | sort | uniq -c | sort -nr | head -n 5

done < <(cat "${file}"| cut -d ' ' -f 2 | sort | uniq -c | sort -nr  | head -n 3 | awk '{print $2}')