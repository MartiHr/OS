#!/bin/bash

if [[ $# -ne 2 ]]; then
    echo "Wrong number of arguments - should be 2"
    exit 1
fi

dirPath=$1
packagePath=$2

if [[ ! -d "$dirPath" ]]; then
    echo "The first argument should be a directory"
    exit 2
fi

if [[ ! -d "$packagePath" ]]; then
    echo "The second argument should be a directory"
    exit 3
fi

packageName=$(basename "$packagePath")
packageVersion=$(find "$packagePath" -maxdepth 1 -type f | head -n 1 | xargs cat)

packageContentPath=$(find "$packagePath" -mindepth 1 -maxdepth 1 -type d | head -n 1)
temp=$(mktemp)
tar -caf "${temp}.tar.xz" -C "$packageContentPath" .
checksum=$(sha256sum "${temp}.tar.xz" | awk '{print $1}')

line="$packageName-$packageVersion $checksum"

packagesPath=$(find "$dirPath" -maxdepth 1 -type d | grep -v "^$dirPath$" | head -n 1)
db=$(find "$dirPath" -maxdepth 1 -type f | head -n 1)
grep -E -q "^${packageName}-${packageVersion} .*$"  "$db"

if [[ $? -ne 0 ]]; then
    echo "$line" >> "$db"
    sort "$db" -o "$db"
    cp "${temp}.tar.xz" "$packagesPath/${checksum}.tar.xz"
else
    checksumToRemove=$(grep -E "^${packageName}-${packageVersion} " "$db" | awk '{print $2}')
    sed -i -E "s/^${packageName}-${packageVersion} .*/${line}/" "$db"
    rm -f "$packagesPath/${checksumToRemove}.tar.xz"
    cp -f "${temp}.tar.xz" "$packagesPath/${checksum}.tar.xz"
fi

rm -f "${temp}.tar.xz"