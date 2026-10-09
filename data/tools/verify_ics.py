"""Независимая сверка календарей .ics: события пересчитываются заново из JSON групп и правил календаря
(начало семестра, чётность недель, звонки) и сравниваются с тем, что записано в public/ics.

Запуск:  python tools/verify_ics.py public     (из папки data)
"""
import collections
import glob
import json
import os
import re
import sys
from datetime import date, datetime, timedelta, timezone


def check(out: str, config_path: str = "config.json") -> tuple[dict, list[str]]:
    cfg = json.load(open(config_path, encoding="utf-8"))
    anchor = date.fromisoformat(cfg["weekAnchor"])
    start = date.fromisoformat(cfg["semester"]["start"])
    end = date.fromisoformat(cfg["semester"]["end"])
    bells = cfg["bells"]
    holidays = set(cfg["holidays"])
    msk = timezone(timedelta(hours=3))

    def utc(d: date, hm: str) -> str:
        h, m = map(int, hm.split(":"))
        return datetime(d.year, d.month, d.day, h, m, tzinfo=msk).astimezone(timezone.utc).strftime("%Y%m%dT%H%M%SZ")

    docs = {os.path.basename(f)[:-5]: json.load(open(f, encoding="utf-8")) for f in glob.glob(f"{out}/groups/*.json")}
    problems, files, events_total = [], 0, 0
    for path in sorted(glob.glob(f"{out}/ics/*.ics")):
        name = os.path.basename(path)[:-4]
        m = re.fullmatch(r"(.+)-(\d+)(?:-([mf]))?", name)
        group_id, subgroup, gender = m.group(1), int(m.group(2)), {"m": "male", "f": "female"}.get(m.group(3))
        doc = docs[group_id]

        # Что должно быть: каждый день семестра (кроме воскресенья и праздников) × подходящие занятия
        expected = collections.Counter()
        day = start
        while day <= end:
            if day.weekday() != 6 and day.isoformat() not in holidays:
                week = ((day - anchor).days // 7) % 2 + 1
                for lesson in doc["lessons"]:
                    if lesson["weekday"] != day.isoweekday() or lesson["week"] not in (0, week) or subgroup not in lesson["subgroups"]:
                        continue
                    if lesson["tags"] and gender and gender not in lesson["tags"]:
                        continue
                    bell = bells[lesson["pair"] - 1]
                    expected[(utc(day, bell[0]), utc(day, bell[1]), lesson["subject"], lesson["room"])] += 1
            day += timedelta(days=1)

        # Что записано в файле (длинные строки ICS переносятся: убираем переносы)
        text = re.sub(r"\r?\n[ \t]", "", open(path, encoding="utf-8", newline="").read()).replace("\r", "")
        actual = collections.Counter()
        for event in re.findall(r"BEGIN:VEVENT(.*?)END:VEVENT", text, re.S):

            def field(key: str) -> str:
                found = re.search(rf"^{key}[^:\n]*:(.*)$", event, re.M)
                return found.group(1) if found else ""

            summary = field("SUMMARY").replace("\\,", ",").split(" · ")[0]
            actual[(field("DTSTART"), field("DTEND"), summary, field("LOCATION").replace("\\,", ","))] += 1

        files += 1
        events_total += sum(actual.values())
        if expected != actual:
            problems.append(
                f"{name}: ожидалось событий {sum(expected.values())}, в файле {sum(actual.values())}; "
                f"нет в файле: {list(expected - actual)[:2]}; лишнее: {list(actual - expected)[:2]}"
            )
    return {"files": files, "events": events_total}, problems


if __name__ == "__main__":
    stats, problems = check(sys.argv[1] if len(sys.argv) > 1 else "public")
    print(f"Календарей: {stats['files']}, событий: {stats['events']}, расхождений: {len(problems)}")
    for p in problems[:20]:
        print(" -", p)
    sys.exit(1 if problems else 0)
