#!/bin/bash

if [[ $# -ne 3 ]]; then
    echo "Wrong number of arguments"
    exit 1
fi

if [[ ! -d $1 || ! -d $2 ]]; then
    echo "The first and second arguments should be directories"
    exit 2
fi

if [[ -z $3 ]]; then
    echo "The third parameter should be a non empty string"
    exit 3
fi

if [[ "$(id -u)" -ne 0 ]]; then
    echo "The user should be root"
    exit 4
fi

src=$1
dest=$2
str=$3

while IFS= read -r filepath; do
  # Remove "$src/" prefix using sed to get the relative path
  relpath=$(echo "$filepath" | sed "s:^$src/::")

  # Create destination directory structure
  mkdir -p "$dest/$(dirname "$relpath")"

  # Move the file
  mv "$filepath" "$dest/$relpath"
done < <(find "$src" -type f | grep -E "^$str")