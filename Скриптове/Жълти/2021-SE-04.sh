#gpt довършено
#!/bin/bash

# Проверка за потребител
user=$(whoami)
if [[ $user != "oracle" && $user != "grid" ]]; then
    echo "Invalid user $user"
    exit 1
fi

# Проверка за аргументи
if [[ $# -ne 1 ]]; then
    echo "Usage: $0 <hours>"
    exit 2
fi

# Проверка дали е число
hours=$1
if ! echo "$hours" | grep -qE '^[0-9]+$'; then
    echo "First argument must be a number"
    exit 3
fi

# Минимално време: 2 часа
if (( hours < 2 )); then
    echo "Minimum is 2 hours"
    exit 4
fi

# Проверка за ORACLE_HOME
if [[ -z "$ORACLE_HOME" ]]; then
    echo "ORACLE_HOME not set"
    exit 5
fi

adrci="$ORACLE_HOME/bin/adrci"

# Проверка за adrci
if [[ ! -x $adrci ]]; then
    echo "adrci not found or not executable at $adrci"
    exit 6
fi

# diag_dest директория
diag_dest="/u01/app/$user"
if [[ ! -d "$diag_dest" ]]; then
    echo "Directory $diag_dest does not exist"
    exit 7
fi

# Вземаме изхода на SHOW HOMES
homes_output=$("$adrci" exec="SET BASE $diag_dest; SHOW HOMES")

# Проверка дали има ADR home-ове
if echo "$homes_output" | grep -q "No ADR homes are set"; then
    echo "No ADR homes available"
    exit 0
fi

# Интересни директории
interesting_dirs="crs|tnslsnr|kfod|asm|rdbms"

# Извличаме само валидните ADR home-ове
echo "$homes_output" | tail -n +2 | while read -r home; do
    # Премахваме водещи/крайни интервали
    home=$(echo "$home" | sed -E -e 's/^[[:space:]]+//' -e 's/[[:space:]]+$//')

    # Проверка дали второто ниво е интересно
    second_level=$(echo "$home" | cut -d/ -f2)
    if echo "$second_level" | grep -Eq "^($interesting_dirs)$"; then
        # Изчисляваме времето в минути
        minutes=$((hours * 60))

        # Извикваме PURGE за този home
        "$adrci" exec="SET BASE $diag_dest; SET HOMEPATH $home; PURGE -AGE $minutes"
    fi
done
