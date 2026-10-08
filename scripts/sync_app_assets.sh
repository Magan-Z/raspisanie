#!/bin/bash
# Копирует результат парсера (data/public) во встроенную копию расписания приложения.
# Запускать из папки проекта после работы парсера:  bash scripts/sync_app_assets.sh
set -e
cd "$(dirname "$0")/.."
rm -rf app/assets/schedule
mkdir -p app/assets/schedule/groups
cp data/public/index.json app/assets/schedule/
cp data/public/groups/*.json app/assets/schedule/groups/
echo "Скопировано: $(ls app/assets/schedule/groups | wc -l) файлов групп"
