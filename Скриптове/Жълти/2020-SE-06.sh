#!/bin/bash

# Проверка за точно 3 аргумента
if [[ $# -ne 3 ]]; then
    echo "Wrong number of arguments"
    exit 1
fi

file=$1
key=$2
value=$3

# Проверка дали първият аргумент е файл
if [[ ! -f "$file" ]]; then
    echo "The first argument should be a file"
    exit 2
fi

# Проверка дали key е валиден
echo "$key" | grep -Eq '^[0-9a-zA-Z_]+$'
if [[ $? -ne 0 ]]; then
    echo "Argument 2 invalid"
    exit 3
fi

# Проверка дали value е валиден
echo "$value" | grep -Eq '^[0-9a-zA-Z_]+$'
if [[ $? -ne 0 ]]; then
    echo "Argument 3 invalid"
    exit 4
fi

exists=0
temp_file=$(mktemp)

while IFS= read -r line; do
    trimmed=$(echo "$line" | xargs)

    # Ако е празен ред или коментар, запази го
    if [[ -z "$trimmed" || "$trimmed" =~ ^# ]]; then
        echo "$line" >> "$temp_file"
        continue
    fi

    # Вземи ключа от реда (без коментара)
    main_part=$(echo "$line" | cut -d '#' -f 1)
    curr_key=$(echo "$main_part" | cut -d '=' -f 1 | xargs)
    curr_value=$(echo "$main_part" | cut -d '=' -f 2 | xargs)

    if [[ "$curr_key" == "$key" ]]; then
        exists=1
        if [[ "$curr_value" != "$value" ]]; then
            echo "# $line # edited at $(date) by $(whoami)" >> "$temp_file"
            echo "$key = $value # added at $(date) by $(whoami)" >> "$temp_file"
        else
            echo "$line" >> "$temp_file"
        fi
    else
        echo "$line" >> "$temp_file"
    fi
done < "$file"

# Ако не е намерен ключът, добави го в края
if (( exists == 0 )); then
    echo "$key = $value # added at $(date) by $(whoami)" >> "$temp_file"
fi

# Замени оригиналния файл с временния
mv "$temp_file" "$file"
