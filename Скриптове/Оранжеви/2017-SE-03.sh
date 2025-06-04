#!/bin/bash

if [[ "$(id -u)" -ne 0 ]]; then
    echo "Only root is allowed to run script"
    exit 1
fi

while read -r user; do

    processes=$(ps -u "${user}" -o rss=,pid=)
    rssTotal=0
    pCount=0
    biggestRss=0
    pidOfBiggest=''

    while read -r rss pid; do
        ((pCount++))
        rssTotal=$(( rssTotal + rss  ))

        if (( rss > biggestRss  )) ; then
            biggestRss=$rss
            pidOfBiggest=$pid
        fi
    done < <(echo "${processes}")

    if (( pCount > 0 )); then
        #avg=$(echo "$rssTotal / $pCount " | bc)
        avg=$((rssTotal / pCount))

        if (( biggestRss > 2 * avg  )); then
            kill $pidOfBiggest
        fi
    fi
done < <(ps -e -o user= | sort | uniq)