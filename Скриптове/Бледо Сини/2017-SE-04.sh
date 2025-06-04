 #!/bin/bash

 if (( $# < 1 || $# > 2 )); then
     echo "Wrong number of arguments. There should be one or two"
     exit 1
 fi

 if [[ ! -d $1 ]]; then
     echo "The first argument should be a directory"
     exit 2
 fi

 fileName=""
 if (( $# == 2 )); then
     fileName=$2
 fi

 count=0
 tempFile=$(mktemp /tmp/mytempfile.XXXXXX)

 while read -r symlink; do
     filePath=$(readlink -f "${symlink}")

     if [[ -e "${filePath}" ]]; then
         echo "${symlink} -> ${filePath}" >> "${tempFile}"
     else
         (( count++ ))
     fi
 done < <(find "${1}" -type l 2>/dev/null)

 if [[ -n "${fileName}" ]]; then
     cat "${tempFile}" >> "${fileName}"
     echo "Broken symlinks: ${count}" >> "${fileName}"
 else
     cat "${tempFile}"
     echo "Broken symlinks: ${count}"
 fi

 rm "${tempFile}"