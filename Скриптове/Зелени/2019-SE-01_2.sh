#!/bin/bash

tempFile=$(mktemp)

while read line; do
    echo "$line" >> "$tempFile"
done

tempFileNums=$(mktemp)

# Извличаме уникални цели числа
grep -E '\-?[0-9]+' -o "$tempFile" | sort -n | uniq > "$tempFileNums"

# Намираме максималната сума на цифрите
maxSum=-1
while read -r number; do
    abs=${number#-}
    sum=0
    for (( i=0; i<${#abs}; i++ )); do
        digit=${abs:$i:1}
        ((sum += digit))
    done

    if (( sum > maxSum )); then
        maxSum=$sum
    fi
done < "$tempFileNums"

# Записваме числата с максимална сума на цифрите
tempFileFiltered=$(mktemp)

while read -r number; do
    abs=${number#-}
    sum=0
    for (( i=0; i<${#abs}; i++ )); do
        digit=${abs:$i:1}
        ((sum += digit))
    done

    if (( sum == maxSum )); then
        echo "$number" >> "$tempFileFiltered"
    fi
done < "$tempFileNums"

# Извеждаме най-малкото от тях
sort -n "$tempFileFiltered" | head -n 1

rm -f "$tempFile" "$tempFileNums" "$tempFileFiltered"
