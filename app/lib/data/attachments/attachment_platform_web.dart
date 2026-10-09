// Вложения в браузере (iPhone и др.): файлов на диске нет, поэтому содержимое хранится в базе приложения (IndexedDB).

import 'dart:js_interop';
import 'dart:typed_data';

import 'package:drift/drift.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/widgets.dart';
import 'package:image_picker/image_picker.dart';
import 'package:web/web.dart' as web;

import '../../domain/attachment.dart';
import '../local/database.dart';
import 'attachment_types.dart';

AttachmentStore createAttachmentStore(AppDatabase db) => DatabaseAttachmentStore(db);

AttachmentPicker createAttachmentPicker() => WebAttachmentPicker();

class WebAttachmentPicker implements AttachmentPicker {
  final _images = ImagePicker();

  @override
  Future<List<PickedFileInfo>> pickFiles() async {
    final files = await FilePicker.pickFiles();
    return [for (final f in files) PickedFileInfo(name: f.name, sizeBytes: f.lengthSync(), readBytes: f.readAsBytes)];
  }

  @override
  Future<PickedFileInfo?> takePhoto() async {
    final shot = await _images.pickImage(source: ImageSource.camera, maxWidth: 2000, imageQuality: 85);
    return shot == null ? null : await _fromXFile(shot);
  }

  @override
  Future<List<PickedFileInfo>> pickImages() async {
    final shots = await _images.pickMultiImage(maxWidth: 2000, imageQuality: 85);
    return [for (final s in shots) await _fromXFile(s)];
  }

  Future<PickedFileInfo> _fromXFile(XFile f) async => PickedFileInfo(name: f.name, sizeBytes: await f.length(), readBytes: f.readAsBytes);
}

/// Файл хранится в таблице attachment_blobs; в `Attachment.path` записан номер: «blob:12».
class DatabaseAttachmentStore implements AttachmentStore {
  DatabaseAttachmentStore(this.db);
  final AppDatabase db;
  final _cache = <int, Uint8List>{};

  static int? _id(Attachment a) => a.path.startsWith('blob:') ? int.tryParse(a.path.substring(5)) : null;

  @override
  Future<Attachment> save(PickedFileInfo picked) async {
    final bytes = await picked.readBytes!();
    final id = await db.into(db.attachmentBlobs).insert(AttachmentBlobsCompanion.insert(bytes: bytes));
    _cache[id] = bytes;
    return Attachment(name: picked.name, path: 'blob:$id', sizeBytes: picked.sizeBytes ?? bytes.length);
  }

  @override
  Future<void> delete(Attachment attachment) async {
    final id = _id(attachment);
    if (id == null) return;
    _cache.remove(id);
    await (db.delete(db.attachmentBlobs)..where((t) => t.id.equals(id))).go();
  }

  // В браузере наличие файла синхронно не проверить; если его нет, картинка покажет «значок ошибки», а открытие — сообщение.
  @override
  bool exists(Attachment attachment) => _id(attachment) != null;

  @override
  Future<Uint8List?> readBytes(Attachment attachment) => _bytes(attachment);

  Future<Uint8List?> _bytes(Attachment attachment) async {
    final id = _id(attachment);
    if (id == null) return null;
    final cached = _cache[id];
    if (cached != null) return cached;
    final row = await (db.select(db.attachmentBlobs)..where((t) => t.id.equals(id))).getSingleOrNull();
    if (row != null) _cache[id] = row.bytes;
    return row?.bytes;
  }

  static const _mime = {
    'pdf': 'application/pdf',
    'png': 'image/png',
    'jpg': 'image/jpeg',
    'jpeg': 'image/jpeg',
    'gif': 'image/gif',
    'webp': 'image/webp',
    'txt': 'text/plain',
    'doc': 'application/msword',
    'docx': 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'xls': 'application/vnd.ms-excel',
    'xlsx': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    'ppt': 'application/vnd.ms-powerpoint',
    'pptx': 'application/vnd.openxmlformats-officedocument.presentationml.presentation',
    'zip': 'application/zip',
  };

  /// В браузере файл «скачивается» (на iPhone откроется просмотр или предложение сохранить).
  @override
  Future<String?> open(Attachment attachment) async {
    final bytes = await _bytes(attachment);
    if (bytes == null) return 'Файл не найден: возможно, данные браузера были очищены';
    final blob = web.Blob([bytes.toJS].toJS, web.BlobPropertyBag(type: _mime[attachment.extension] ?? 'application/octet-stream'));
    final url = web.URL.createObjectURL(blob);
    final link = web.document.createElement('a') as web.HTMLAnchorElement
      ..href = url
      ..download = attachment.name
      ..target = '_blank';
    web.document.body?.append(link);
    link.click();
    link.remove();
    Future<void>.delayed(const Duration(seconds: 30), () => web.URL.revokeObjectURL(url));
    return null;
  }

  @override
  Widget image(Attachment attachment, {double? width, double? height, BoxFit? fit, int? cacheWidth}) {
    return FutureBuilder<Uint8List?>(
      future: _bytes(attachment),
      builder: (context, snapshot) {
        final bytes = snapshot.data;
        if (bytes == null) return SizedBox(width: width, height: height);
        return Image.memory(bytes, width: width, height: height, fit: fit, cacheWidth: cacheWidth, semanticLabel: attachment.name);
      },
    );
  }
}
