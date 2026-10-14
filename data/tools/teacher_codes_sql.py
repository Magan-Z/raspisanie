"""Готовит команду для SQL Editor (Supabase): коды преподавателей на всех преподавателей из расписания.

Каждый код привязан к преподавателю и к списку его групп (из расписания): только им он сможет отправлять ДЗ.
Запуск (из папки data):
    python tools/teacher_codes_sql.py                      # все преподаватели
    python tools/teacher_codes_sql.py --only Халиев        # только те, у кого в имени есть «Халиев»
    python tools/teacher_codes_sql.py --dir public         # откуда брать расписание (по умолчанию app/assets/schedule)
Результат вставьте в Supabase → SQL Editor → Run: в таблице появятся имя и код. Код отдайте преподавателю лично.

Совпадение имён такое же, как в приложении (domain/search.dart): фамилия и первые буквы имени и отчества;
если буквы отчества нет в одном из написаний, она не мешает. Полное ФИО берётся из справочника config.json (teachers).
"""
import argparse
import glob
import json
import os
import re


def split_name(name: str) -> tuple[str, str, str]:
    """«Чураев И.Л.» и «Чураев Ибрагим Лечаевич» → (фамилия, буква имени, буква отчества), строчные."""
    parts = name.strip().split()
    surname = parts[0].replace(".", "").lower()
    if len(parts) == 1:
        return surname, "", ""
    if len(parts) >= 3 and "." not in parts[1] and len(parts[1]) > 2:
        return surname, parts[1][0].lower(), parts[2][0].lower()
    rest = "".join(parts[1:]).lower()
    dot = rest.find(".")
    return surname, rest[0] if rest else "", rest[dot + 1] if 0 <= dot < len(rest) - 1 else ""


def same_teacher(a: str, b: str) -> bool:
    x, y = split_name(a), split_name(b)
    if x[0] != y[0]:
        return False
    if x[1] and y[1] and x[1] != y[1]:
        return False
    if x[2] and y[2] and x[2] != y[2]:
        return False
    return True


def teachers_with_groups(schedule_dir: str, directory: list[str]) -> list[tuple[str, list[str]]]:
    """[(имя, [номера групп])] по алфавиту: имя полное из справочника, если есть, иначе самое полное из расписания."""
    names: dict[str, set[str]] = {}  # написание в расписании → группы
    for path in sorted(glob.glob(os.path.join(schedule_dir, "groups", "*.json"))):
        doc = json.load(open(path, encoding="utf-8"))
        group = doc["group"]["id"]
        for lesson in doc["lessons"]:
            if lesson.get("teacher"):
                names.setdefault(lesson["teacher"], set()).add(group)

    spellings = list(names)
    # «Алиева М.» лишняя, если есть «Алиева М.В.» (то же правило, что в приложении)
    keep = [s for s in spellings if split_name(s)[2] or not any(o != s and split_name(o)[2] and same_teacher(s, o) for o in spellings)]

    result: dict[str, set[str]] = {}
    for name in keep:
        full = next((d for d in directory if same_teacher(name, d)), name)
        groups: set[str] = set()
        for spelling, gs in names.items():
            if same_teacher(name, spelling):
                groups |= gs
        result.setdefault(full, set()).update(groups)
    return sorted((n, sorted(g)) for n, g in result.items())


def build_sql(teachers: list[tuple[str, list[str]]], version: str = "") -> str:
    def q(text: str) -> str:
        return "'" + text.replace("'", "''") + "'"

    rows = ",\n  ".join(f"({q(name)}, array[{', '.join(q(g) for g in groups)}])" for name, groups in teachers)
    return (
        f"-- Коды преподавателей{f' (расписание {version})' if version else ''}: {len(teachers)} шт.\n"
        "-- Вставьте в Supabase → SQL Editor и нажмите Run. В ответе будут имя и код: код отдайте преподавателю лично.\n"
        "-- Код одноразовый; у преподавателя не больше двух кодов. Отозвать: delete from public.teacher_codes where code = 'КОД';\n"
        "select t.name, public.owner_issue_teacher_code(t.name, t.groups) as code\n"
        "from (values\n  " + rows + "\n) as t(name, groups)\n"
        "order by t.name;\n"
    )


def main() -> None:
    here = os.path.dirname(os.path.abspath(__file__))
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--dir", default=os.path.join(here, "..", "..", "app", "assets", "schedule"))
    parser.add_argument("--only", default="", help="часть имени: только подходящие преподаватели")
    args = parser.parse_args()

    config = json.load(open(os.path.join(here, "..", "config.json"), encoding="utf-8"))
    index = json.load(open(os.path.join(args.dir, "index.json"), encoding="utf-8"))
    teachers = teachers_with_groups(args.dir, config.get("teachers", []))
    if args.only:
        teachers = [(n, g) for n, g in teachers if re.search(re.escape(args.only), n, re.IGNORECASE)]
    if not teachers:
        raise SystemExit("Никого не нашлось")
    print(build_sql(teachers, index.get("version", "")))


if __name__ == "__main__":
    main()
