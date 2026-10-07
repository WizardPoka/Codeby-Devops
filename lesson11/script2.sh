#!/bin/bash
#
# script2.sh — обрабатывает папку myfolder.
#
# Назначение:
#   - Считает количество файлов в папке
#   - Меняет права второго файла с 777 на 664
#   - Удаляет пустые файлы
#   - Оставляет только первую строку в непустых файлах
#
# Идемпотентность:
#   Скрипт можно запускать многократно и до создания папки —
#   он не падает и корректно обрабатывает отсутствие файлов.
#
# Использование:
#   ./script2.sh
#
# Коды возврата:
#   0 — успех (в т.ч. если папки нет)
#   1 — не удалось обработать файлы
#
# Автор: <ваше имя>
# Дата: 2026-10-07
#

set -u
set -o pipefail

# --- Константы ---------------------------------------------------------
readonly MYFOLDER="${HOME}/myfolder"
readonly FILE2="${MYFOLDER}/file2.txt"

readonly FILE2_NEW_PERMISSIONS=664
readonly TMP_SUFFIX=".tmp"

# Коды возврата
readonly E_CANNOT_PROCESS=1

# --- Функции -----------------------------------------------------------

# Возвращает количество обычных файлов в папке.
count_files() {
    local target_dir="$1"
    local count
    count=$(find "$target_dir" -maxdepth 1 -type f | wc -l)
    echo "$count"
}

# Меняет права file2 с 777 на 664, если файл существует и права не те.
fix_file2_permissions() {
    local file_path="$1"

    if [ ! -f "$file_path" ]; then
        echo "$file_path not found, skipping chmod"
        return 0
    fi

    local current_permissions
    current_permissions=$(stat -c '%a' "$file_path")

    if [ "$current_permissions" = "$FILE2_NEW_PERMISSIONS" ]; then
        echo "$file_path already has $FILE2_NEW_PERMISSIONS"
        return 0
    fi

    if ! chmod "$FILE2_NEW_PERMISSIONS" "$file_path"; then
        echo "ERROR: cannot chmod $file_path" >&2
        return "$E_CANNOT_PROCESS"
    fi

    echo "Changed perms on $file_path: $current_permissions -> $FILE2_NEW_PERMISSIONS"
    return 0
}

# Удаляет пустые файлы в папке.
# Возвращает количество удалённых файлов через stdout.
remove_empty_files() {
    local target_dir="$1"
    local removed_count=0
    local file_path

    # Оптимизация: используем glob вместо find, если файлов немного
    for file_path in "$target_dir"/*; do
        [ -f "$file_path" ] || continue

        if [ ! -s "$file_path" ]; then
            echo "Removing empty file: $file_path"
            rm -f "$file_path"
            removed_count=$((removed_count + 1))
        fi
    done

    echo "$removed_count"
}

# Оставляет только первую строку в непустых файлах.
trim_to_first_line() {
    local target_dir="$1"
    local file_path

    for file_path in "$target_dir"/*; do
        [ -f "$file_path" ] || continue

        if [ -s "$file_path" ]; then
            # Оптимизация: без cat, один head + mv
            if head -n 1 "$file_path" > "${file_path}${TMP_SUFFIX}" && \
               mv "${file_path}${TMP_SUFFIX}" "$file_path"; then
                echo "Trimmed to first line: $file_path"
            else
                echo "ERROR: cannot trim $file_path" >&2
                rm -f "${file_path}${TMP_SUFFIX}"
                return "$E_CANNOT_PROCESS"
            fi
        fi
    done

    return 0
}

# --- Основная логика ---------------------------------------------------

main() {
    echo "=== script2.sh started ==="

    # Папки нет — выходим без ошибки (идемпотентность)
    if [ ! -d "$MYFOLDER" ]; then
        echo "Folder $MYFOLDER does not exist. Nothing to do."
        return 0
    fi

    # 1. Считаем файлы
    local file_count
    file_count=$(count_files "$MYFOLDER")
    echo "Files in $MYFOLDER: $file_count"

    # 2. Права file2
    fix_file2_permissions "$FILE2" || return $?

    # 3. Удаляем пустые
    local removed_count
    removed_count=$(remove_empty_files "$MYFOLDER")
    echo "Removed empty files: $removed_count"

    # 4. Оставляем первую строку
    trim_to_first_line "$MYFOLDER" || return $?

    echo "=== script2.sh done ==="
    echo "Files in $MYFOLDER after processing:"
    ls -la "$MYFOLDER"

    return 0
}

main "$@"
exit $?