#!/bin/bash

if (( $# < 1 || $# > 2 )); then
    echo "Wrong number of arguments"
    exit 1
fi

if [[ ! -d $1 ]]; then
    echo "The first argument should be a directory"
    exit 2
fi

if (( $# == 2 )); then
    number=$(echo "${2} - 1 " | bc)

    if (( $number < 0 )); then
        number=0
    fi

    find "${1}" -type f -links +"${number}" 2>/dev/null
else
    find "${1}" -type l ! -exec test -e {} \; 2>/dev/null
fi