#!/usr/bin/env bash
set -euo pipefail

# Параметры
REPO_URL="https://github.com/wiqt8r/shvirtd-example-python.git"
DEST_DIR="/opt/shvirtd-example-python"
COMPOSE_CMD="docker compose"   # можно заменить на docker-compose если требуется

# Проверки
command -v git >/dev/null 2>&1 || { echo "git не найден. Установите git и повторите."; exit 1; }
command -v docker >/dev/null 2>&1 || { echo "docker не найден. Установите docker и повторите."; exit 1; }
# проверить наличие docker compose
if ! $COMPOSE_CMD version >/dev/null 2>&1; then
  echo "docker compose недоступен."
fi

echo
echo "Подготовка к развертыванию проекта в $DEST_DIR"
echo

# Ввод паролей (скрытый)
read -rp "Введите имя пользователя MySQL для приложения (по умолчанию 'app'): " MYSQL_USER
MYSQL_USER=${MYSQL_USER:-app}

read -rp "Введите имя базы данных (по умолчанию 'virtd'): " MYSQL_DATABASE
MYSQL_DATABASE=${MYSQL_DATABASE:-virtd}

# root password
while true; do
  read -s -rp "Введите пароль root для MySQL: " MYSQL_ROOT_PASSWORD
  echo
  read -s -rp "Подтвердите пароль root: " MYSQL_ROOT_PASSWORD_CONFIRM
  echo
  [[ "$MYSQL_ROOT_PASSWORD" == "$MYSQL_ROOT_PASSWORD_CONFIRM" ]] && break
  echo "Пароли не совпадают, попробуйте ещё раз."
done

# app password
while true; do
  read -s -rp "Введите пароль для пользователя $MYSQL_USER: " MYSQL_USER_PASSWORD
  echo
  read -s -rp "Подтвердите пароль для $MYSQL_USER: " MYSQL_USER_PASSWORD_CONFIRM
  echo
  [[ "$MYSQL_USER_PASSWORD" == "$MYSQL_USER_PASSWORD_CONFIRM" ]] && break
  echo "Пароли не совпадают, попробуйте ещё раз."
done

echo
echo "Пароли заданы. Продолжаем."

# Клонирование или обновление репозитория
if [ -d "$DEST_DIR/.git" ]; then
  echo "Репозиторий уже существует в $DEST_DIR, делаем git pull"
  cd "$DEST_DIR"
  git reset --hard HEAD || true
  git clean -fd || true
  git pull --rebase || git pull || true
else
  echo "Клонируем репозиторий в $DEST_DIR..."
  mkdir -p "$(dirname "$DEST_DIR")"
  git clone "$REPO_URL" "$DEST_DIR"
  cd "$DEST_DIR"
fi

# Создаём или перезаписываем переменные
echo "Создаём/обновляем файл .env в $DEST_DIR"

cat > .env <<EOF
# MySQL (используется docker-compose и приложение)
DB_HOST=db
DB_PORT=3306
DB_USER=${MYSQL_USER}
DB_PASSWORD=${MYSQL_USER_PASSWORD}
DB_NAME=${MYSQL_DATABASE}
TABLE_NAME=requests

MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD}
MYSQL_DATABASE=${MYSQL_DATABASE}
MYSQL_USER=${MYSQL_USER}
MYSQL_PASSWORD=${MYSQL_USER_PASSWORD}
EOF

if ! grep -q "^.env$" .gitignore 2>/dev/null; then
  echo ".env" >> .gitignore
  echo "Добавлена строка '.env' в .gitignore, чтобы секреты не попали в git."
fi

# Очистка старых контейнеров
echo
read -rp "Хотите выполнить 'docker compose down -v' перед запуском (это удалит существующие тома)? [y/N]: " RESP
RESP=${RESP:-N}

if [[ "$RESP" =~ ^[Yy]$ ]]; then
  echo "Останавливаем старые контейнеры и удаляем связанные тома."
  $COMPOSE_CMD down -v || true
fi

# Запускаем проект
echo "Запускаем проект: $COMPOSE_CMD up -d"
$COMPOSE_CMD up -d --build

echo "Готово. Проект развернут."

