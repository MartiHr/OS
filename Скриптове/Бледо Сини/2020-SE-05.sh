#gpt довършено решение !!!

#!/bin/bash

if [[ $# -ne 3 ]]; then
    echo "Wrong number of arguments"
    exit 1
fi

file1=$1      # passwords file
file2=$2      # output config file
dir=$3        # directory with .cfg files

if [[ ! -f "${file1}" ]]; then
    echo "The first argument should be a file"
    exit 2
fi

if [[ ! -f "${file2}" ]]; then
    # Ако изходният файл не съществува, създаваме го празен
    touch "$file2"
fi

if [[ ! -d "${dir}" ]]; then
    echo "The third argument should be a directory"
    exit 3
fi

# Зареждаме съществуващите потребители в асоциативен масив
declare -A users
while IFS=: read -r user pass; do
    users["$user"]=1
done < "$file1"

# Празен временен файл за обединение на валидните .cfg файлове
tmp_merged=$(mktemp)

# Обработваме всеки .cfg файл в директорията
while read -r file; do
    valid=1
    tmp_errors=$(mktemp)
    lineno=0

    while IFS= read -r line; do
        ((lineno++))
        # Проверка дали редът е валиден
        if [[ "$line" =~ ^# ]] || [[ "$line" =~ ^\{[[:space:]]*.*[[:space:]]*\};$ ]]; then
            # валиден ред - няма действие
            continue
        else
            valid=0
            echo "Line $lineno:$line" >> "$tmp_errors"
        fi
    done < "$file"

    if (( valid == 0 )); then
        echo "Error in $(basename "$file"):"
        cat "$tmp_errors"
        rm "$tmp_errors"
        continue
    fi
    rm "$tmp_errors"

    # Ако файлът е валиден, добавяме съдържанието му към временния конфигурационен файл
    cat "$file" >> "$tmp_merged"
    echo "" >> "$tmp_merged"

    # Вземаме потребителското име от името на файла без .cfg
    baseuser=$(basename "$file" .cfg)

    # Ако потребителят липсва в паролния файл, генерираме парола и добавяме
    if [[ -z "${users[$baseuser]}" ]]; then
        newpass=$(pwgen 16 1)
        echo "$baseuser:$newpass" >> "$file1"
        echo "$baseuser $newpass"
        users["$baseuser"]=1
    fi

done < <(find "$dir" -type f -name '*.cfg')

# Записваме обединения файл като output config file
mv "$tmp_merged" "$file2"
