"""Общие заготовки для тестов: конфиг и разобранный реальный файл (разбирается один раз)."""

import json
from pathlib import Path

import pytest

from schedule_parser.extract import extract_workbook
from schedule_parser.models import Group

DATA_DIR = Path(__file__).resolve().parent.parent


@pytest.fixture(scope="session")
def config() -> dict:
    return json.loads((DATA_DIR / "config.json").read_text(encoding="utf-8"))


@pytest.fixture(scope="session")
def sheets(config: dict) -> dict[str, list[Group]]:
    return extract_workbook(DATA_DIR / config["source"], config)


@pytest.fixture(scope="session")
def groups(sheets: dict[str, list[Group]]) -> dict[str, Group]:
    """Все группы по id."""
    return {g.id: g for gs in sheets.values() for g in gs}
