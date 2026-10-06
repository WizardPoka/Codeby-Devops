#!/bin/bash
# Скрипт бэкапа MySQL с последующей синхронизацией на store
# Запускается по cron раз в час от root

set -e

BACKUP_DIR="/opt/mysql_backup"
DB_NAME="lesson9db"
DATE=$(date +%Y-%m-%d_%H-%M-%S)
DUMP_FILE="${BACKUP_DIR}/${DB_NAME}_${DATE}.sql"
STORE_HOST="store"
STORE_USER="vagrant"
STORE_DEST="/opt/store/mysql/"

echo "[$(date)] Starting backup of ${DB_NAME}"

# 1. Дамп базы
mysqldump --single-transaction --routines --triggers "${DB_NAME}" > "${DUMP_FILE}"
echo "[$(date)] Dump created: ${DUMP_FILE}"

# 2. Синхронизация на store через rsync поверх SSH
rsync -avz -e "ssh -i /root/.ssh/store_key -o StrictHostKeyChecking=no" \
    "${BACKUP_DIR}/" \
    "${STORE_USER}@${STORE_HOST}:${STORE_DEST}"

echo "[$(date)] Backup synced to ${STORE_HOST}:${STORE_DEST}"

# 3. Оставляем только последние 24 бэкапа (сутки)
ls -1t ${BACKUP_DIR}/*.sql 2>/dev/null | tail -n +25 | xargs -r rm -f

echo "[$(date)] Backup finished"