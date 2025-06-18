#!/bin/bash

if [[ $# -ne 2 ]]; then
    echo "Wrong num of arguments"
    exit 1
fi

prohibitedWordsFile=$1
dir=$2

if [[ ! -f $prohibitedWordsFile ]]; then
    echo "The first arg should be a file"
    exit 2
fi

if [[ ! -d $dir ]]; then
    echo "The second arg should be a dir"
    exit 3
fi

while read -r file; do

        while read -r prohibitedWord; do

            wordLen=$(echo -n $prohibitedWord | wc -m)

            stars=""

            for (( i=0; i<$wordLen; i++ )); do
                stars=$(printf "$stars%s" "*")
            done

            # Замяна на точно съвпадение на дума: \b означава граница на дума
            sed -E -i "s/\\b$prohibitedWord\\b/$stars/g" "$file"

        done < "$prohibitedWordsFile"

done < <(find "$dir" -type f -name '*.txt')