// lib/services/photo_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class PhotoService {
  static const String baseUrl = 'https://focusbridge-backend1.onrender.com';

  /// 使用者登入，取得 token 並儲存
  static Future<void> login({
    required String username,
    required String password,
  }) async {
    final uri = Uri.parse('$baseUrl/api/auth/token/');
    final rsp = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );
    if (rsp.statusCode == 200) {
      final token = jsonDecode(rsp.body)['token'] as String;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', token);
    } else {
      throw Exception('登入失敗：${rsp.body}');
    }
  }

  /// 上傳照片到後端 /api/photos/，需先登入取得 token
  static Future<void> uploadPhoto({
    required File imageFile,
    required String emotion,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) {
      throw Exception('尚未登入，請先呼叫 PhotoService.login');
    }

    final uri = Uri.parse('$baseUrl/api/photos/');
    final req = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Token $token'
      ..fields['emotion'] = emotion
      ..files.add(
        await http.MultipartFile.fromPath('image', imageFile.path),
      );

    final rsp = await req.send();
    final body = await rsp.stream.bytesToString();
    if (rsp.statusCode != 201) {
      throw Exception('新增相片失敗 (狀態碼 ${rsp.statusCode})：$body');
    }
  }

  /// 取得所有照片列表，需先登入
  static Future<List<Map<String, dynamic>>> fetchPhotos() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) {
      throw Exception('尚未登入，請先呼叫 PhotoService.login');
    }

    final uri = Uri.parse('$baseUrl/api/photos/');
    final rsp = await http.get(
      uri,
      headers: {'Authorization': 'Token $token'},
    );

    if (rsp.statusCode == 200) {
      // 使用 utf8 解碼，以正確處理中文
      final bodyString = utf8.decode(rsp.bodyBytes);
      return List<Map<String, dynamic>>.from(jsonDecode(bodyString));
    } else {
      throw Exception('取得相片失敗 (狀態碼 ${rsp.statusCode})：${rsp.body}');
    }
  }

  /// 刪除指定 id 的照片，需先登入
  static Future<void> deletePhoto(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) {
      throw Exception('尚未登入，請先呼叫 PhotoService.login');
    }

    final uri = Uri.parse('$baseUrl/api/photos/$id/');
    final rsp = await http.delete(
      uri,
      headers: {'Authorization': 'Token $token'},
    );
    if (rsp.statusCode != 204) {
      throw Exception('刪除失敗 (狀態碼 ${rsp.statusCode})：${rsp.body}');
    }
  }
}
