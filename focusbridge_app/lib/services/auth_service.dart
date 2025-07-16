// lib/services/auth_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  // TODO: 把下面的 baseUrl 改成你後端實際對外可訪問的 URL
  // 比如：'http://127.0.0.1:8000' 或 'http://192.168.0.100:8000'
  static const String baseUrl = 'http://10.0.2.2:8000';

  
  /// 註冊：呼叫後端 POST /api/auth/register/
  /// 成功時回傳 Map，裡面包含 'username'、'email'、'token' 等欄位
  static Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
    required String password2,
  }) async {
    final url = Uri.parse('$baseUrl/api/auth/register/');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'email': email,
        'password': password,
        'password2': password2,
      }),
    );

    if (response.statusCode == 201) {
      // 成功註冊，解析 JSON 並回傳
      return jsonDecode(response.body);
    } else {
      // 失敗時，直接將後端回傳的錯誤訊息拋出
      throw Exception(jsonDecode(response.body));
    }
  }

  /// 登入：呼叫後端 POST /api/auth/login/
  /// 成功時回傳 token 字串，並把它存到 SharedPreferences
  static Future<String> login({
    required String username,
    required String password,
  }) async {
    final url = Uri.parse('$baseUrl/api/auth/login/');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final token = data['token'];
      // 存到 SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', token);
      return token;
    } else {
      throw Exception(jsonDecode(response.body));
    }
  }

  /// 登出：呼叫後端 POST /api/auth/logout/
  /// 會將當前 token 從後端刪除，並從本機 SharedPreferences 移除
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token != null) {
      final url = Uri.parse('$baseUrl/api/auth/logout/');
      // 帶上 Authorization: Token <token>
      await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
      );
      // 無論後端回傳如何，都移除本地 token
      await prefs.remove('token');
    }
  }

  /// 嘗試從本機讀取已儲存的 token（如果有）
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }
}
