#!/bin/bash

if [[ $# -ne 1 ]]; then
    echo "There should be exactly 1 argument"
    exit 1
fi

size=$1

echo "${size}" | grep -E -q '^-?[0-9]+$'
if [[ "${?}" -ne 0 ]]; then
    echo "The argument should be a number"
    exit 2
fi

currentUser=$(whoami)

if [[ "${currentUser}" == "root" ]]; then
    while read -r user; do
        biggestRss=0
        biggestPid=''
        rssTotal=0
        processes=$(ps -u "$user" -o rss=,pid=)

        while read -r rss pid; do
            rssTotal=$(( rssTotal + rss ))

            if (( rss > biggestRss )); then
                biggestRss="${rss}"
                biggestPid="${pid}"
            fi
        done < <(echo "${processes}")

        if (( rssTotal > size )); then
            if [[ -n "${biggestPid}"  ]]; then
                kill -TERM "${biggestPid}"
            fi
        fi
    done < <(ps -e -o user= | sort | uniq)
fi