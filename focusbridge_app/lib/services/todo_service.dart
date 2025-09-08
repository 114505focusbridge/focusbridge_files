// lib/services/todo_service.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:focusbridge_app/models/todo.dart';

class TodoService {
  final String baseUrl;
  final Future<String?> Function() tokenProvider;

  const TodoService({
    this.baseUrl = _defaultBaseUrl,
    required this.tokenProvider,
  });

  // ✅ USB + adb reverse 版本
  //   先在電腦執行：adb reverse tcp:8000 tcp:8000
  //   然後手機就能用 127.0.0.1 連到電腦
  static const String _defaultBaseUrl = 'http://140.131.115.111:8000/api';
  // 🔁 如果改走區網，換成：
  // static const String _defaultBaseUrl = 'http://<你的電腦IP>:8000/api';

  // ====== Public APIs ======

  Future<List<Todo>> fetchTodosByDate(DateTime date) async {
    final token = await _requireToken();
    final uri = Uri.parse('$baseUrl/todos/?date=${dateToApi(date)}');
    debugPrint('[GET] $uri'); // 臨時除錯

    final resp = await http.get(uri, headers: _headers(token));
    _throwIfFailed(resp, '取得待辦失敗');

    final List data = jsonDecode(resp.body) as List;
    return data.map((e) => Todo.fromJson(e as Map<String, dynamic>)).toList()
      ..sort(Todo.compare);
  }

  Future<List<Todo>> fetchTodayTodos() => fetchTodosByDate(DateTime.now());

  Future<Todo> createTodo({
    required String title,
    DateTime? date, // 建議在呼叫端傳 DateTime.now()，避免時區不一致
    TimeOfDay? time,
  }) async {
    final token = await _requireToken();
    final uri = Uri.parse('$baseUrl/todos/');

    final body = <String, dynamic>{'title': title.trim()};
    if (date != null) body['date'] = dateToApi(date);
    final t = timeOfDayToApi(time);
    if (t != null) body['time'] = t;

    debugPrint('[POST] $uri $body'); // 臨時除錯
    final resp = await http.post(uri, headers: _headers(token), body: jsonEncode(body));
    _throwIfFailed(resp, '新增待辦失敗');

    return Todo.fromJson(jsonDecode(resp.body) as Map<String, dynamic>);
  }

  Future<Todo> toggleDone({required int id, required bool isDone}) async {
    final token = await _requireToken();
    final uri = Uri.parse('$baseUrl/todos/$id/');
    final resp = await http.patch(
      uri,
      headers: _headers(token),
      body: jsonEncode(Todo.patchIsDone(isDone)),
    );
    _throwIfFailed(resp, '更新完成狀態失敗');
    return Todo.fromJson(jsonDecode(resp.body) as Map<String, dynamic>);
  }

  Future<void> deleteTodo(int id) async {
    final token = await _requireToken();
    final uri = Uri.parse('$baseUrl/todos/$id/');
    final resp = await http.delete(uri, headers: _headers(token));
    _throwIfFailed(resp, '刪除待辦失敗', allowNoContent: true);
  }

  // ====== Helpers ======

  Future<String> _requireToken() async {
    final token = await tokenProvider();
    if (token == null || token.isEmpty) {
      throw const ApiException('尚未登入或 Token 無效');
    }
    return token;
  }

  Map<String, String> _headers(String token) => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Token $token',
      };

  void _throwIfFailed(http.Response resp, String defaultMsg, {bool allowNoContent = false}) {
    final ok = resp.statusCode >= 200 && resp.statusCode < 300;
    if (ok) {
      if (allowNoContent && resp.statusCode == 204) return;
      return;
    }
    try {
      final body = jsonDecode(resp.body);
      throw ApiException(body is Map && body['error'] != null
          ? body['error'].toString()
          : '$defaultMsg（${resp.statusCode}）');
    } catch (_) {
      throw ApiException('$defaultMsg（${resp.statusCode}）');
    }
  }
}

class ApiException implements Exception {
  final String message;
  const ApiException(this.message);
  @override
  String toString() => 'ApiException: $message';
}
