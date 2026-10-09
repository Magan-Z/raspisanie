"""Независимая перепроверка: Excel ↔ JSON групп ↔ календари .ics (код в tools/, не использует парсер)."""

import subprocess
import sys
from pathlib import Path

import pytest

DATA = Path(__file__).resolve().parent.parent
SOURCE = DATA / "sources" / "raspisanie.xlsx"
sys.path.insert(0, str(DATA / "tools"))

import verify_ics  # noqa: E402
import verify_xlsx  # noqa: E402


@pytest.fixture(scope="module")
def output(tmp_path_factory) -> Path:
    out = tmp_path_factory.mktemp("public")
    subprocess.run([sys.executable, "-m", "schedule_parser", "--out", str(out)], cwd=DATA, check=True, capture_output=True)
    return out


def test_json_matches_excel_cell_by_cell(output: Path) -> None:
    stats, problems = verify_xlsx.check(str(SOURCE), str(output))
    assert problems == []
    assert stats["groups"] == stats["json_groups"] == 50
    assert stats["cells"] > 1000


def test_calendars_match_lessons(output: Path) -> None:
    stats, problems = verify_ics.check(str(output), str(DATA / "config.json"))
    assert problems == []
    assert stats["files"] == 172


def test_verifier_detects_a_broken_file(output: Path, tmp_path: Path) -> None:
    """Проверка самой проверки: испорченный JSON должен находиться."""
    import json
    import shutil

    broken = tmp_path / "broken"
    shutil.copytree(output, broken)
    p = broken / "groups" / "ofo-1-bi-25.json"
    doc = json.loads(p.read_text(encoding="utf-8"))
    doc["lessons"][0]["pair"] = 5
    p.write_text(json.dumps(doc, ensure_ascii=False), encoding="utf-8")
    _, problems = verify_xlsx.check(str(SOURCE), str(broken))
    assert problems
