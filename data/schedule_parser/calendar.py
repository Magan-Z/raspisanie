"""Всё, что связано с датами: номер недели, курс группы, время пар."""

import re
from datetime import date, datetime, time, timedelta
from zoneinfo import ZoneInfo


def parse_date(text: str) -> date:
    """«2026-08-31» → date(2026, 8, 31)."""
    return date.fromisoformat(text)


def week_number(day: date, week_anchor: date) -> int:
    """Номер недели (1 или 2). week_anchor — понедельник первой «1 недели»."""
    return ((day - week_anchor).days // 7) % 2 + 1


def course_from_group_name(name: str, academic_year_start: int) -> int:
    """Курс по году поступления в названии группы: «1 БИ-25» в 2026 году → 2 курс."""
    match = re.search(r"-(\d{2})\b", name)
    if match is None:
        raise ValueError(f"В названии группы нет года: {name!r}")
    return academic_year_start - (2000 + int(match.group(1))) + 1


def pair_times(day: date, pair: int, bells: list[list[str]], timezone: str) -> tuple[datetime, datetime]:
    """Начало и конец пары в этот день (с часовым поясом)."""
    start_text, end_text = bells[pair - 1]
    tz = ZoneInfo(timezone)
    start = datetime.combine(day, time.fromisoformat(start_text), tzinfo=tz)
    end = datetime.combine(day, time.fromisoformat(end_text), tzinfo=tz)
    return start, end


def study_days(config: dict) -> list[date]:
    """Все учебные дни семестра: без воскресений и праздников."""
    start = parse_date(config["semester"]["start"])
    end = parse_date(config["semester"]["end"])
    holidays = {parse_date(h) for h in config["holidays"]}

    days = []
    day = start
    while day <= end:
        if day.isoweekday() != 7 and day not in holidays:
            days.append(day)
        day += timedelta(days=1)
    return days
