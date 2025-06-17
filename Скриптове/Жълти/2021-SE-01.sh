#!/bin/bash

# Стъпка 1: Само oracle или grid
if [[ "$(whoami)" != "oracle" && "$(whoami)" != "grid" ]]; then
    echo "Script must be run as oracle or grid" >&2
    exit 1
fi

# Стъпка 2: ORACLE_HOME трябва да е зададен
if [[ -z "$ORACLE_HOME" ]]; then
    echo "ORACLE_HOME is not set" >&2
    exit 2
fi

# Стъпка 3: adrci трябва да съществува и да е изпълним
adrci_bin="$ORACLE_HOME/bin/adrci"
if [[ ! -x "$adrci_bin" ]]; then
    echo "adrci not found at $adrci_bin" >&2
    exit 3
fi

# Стъпка 4: diag_dest на потребителя
diag_dest="/u01/app/$(whoami)"

# Стъпка 5: Изпълняваме "show homes"
homes_output="$("$adrci_bin" exec="show homes")"
if echo "$homes_output" | grep -q "No ADR homes are set"; then
    exit 0
fi

# Стъпка 6: Обработваме всеки ADR home
echo "$homes_output" | tail -n +2 | while read -r home; do
    # sed -e нещо -е нещо -> просто все едно два седа на отделни редове, които се изпълняват последователно 
    home=$(echo "$home" | sed -E -e 's/^[[:space:]]+//' -e 's/[[:space:]]+$//')
    path="$diag_dest/$home"

    if [[ -d "$path" ]]; then
        bytes=$(find "$path" -type f -exec stat -c %s {} + 2>/dev/null | awk '{sum += $1} END {print sum}')
        mb=$((bytes / 1024 / 1024))
        echo "$mb $path"
    fi
done
