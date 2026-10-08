"""Поиск «скелета» листа: где дни недели, где группы и подгруппы, в каких строках пары.

Всё ищется по тексту, а не по жёстким координатам: если в новом файле
строки или столбцы сдвинутся, парсер всё равно их найдёт.
"""

import re
from dataclasses import dataclass

from .sheet import Area, MergedSheet

# Название группы: буквы, дефис, две цифры года («БИ-25», «М-ИВТ-26», «ИТиСС-23»)
GROUP_RE = re.compile(r"[А-ЯЁа-яёA-Za-z]+-\d{2}\b")

# Ячейка «Часы»: «1-2», «3-4» … (на всякий случай допускаем пробелы и длинное тире)
HOURS_RE = re.compile(r"^(\d+)\s*[-–—]\s*(\d+)$")

# Первые три буквы дня недели → номер дня
WEEKDAYS = {"пон": 1, "вто": 2, "сре": 3, "чет": 4, "пят": 5, "суб": 6}


@dataclass
class SubgroupLayout:
    n: int
    label: str | None   # None, если подписи в таблице нет
    cols: list[int]


@dataclass
class GroupLayout:
    name: str           # «1 БИ-25» (без «(30)»)
    area: Area          # ячейка с названием группы
    day_col: int        # столбец «Дни недели» её блока
    subgroups: list[SubgroupLayout]

    @property
    def cols(self) -> list[int]:
        return list(self.area.cols)


@dataclass
class Slot:
    """Одна пара в сетке: день, номер пары и строки (верхняя = 1 неделя, нижняя = 2)."""
    weekday: int
    pair: int
    rows: list[int]


@dataclass
class SheetLayout:
    day_cols: list[int]
    first_data_row: int
    groups: list[GroupLayout]
    slots: dict[int, list[Slot]]   # столбец «Дни недели» → пары этого блока


class LayoutError(Exception):
    """Лист не похож на расписание (не нашлись заголовки)."""


def find_layout(sheet: MergedSheet) -> SheetLayout:
    header_row, day_cols = _find_header(sheet)
    first_data_row = sheet.area(header_row, day_cols[0]).bottom + 1

    group_row, subgroup_row = _find_group_rows(sheet, header_row, first_data_row)
    groups = _find_groups(sheet, group_row, subgroup_row, day_cols)
    slots = {day_col: _find_slots(sheet, day_col, first_data_row) for day_col in day_cols}
    return SheetLayout(day_cols, first_data_row, groups, slots)


def _top_left_texts(sheet: MergedSheet, row: int) -> list[tuple[int, str]]:
    """Непустые тексты строки — только левые верхние клетки областей (без дублей)."""
    result = []
    for col in range(1, sheet.max_col + 1):
        if sheet.is_top_left(row, col):
            text = sheet.text(row, col)
            if text:
                result.append((col, text))
    return result


def _find_header(sheet: MergedSheet) -> tuple[int, list[int]]:
    """Шаг 1: строка, где написано «Дни недели», и все такие столбцы."""
    for row in range(1, sheet.max_row + 1):
        day_cols = [col for col, text in _top_left_texts(sheet, row) if text.lower() == "дни недели"]
        if day_cols:
            return row, day_cols
    raise LayoutError(f"Лист «{sheet.title}»: не найдена ячейка «Дни недели»")


def _find_group_rows(sheet: MergedSheet, header_row: int, first_data_row: int) -> tuple[int, int | None]:
    """Шаг 2: строка с названиями групп и (если есть) строка с подписями подгрупп."""
    matching_rows = [
        row
        for row in range(header_row, first_data_row)
        if any(GROUP_RE.search(text) for _, text in _top_left_texts(sheet, row))
    ]
    if not matching_rows:
        raise LayoutError(f"Лист «{sheet.title}»: не найдена строка с названиями групп")
    group_row = matching_rows[0]
    subgroup_row = matching_rows[1] if len(matching_rows) > 1 else None
    return group_row, subgroup_row


def _find_groups(
    sheet: MergedSheet, group_row: int, subgroup_row: int | None, day_cols: list[int]
) -> list[GroupLayout]:
    """Шаги 3–4: группы и их подгруппы."""
    groups = []
    for col, text in _top_left_texts(sheet, group_row):
        if not GROUP_RE.search(text):
            continue
        # «1 БИ-25 (30)» → «1 БИ-25»; скобки бывают и пустыми: «М-ИВТ-25 ()»
        name = re.sub(r"\s*\([^)]*\)\s*$", "", text).strip()
        area = sheet.area(group_row, col)
        day_col = max((d for d in day_cols if d < col), default=None)
        if day_col is None:
            raise LayoutError(f"Лист «{sheet.title}»: у группы {name} нет столбца «Дни недели» слева")
        subgroups = _find_subgroups(sheet, area, subgroup_row)
        groups.append(GroupLayout(name, area, day_col, subgroups))
    return groups


def _find_subgroups(sheet: MergedSheet, group_area: Area, subgroup_row: int | None) -> list[SubgroupLayout]:
    """Подгруппа = отдельная область в строке подгрупп. Нет такой строки — каждый столбец."""
    parts: list[tuple[str | None, list[int]]] = []
    if subgroup_row is not None:
        seen: set[Area] = set()
        for col in group_area.cols:
            area = sheet.area(subgroup_row, col)
            if area in seen:
                continue
            seen.add(area)
            cols = [c for c in area.cols if c in group_area.cols]
            parts.append((sheet.text(subgroup_row, col) or None, cols))
    else:
        parts = [(None, [col]) for col in group_area.cols]

    return [SubgroupLayout(n, label, cols) for n, (label, cols) in enumerate(parts, start=1)]


def _find_slots(sheet: MergedSheet, day_col: int, first_data_row: int) -> list[Slot]:
    """Шаг 5: идём вниз по столбцу «Часы» и собираем пары."""
    hours_col = day_col + 1
    slots = []
    row = first_data_row
    while row <= sheet.max_row:
        area = sheet.area(row, hours_col)
        match = HOURS_RE.match(sheet.text(row, hours_col))
        if not match or area.top != row:
            row = area.bottom + 1
            continue

        rows = list(area.rows)
        # «Часы» не объединены, а следующая строка пустая — она тоже относится к этой паре
        next_row = area.bottom + 1
        if len(rows) == 1 and next_row <= sheet.max_row and not sheet.text(next_row, hours_col):
            rows.append(next_row)

        weekday = WEEKDAYS.get(sheet.text(row, day_col)[:3].lower())
        if weekday is not None:
            slots.append(Slot(weekday=weekday, pair=int(match.group(2)) // 2, rows=rows))
        row = rows[-1] + 1
    return slots
