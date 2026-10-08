"""Сравнение нового расписания с прошлой опубликованной версией."""

import json
import urllib.request
from pathlib import Path

# По этим полям ищем «то же самое» занятие в старой и новой версии
KEY_FIELDS = ("weekday", "pair", "week", "subgroups", "tags")
# Эти поля сравниваем, чтобы найти изменения
COMPARED_FIELDS = ("subject", "teacher", "room", "kind")


def load_previous(source: str | None) -> dict | None:
    """Скачивает прошлую публикацию: {"index": {...}, "groups": {id: {...}}}.

    source — адрес сайта (https://…) или папка на диске (удобно для проверки).
    Если прошлой версии нет или адрес ещё не настроен — возвращает None.
    """
    if not source or "<" in source:  # в config ещё стоит заглушка «<github-логин>»
        return None
    try:
        index = _read_json(source, "index.json")
        groups = {}
        for form in index["forms"]:
            for group in form["groups"]:
                groups[group["id"]] = _read_json(source, f"groups/{group['id']}.json")
        return {"index": index, "groups": groups}
    except Exception as error:  # сети нет, сайта ещё нет, файл битый — просто сравнивать не с чем
        print(f"Прошлая версия недоступна ({error}); сравнение пропущено.")
        return None


def _read_json(source: str, path: str) -> dict:
    if source.startswith(("http://", "https://")):
        url = source.rstrip("/") + "/" + path
        with urllib.request.urlopen(url, timeout=20) as response:
            return json.loads(response.read().decode("utf-8"))
    return json.loads((Path(source) / path).read_text(encoding="utf-8"))


def _key(lesson: dict) -> tuple:
    return tuple(tuple(v) if isinstance(v, list) else v for v in (lesson[f] for f in KEY_FIELDS))


def compare(previous: dict | None, new_groups: dict[str, dict], new_version: str) -> dict:
    """Строит diff/latest.json. new_groups — содержимое новых groups/<id>.json."""
    result = {
        "from": previous["index"]["version"] if previous else None,
        "to": new_version,
        "groupsAdded": [],
        "groupsRemoved": [],
        "groups": {},
        "summary": {"added": 0, "removed": 0, "changed": 0},
    }
    if previous is None:
        return result

    old_groups = previous["groups"]
    result["groupsAdded"] = sorted(set(new_groups) - set(old_groups))
    result["groupsRemoved"] = sorted(set(old_groups) - set(new_groups))

    for group_id in sorted(set(new_groups) & set(old_groups)):
        old = {_key(l): l for l in old_groups[group_id]["lessons"]}
        new = {_key(l): l for l in new_groups[group_id]["lessons"]}

        added = [new[k] for k in new if k not in old]
        removed = [old[k] for k in old if k not in new]
        changed = []
        for k in new.keys() & old.keys():
            fields = {
                f: [old[k][f], new[k][f]] for f in COMPARED_FIELDS if old[k][f] != new[k][f]
            }
            if fields:
                changed.append({"lesson": new[k], "changes": fields})  # поле: [было, стало]

        if added or removed or changed:
            result["groups"][group_id] = {"added": added, "removed": removed, "changed": changed}
            result["summary"]["added"] += len(added)
            result["summary"]["removed"] += len(removed)
            result["summary"]["changed"] += len(changed)
    return result
