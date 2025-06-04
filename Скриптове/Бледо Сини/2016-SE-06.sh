#!/bin/bash

if (( "${#}" != 1 )); then
    echo "There should be only one argument"
    exit 1
fi

if [[ ! -f "${$1}" ]]; then
    echo "The argument shouldd be a file"
    exit 2
fi

cat "${1}" | sed -E 's/^[0-9]{4} г\. - //' |  awk '{printf "%s. %s \n", NR, $0 }' | sort -t ' ' -k 2