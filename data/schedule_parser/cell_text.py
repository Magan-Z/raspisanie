"""Разбор текста ячейки: «Предмет Фамилия И.О. Аудитория» → отдельные поля."""

import re
from dataclasses import dataclass


@dataclass
class ParsedCell:
    subject: str
    teacher: str | None
    room: str | None
    tags: list[str]


# Пометки физ-ры: «(юноши)» → male, «(девушки)» → female
TAG_PATTERNS = {
    "male": re.compile(r"\(\s*юноши\s*\)", re.IGNORECASE),
    "female": re.compile(r"\(\s*девушки\s*\)", re.IGNORECASE),
}

# Аудитория в самом конце строки. Пробел перед ней не обязателен («Батаева П.С.2-05»).
#   2-05, 3-120, 4-02а  |  3 корпус  |  читальный зал (1 этаж)
ROOM_RE = re.compile(
    r"\s*("
    r"(?<!\d)\d-\d{2,3}[а-я]?"
    r"|\d\s*корпус"
    r"|читальный зал(?:\s*\(.*?\))?"
    r")\s*$",
    re.IGNORECASE,
)

# Преподаватель в конце строки: Фамилия (можно двойную и с лишней точкой) + инициалы.
# Инициалы бывают такие: «А.», «А.Х.», «М.С-У.», «М-Х.Р.», «А.А», «С-М.».
SURNAME = r"[А-ЯЁ][а-яё]+(?:-[А-ЯЁ][а-яё]+)?\.?"
INITIAL = r"[А-ЯЁ](?:-[А-ЯЁ])?"
INITIALS = rf"{INITIAL}\.(?:\s?{INITIAL}\.?)?"
TEACHER_RE = re.compile(rf"(?:^|\s)({SURNAME}\s+{INITIALS})\s*$")


def apply_fixes(text: str, fixes: dict[str, str]) -> str:
    """Исправляет опечатки по словарю из config.json (subjectFixes)."""
    for wrong, right in fixes.items():
        text = text.replace(wrong, right)
    return text


def parse(raw: str, fixes: dict[str, str] | None = None) -> ParsedCell:
    """Разбирает текст ячейки (уже без лишних пробелов) на предмет, преподавателя, аудиторию и теги."""
    rest = apply_fixes(raw, fixes or {})

    # Теги физ-ры
    tags = []
    for tag, pattern in TAG_PATTERNS.items():
        if pattern.search(rest):
            tags.append(tag)
            rest = pattern.sub(" ", rest)
    rest = " ".join(rest.split())

    # Аудитория — с конца строки
    room = None
    match = ROOM_RE.search(rest)
    if match:
        room = " ".join(match.group(1).split())
        rest = rest[: match.start()].strip()

    # Преподаватель — с конца того, что осталось
    teacher = None
    match = TEACHER_RE.search(rest)
    if match:
        teacher = match.group(1)
        rest = rest[: match.start()].strip()

    subject = rest.strip(" ,;") or raw
    return ParsedCell(subject=subject, teacher=teacher, room=room, tags=tags)
