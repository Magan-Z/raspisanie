"""Инструмент выдачи кодов преподавателей: имена совпадают как в приложении, группы берутся из расписания."""
import json
import sys
from pathlib import Path

DATA = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(DATA / "tools"))

import teacher_codes_sql as tool  # noqa: E402


def _group(tmp: Path, group_id: str, lessons: list[tuple[str, str | None]]) -> None:
    (tmp / "groups").mkdir(exist_ok=True)
    doc = {"group": {"id": group_id}, "lessons": [{"teacher": t, "subject": s} for s, t in lessons]}
    (tmp / "groups" / f"{group_id}.json").write_text(json.dumps(doc, ensure_ascii=False), encoding="utf-8")


def test_same_teacher_like_in_app():
    assert tool.same_teacher("Чураев И.Л.", "Чураев Ибрагим Лечаевич")
    assert tool.same_teacher("Алиева М.", "Алиева М.В.")
    assert not tool.same_teacher("Алиева М.В.", "Алиева М.И.")
    assert not tool.same_teacher("Юсупова М.Д.", "Юсупова Э.Д.")
    assert tool.same_teacher("Аюбов. С-М.", "Аюбов С.М.")


def test_groups_and_full_names(tmp_path):
    _group(tmp_path, "g-1", [("Мат", "Чураев И.Л."), ("Физ", "Алиева М."), ("Нет", None)])
    _group(tmp_path, "g-2", [("Мат", "Чураев Ибрагим Лечаевич"), ("Физ", "Алиева М.В.")])
    teachers = tool.teachers_with_groups(str(tmp_path), ["Чураев Ибрагим Лечаевич"])
    assert teachers == [("Алиева М.В.", ["g-1", "g-2"]), ("Чураев Ибрагим Лечаевич", ["g-1", "g-2"])]


def test_sql_is_valid_and_quotes_are_escaped():
    sql = tool.build_sql([("О'Нил А.Б.", ["ofo-1-bi-25", "ofo-2-bi-25"])], "2026-10-13")
    assert "owner_issue_teacher_code(t.name, t.groups)" in sql
    assert "('О''Нил А.Б.', array['ofo-1-bi-25', 'ofo-2-bi-25'])" in sql
    assert sql.rstrip().endswith("order by t.name;")
