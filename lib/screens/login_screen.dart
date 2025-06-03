// lib/screens/login_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:focusbridge_app/providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  String _username = '';
  String _password = '';
  bool _isLoading = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    final authProvider = context.read<AuthProvider>();

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
                // 1. 上方 Logo 圖片
                SizedBox(
                  height: 120,
                  child: Image.asset(
                    'assets/images/LOGO.png',
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 24),

                // 如果有錯誤訊息則顯示
                if (_errorMessage != null) ...[
                  Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 12),
                ],

                // 【登入表單】
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // 使用者名稱欄位
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: '使用者名稱',
                          border: OutlineInputBorder(),
                        ),
                        onSaved: (val) => _username = val?.trim() ?? '',
                        validator: (val) {
                          if (val == null || val.isEmpty) {
                            return '請輸入使用者名稱';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // 密碼欄位
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: '密碼',
                          border: OutlineInputBorder(),
                        ),
                        obscureText: true,
                        onSaved: (val) => _password = val ?? '',
                        validator: (val) {
                          if (val == null || val.isEmpty) {
                            return '請輸入密碼';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      // 【登入按鈕】
                      _isLoading
                          ? const CircularProgressIndicator()
                          : SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton(
                                onPressed: () async {
                                  // 清除上一輪錯誤
                                  setState(() => _errorMessage = null);

                                  // 驗證表單
                                  final form = _formKey.currentState;
                                  if (form != null && form.validate()) {
                                    form.save();
                                    setState(() => _isLoading = true);

                                    try {
                                      // 呼叫 Provider.login()
                                      await authProvider.login(_username, _password);
                                      // 登入成功後，跳到 Home
                                      if (mounted) {
                                        Navigator.pushReplacementNamed(context, '/home');
                                      }
                                    } catch (err) {
                                      // 如果錯了，顯示錯誤訊息
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
                                },
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
                ),

                const SizedBox(height: 16),
                // 如果沒有帳號，點此跳轉到註冊
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, '/register');
                  },
                  child: const Text('還沒有帳號？註冊'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
