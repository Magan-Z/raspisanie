"""Контрольные факты (§11 АРХИТЕКТУРА.md) на реальном файле расписания."""

from schedule_parser.models import Group, Lesson

MON, TUE, WED, THU, FRI, SAT = 1, 2, 3, 4, 5, 6


def lessons_for(group: Group, subgroup: int) -> list[Lesson]:
    return [l for l in group.lessons if subgroup in l.subgroups]


def find(group: Group, weekday: int, pair: int, week: int | None = None, subgroup: int | None = None) -> list[Lesson]:
    return [
        l for l in group.lessons
        if l.weekday == weekday and l.pair == pair
        and (week is None or l.week == week)
        and (subgroup is None or subgroup in l.subgroups)
    ]


# ---------- количество групп ----------

def test_group_counts(sheets: dict[str, list[Group]]) -> None:
    assert len(sheets["ОФО"]) == 29
    assert len(sheets["ОЗФО"]) == 17
    assert len(sheets["Магистратура ОФО"]) == 4
    assert sum(len(g) for g in sheets.values()) == 50


def test_ids_are_unique(groups: dict[str, Group]) -> None:
    assert len(groups) == 50


# ---------- 1 БИ-25 ----------

def test_bi25_group_info(groups: dict[str, Group]) -> None:
    g = groups["ofo-1-bi-25"]
    assert g.title == "1 БИ-25"
    assert g.course == 2
    assert [(s.n, s.label) for s in g.subgroups] == [(1, "БИ-25-1"), (2, "БИ-25-2")]
    assert g.has_gendered_pe


# (день, пара, неделя, предмет, преподаватель, тип, аудитория, теги, только_п/г_1)
BI25_SUBGROUP_1 = [
    (MON, 1, 0, "Философия", "Кутаев А.Х.", "lecture", "3-01", [], False),
    (MON, 2, 0, "Философия", "Кутаев А.Х.", "practice", "2-07", [], False),
    (MON, 3, 0, "Иностранный язык", "Идразова Э.С-А.", "practice", "2-16", [], True),
    (MON, 4, 0, "Технологии бизнес-коммуникаций", "Юнаева С.М.", "practice", "3-20", [], True),
    (TUE, 2, 0, "Физическая культура и спорт", "Навурбиев А.В.", "pe", "3 корпус", ["male"], False),
    (TUE, 3, 0, "Управление проектами", "Агаев М.В.", "lecture", "2-05", [], False),
    (TUE, 4, 0, "Аккаунтинг и аудит", "Батаева П.С.", "lecture", "2-05", [], False),
    (WED, 3, 0, "Технологическое предпринимательство", "Халиев М.С-У.", "lecture", "2-05", [], False),
    (WED, 4, 1, "ЧТК и этика", "Ахмадова М.П.", "lecture", "2-07", [], False),
    (WED, 4, 2, "ЧТК и этика", "Ахмадова М.П.", "practice", "2-15", [], False),
    (WED, 5, 1, "Кураторский час", "Юнаева С.М.", "curator", "2-05", [], False),
    (THU, 1, 0, "Управление проектами", "Адымханов А.", "practice", "2-21", [], True),
    (THU, 2, 0, "Аккаунтинг и аудит", "Батаева П.С.", "practice", "2-16", [], False),
    (THU, 3, 0, "Системы управления контентом", "Магомадов В.С.", "practice", "2-23", [], True),
    (FRI, 2, 0, "Физическая культура и спорт", "Магомадова Я.Г.", "pe", "3 корпус", ["female"], False),
    (SAT, 1, 0, "Технологическое предпринимательство", "Халиев М.С-У.", "practice", "2-23", [], True),
    (SAT, 2, 0, "Графический дизайн", "Магомедов И.А.", "practice", "2-18", [], True),
]


def test_bi25_subgroup_1_all_lessons(groups: dict[str, Group]) -> None:
    actual = sorted(
        (l.weekday, l.pair, l.week, l.subject, l.teacher, l.kind, l.room, l.tags, l.subgroups == [1])
        for l in lessons_for(groups["ofo-1-bi-25"], 1)
    )
    assert actual == sorted(BI25_SUBGROUP_1)


