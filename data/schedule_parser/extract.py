"""Сборка занятий для всех групп всех листов."""

import re
from pathlib import Path

import openpyxl

from . import cell_text
from .calendar import course_from_group_name
from .layout import GroupLayout, SheetLayout, Slot, find_layout
from .models import Group, Lesson, Subgroup
from .sheet import Area, MergedSheet

TRANSLIT = {
    "а": "a", "б": "b", "в": "v", "г": "g", "д": "d", "е": "e", "ё": "e", "ж": "zh",
    "з": "z", "и": "i", "й": "y", "к": "k", "л": "l", "м": "m", "н": "n", "о": "o",
    "п": "p", "р": "r", "с": "s", "т": "t", "у": "u", "ф": "f", "х": "h", "ц": "ts",
    "ч": "ch", "ш": "sh", "щ": "sch", "ъ": "", "ы": "y", "ь": "", "э": "e", "ю": "yu",
    "я": "ya",
}


def slugify(name: str) -> str:
    """«ОЗ-1 ИТиСС-26» → «oz-1-itiss-26»."""
    latin = "".join(TRANSLIT.get(ch, ch) for ch in name.lower())
    return re.sub(r"[^a-z0-9]+", "-", latin).strip("-")


def extract_workbook(path: Path, config: dict) -> dict[str, list[Group]]:
    """Открывает xlsx и разбирает листы из config. Результат: имя листа → группы."""
    workbook = openpyxl.load_workbook(path, data_only=True)
    result = {}
    for sheet_name, sheet_conf in config["sheets"].items():
        if sheet_name not in workbook.sheetnames:
            raise ValueError(f"В файле нет листа «{sheet_name}»")
        sheet = MergedSheet(workbook[sheet_name])
        result[sheet_name] = extract_sheet(sheet, sheet_conf["code"], config)
    return result


def extract_sheet(sheet: MergedSheet, form_code: str, config: dict) -> list[Group]:
    layout = find_layout(sheet)
    groups = []
    for group_layout in layout.groups:
        subgroups = [
            Subgroup(s.n, s.label or f"Подгруппа {s.n}") for s in group_layout.subgroups
        ]
        group = Group(
            id=f"{form_code}-{slugify(group_layout.name)}",
            title=group_layout.name,
            form=form_code,
            sheet=sheet.title,
            course=course_from_group_name(group_layout.name, config["academicYearStart"]),
            subgroups=subgroups,
        )
        for slot in layout.slots[group_layout.day_col]:
            group.lessons.extend(_lessons_in_slot(sheet, layout, group_layout, slot, config))
        _collapse_subgroups(group, group_layout)
        group.lessons.sort(key=lambda l: (l.weekday, l.pair, l.week, l.subgroups, l.tags))
        groups.append(group)
    return groups


def _lessons_in_slot(
    sheet: MergedSheet, layout: SheetLayout, group: GroupLayout, slot: Slot, config: dict
) -> list[Lesson]:
    """Шаг 6: занятия одной группы в одной паре."""
    top, bottom = slot.rows[0], slot.rows[-1]

    # (неделя, текст) → номера подгрупп и области ячеек, откуда взят текст
    found: dict[tuple[int, str], tuple[list[int], list[Area]]] = {}

    def remember(week: int, text: str, n: int, areas: list[Area]) -> None:
        subgroups, all_areas = found.setdefault((week, text), ([], []))
        if n not in subgroups:
            subgroups.append(n)
        all_areas.extend(a for a in areas if a not in all_areas)

    for subgroup in group.subgroups:
        col = subgroup.cols[0]
        t1, t2 = sheet.text(top, col), sheet.text(bottom, col)
        area1, area2 = sheet.area(top, col), sheet.area(bottom, col)
        if t1 and t1 == t2:
            remember(0, t1, subgroup.n, [area1, area2])
        else:
            if t1:
                remember(1, t1, subgroup.n, [area1])
            if t2:
                remember(2, t2, subgroup.n, [area2])

    lessons = []
    for (week, text), (subgroups, areas) in found.items():
        parsed = cell_text.parse(text, config.get("subjectFixes"))
        lessons.append(
            Lesson(
                weekday=slot.weekday,
                pair=slot.pair,
                week=week,
                subgroups=sorted(subgroups),
                kind=_lesson_kind(text, areas, layout),
                subject=parsed.subject,
                teacher=parsed.teacher,
                room=parsed.room,
                tags=parsed.tags,
                raw=text,
                cells=[a.coord for a in areas],
                with_groups=_groups_sharing(areas, layout, group),
            )
        )
    return lessons


def _groups_sharing(areas: list[Area], layout: SheetLayout, own: GroupLayout) -> list[str]:
    """С какими ещё группами объединена ячейка (общая лекция, поток): названия групп слева направо.

    Если занятие идёт каждую неделю, но в верхней и нижней строке ячейка объединена по-разному
    (например, на 1 неделе лекция у двух групп, а на 2 неделе у четырёх), называем только группы,
    которые вместе с этой во ВСЕ недели: так мы никогда не укажем лишнего."""
    per_row: dict[int, set[int]] = {}
    for area in areas:
        for row in area.rows:
            per_row.setdefault(row, set()).update(area.cols)
    shared: set[str] | None = None
    for cols in per_row.values():
        names = {g.name for g in layout.groups if g is not own and cols & set(g.cols)}
        shared = names if shared is None else shared & names
    return [g.name for g in layout.groups if g.name in (shared or set())]


def _lesson_kind(text: str, areas: list[Area], layout: SheetLayout) -> str:
    lower = text.lower()
    if "физическая культура" in lower:
        return "pe"
    if "кураторский час" in lower:
        return "curator"
    # Ячейка шире одной группы → общая лекция для нескольких групп
    cols = {c for a in areas for c in a.cols}
    groups_covered = sum(1 for g in layout.groups if cols & set(g.cols))
    return "lecture" if groups_covered > 1 else "practice"


def _collapse_subgroups(group: Group, layout: GroupLayout) -> None:
    """Если подписей подгрупп нет и все занятия общие для всех — подгруппа на самом деле одна."""
    if len(group.subgroups) < 2 or any(s.label for s in layout.subgroups):
        return
    everyone = [s.n for s in group.subgroups]
    if all(lesson.subgroups == everyone for lesson in group.lessons):
        group.subgroups = [Subgroup(1, "Подгруппа 1")]
        for lesson in group.lessons:
            lesson.subgroups = [1]
