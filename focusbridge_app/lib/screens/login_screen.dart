// lib/screens/login_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:focusbridge_app/providers/auth_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // 1. 改用 TextEditingController 來管理輸入框
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // 用來控制是否顯示 CircularProgressIndicator
  bool _isLoading = false;
  // 如果有錯誤要顯示的訊息
  String? _errorMessage;

  // 2. 「記住我」的狀態
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  /// 從 SharedPreferences 讀取是否之前有儲存過帳號/密碼
  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUser = prefs.getString('saved_username') ?? '';
    final savedPass = prefs.getString('saved_password') ?? '';

    if (savedUser.isNotEmpty && savedPass.isNotEmpty) {
      // 如果有儲存過，就把帳號密碼填回欄位，並勾選「記住我」
      setState(() {
        _usernameController.text = savedUser;
        _passwordController.text = savedPass;
        _rememberMe = true;
      });
      // 以下如果要自動登入，可以在這裡直接呼叫 _attemptLogin();
      // 例如：await _attemptLogin();
    }
  }

  /// 按下「登入」時的邏輯：先儲存或清除 SharedPreferences，然後呼叫 Provider.login()
  Future<void> _attemptLogin() async {
    final authProvider = context.read<AuthProvider>();
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = '請輸入使用者名稱和密碼';
      });
      return;
    }

    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    try {
      // 如果勾了「記住我」，就把帳號、密碼存在 SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      if (_rememberMe) {
        await prefs.setString('saved_username', username);
        await prefs.setString('saved_password', password);
      } else {
        // 如果沒有勾，就把以前儲存的帳密清空
        await prefs.remove('saved_username');
        await prefs.remove('saved_password');
      }

      // 呼叫 AuthProvider.login() 進行後端驗證
      await authProvider.login(username, password);

      // 登入成功之後，頁面導到 Home，並清除前面所有頁面
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (err) {
      // 如果登入失敗，顯示錯誤訊息
      String msg = '登入失敗';
      if (err is Exception && err.toString().isNotEmpty) {
        msg = err.toString();
      }
      setState(() {
        _errorMessage = msg;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('使用者登入'),
        backgroundColor: const Color(0xFF9CAF88),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                // 顯示錯誤訊息（如果有的話）
                if (_errorMessage != null) ...[
                  Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 12),
                ],

                // 【登入表單】改成直接用 TextField + Controller
                Column(
                  children: [
                    // 使用者名稱欄位
                    TextField(
                      controller: _usernameController,
                      decoration: const InputDecoration(
                        labelText: '使用者名稱',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 密碼欄位
                    TextField(
                      controller: _passwordController,
                      decoration: const InputDecoration(
                        labelText: '密碼',
                        border: OutlineInputBorder(),
                      ),
                      obscureText: true,
                    ),
                    const SizedBox(height: 8),

                    // 「記住我」的 Checkbox
                    CheckboxListTile(
                      title: const Text('記住我'),
                      value: _rememberMe,
                      onChanged: (bool? val) {
                        if (val == null) return;
                        setState(() {
                          _rememberMe = val;
                        });
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                    ),

                    const SizedBox(height: 16),

                    // 【登入按鈕】
                    _isLoading
                        ? const CircularProgressIndicator()
                        : SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: _attemptLogin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF9CAF88),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                              ),
                              child: const Text(
                                '登入',
                                style: TextStyle(fontSize: 18),
                              ),
                            ),
                          ),
                  ],
                ),

                const SizedBox(height: 16),

                // 如果沒有帳號，點此跳轉到註冊
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, '/register');
                  },
                  child: const Text('還沒有帳號？註冊'),
                ),

                // 忘記密碼按鈕
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/forgot_password');
                  },
                  child: const Text('忘記密碼？'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
