"""Готовит кэш приложения для браузера: подставляет в sw.js список файлов и «отпечаток» сборки.

Запуск (из scripts/build_web.sh):  python3 scripts/make_sw.py app/build/web
Отпечаток считается по всем файлам приложения, КРОМЕ встроенной копии расписания: так, пока код приложения
не менялся, обновление расписания не заставляет всех заново скачивать 5 МБ.
"""
import hashlib
import json
import os
import sys

root = sys.argv[1]
SKIP_DIRS = ("canvaskit/",)  # движок кладётся отдельно (sw.js выбирает нужную версию)
SKIP_NAMES = {"sw.js", "flutter_service_worker.js", "drift_worker.dart", "NOTICES", "version.json"}
SKIP_SUFFIXES = (".map", ".deps", ".symbols")

files = []
for folder, _, names in os.walk(root):
    for name in names:
        rel = os.path.relpath(os.path.join(folder, name), root).replace(os.sep, "/")
        if name.startswith(".") or name in SKIP_NAMES or rel.startswith(SKIP_DIRS) or rel.endswith(SKIP_SUFFIXES):
            continue
        files.append(rel)
files.sort()

digest = hashlib.sha1()
for rel in files:
    if "/schedule/" in rel:
        continue
    digest.update(rel.encode())
    digest.update(open(os.path.join(root, rel), "rb").read())
# Движок тоже влияет на работу приложения: его отпечаток лежит в flutter_bootstrap.js, так что он уже учтён.

# Страница открывается и по адресу «app/», а не только «app/index.html»
listed = ["./"] + files
path = os.path.join(root, "sw.js")
text = open(path, encoding="utf-8").read()
text = text.replace("__BUILD__", digest.hexdigest()[:12]).replace("__FILES__", json.dumps(listed, ensure_ascii=False))
open(path, "w", encoding="utf-8").write(text)
print(f"sw.js: {len(listed)} файлов, сборка {digest.hexdigest()[:12]}")
