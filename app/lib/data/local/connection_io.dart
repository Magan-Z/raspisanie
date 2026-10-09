// Открытие базы данных на телефоне: обычный файл SQLite.

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

QueryExecutor openAppConnection() => driftDatabase(name: 'raspisanie');
