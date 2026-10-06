#!/bin/bash
# script1.sh — создаёт myfolder и 5 файлов в нём

set -u  # не падать на неинициализированных переменных, но без -e:
        # чтобы при повторном запуске не выходить из-за "уже существует"

# Домашняя папка текущего пользователя
HOME_DIR="$HOME"
MYFOLDER="${HOME_DIR}/WORK/codeby-devops/lesson10/myfolder"

echo "=== script1.sh started ==="

# 1. Создаём папку (идемпотентно: -p не ругается, если уже есть)
mkdir -p "$MYFOLDER"

# 2. Файл 1: две строки — приветствие и текущие дата/время
FILE1="${MYFOLDER}/file1.txt"
{
    echo "Hello, $(whoami)!"
    echo "Current date and time: $(date '+%Y-%m-%d %H:%M:%S')"
} > "$FILE1"
echo "Created/updated: $FILE1"

# 3. Файл 2: пустой, права 777
FILE2="${MYFOLDER}/file2.txt"
> "$FILE2"                # обнулить содержимое (создать, если нет)
chmod 777 "$FILE2"        # идемпотентно: chmod не падает, если уже 777
echo "Created/updated: $FILE2 (perm 777)"

# 4. Файл 3: одна строка длиной 20 случайных символов
FILE3="${MYFOLDER}/file3.txt"
RANDOM_STR=$(tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 20)
echo "$RANDOM_STR" > "$FILE3"
echo "Created/updated: $FILE3 (20 random chars)"

# 5. Файлы 4 и 5: пустые
FILE4="${MYFOLDER}/file4.txt"
FILE5="${MYFOLDER}/file5.txt"
> "$FILE4"
> "$FILE5"
echo "Created/updated: $FILE4, $FILE5 (empty)"

echo "=== script1.sh done ==="
echo "Files in $MYFOLDER:"
ls -la "$MYFOLDER"

exit 0