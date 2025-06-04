#!/bin/bash

if [[ $# -ne 1 ]] || [[ ! -d $1 ]]; then
    echo "Expected exactly one argument - directory"
    exit 1
fi

dir=$1
HASH_FILE="$HOME/.hashes_report"
TMP_HASHES=$(mktemp)
mkdir -p /extracted
touch "$HASH_FILE"

# 1. Намери всички валидни архиви
archives=$(find "$dir" -maxdepth 1 -type f -regex ".*/[^_]+_report-[0-9]+\.tgz")

# 2. Изчисли текущите хешове
for file in $archives; do
    sha256sum "$file"
done > "$TMP_HASHES"

# 3. Намери променените или новите файлове
changed_files=$(grep -Fvxf "$HASH_FILE" "$TMP_HASHES" | awk '{print $2}')

# 4. Обходи ги и екстрахирай meow.txt
for file in $changed_files; do
    filename=$(basename "$file")
    NAME=$(echo "$filename" | sed -E 's/^([^_]+)_report-.*/\1/')
    TIMESTAMP=$(echo "$filename" | sed -E 's/.*report-([0-9]+)\.tgz/\1/')

    # Потърси meow.txt вътре
    meow_path=$(tar -tzf "$file" | grep -E "meow.txt" || true)
    if [[ -n "$meow_path" ]]; then
        tar -xzf "$file" "$meow_path" -C "$(dirname "$file")"
        mv "$(dirname "$file")/$meow_path" "/extracted/${NAME}_${TIMESTAMP}.txt"
    fi
done

# 5. Запази новите хешове
mv "$TMP_HASHES" "$HASH_FILE"

------------------------------

#!/bin/bash

if [[ ${#} -ne 1 ]] ; then
        echo "Expected 1 argument - directory"
        exit 1
fi

DIR="${1}"

allArchives=$(find "${DIR}" -mindepth 1 -maxdepth 1 -type f -name "*_report-*.tgz" -printf "%p %M@\n")
lastExecution=$(stat -c "%X" ${0})
resultArchives=$(echo "${allArchives}" | awk -v var=${lastExecution} '{if ($2>=var) print $1}')

while read file ; do
        NAME=$(echo ${file} | sed -E 's/(.*)_/\1/')
        TIMESTAMP=$(echo ${file} | sed -E 's/report-(.*)[.]tgz/\1/')
        while read line ; do
                bn=$(basename ${line})
                if [[ ${bn} == "meow.txt" ]] && [[ -f ${bn} ]] ; then
                        tar -xf ${file} ${line}
                        dir=$(dirname ${file})
                        mv "${dir}/${line}" "/extracted/${NAME}_${TIMESTAMP}.txt"
                        break
                fi
        done < <(tar -tf ${file} | egrep "meow.txt")
done < <(echo ${resultArchive})