def test_bi25_subgroup_2_monday_pair_4(groups: dict[str, Group]) -> None:
    [lesson] = find(groups["ofo-1-bi-25"], MON, 4, subgroup=2)
    assert (lesson.subject, lesson.teacher, lesson.room) == ("Иностранный язык", "Идразова Э.С-А.", "2-16")


# ---------- особые группы ОФО ----------

def test_ib26_has_no_subgroups(groups: dict[str, Group]) -> None:
    assert len(groups["ofo-ib-26"].subgroups) == 1


def test_itiss23_subgroups_collapsed(groups: dict[str, Group]) -> None:
    # В строке подгрупп нет подписей, оба столбца всегда одинаковые → одна подгруппа
    assert len(groups["ofo-itiss-23"].subgroups) == 1


# ---------- ОЗФО ----------

def test_ozfo_only_friday_and_saturday(sheets: dict[str, list[Group]]) -> None:
    weekdays = {l.weekday for g in sheets["ОЗФО"] for l in g.lessons}
    assert weekdays == {FRI, SAT}


def test_ozfo_bi26_collapsed_to_one_subgroup(groups: dict[str, Group]) -> None:
    # Группа занимает 2 столбца без подписей, но в них всегда одно и то же → подгруппа одна
    assert len(groups["ozfo-oz-bi-26"].subgroups) == 1


def test_ozfo_two_unlabeled_subgroups(groups: dict[str, Group]) -> None:
    # А здесь столбцы G и H различаются → 2 подгруппы «Подгруппа 1/2»
    g = groups["ozfo-oz-1-itiss-26"]
    assert [s.label for s in g.subgroups] == ["Подгруппа 1", "Подгруппа 2"]


def test_ozfo_ib25_single_subgroup(groups: dict[str, Group]) -> None:
    assert len(groups["ozfo-oz-ib-25"].subgroups) == 1


def test_ozfo_bi25_friday_pair_3_philosophy_lecture(groups: dict[str, Group]) -> None:
    g = groups["ozfo-oz-bi-25"]
    for week in (1, 2):
        [lesson] = [l for l in find(g, FRI, 3) if l.week in (0, week)]
        assert lesson.subject == "Философия"
        assert lesson.teacher == "Кутаев А.Х."
        assert lesson.room == "3-01"
        assert lesson.kind == "lecture"  # ячейка O12:Q12 покрывает и ОЗ-ИБ-25


# ---------- Магистратура ----------

def test_magistracy_groups(sheets: dict[str, list[Group]]) -> None:
    mag = sheets["Магистратура ОФО"]
    assert [g.title for g in mag] == ["М-БИ-26", "М-ИВТ-26", "М-БИ-25", "М-ИВТ-25"]
    assert all(len(g.subgroups) == 1 for g in mag)


def test_magistracy_saturday_week_1_only(groups: dict[str, Group]) -> None:
    [lesson] = find(groups["mag-m-ivt-25"], SAT, 1)
    assert lesson.subject.startswith("Проектирование интеллектуальных систем")
    assert lesson.week == 1


# ---------- общее качество ----------

def test_every_group_has_lessons(groups: dict[str, Group]) -> None:
    assert all(g.lessons for g in groups.values())


def test_values_in_allowed_ranges(groups: dict[str, Group]) -> None:
    for g in groups.values():
        for l in g.lessons:
            assert 1 <= l.weekday <= 6
            assert 1 <= l.pair <= 5
            assert l.week in (0, 1, 2)
            assert l.kind in ("lecture", "practice", "pe", "curator")
            assert set(l.tags) <= {"male", "female"}
            assert l.subgroups and set(l.subgroups) <= {s.n for s in g.subgroups}


def test_subject_fixes_applied(groups: dict[str, Group]) -> None:
    subjects = {l.subject for g in groups.values() for l in g.lessons}
    assert not any("Аккаутинг" in s or "IТ-" in s for s in subjects)
