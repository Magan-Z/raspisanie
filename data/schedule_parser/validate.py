"""Проверки перед публикацией. Если хоть одна не прошла — сайт не обновляется."""

from .models import Group

MIN_TEACHER_SHARE = 0.95       # доля занятий, где нашёлся преподаватель
MIN_GROUPS_SHARE = 0.90        # групп не меньше 90 % от прошлой версии
MAX_LESSONS_CHANGE = 0.40      # число занятий изменилось не больше чем на 40 %


def validate(sheets: dict[str, list[Group]], previous: dict | None) -> list[str]:
    """Возвращает список ошибок (пустой список — всё хорошо)."""
    errors = []
    all_groups = [g for groups in sheets.values() for g in groups]
    all_lessons = [l for g in all_groups for l in g.lessons]

    for sheet_name, groups in sheets.items():
        if not groups:
            errors.append(f"На листе «{sheet_name}» не найдено ни одной группы")

    for group in all_groups:
        if not group.lessons:
            errors.append(f"У группы {group.title} ({group.sheet}) нет ни одного занятия")

    ids = [g.id for g in all_groups]
    duplicates = sorted({i for i in ids if ids.count(i) > 1})
    if duplicates:
        errors.append(f"Одинаковые id у разных групп: {', '.join(duplicates)}")

    if all_lessons:
        share = sum(1 for l in all_lessons if l.teacher) / len(all_lessons)
        if share < MIN_TEACHER_SHARE:
            errors.append(f"Преподаватель распознан только в {share:.0%} занятий (нужно ≥ 95 %)")

    if previous is not None:
        old_groups = previous["groups"]
        if len(all_groups) < MIN_GROUPS_SHARE * len(old_groups):
            errors.append(f"Групп стало {len(all_groups)}, а было {len(old_groups)} — подозрительно мало")

        old_lessons = sum(len(g["lessons"]) for g in old_groups.values())
        if old_lessons and abs(len(all_lessons) - old_lessons) / old_lessons > MAX_LESSONS_CHANGE:
            errors.append(
                f"Число занятий изменилось слишком сильно: было {old_lessons}, стало {len(all_lessons)}"
            )
    return errors
