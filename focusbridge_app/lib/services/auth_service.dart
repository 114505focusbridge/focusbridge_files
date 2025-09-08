import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

// 定義一個 User 類別來存放從 Token 解析出的使用者資訊
class User {
  final int? id;
  final String? username;
  final String? email;

  User({this.id, this.username, this.email});
}

class AuthService {
  static const String baseUrl = 'http://140.131.115.111:8000';

  /// 註冊：POST /api/auth/register/
  static Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
    required String password2,
  }) async {
    final url = Uri.parse('$baseUrl/api/auth/register/');
    final body = {
      'username': username,
      'email': email,
      'password': password,
      'password2': password2,
    };

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      debugPrint('AuthService.register status: ${response.statusCode}');
      debugPrint('AuthService.register body: ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>;
        final errorMessage = errorData['error'] ?? 
                             errorData['detail'] ?? 
                             errorData['email']?.first ?? 
                             errorData['username']?.first ?? 
                             errorData['non_field_errors']?.first ?? 
                             '註冊失敗，請稍後再試。';
                             
        throw Exception(errorMessage);
      }
    } catch (e) {
      debugPrint('AuthService.register 捕捉到例外: $e');
      rethrow;
    }
  }

  /// 登入：POST /api/auth/login/
  static Future<String> login({
    required String username,
    required String password,
  }) async {
    final url = Uri.parse('$baseUrl/api/auth/login/');
    final body = {
      'username': username,
      'password': password,
    };
    
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['token'] as String;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);

        // ✅ 新增：印出從後端取得的完整 token
        debugPrint('✅ 登入成功！從後端取得的 Token: $token');

        return token;
      } else {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>;
        final errorMessage = errorData['detail'] ?? 
                             errorData['non_field_errors']?.first ?? 
                             '登入失敗，請檢查帳號或密碼。';
        throw Exception(errorMessage);
      }
    } catch (e) {
      debugPrint('AuthService.login 捕捉到例外: $e');
      throw Exception('登入時發生錯誤：${e.toString()}');
    }
  }

  /// 登出：POST /api/auth/logout/
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token != null) {
      final url = Uri.parse('$baseUrl/api/auth/logout/');
      try {
        await http.post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Token $token',
          },
        );
      } catch (e) {
        debugPrint('登出 API 呼叫失敗，但仍將移除本地 token: $e');
      }
      await prefs.remove('token');
    }
  }

  /// 取得本地儲存的 token
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  /// 從 token 中取得使用者 ID
  static Future<String?> getCurrentUserId() async {
    final token = await getToken();
    
    // ✅ 新增：確認本地是否有 token
    debugPrint('✅ 嘗試從本地取得 Token: $token');

    if (token == null) {
      return null;
    }
    
    try {
      final Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
      
      // ✅ 新增：印出解析後的 token 內容
      debugPrint('✅ 成功解析 Token！內容為: $decodedToken');

      if (decodedToken.containsKey('user_id')) {
        return decodedToken['user_id'].toString();
      } else if (decodedToken.containsKey('id')) {
        return decodedToken['id'].toString();
      }
      return null;
    } catch (e) {
      debugPrint('❌ 解析 JWT Token 失敗: $e');
      return null;
    }
  }

  /// 從 token 中取得完整使用者物件
  static Future<User?> getCurrentUser() async {
    final token = await getToken();
    if (token == null) {
      return null;
    }
    
    try {
      final Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
      
      int? id;
      String? username;
      String? email;

      if (decodedToken.containsKey('user_id')) {
        id = decodedToken['user_id'];
      } else if (decodedToken.containsKey('id')) {
        id = decodedToken['id'];
      }
      
      if (decodedToken.containsKey('username')) {
        username = decodedToken['username'];
      }
      
      if (decodedToken.containsKey('email')) {
        email = decodedToken['email'];
      }

      if (id != null) {
        return User(id: id, username: username, email: email);
      }
      
      return null;
    } catch (e) {
      debugPrint('❌ 解析 JWT Token 失敗: $e');
      return null;
    }
  }
}