// lib/providers/auth_provider.dart

import 'package:flutter/foundation.dart';
// 將這裡改成你在 pubspec.yaml 裡面設定的 package 名稱
import 'package:focusbridge_app/services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  String? _token; // 儲存目前的 token（如果有）
  String? get token => _token;

  bool get isAuthenticated => _token != null;

  /// 啟動 App 時，檢查本機是否有存 token
  Future<void> loadToken() async {
    try {
      // 如果你的 AuthService.getToken() 是 static 方法，就這樣呼叫
      // 如果不是 static，請改成：final savedToken = await AuthService().getToken();
      final savedToken = await AuthService.getToken();
      _token = savedToken;
    } catch (e) {
      // 如果撈不到 token，也不要讓 App 崩潰
      _token = null;
      debugPrint('載入 token 時發生錯誤：$e');
    }
    notifyListeners();
  }

  /// 登入：呼叫 AuthService.login() 並更新狀態
  Future<void> login(String username, String password) async {
    try {
      // 如果 AuthService.login 回傳的是 String token，就直接 assign
      // 否則若回傳 Map，也可以改成 data['token'] 的寫法
      final newToken = await AuthService.login(
        username: username,
        password: password,
      );
      _token = newToken;
    } catch (e) {
      _token = null;
      debugPrint('登入時發生錯誤：$e');
      rethrow;
    }
    notifyListeners();
  }

  /// 註冊：呼叫 AuthService.register() 並更新狀態
  Future<void> register(
    String username,
    String email,
    String password,
    String password2,
  ) async {
    try {
      // 假設 AuthService.register() 回傳的是 Map，裡面有 token 欄位
      final data = await AuthService.register(
        username: username,
        email: email,
        password: password,
        password2: password2,
      );
      // 如果 register 直接回傳 token String，就改成：
      // final newToken = await AuthService.register(...);
      // _token = newToken;
      final newToken = data['token'] as String;
      _token = newToken;
    } catch (e) {
      _token = null;
      debugPrint('註冊時發生錯誤：$e');
      rethrow;
    }
    notifyListeners();
  }

  /// 登出：呼叫 AuthService.logout() 並清除本機 token
  Future<void> logout() async {
    try {
      await AuthService.logout();
    } catch (e) {
      debugPrint('登出時發生錯誤：$e');
    }
    _token = null;
    notifyListeners();
  }
}
