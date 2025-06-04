// lib/screens/register_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:focusbridge_app/providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  String _username = '';
  String _email = '';
  String _password = '';
  String _password2 = '';
  bool _isLoading = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    final authProvider = context.read<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('註冊'),
        backgroundColor: const Color(0xFF9CAF88),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                // 顯示錯誤訊息
                if (_errorMessage != null) ...[
                  Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 12),
                ],

                // 【註冊表單】
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // 使用者名稱
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

                      // 電子郵件（可選填）
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: '電子郵件 (可選)',
                          border: OutlineInputBorder(),
                        ),
                        onSaved: (val) => _email = val?.trim() ?? '',
                        validator: (val) {
                          // 可以加上更嚴謹的 Email 格式驗證
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // 密碼
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
                          if (val.length < 6) {
                            return '密碼至少 6 位';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // 確認密碼
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: '確認密碼',
                          border: OutlineInputBorder(),
                        ),
                        obscureText: true,
                        onSaved: (val) => _password2 = val ?? '',
                        validator: (val) {
                          if (val == null || val.isEmpty) {
                            return '請再次輸入密碼';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      // 【註冊按鈕】
                      _isLoading
                          ? const CircularProgressIndicator()
                          : SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton(
                                onPressed: () async {
                                  // 清除上一輪錯誤
                                  setState(() => _errorMessage = null);

                                  final form = _formKey.currentState;
                                  if (form != null && form.validate()) {
                                    form.save();

                                    // 本地先檢查兩次密碼是否相同
                                    if (_password != _password2) {
                                      setState(() {
                                        _errorMessage = '兩次密碼輸入不一致';
                                      });
                                      return;
                                    }

                                    setState(() => _isLoading = true);

                                    try {
                                      // 呼叫 Provider.register()
                                      await authProvider.register(
                                        _username,
                                        _email,
                                        _password,
                                        _password2,
                                      );
                                      // 註冊成功後直接跳轉到 Home
                                      if (mounted) {
                                        Navigator.pushReplacementNamed(context, '/home');
                                      }
                                    } catch (err) {
                                      String msg = '註冊失敗';
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
                                  '註冊',
                                  style: TextStyle(fontSize: 18),
                                ),
                              ),
                            ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),
                // 如果已經有帳號，跳轉到 登入 頁
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, '/login');
                  },
                  child: const Text('已有帳號？登入'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
