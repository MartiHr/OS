#!/bin/bash

if [[ $(id -u) -ne 0 ]]; then
    echo "The script should be ran by root"
    exit 1
fi

rootRss=$(ps -u root -o rss= | awk 'BEGIN {sum=0} {sum+=$1} END {print sum}')

while read -r user; do

    if [[ "${user}" == "root" ]]; then
        continue
    fi

    id "${user}" &>/dev/null

    if [[ "${?}" -ne 0 ]]; then
        continue
    fi

    homeDir=$(grep -E "^${user}:" /etc/passwd | cut -d ':' -f 6)

    validUser=0

    if [[ ! -d "${homeDir}" ]]; then
        validUser=1
    elif [[ "$(stat -c '%U' "${homeDir}" 2>/dev/null)" != "${user}" ]]; then
        validUser=1
    elif ! sudo -u "${user}" test -w "${homeDir}"; then
        validUser=1
    fi

    if (( $validUser == 1 )); then
        userRss=$(ps -u "$user" -o rss= | awk '{sum+=$1} END {print sum}')

        if (( $userRss > $rootRss )); then
            echo "Killing all processes of $user (RSS $userRss > root $rootRss)"
            ps -u $user -o pid= | xargs kill -r -TERM
        fi
    fi

done < <(ps -e -o user= | sort | uniq)