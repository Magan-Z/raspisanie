// Личные правки: хранение и описание (АРХИТЕКТУРА.md, §7.3–7.4).

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raspisanie/data/local/database.dart';
import 'package:raspisanie/data/repositories/overrides_repository.dart';
import 'package:raspisanie/domain/models.dart';
import 'package:raspisanie/domain/overrides_text.dart';

void main() {
  late AppDatabase db;
  late OverridesRepository repo;
  final day = DateTime.utc(2026, 10, 7);

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = OverridesRepository(db);
  });
  tearDown(() => db.close());

  test('сохранить и прочитать: дата не «съезжает» из-за часового пояса', () async {
    await repo.save(Override(date: day, pair: 4, type: OverrideType.replace, room: '3-01', note: 'перенесли'));
    final all = await repo.all();
    expect(all, hasLength(1));
    expect(all.single.date, day);
    expect(all.single.room, '3-01');
    expect(all.single.subject, isNull);
    expect(all.single.id, isNotNull);
  });

  test('новая правка той же пары заменяет старую', () async {
    await repo.save(Override(date: day, pair: 4, type: OverrideType.replace, room: '3-01'));
    await repo.save(Override(date: day, pair: 4, type: OverrideType.replace, room: '3-02'));
    expect((await repo.all()).single.room, '3-02');
  });

  test('отмена и замена исключают друг друга', () async {
    await repo.save(Override(date: day, pair: 4, type: OverrideType.replace, room: '3-01'));
    await repo.save(Override(date: day, pair: 4, type: OverrideType.cancel));
    final all = await repo.all();
    expect(all.map((o) => o.type), [OverrideType.cancel]);
  });

  test('своя пара не мешает правкам обычной пары', () async {
    await repo.save(Override(date: day, pair: 4, type: OverrideType.cancel));
    await repo.save(Override(date: day, pair: 4, type: OverrideType.add, subject: 'Консультация'));
    expect(await repo.all(), hasLength(2));
  });

  test('удалить одну правку и очистить пару', () async {
    await repo.save(Override(date: day, pair: 3, type: OverrideType.cancel));
    await repo.save(Override(date: day, pair: 4, type: OverrideType.cancel));
    await repo.save(Override(date: day, pair: 4, type: OverrideType.add, subject: 'Своя'));

    await repo.clearPair(day, 4);
    var all = await repo.all();
    expect(all.map((o) => o.pair), [3]);

    await repo.delete(all.single.id!);
    expect(await repo.all(), isEmpty);
  });

  test('описания правок', () {
    expect(describeOverride(Override(date: day, pair: 3, type: OverrideType.cancel)), 'Отменена: 3 пара');
    expect(describeOverride(Override(date: day, pair: 4, type: OverrideType.replace, room: '3-01', note: 'перенесли')),
        'Изменена: 4 пара — аудитория: 3-01, заметка: перенесли');
    expect(describeOverride(Override(date: day, pair: 1, type: OverrideType.add, subject: 'Консультация', room: '2-10')),
        'Своя пара: 1 пара — Консультация, 2-10');
  });

  test('пустое поле → «не менять»', () {
    expect(blankToNull('   '), isNull);
    expect(blankToNull(' 3-01 '), '3-01');
  });
}
