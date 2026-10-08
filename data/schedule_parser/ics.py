"""Генерация календарей .ics (RFC 5545) — для подписки на iPhone и в Google Календаре.

Каждое занятие — отдельное событие на конкретную дату (без правил повторения):
так проще и одинаково работает во всех календарях.
"""

from datetime import datetime, timezone

from .calendar import pair_times, parse_date, study_days, week_number
from .models import Group, Lesson

KIND_TITLES = {"lecture": "лекция", "practice": "практика"}
GENDER_TITLES = {"m": "юноши", "f": "девушки"}
# В варианте «юноши» убираем занятия с тегом female, и наоборот
EXCLUDED_TAG = {"m": "female", "f": "male"}


def calendar_variants(group: Group) -> list[tuple[int, str | None]]:
    """Какие календари нужны группе: (номер подгруппы, None | 'm' | 'f')."""
    genders = [None, "m", "f"] if group.has_gendered_pe else [None]
    return [(s.n, g) for s in group.subgroups for g in genders]


def calendar_file_name(group: Group, subgroup: int, gender: str | None) -> str:
    """«ofo-1-bi-25-1-m.ics»."""
    suffix = f"-{gender}" if gender else ""
    return f"{group.id}-{subgroup}{suffix}.ics"


def build_calendar(group: Group, subgroup: int, gender: str | None, config: dict, generated_at: datetime) -> str:
    lessons = [l for l in group.lessons if _fits(l, subgroup, gender)]

    name = group.title
    if len(group.subgroups) > 1:
        name += f" · подгруппа {subgroup}"
    if gender:
        name += f" · {GENDER_TITLES[gender]}"

    lines = [
        "BEGIN:VCALENDAR",
        "VERSION:2.0",
        "PRODID:-//raspisanie//schedule_parser//RU",
        "CALSCALE:GREGORIAN",
        "METHOD:PUBLISH",
        f"X-WR-CALNAME:{escape(name)}",
        f"X-WR-TIMEZONE:{config['timezone']}",
        "REFRESH-INTERVAL;VALUE=DURATION:PT6H",
        "X-PUBLISHED-TTL:PT6H",
    ]

    anchor = parse_date(config["weekAnchor"])
    stamp = _utc(generated_at)
    used_uids: set[str] = set()
    for day in study_days(config):
        week = week_number(day, anchor)
        todays = [l for l in lessons if l.weekday == day.isoweekday() and l.week in (0, week)]
        for lesson in sorted(todays, key=lambda l: (l.pair, l.tags)):
            start, end = pair_times(day, lesson.pair, config["bells"], config["timezone"])

            # UID не меняется между запусками — календарь обновит событие, а не создаст дубль
            uid = f"{group.id}-{subgroup}-{day:%Y%m%d}-{lesson.pair}"
            if uid in used_uids:  # две пары в одной клетке (например, физ-ра юношей и девушек)
                uid += "-" + "-".join(lesson.tags or ["x"])
            used_uids.add(uid)

            lines += [
                "BEGIN:VEVENT",
                f"UID:{uid}@raspisanie",
                f"DTSTAMP:{stamp}",
                f"DTSTART:{_utc(start)}",
                f"DTEND:{_utc(end)}",
                f"SUMMARY:{escape(_summary(lesson))}",
            ]
            if lesson.room:
                lines.append(f"LOCATION:{escape(lesson.room)}")
            lines += [f"DESCRIPTION:{escape(_description(lesson))}", "END:VEVENT"]

    lines.append("END:VCALENDAR")
    return "".join(fold(line) + "\r\n" for line in lines)


def _fits(lesson: Lesson, subgroup: int, gender: str | None) -> bool:
    if subgroup not in lesson.subgroups:
        return False
    return not (gender and EXCLUDED_TAG[gender] in lesson.tags)


def _summary(lesson: Lesson) -> str:
    """«ЧТК и этика · практика». У физ-ры и кураторского часа тип и так понятен."""
    kind = KIND_TITLES.get(lesson.kind)
    return f"{lesson.subject} · {kind}" if kind else lesson.subject


def _description(lesson: Lesson) -> str:
    week = "каждую неделю" if lesson.week == 0 else f"{lesson.week} неделя"
    parts = [lesson.teacher, week, lesson.raw]
    return "\n".join(p for p in parts if p)


def _utc(moment: datetime) -> str:
    """Время в UTC в формате iCalendar: 20261007T114000Z."""
    return moment.astimezone(timezone.utc).strftime("%Y%m%dT%H%M%SZ")


def escape(text: str) -> str:
    """Экранирование спецсимволов в значениях: \\ ; , и перевод строки."""
    return (
        text.replace("\\", "\\\\")
        .replace(";", "\\;")
        .replace(",", "\\,")
        .replace("\n", "\\n")
    )


def fold(line: str) -> str:
    """Переносит строки длиннее 75 байт (RFC 5545). Буквы не разрываются посередине."""
    if len(line.encode("utf-8")) <= 75:
        return line
    parts = []
    current = ""
    limit = 75
    for ch in line:
        if len((current + ch).encode("utf-8")) > limit:
            parts.append(current)
            current = ch
            limit = 74  # продолжение начинается с пробела, он тоже считается
        else:
            current += ch
    parts.append(current)
    return "\r\n ".join(parts)
