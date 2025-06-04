 #!/bin/bash

 if (( "${#}" != 1 )); then
     echo "There should be exaclty 1 parameter"
     exit 1
 fi

 if [[ ! -d "${1}" ]]; then
     echo "The parameter should be a directory"
     exit 2
 fi

 while IFS= read -r symlink; do
     target=$(readlink "${symlink}")
     if [[ ! -e "${symlink}" ]]; then
         echo "Broken symlink ${symlink} -> ${target}"
     fi
 done < <(find "${1}" -type l)