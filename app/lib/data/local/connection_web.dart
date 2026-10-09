// Открытие базы данных в браузере (iPhone и др.): SQLite через WebAssembly, данные — в IndexedDB браузера.
// Нужны два файла рядом со страницей: sqlite3.wasm и drift_worker.js (их готовит scripts/build_web.sh).

import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';

const _databaseName = 'raspisanie';

QueryExecutor openAppConnection() => DatabaseConnection.delayed(_open());

Future<DatabaseConnection> _open() async {
  // Адреса делаем полными: рабочий процесс браузера сам не знает, где лежит страница
  final probed = await WasmDatabase.probe(
    sqlite3Uri: Uri.base.resolve('sqlite3.wasm'),
    driftWorkerUri: Uri.base.resolve('drift_worker.js'),
    databaseName: _databaseName,
  );

  // Предпочтительный способ хранения. «Общий воркер + IndexedDB» (который drift берёт по умолчанию) на разных
  // браузерах капризничает, а обычный воркер + IndexedDB работает везде, включая iPhone. Страница приложения
  // обычно открыта в одном окне, поэтому его ограничение (нельзя одновременно из двух вкладок) нам не мешает.
  const preferred = [
    WasmStorageImplementation.opfsShared,
    WasmStorageImplementation.opfsLocks,
    WasmStorageImplementation.unsafeIndexedDb,
    WasmStorageImplementation.sharedIndexedDb,
  ];
  var chosen = preferred.firstWhere(probed.availableStorages.contains, orElse: () => WasmStorageImplementation.inMemory);

  // Если данные уже лежат в IndexedDB, продолжаем с ними (чтобы после обновления браузера ничего не «пропало»)
  final hasIndexedDbCopy = probed.existingDatabases.any((e) => e.$1 == WebStorageApi.indexedDb && e.$2 == _databaseName);
  if (hasIndexedDbCopy && chosen.storageApi != WebStorageApi.indexedDb) {
    chosen = [WasmStorageImplementation.unsafeIndexedDb, WasmStorageImplementation.sharedIndexedDb]
        .firstWhere(probed.availableStorages.contains, orElse: () => chosen);
  }

  return probed.open(chosen, _databaseName);
}
