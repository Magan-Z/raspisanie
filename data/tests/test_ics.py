"""Календари .ics: контрольные события, отсутствие лишних дней, стабильные UID."""

import re
from datetime import datetime, timezone

from schedule_parser.ics import build_calendar, calendar_file_name, calendar_variants, escape, fold
from schedule_parser.models import Group

NOW = datetime(2026, 10, 8, 12, 0, tzinfo=timezone.utc)


def events(text: str) -> list[str]:
    """Тексты событий VEVENT с «развёрнутыми» длинными строками."""
    unfolded = text.replace("\r\n ", "")
    return re.findall(r"BEGIN:VEVENT\r\n(.*?)END:VEVENT", unfolded, re.S)


def bi25_male(groups: dict[str, Group], config: dict) -> str:
    return build_calendar(groups["ofo-1-bi-25"], 1, "m", config, NOW)


def test_file_names(groups: dict[str, Group]) -> None:
    g = groups["ofo-1-bi-25"]
    names = [calendar_file_name(g, n, gender) for n, gender in calendar_variants(g)]
    assert "ofo-1-bi-25-1-m.ics" in names
    assert "ofo-1-bi-25-2.ics" in names
    assert len(names) == 6  # 2 подгруппы × (обе / юноши / девушки)


def test_header(groups: dict[str, Group], config: dict) -> None:
    text = bi25_male(groups, config)
    assert "X-WR-CALNAME:1 БИ-25 · подгруппа 1 · юноши" in text.replace("\r\n ", "")
    assert "X-WR-TIMEZONE:Europe/Moscow\r\n" in text
    assert "REFRESH-INTERVAL;VALUE=DURATION:PT6H\r\n" in text


def test_chtk_practice_on_october_7(groups: dict[str, Group], config: dict) -> None:
    found = [e for e in events(bi25_male(groups, config)) if "DTSTART:20261007T114000Z" in e]
    assert len(found) == 1
    assert "LOCATION:2-15" in found[0]
    assert "SUMMARY:ЧТК и этика · практика" in found[0]


def test_october_7_and_14(groups: dict[str, Group], config: dict) -> None:
    all_events = events(bi25_male(groups, config))
    oct7 = [e for e in all_events if "DTSTART:20261007" in e]
    oct14 = [e for e in all_events if "DTSTART:20261014" in e]
    assert len(oct7) == 2   # ТП + ЧТК практика, без кураторского часа
    assert len(oct14) == 3  # ТП + ЧТК лекция + кураторский час
    assert any("Кураторский час" in e and "DTSTART:20261014T132000Z" in e for e in oct14)


def test_female_pe_filtered_for_male(groups: dict[str, Group], config: dict) -> None:
    oct9 = [e for e in events(bi25_male(groups, config)) if "DTSTART:20261009" in e]
    assert oct9 == []  # в пятницу только физ-ра девушек


def test_no_events_on_holiday_and_sundays(groups: dict[str, Group], config: dict) -> None:
    text = build_calendar(groups["ofo-1-bi-25"], 1, None, config, NOW)
    starts = re.findall(r"DTSTART:(\d{8})", text)
    assert starts
    assert "20261104" not in starts
    for day in starts:
        assert datetime.strptime(day, "%Y%m%d").isoweekday() != 7


def test_uid_stable_between_runs(groups: dict[str, Group], config: dict) -> None:
    later = datetime(2026, 11, 1, tzinfo=timezone.utc)
    first = build_calendar(groups["ofo-1-bi-25"], 1, "m", config, NOW)
    second = build_calendar(groups["ofo-1-bi-25"], 1, "m", config, later)
    uids = re.findall(r"UID:(\S+)", first)
    assert uids == re.findall(r"UID:(\S+)", second)
    assert len(uids) == len(set(uids))
    assert "ofo-1-bi-25-1-20261007-4@raspisanie" in uids


def test_uids_unique_in_every_calendar(groups: dict[str, Group], config: dict) -> None:
    for g in groups.values():
        for n, gender in calendar_variants(g):
            uids = re.findall(r"UID:(\S+)", build_calendar(g, n, gender, config, NOW))
            assert len(uids) == len(set(uids)), calendar_file_name(g, n, gender)


def test_escape() -> None:
    assert escape("a,b;c\\d\ne") == "a\\,b\\;c\\\\d\\ne"


def test_fold_long_lines_by_bytes() -> None:
    line = "DESCRIPTION:" + "Ж" * 100  # каждая «Ж» — 2 байта
    folded = fold(line)
    parts = folded.split("\r\n ")
    assert len(parts) > 1
    assert all(len(p.encode("utf-8")) <= 75 for p in parts)
    assert "".join(parts) == line


def test_lines_not_longer_than_75_bytes(groups: dict[str, Group], config: dict) -> None:
    text = bi25_male(groups, config)
    for line in text.split("\r\n"):
        assert len(line.encode("utf-8")) <= 75
