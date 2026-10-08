"""Простые классы данных, из которых состоит разобранное расписание."""

from dataclasses import dataclass, field


@dataclass
class Subgroup:
    n: int       # номер подгруппы: 1, 2, ... слева направо
    label: str   # подпись из таблицы («БИ-25-1») или «Подгруппа N»

    def to_dict(self) -> dict:
        return {"n": self.n, "label": self.label}


@dataclass
class Lesson:
    weekday: int          # 1 = понедельник … 6 = суббота
    pair: int             # номер пары 1–5
    week: int             # 0 = каждая неделя, 1 или 2 = только эта неделя
    subgroups: list[int]  # номера подгрупп, у которых это занятие
    kind: str             # lecture | practice | pe | curator
    subject: str
    teacher: str | None
    room: str | None
    tags: list[str]       # male / female (только для физ-ры)
    raw: str              # исходный текст ячейки
    cells: list[str] = field(default_factory=list)  # адреса ячеек (только для отчёта, в JSON не идут)

    def to_dict(self) -> dict:
        return {
            "weekday": self.weekday,
            "pair": self.pair,
            "week": self.week,
            "subgroups": self.subgroups,
            "kind": self.kind,
            "subject": self.subject,
            "teacher": self.teacher,
            "room": self.room,
            "tags": self.tags,
            "raw": self.raw,
        }


@dataclass
class Group:
    id: str                # «ofo-1-bi-25»
    title: str             # «1 БИ-25»
    form: str              # код формы обучения: ofo / ozfo / mag
    sheet: str             # имя листа в Excel
    course: int
    subgroups: list[Subgroup]
    lessons: list[Lesson] = field(default_factory=list)

    @property
    def has_gendered_pe(self) -> bool:
        """Есть ли у группы физ-ра, разделённая на юношей и девушек."""
        return any(lesson.tags for lesson in self.lessons)

    def info_dict(self) -> dict:
        """Описание группы без занятий (для файла группы)."""
        return {
            "id": self.id,
            "title": self.title,
            "form": self.form,
            "course": self.course,
            "subgroups": [s.to_dict() for s in self.subgroups],
        }
