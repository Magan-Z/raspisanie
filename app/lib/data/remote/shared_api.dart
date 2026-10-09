// Связь с общим сервером старост (Supabase): читать данные группы может любой студент, писать — только староста по токену.
// Все обращения — вызовы функций сервера (POST /rest/v1/rpc/имя); напрямую к таблицам доступа нет.

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../domain/group_shared.dart';

/// Ошибка обращения к серверу. [code] — машинное имя (bad_code, code_used, bad_token, too_many, network, server).
class SharedApiException implements Exception {
  const SharedApiException(this.code, [this.details]);
  final String code;
  final String? details;

  /// Понятное сообщение для человека.
  String get message => switch (code) {
        'bad_code' => 'Код не подошёл. Проверьте, что он введён без ошибок',
        'code_used' => 'Этот код уже использован. Попросите выдать новый',
        'bad_token' => 'Доступ старосты отозван. Введите код заново',
        'too_many' => 'Слишком много записей у группы. Удалите ненужные',
        'network' => 'Нет связи с сервером. Проверьте интернет и повторите',
        _ => 'Ошибка сервера${details == null ? '' : ': $details'}',
      };

  @override
  String toString() => 'SharedApiException($code${details == null ? '' : ', $details'})';
}

class SharedApi {
  SharedApi(this.baseUrl, this.key, {http.Client? client}) : _client = client ?? http.Client();

  final String baseUrl;
  final String key; // публичный ключ проекта (не секретный)
  final http.Client _client;

  static const _timeout = Duration(seconds: 15);

  Future<dynamic> _rpc(String function, Map<String, dynamic> args) async {
    final base = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    final http.Response response;
    try {
      response = await _client
          .post(
            Uri.parse('$base/rest/v1/rpc/$function'),
            headers: {'apikey': key, 'Content-Type': 'application/json'},
            body: jsonEncode(args),
          )
          .timeout(_timeout);
    } on TimeoutException {
      throw const SharedApiException('network');
    } on http.ClientException {
      throw const SharedApiException('network');
    } on Exception {
      // например SocketException на телефоне: нет сети
      throw const SharedApiException('network');
    }

    final text = utf8.decode(response.bodyBytes);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return text.isEmpty ? null : jsonDecode(text);
    }
    String? message;
    try {
      message = (jsonDecode(text) as Map<String, dynamic>)['message'] as String?;
    } catch (_) {}
    const known = {'bad_code', 'code_used', 'bad_token', 'too_many', 'bad_group'};
    if (message != null && known.contains(message)) throw SharedApiException(message);
    throw SharedApiException('server', message ?? 'HTTP ${response.statusCode}');
  }

  /// Данные группы: с [since] — только изменения после этого момента, без — всё.
  Future<Map<String, dynamic>> getGroupData(String group, {String? since}) async =>
      _asMap(await _rpc('get_group_data', {'p_group': group, if (since != null) 'p_since': since}));

  /// Ответ должен быть объектом; иначе сервер ответил не так, как ждёт приложение.
  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    throw const SharedApiException('server', 'неожиданный ответ');
  }

  /// Ввод кода старосты. Возвращает группу и секретный токен для этого телефона.
  Future<EditorSession> redeem(String code) async {
    final r = _asMap(await _rpc('redeem_code', {'p_code': code}));
    return EditorSession(token: r['token'] as String, groupId: r['group_id'] as String);
  }

  /// Проверяет, что токен действует. Возвращает группу.
  Future<String> checkEditor(String token) async {
    final r = await _rpc('check_editor', {'p_token': token});
    if (r is String) return r;
    throw const SharedApiException('server', 'неожиданный ответ');
  }

  Future<void> putOverride(String token, GroupOverrideRow row) => _rpc('put_group_override', {'p_token': token, 'p_row': row.toJson()});

  Future<void> deleteOverride(String token, String id) => _rpc('delete_group_override', {'p_token': token, 'p_id': id});

  /// Стирает правки, сделанные к старому расписанию. Возвращает, сколько стёрто.
  Future<int> clearStale(String token, String keepHash) async =>
      ((await _rpc('clear_stale_group_overrides', {'p_token': token, 'p_keep_hash': keepHash})) as num?)?.toInt() ?? 0;

  Future<void> putHomework(String token, GroupHomeworkRow row) => _rpc('put_group_homework', {'p_token': token, 'p_row': row.toJson()});

  Future<void> deleteHomework(String token, String id) => _rpc('delete_group_homework', {'p_token': token, 'p_id': id});
}
