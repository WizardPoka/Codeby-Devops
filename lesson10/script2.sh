#!/bin/bash
# script2.sh — анализирует myfolder и приводит файлы в порядок

set -u

MYFOLDER="${HOME}/WORK/codeby-devops/lesson10/myfolder"

echo "=== script2.sh started ==="

# 0. Проверка: папка существует?
if [ ! -d "$MYFOLDER" ]; then
    echo "Folder $MYFOLDER does not exist. Nothing to do."
    exit 0
fi

# 1. Сколько файлов в папке
FILE_COUNT=$(find "$MYFOLDER" -maxdepth 1 -type f | wc -l)
echo "Files in $MYFOLDER: $FILE_COUNT"

# 2. Исправить права второго файла с 777 на 664
FILE2="${MYFOLDER}/file2.txt"
if [ -f "$FILE2" ]; then
    CURRENT_PERM=$(stat -c '%a' "$FILE2")
    if [ "$CURRENT_PERM" != "664" ]; then
        chmod 664 "$FILE2"
        echo "Changed perms on $FILE2: $CURRENT_PERM -> 664"
    else
        echo "$FILE2 already has 664"
    fi
else
    echo "$FILE2 not found, skipping chmod"
fi

# 3. Удалить пустые файлы
#    НО! Осторожно: file2 после chmod тоже пустой (мы его обнулили в script1).
#    Задание говорит "определяет пустые файлы и удаляет их" — удаляем все пустые.
#    Если нужно сохранить file2 — см. примечание ниже.
REMOVED=0
for f in "$MYFOLDER"/*; do
    [ -f "$f" ] || continue
    if [ ! -s "$f" ]; then
        echo "Removing empty file: $f"
        rm -f "$f"
        REMOVED=$((REMOVED + 1))
    fi
done
echo "Removed empty files: $REMOVED"

# 4. Удалить все строки кроме первой в оставшихся файлах
for f in "$MYFOLDER"/*; do
    [ -f "$f" ] || continue
    if [ -s "$f" ]; then
        # Оставляем только первую строку
        head -n 1 "$f" > "${f}.tmp" && mv "${f}.tmp" "$f"
        echo "Trimmed to first line: $f"
    fi
done

echo "=== script2.sh done ==="
echo "Files in $MYFOLDER after processing:"
ls -la "$MYFOLDER"

exit 0