#!/bin/bash

if [[ $# -ne 1 ]]; then
    echo "Wrong number of arguments"
    exit 1
fi

user=$1

if [[ "$(id -u)" -ne 0 ]]; then
    echo "The user is not root"
    exit 2
fi

tempFile=$(mktemp)

ps -a -u "${user}" > "${tempFile}"

if [[ $? -ne 0 ]]; then
    echo "The use does not have processes"
    exit 3
fi

procCount=$(wc -l < "$tempFile")

echo "Users with more processes than $user"
ps -eo user= | sort | uniq -c | awk -v count="$procCount" '$1>count {print $2}'

average=$(ps -e -o time= | \
    awk -F ':' '
        NF==3 { sec=$1*3600+$2*60+$3; sum+=sec; count++}
        NF==2 { sec=$1*60+$2; sum+=sec; count++}
        END { if (count > 0) print sum/count; else print 0}
    '
)

echo "Average process time: $average seconds"

threshold=$(( average * 2 ))

echo "Killing processes of $user longer than $threshold seconds:"

ps -u "$user" -o pid=,time= | \
  awk -v thr="$threshold" -F'[: ]+' '
    NF==4 { pid=$1; sec=$2*3600+$3*60+$4 }
    NF==3 { pid=$1; sec=$2*60+$3 }
    sec>thr { print pid }
  ' | xargs -r -n 1 kill -TERM

rm -f "${tempFile}"


# ИЛИ 

#!/bin/bash

# Проверка за аргументи
if [[ $# -ne 1 ]]; then
    echo "Usage: $0 <username>"
    exit 1
fi

user=$1

# Проверка дали скриптът е стартиран от root
if [[ "$(id -u)" -ne 0 ]]; then
    echo "Must be run as root"
    exit 2
fi

# Създаване на временен файл и събиране на процесите на потребителя
tempFile=$(mktemp)
ps -u "$user" --no-headers > "$tempFile" 2>/dev/null

if [[ $? -ne 0 || ! -s "$tempFile" ]]; then
    echo "The user does not have processes"
    rm -f "$tempFile"
    exit 3
fi

# 1) Броим колко процеса има FOO
procCount=$(wc -l < "$tempFile")
echo "User $user has $procCount processes."

# 2) Намираме потребителите с повече процеси от FOO
echo "Users with more processes than $user:"
# Употребяваме асоциативен масив, за да броим процесите per-user
declare -A counts
while read -r owner _; do
    (( counts["$owner"]++ ))
done < <(ps -eo user=,pid=)

for owner in "${!counts[@]}"; do
    if [[ ${counts[$owner]} -gt $procCount && "$owner" != "$user" ]]; then
        echo "  $owner (${counts[$owner]} processes)"
    fi
done

# 3) Изчисляваме средното време (в секунди) на всички процеси
totalSec=0
totalCnt=0

while read -r t; do
    IFS=: read -r h m s <<< "$t"
    if [[ -z $s ]]; then
        # формат MM:SS
        sec=$((10#$h*60 + 10#$m))
    else
        # формат HH:MM:SS
        sec=$((10#$h*3600 + 10#$m*60 + 10#$s))
    fi
    totalSec=$(( totalSec + sec ))
    totalCnt=$(( totalCnt + 1 ))
done < <(ps -eo time= | tr -d ' ')

if (( totalCnt == 0 )); then
    echo "No processes to average."
    rm -f "$tempFile"
    exit 4
fi

average=$(( totalSec / totalCnt ))
echo "Average process time: $average seconds"

# 4) Прекратяване на процесите на FOO, които надвишават 2× средното
threshold=$(( average * 2 ))
echo "Killing processes of $user longer than $threshold seconds:"

while read -r pid t; do
    IFS=: read -r h m s <<< "$t"
    if [[ -z $s ]]; then
        sec=$((10#$h*60 + 10#$m))
    else
        sec=$((10#$h*3600 + 10#$m*60 + 10#$s))
    fi

    if (( sec > threshold )); then
        echo "  Killing PID $pid (ran $sec s)"
        kill -TERM "$pid" 2>/dev/null || kill -KILL "$pid"
    fi
done < <(ps -u "$user" -o pid=,time= --no-headers)

# Почистване
rm -f "$tempFile"
