#!/bin/bash
#
# script1.sh — создаёт рабочую папку и набор тестовых файлов.
#
# Назначение:
#   - Создаёт папку myfolder в домашней директории пользователя
#   - Создаёт 5 файлов с разным содержимым и правами
#
# Идемпотентность:
#   Скрипт можно запускать многократно — существующие файлы
#   перезаписываются без ошибок.
#
# Использование:
#   ./script1.sh
#
# Коды возврата:
#   0 — успех
#   1 — не удалось создать папку
#
# Автор: <ваше имя>
# Дата: 2026-10-07
#

set -u  # Запретить обращение к неинициализированным переменным
set -o pipefail  # Ошибка в конвейере = ошибка всего конвейера

# --- Константы ---------------------------------------------------------
readonly MYFOLDER="${HOME}/myfolder"
readonly FILE1="${MYFOLDER}/file1.txt"
readonly FILE2="${MYFOLDER}/file2.txt"
readonly FILE3="${MYFOLDER}/file3.txt"
readonly FILE4="${MYFOLDER}/file4.txt"
readonly FILE5="${MYFOLDER}/file5.txt"

readonly RANDOM_STRING_LENGTH=20
readonly FILE2_PERMISSIONS=777

# Коды возврата
readonly E_CANNOT_CREATE_DIR=1

# --- Функции -----------------------------------------------------------

# Создаёт рабочую папку, если её нет.
# Возвращает: 0 — успех, E_CANNOT_CREATE_DIR — ошибка.
create_working_directory() {
    local target_dir="$1"

    if ! mkdir -p "$target_dir"; then
        echo "ERROR: cannot create directory $target_dir" >&2
        return "$E_CANNOT_CREATE_DIR"
    fi
    return 0
}

# Создаёт первый файл: приветствие + текущая дата/время.
create_file1() {
    local file_path="$1"
    {
        echo "Hello, $(whoami)!"
        echo "Current date and time: $(date '+%Y-%m-%d %H:%M:%S')"
    } > "$file_path"
    echo "Created/updated: $file_path"
}

# Создаёт второй файл: пустой, с правами 777.
create_file2() {
    local file_path="$1"
    > "$file_path"
    chmod "$FILE2_PERMISSIONS" "$file_path"
    echo "Created/updated: $file_path (perm $FILE2_PERMISSIONS)"
}

# Создаёт третий файл: одна строка из N случайных символов.
create_file3() {
    local file_path="$1"
    local random_string
    random_string=$(tr -dc 'A-Za-z0-9' < /dev/urandom | head -c "$RANDOM_STRING_LENGTH")
    echo "$random_string" > "$file_path"
    echo "Created/updated: $file_path ($RANDOM_STRING_LENGTH random chars)"
}

# Создаёт пустые файлы (4 и 5).
create_empty_files() {
    local file_paths=("$@")
    local file_path

    for file_path in "${file_paths[@]}"; do
        > "$file_path"
    done
    echo "Created/updated: ${file_paths[*]} (empty)"
}

# --- Основная логика ---------------------------------------------------

main() {
    echo "=== script1.sh started ==="

    create_working_directory "$MYFOLDER" || exit $?

    create_file1 "$FILE1"
    create_file2 "$FILE2"
    create_file3 "$FILE3"
    create_empty_files "$FILE4" "$FILE5"

    echo "=== script1.sh done ==="
    echo "Files in $MYFOLDER:"
    ls -la "$MYFOLDER"

    return 0
}

main "$@"
exit $?