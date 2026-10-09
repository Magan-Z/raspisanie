// Обновление базы с версии 1 на 2: старые личные правки не должны потеряться.


import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raspisanie/data/local/database.dart';
import 'package:raspisanie/data/repositories/overrides_repository.dart';
import 'package:raspisanie/domain/models.dart';

void main() {
  test('база версии 1 с правкой открывается, правка сохраняется, новые поля имеют значения по умолчанию', () async {
    // Делаем базу «как была в версии 1»: старая таблица overrides без новых столбцов и user_version = 1
    final executor = NativeDatabase.memory(setup: (raw) {
      raw.execute('''
        CREATE TABLE overrides (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          date INTEGER NOT NULL,
          pair INTEGER NOT NULL,
          type TEXT NOT NULL,
          subject TEXT NULL,
          room TEXT NULL,
          teacher TEXT NULL,
          note TEXT NULL
        );
      ''');
      raw.execute("INSERT INTO overrides (date, pair, type, room) VALUES (${DateTime.utc(2026, 10, 7).millisecondsSinceEpoch ~/ 1000}, 4, 'replace', '3-01');");
      raw.execute('PRAGMA user_version = 1;');
    });

    final db = AppDatabase(executor);
    addTearDown(db.close);

    final all = await OverridesRepository(db).all();
    expect(all, hasLength(1));
    expect(all.single.room, '3-01');
    expect(all.single.type, OverrideType.replace);
    expect(all.single.date, DateTime.utc(2026, 10, 7));
    expect(all.single.repeatWeekly, isFalse); // новое поле — значение по умолчанию
    expect(all.single.matchSubject, isNull);
    expect(all.single.kind, isNull);

    // И в обновлённую базу можно писать новые виды правок
    await OverridesRepository(db).save(Override(date: DateTime.utc(2026, 10, 14), pair: 3, type: OverrideType.cancel, repeatWeekly: true));
    expect(await OverridesRepository(db).all(), hasLength(2));
  });
}
