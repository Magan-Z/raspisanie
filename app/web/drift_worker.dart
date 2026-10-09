// «Рабочий» для базы данных в браузере (drift + SQLite через WebAssembly).
// Собирается в drift_worker.js скриптом scripts/build_web.sh.
import 'package:drift/wasm.dart';

void main() => WasmDatabase.workerMainForOpen();
