#!/bin/bash

if [[ $# -ne 2 ]]; then
    echo "Wrong number of arguments"
    exit 1
fi

src=$1
dst=$2

if [[ ! -d $src ]]; then
    echo "The first dir should exist"
    exit 2
fi

mkdir -p "$dst/images"

# Обхождаме всички .jpg файлове (независимо от case-а)
find "$src" -type f -iname '*.jpg' | while read -r filepath; do
    filename=$(basename "$filepath")

    # Премахваме разширението
    nameOnly=$(echo "$filename" | sed -E 's/\.[jJ][pP][gG]$//')

    # Заглавие: премахване на скоби и почистване
    title=$(echo "$nameOnly" | sed -E 's/\([^)]*\)//g' | xargs)

    # Албум: взимаме последния низ в скоби (ако има), иначе "misc"
    album=$(echo "$nameOnly" | grep -oE '\([^)]*\)' | tail -n1 | sed -E 's/^\(|\)$//g' | xargs)
    if [[ -z "$album" ]]; then
        album="misc"
    fi

    # Дата на последна модификация, във формат YYYY-MMDD
    mod_time=$(stat -c '%y' "$filepath")
    date=$(date -d "$mod_time" +%Y-%m%d)

    # Хеш - първите 16 символа от sha256 сумата
    hash=$(sha256sum "$filepath" | cut -c1-16)

    # Копиране на файла
    cp "$filepath" "$dst/images/$hash.jpg"

    # Подготовка на symlink-ите
    rel_path="../../../../images/$hash.jpg"

    # Списък със symlink цели и директории
    links=(
        "$dst/by-date/$date/by-album/$album/by-title/$title.jpg"
        "$dst/by-date/$date/by-title/$title.jpg"
        "$dst/by-album/$album/by-date/$date/by-title/$title.jpg"
        "$dst/by-album/$album/by-title/$title.jpg"
        "$dst/by-title/$title.jpg"
    )

    for link in "${links[@]}"; do
        dir=$(dirname "$link")
        mkdir -p "$dir"

        # Пресмятане на относителен път до images/$hash.jpg
        rel_to_image=$(realpath --relative-to="$dir" "$dst/images/$hash.jpg")

        ln -sf "$rel_to_image" "$link"
    done

done
