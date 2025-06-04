#!/bin/bash

if [[ $# -ne 2 ]]; then
    echo "Wrong number of arguments"
    exit 1
fi

if [[ ! -d $1 ]]; then
    echo "First argument should be a dir"
    exit 2
fi

if [[ -z $2 ]]; then
    echo "The second argument should be a non empty string"
    exit 3
fi

basename $(find "${1}" -maxdepth 1 -type f | grep -E 'vmlinuz-[0-9]+\.[0-9]+\.[0-9]+-.*' | sort -t '-' -k 2 -rV | awk -F '-' -v str="${2}" '$3==str {print}' | head -n 1)