#!/bin/bash

if [[ $# -ne 2 ]]; then
    echo "Wrong number of arguments (should be 2)"
    exit 1
fi

inputFile=$1
outputFile=$2

if [[ ! -f "${inputFile}" ]]; then
    echo "The input file $inputFile does not exist"
    exit 2
fi

if [[ -f "${outputFile}" ]]; then
    echo "The output file already exists ${outputFile}"
    exit 3
fi

touch $outputFile

tempFile=$(mktemp)
cat $inputFile > $tempFile

while read -r rest ; do

    matchedLines=$(grep ",$rest" "$tempFile")

    minLine=$(echo "$matchedLines" | sort -n -t ',' -k 1 | head -n 1)

    echo "$minLine" >> "$outputFile"

    escapedRest=$(echo "$rest" | sed 's/[]\/$*.^[]/\\&/g')
    sed -i "/,$escapedRest$/d" "$tempFile"

done < <(cut -d ',' -f 2- "$inputFile" | sort | uniq -d)

rm -f $tempFile