"""Запуск парсера из командной строки (из папки data/):

    python -m schedule_parser --out public

Что происходит: xlsx → разбор → проверки → сравнение с прошлой версией → файлы в папке --out.
Если проверки не прошли — пишется только report.txt, а программа завершается с кодом 1.
"""

import argparse
import json
import sys
from datetime import datetime, timezone
from pathlib import Path

from .diff import compare, load_previous
from .extract import extract_workbook
from .layout import LayoutError
from .publish import build_report, group_documents, make_version, write_public
from .validate import validate

DATA_DIR = Path(__file__).resolve().parent.parent  # папка data/


def main() -> int:
    parser = argparse.ArgumentParser(prog="schedule_parser", description="Разбор расписания из xlsx в JSON и .ics")
    parser.add_argument("--out", default="public", help="куда положить результат (по умолчанию public)")
    parser.add_argument("--config", default=str(DATA_DIR / "config.json"), help="путь к config.json")
    parser.add_argument("--source", help="другой xlsx вместо указанного в config (для проверок)")
    parser.add_argument(
        "--previous",
        help="прошлая публикация для сравнения: адрес сайта или папка (по умолчанию publicBaseUrl из config)",
    )
    args = parser.parse_args()

    config_path = Path(args.config)
    config = json.loads(config_path.read_text(encoding="utf-8"))
    source = Path(args.source) if args.source else config_path.parent / config["source"]
    out = Path(args.out)
    out.mkdir(parents=True, exist_ok=True)

    print(f"Читаю {source} …")
    try:
        sheets = extract_workbook(source, config)
    except (LayoutError, ValueError, OSError) as error:
        # Файл не удалось даже разобрать (нет листа, сдвинулись заголовки, файла нет)
        (out / "report.txt").write_text(f"ОШИБКА разбора, публикация остановлена:\n  ✗ {error}\n", encoding="utf-8")
        print(f"\nФайл не разобран, публикация остановлена:\n  ✗ {error}")
        return 1
    previous = load_previous(args.previous if args.previous is not None else config.get("publicBaseUrl"))

    errors = validate(sheets, previous)
    if errors:
        (out / "report.txt").write_text(build_report(sheets, errors, None), encoding="utf-8")
        print("\nПроверки НЕ пройдены, файлы расписания не обновлены:")
        for error in errors:
            print(f"  ✗ {error}")
        print(f"Подробности: {out / 'report.txt'}")
        return 1

    now = datetime.now(timezone.utc).replace(microsecond=0)
    version = make_version(sheets, now)
    docs = group_documents(sheets, version)
    diff = compare(previous, docs, version)
    calendars = write_public(out, sheets, config, version, docs, diff, now)
    (out / "report.txt").write_text(build_report(sheets, [], version), encoding="utf-8")

    for sheet_name, groups in sheets.items():
        print(f"  {sheet_name}: {len(groups)} групп")
    s = diff["summary"]
    print(f"Готово: {len(docs)} файлов групп, {calendars} календарей → {out}/")
    if previous:
        print(f"Изменения: добавлено {s['added']}, удалено {s['removed']}, изменено {s['changed']}")
    print(f"Версия: {version}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
