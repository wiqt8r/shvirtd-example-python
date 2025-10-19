#!/bin/bash
# Папка для бэкапов
BACKUP_DIR="/opt/backup"
mkdir -p "$BACKUP_DIR"

# Берем пароли из .env, чтобы не светить в явном виде
ENV_FILE="/opt/shvirtd-example-python/.env"
export $(grep -v '^#' $ENV_FILE | xargs)

# Называем файл бэкапа с текущей датой
NOW=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="$BACKUP_DIR/virtd_backup_$NOW.sql"

# Запускаем контейнер mysqldump в сети backend
docker run --rm --network shvirtd-example-python_backend \
    -v "$BACKUP_DIR":"$BACKUP_DIR" \
    schnitzler/mysqldump \
    -h mysql-container -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" "$MYSQL_DATABASE" > "$BACKUP_FILE"
