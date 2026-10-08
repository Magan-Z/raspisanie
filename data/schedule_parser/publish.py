"""Запись готовых файлов в папку public/ (её потом выкладывает GitHub Pages)."""

import hashlib
import json
import shutil
from datetime import datetime
from pathlib import Path

from .ics import build_calendar, calendar_file_name, calendar_variants
from .models import Group

SCHEMA_VERSION = 1


def content_hash(data: object) -> str:
    """Хеш содержимого: одинаковые данные → одинаковый хеш."""
    text = json.dumps(data, ensure_ascii=False, sort_keys=True)
    return hashlib.sha256(text.encode("utf-8")).hexdigest()


def group_documents(sheets: dict[str, list[Group]], version: str) -> dict[str, dict]:
    """Содержимое всех groups/<id>.json."""
    docs = {}
    for groups in sheets.values():
        for group in groups:
            docs[group.id] = {
                "schemaVersion": SCHEMA_VERSION,
                "version": version,
                "group": group.info_dict(),
                "lessons": [l.to_dict() for l in group.lessons],
            }
    return docs


def make_version(sheets: dict[str, list[Group]], now: datetime) -> str:
    """«2026-10-08T16:36:00Z-a1b2c3d4»: время сборки + начало хеша всех данных."""
    everything = {g.id: _group_content(g) for groups in sheets.values() for g in groups}
    return f"{now:%Y-%m-%dT%H:%M:%SZ}-{content_hash(everything)[:8]}"


def _group_content(group: Group) -> dict:
    # Без поля version: иначе хеш менялся бы при каждой сборке, и приложение зря качало бы файл
    return {"group": group.info_dict(), "lessons": [l.to_dict() for l in group.lessons]}


def build_index(sheets: dict[str, list[Group]], config: dict, version: str) -> dict:
    forms = []
    for sheet_name, groups in sheets.items():
        sheet_conf = config["sheets"][sheet_name]
        forms.append({
            "code": sheet_conf["code"],
            "title": sheet_conf["title"],
            "groups": [
                {
                    "id": g.id,
                    "title": g.title,
                    "course": g.course,
                    "subgroups": [s.to_dict() for s in g.subgroups],
                    "hasGenderedPe": g.has_gendered_pe,
                    "hash": content_hash(_group_content(g))[:16],
                }
                for g in groups
            ],
        })
    return {
        "schemaVersion": SCHEMA_VERSION,
        "version": version,
        "semester": config["semester"],
        "weekAnchor": config["weekAnchor"],
        "timezone": config["timezone"],
        "bells": config["bells"],
        "holidays": config["holidays"],
        "forms": forms,
    }


def write_json(path: Path, data: object) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, ensure_ascii=False, indent=1) + "\n", encoding="utf-8")


def write_public(
    out: Path,
    sheets: dict[str, list[Group]],
    config: dict,
    version: str,
    group_docs: dict[str, dict],
    diff: dict,
    now: datetime,
) -> int:
    """Записывает index.json, groups/, ics/, diff/. Возвращает число календарей."""
    # Старые файлы удаляем, чтобы не остались группы, которых больше нет
    for sub in ("groups", "ics", "diff"):
        shutil.rmtree(out / sub, ignore_errors=True)

    write_json(out / "index.json", build_index(sheets, config, version))
    for group_id, doc in group_docs.items():
        write_json(out / "groups" / f"{group_id}.json", doc)
    write_json(out / "diff" / "latest.json", diff)

    ics_dir = out / "ics"
    ics_dir.mkdir(parents=True, exist_ok=True)
    count = 0
    for groups in sheets.values():
        for group in groups:
            for subgroup, gender in calendar_variants(group):
                text = build_calendar(group, subgroup, gender, config, now)
                # newline="" — чтобы Python не превращал \r\n в другие переводы строк
                with open(ics_dir / calendar_file_name(group, subgroup, gender), "w", encoding="utf-8", newline="") as f:
                    f.write(text)
                count += 1
    return count


def build_report(sheets: dict[str, list[Group]], errors: list[str], version: str | None) -> str:
    """Текстовый отчёт для владельца: что нашлось и что распозналось плохо."""
    lines = [f"Отчёт парсера расписания. Версия: {version or '— (не опубликовано)'}", ""]

    if errors:
        lines += ["ОШИБКИ (публикация остановлена):"] + [f"  ✗ {e}" for e in errors] + [""]
    else:
        lines += ["Все проверки пройдены ✓", ""]

    total_groups = total_lessons = 0
    lines.append("Группы по листам:")
    for sheet_name, groups in sheets.items():
        lessons = sum(len(g.lessons) for g in groups)
        total_groups += len(groups)
        total_lessons += lessons
        lines.append(f"  {sheet_name}: {len(groups)} групп, {lessons} занятий")
        for g in groups:
            subgroups = ", ".join(s.label for s in g.subgroups)
            lines.append(f"      {g.title:<16} курс {g.course}  занятий {len(g.lessons):>3}  подгруппы: {subgroups}")
    lines += [f"  Всего: {total_groups} групп, {total_lessons} занятий", ""]

    for field, title in (("teacher", "преподаватель"), ("room", "аудитория")):
        problems = sorted({
            (g.sheet, ", ".join(l.cells), l.raw)
            for groups in sheets.values()
            for g in groups
            for l in g.lessons
            if getattr(l, field) is None
        })
        lines.append(f"Ячейки, где не найден(а) {title}: {len(problems)}")
        lines += [f"  {sheet} {cells}: {raw}" for sheet, cells, raw in problems]
        lines.append("")
    return "\n".join(lines)
