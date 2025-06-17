#!/bin/bash

[[ $# -ne 3 ]] && echo "3 params expected" && exit 1
[[ ! -f $1 ]] && echo "The 1st param must be a file that exists" && exit 2
[[ -f $2 ]] && echo "The 2nd param must be a file that does not exist" && exit 3
[[ ! -d $3 ]] && echo "The 3rd param must be a folder" && exit 4

files=$(find $3 -type f -name '*.cfg')

regex="^\s*$|^#.*$|^\s*\{\s.+\s\};(\s*#.*)?$"

validFiles=""
while read file; do
	invalidLines=$(cat "$file" | egrep -v "$regex")
	basename=$(basename "$file")
	
	if [[ ! -z $invalidLines ]]; then
		echo "Errors in file $basename"
		cat -n "$file" | egrep "$invalidLines" | sed -E 's/^\s+([0-9]+)\s+/Line \1:/g'
		continue
	fi

	validFiles="$validFiles $file"
	
	username=$(echo "$basename" | sed -E 's/\.cfg//g')

	line=$(egrep "^$username:" $1)
	[[ ! -z $line ]] && continue

	pass=$(pwgen 16 1)
	echo "$username $pass"

	pass=$(mkpasswd "$pass")
	echo -ne "$username:$pass\n" >> $1
done < <(echo "$files")

cat $validFiles > $2


# OR

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
