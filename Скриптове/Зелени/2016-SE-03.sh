#!/bin/bash

if [[ "$(id -u)" -ne 0 ]]; then
    echo "The user should be root"
    exit 1
fi

while IFS=: read -r user homedir; do
    if [[ -z "${homedir}" ]]; then
        echo "The user ${user} does not have home dir."
    elif [[ ! -d "${homedir}" ]]; then
        echo "The user ${user} does not have home dir"
    else
        ownerUid=$(stat -c '%u' "${homedir}")

        userUid=$(id -u "${user}" 2>/dev/null)

        if [[ -z "${userUid}" ]]; then
            echo "User ${user} does not exist or cannot get UID."
        elif [[ "${ownerUid}" -ne "${userUid}" ]]; then
            echo "User ${user} is not the owner of ${homedir}"
        elif [[ ! -w "${homedir}" ]]; then
            echo "User ${user} cannot write to ${homedir}"
        fi
    fi
done < <(cat /etc/passwd | cut -d ':' -f 1,6)

# or
#!/bin/bash

if [[ "$(id -u)" -ne 0 ]]; then
    echo "The user should be root"
    exit 1
fi

while IFS=: read -r user homedir; do
    userUid=$(id -u "$user" 2>/dev/null)

    if [[ -z "$userUid" ]]; then
        echo "User ${user} does not exist or cannot get UID."
    elif [[ -z "$homedir" ]]; then
        echo "The user ${user} does not have home dir."
    elif [[ ! -d "$homedir" ]]; then
        echo "The user ${user} does not have home dir"
    else
        ownerUid=$(stat -c '%u' "$homedir")

        if [[ "$ownerUid" -ne "$userUid" ]]; then
            echo "User ${user} is not the owner of ${homedir}"
        elif ! sudo -u "$user" test -w "$homedir"; then
            echo "User ${user} cannot write to ${homedir}"
        fi
    fi
done < <(awk -F: '{print $1 ":" $6}' /etc/passwd)
