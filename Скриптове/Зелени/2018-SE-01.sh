#!/bin/bash

if [[ $# -ne 1 ]]; then
    echo "Wrong number of arguments";
    exit 1

fi

if [[ ! -d $1 ]]; then
    echo "The passed argument should be a directory"
    exit 2
fi

tempFile=$(mktemp)

while read -r user filePath; do
    lines=$(cat "${filePath}" | wc -l)
    echo $user $lines >> "${tempFile}"
    #echo $user $lines > $tempFile

done < <(find $1 -mindepth 4 -type f | awk -F '/' '{print $(NF-1), $0}')

cat $tempFile | awk '{ value[$1] += $2 } END { for (key in value) print key, value[key] }' | sort -t ' ' -k 2 -nr | head

rm -f $tempFile