// lib/providers/auth_provider.dart

import 'package:flutter/material.dart';
import 'package:focusbridge_app/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider with ChangeNotifier {
  String? _token;

  String? get token => _token;

  bool get isAuthenticated => _token != null;

  /// 檢查本地儲存的 token，以判斷使用者是否已登入
  Future<void> checkAuthStatus() async {
    _token = await AuthService.getToken();
    notifyListeners();
  }

  /// 註冊新帳號
  /// 呼叫 AuthService 進行 API 請求，並在成功後更新狀態
  Future<void> register(
    String username,
    String email,
    String password,
    String password2,
  ) async {
    try {
      final response = await AuthService.register(
        username: username,
        email: email,
        password: password,
        password2: password2,
      );
      
      // 註冊成功後，自動登入並儲存 token
      // 確保 response['token'] 不為 null
      if (response['token'] != null) {
        _token = response['token'] as String;
        // 這裡需要新增一個方法來儲存 token
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', _token!);
        notifyListeners();
      } else {
        // 如果後端沒有回傳 token，拋出例外
        throw Exception('註冊成功，但無法取得登入資訊。');
      }
    } catch (e) {
      // 將 AuthService 拋出的例外重新拋出，讓 UI 層捕捉
      rethrow;
    }
  }

  /// 登入帳號
  /// 呼叫 AuthService 進行登入，並在成功後更新 token
  Future<void> login(String username, String password) async {
    try {
      final token = await AuthService.login(
        username: username,
        password: password,
      );
      _token = token;
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  /// 登出帳號
  /// 呼叫 AuthService 進行登出，並清除本地 token
  Future<void> logout() async {
    await AuthService.logout();
    _token = null;
    notifyListeners();
  }
}