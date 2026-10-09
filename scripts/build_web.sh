#!/bin/bash
# Собирает веб-версию приложения (для iPhone и любых браузеров) в app/build/web.
# Запускать из папки проекта:  bash scripts/build_web.sh
# Переменные (необязательно):
#   BASE_HREF  — где лежит приложение на сайте (по умолчанию /raspisanie/app/)
#   SITE_URL   — адрес сайта с расписанием (по умолчанию из data/config.json)
set -e
cd "$(dirname "$0")/../app"

BASE_HREF="${BASE_HREF:-/raspisanie/app/}"
SITE_URL="${SITE_URL:-$(python3 -c "import json;print(json.load(open('../data/config.json'))['publicBaseUrl'])")}"

# 1. База данных в браузере работает через WebAssembly: нужны sqlite3.wasm (той же версии, что в pubspec.lock)
#    и «рабочий» drift_worker.js — собирается из web/drift_worker.dart
VERSION=$(grep -A8 '^  sqlite3:' pubspec.lock | grep 'version:' | head -1 | sed 's/.*"\(.*\)".*/\1/')
if [ ! -f web/sqlite3.wasm ] || [ ! -f web/.sqlite3-version ] || [ "$(cat web/.sqlite3-version)" != "$VERSION" ]; then
  echo "Скачиваю sqlite3.wasm $VERSION …"
  curl -fL -o web/sqlite3.wasm "https://github.com/simolus3/sqlite3.dart/releases/download/sqlite3-$VERSION/sqlite3.wasm"
  echo "$VERSION" > web/.sqlite3-version
fi
dart compile js -O4 web/drift_worker.dart -o web/drift_worker.js
rm -f web/drift_worker.js.deps web/drift_worker.js.map

# 2. Сама сборка. canvaskit кладём внутрь сборки (без загрузки с чужого сервера) — приложение работает и без интернета
flutter build web --release --base-href "$BASE_HREF" --no-web-resources-cdn \
  --dart-define=SCHEDULE_BASE_URL="$SITE_URL"
echo "Готово: app/build/web (адрес на сайте: $BASE_HREF)"
