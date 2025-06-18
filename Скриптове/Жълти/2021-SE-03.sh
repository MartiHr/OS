# от цветилин
#!/bin/bash

if [[ ${#} -ne 2 ]] ; then
        echo "Expected 2 arguments"
        exit 1
fi

if [[ ! -f ${1} ]] ; then
        echo "File does not exist"
        exit 1
fi


BINARY=${1}
OUTPUT=${2}

touch ${OUTPUT}
echo "#include <stdint.h>" > ${OUTPUT}

ARR=""

for UINT16 in $(xxd $BINARY | cut -d ' ' -f2-9) ; do
        UINT16=$(echo "${UINT16}" | sed -E 's/^(..)(..)$/\2\1/' )
        ARR="${ARR}0x${UINT16},"
done

ARR=$(echo "${ARR}" | sed -E "s/,$//")

echo "uint16_t arr[] = { ${ARR} };" > ${OUTPUT}
        