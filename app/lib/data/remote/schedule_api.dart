// Загрузка расписания с сайта (GitHub Pages) с поддержкой ETag:
// если файл не изменился, сервер отвечает «304 Not Modified» и ничего не присылает.

import 'dart:convert';

import 'package:http/http.dart' as http;

class FetchResult {
  const FetchResult({required this.notModified, this.body, this.etag});
  final bool notModified;
  final String? body;
  final String? etag;
}

class ScheduleApi {
  ScheduleApi(this.baseUrl, {http.Client? client}) : _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  static const _timeout = Duration(seconds: 15);

  /// Скачивает файл по пути относительно сайта: «index.json», «groups/ofo-1-bi-25.json».
  Future<FetchResult> fetch(String path, {String? etag}) async {
    final base = baseUrl.endsWith('/') ? baseUrl : '$baseUrl/';
    final uri = Uri.parse(base).resolve(path);
    final response = await _client.get(uri, headers: {
      if (etag != null) 'If-None-Match': etag,
      'Cache-Control': 'no-cache',
    }).timeout(_timeout);

    if (response.statusCode == 304) return const FetchResult(notModified: true);
    if (response.statusCode != 200) {
      throw ScheduleApiException('Сервер ответил ${response.statusCode} на $uri');
    }
    return FetchResult(notModified: false, body: utf8.decode(response.bodyBytes), etag: response.headers['etag']);
  }
}

class ScheduleApiException implements Exception {
  ScheduleApiException(this.message);
  final String message;

  @override
  String toString() => message;
}
