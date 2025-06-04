#!/bin/bash

# Проверка за два аргумента
if [ "$#" -ne 2 ]; then
    echo "Употреба: $0 <файл1> <файл2>"
    exit 1
fi

# Пътища до файловете в home директорията
FILE1="$HOME/$1"
FILE2="$HOME/$2"

# Проверка дали файловете съществуват
if [ ! -f "$FILE1" ] || [ ! -f "$FILE2" ]; then
    echo "Един или и двата файла не съществуват в \$HOME"
    exit 2
fi

# Имената на изпълнителите се извличат от имената на файловете
ARTIST1=$(basename "$FILE1")
ARTIST2=$(basename "$FILE2")

# Броене на редовете, съдържащи името на изпълнителя
COUNT1=$(grep -c "$ARTIST1" "$FILE1")
COUNT2=$(grep -c "$ARTIST2" "$FILE2")

# Определяне на победителя
if [ "$COUNT1" -gt "$COUNT2" ]; then
    WINNER_FILE="$FILE1"
    WINNER_ARTIST="$ARTIST1"
else
    WINNER_FILE="$FILE2"
    WINNER_ARTIST="$ARTIST2"
fi

# Обработка: Премахване на годината и името на изпълнителя в началото
# Формат на ред: 2005г. Bonnie - "Име на песен" (Автори) – Времетраене
# Очакваме: всичко СЛЕД името и тирето (т.е. `Bonnie -`)
grep "^.*$WINNER_ARTIST -" "$WINNER_FILE" \
    | sed -E "s/^[0-9]{4}г\. $WINNER_ARTIST - //" \
    | sort > "$HOME/${WINNER_ARTIST}.songs"

echo "Файлът с повече песни: $WINNER_ARTIST"
echo "Резултатът е записан в: $HOME/${WINNER_ARTIST}.songs"
