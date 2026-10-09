"""Номер недели, курс, время пар (§1.6 АРХИТЕКТУРА.md)."""

import json
from datetime import date
from pathlib import Path

import pytest

from schedule_parser.calendar import course_from_group_name, pair_times, study_days, week_number

ANCHOR = date(2026, 8, 31)
CONFIG = json.loads((Path(__file__).parent.parent / "config.json").read_text(encoding="utf-8"))

WEEK_1 = ["2026-08-31", "2026-09-05", "2026-09-14", "2026-10-12", "2027-01-04", "2027-07-05"]
WEEK_2 = ["2026-09-07", "2026-10-05", "2026-10-08", "2026-12-28", "2027-01-02", "2027-07-12"]


@pytest.mark.parametrize("day", WEEK_1)
def test_week_1(day: str) -> None:
    assert week_number(date.fromisoformat(day), ANCHOR) == 1


@pytest.mark.parametrize("day", WEEK_2)
def test_week_2(day: str) -> None:
    assert week_number(date.fromisoformat(day), ANCHOR) == 2


@pytest.mark.parametrize(
    "name, course",
    [("1 БИ-25", 2), ("ИБ-26", 1), ("ОЗ-1 ИТиСС-26", 1), ("ОЗ-БИ-22", 5), ("М-ИВТ-25", 2), ("ИТиСС-23", 4)],
)
def test_course(name: str, course: int) -> None:
    assert course_from_group_name(name, 2026) == course


def test_pair_times_in_utc() -> None:
    start, end = pair_times(date(2026, 10, 7), 4, CONFIG["bells"], "Europe/Moscow")
    assert start.isoformat() == "2026-10-07T14:40:00+03:00"
    assert end.isoformat() == "2026-10-07T16:10:00+03:00"


def test_study_days_skip_sundays_and_holidays() -> None:
    # В настройках праздников сейчас нет (владелец так решил), поэтому праздник задаём в самом тесте
    days = study_days({**CONFIG, "holidays": ["2026-11-04"]})
    assert date(2026, 11, 4) not in days          # праздник
    assert date(2026, 10, 11) not in days         # воскресенье
    assert date(2026, 10, 10) in days             # суббота — учебный день
    assert all(d.isoweekday() != 7 for d in days)
