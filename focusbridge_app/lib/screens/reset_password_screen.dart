// lib/screens/reset_password_screen.dart

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ResetPasswordScreen extends StatefulWidget {
  final String uid;
  final String token;

  const ResetPasswordScreen({
    super.key,
    required this.uid,
    required this.token,
  });

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final TextEditingController _newController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  Future<void> _resetPassword() async {
    final newPwd = _newController.text;
    final confirmPwd = _confirmController.text;

    if (newPwd.isEmpty || confirmPwd.isEmpty) {
      setState(() {
        _errorMessage = '請填寫所有欄位';
        _successMessage = null;
      });
      return;
    }
    if (newPwd != confirmPwd) {
      setState(() {
        _errorMessage = '兩次密碼輸入不一致';
        _successMessage = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final response = await http.post(
        Uri.parse(
            'https://your-backend.example.com/api/auth/password-reset-confirm/${widget.uid}/${widget.token}/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'new_password': newPwd,
          're_new_password': confirmPwd,
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          _successMessage = '密碼已重設成功，請重新登入';
          _errorMessage = null;
        });
      } else {
        setState(() {
          _errorMessage = '連結無效或已過期，請重新申請';
          _successMessage = null;
        });
      }
    } catch (_) {
      setState(() {
        _errorMessage = '網路錯誤，請稍後再試';
        _successMessage = null;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('重設密碼'),
        backgroundColor: const Color(0xFF9CAF88),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Text(
              '請輸入新密碼並確認，完成後即可使用新密碼登入。',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _newController,
              decoration: const InputDecoration(
                labelText: '新密碼',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _confirmController,
              decoration: const InputDecoration(
                labelText: '再次輸入新密碼',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            if (_errorMessage != null) ...[
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 12),
            ],
            if (_successMessage != null) ...[
              Text(
                _successMessage!,
                style: const TextStyle(color: Colors.green),
              ),
              const SizedBox(height: 12),
            ],
            _isLoading
                ? const CircularProgressIndicator()
                : SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _resetPassword,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF9CAF88),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child: const Text(
                        '確定重設',
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                Navigator.popUntil(context, ModalRoute.withName('/login'));
              },
              child: const Text('返回登入'),
            ),
          ],
        ),
      ),
    );
  }
}
