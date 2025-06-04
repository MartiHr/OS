#!/bin/bash

latestFile=""
latestUser=""
latestTime=0

while read -r line; do
    dir=$(echo "${line}" | awk '{print $1}')
    user=$(echo "${line}" | awk '{print $2}')

    if [[ ! -d "${dir}" ]]; then
        continue
    fi

    currNewestFile=$(find "${dir}" -type f -printf '%T@ %p\n' 2>/dev/null | sort -nr | head -n 1)

    if [[ -n "${currNewestFile}" ]]; then
        time=$(echo "${currNewestFile}" | cut -d ' ' -f 1)
        filepath=$(echo "${currNewestFile}" | cut -d ' ' -f 2)

        if (( $(echo "$time > $latestTime" | bc -l) )); then
            latestTime=${time}
            latestFile="${filepath}"
            latestUser="${user}"
        fi
    fi
done < <(awk -F ':' '{print $(NF-1), $1}' /etc/passwd)

if [[ -n "${latestFile}" && -n "${latestUser}" ]]; then
    echo "The newest file is ${latestFile}"
    echo "The user is ${latestUser}"
else
    echo "Not found"
fi