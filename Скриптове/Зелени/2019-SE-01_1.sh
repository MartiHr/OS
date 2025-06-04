#!/bin/bash

tempFile=$(mktemp)

while read line; do
    echo $line >> $tempFile
done

maxAbs=-1
while read -r abs; do
    if (( abs > maxAbs )); then
        maxAbs=$abs
    fi
done < <(grep -E '[0-9]+' -o "$tempFile")

tempFile2=$(mktemp)

while read -r number; do
    abs=$(echo $number | grep -E '[0-9]+' -o)

    if (( abs == maxAbs )); then
        echo "$number" >> "$tempFile2"
    fi
done < <(grep -E '\-?[0-9]+' -o "$tempFile")

cat "$tempFile2" | sort | uniq

rm -f $tempFile
rm -f $tempFile2