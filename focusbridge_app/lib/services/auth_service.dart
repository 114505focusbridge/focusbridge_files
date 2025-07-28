import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  // ✅ 注意：這裡 baseUrl 不要加 /api，路徑由下面補上
  static const String baseUrl = 'https://focusbridge-backend1.onrender.com';

  /// ✅ 註冊：POST /api/auth/register/
  /// 成功回傳 Map：包含 username、email、token
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
      return jsonDecode(response.body);
    } else {
      print('❌ 註冊失敗：${response.statusCode}');
      print('❌ 回傳內容：${response.body}');
      throw Exception(jsonDecode(response.body));
    }
  }

  /// ✅ 登入：POST /api/auth/login/
  /// 成功時回傳 token 字串，並存入 SharedPreferences
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
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', token);
      return token;
    } else {
      print('❌ 登入失敗：${response.statusCode}');
      print('❌ 回傳內容：${response.body}');
      throw Exception(jsonDecode(response.body));
    }
  }

  /// ✅ 登出：POST /api/auth/logout/ 並移除本地 token
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token != null) {
      final url = Uri.parse('$baseUrl/api/auth/logout/');
      await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
      );
      await prefs.remove('token');
    }
  }

  /// ✅ 嘗試取得本地儲存的 token
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }
}
