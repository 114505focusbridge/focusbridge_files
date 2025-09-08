// lib/screens/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:focusbridge_app/providers/auth_provider.dart';
import 'package:focusbridge_app/widgets/app_bottom_nav.dart';


class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // 簡約風格 UI 配色
  final Color _backgroundColor = const Color(0xFFF0F0F0); // 淺灰色背景
  final Color _primaryColor = const Color(0xFF4A4A4A); // 深灰色按鈕
  final Color _textColor = const Color(0xFF2E2E2E); // 幾乎黑的文字
  final Color _destructiveColor = Colors.red.shade400; // 登出按鈕顏色

  // 顯示尚未實作提示
  void _showComingSoon() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('此功能暫未實作'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  // 統一按鈕樣式
  Widget _buildButton(String label, VoidCallback onPressed, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: color ?? _primaryColor, // 根據傳入的顏色或預設值
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
          ),
          child: Text(
            label,
            style: const TextStyle(fontSize: 18, color: Colors.white),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    return Scaffold(
      backgroundColor: _backgroundColor, // 設定頁面背景色
      appBar: AppBar(
        title: Text('設定', style: TextStyle(fontWeight: FontWeight.bold, color: _textColor)),
        backgroundColor: _backgroundColor,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            children: [
              const SizedBox(height: 8),
              _buildButton('偏好設置', () {
                Navigator.pushNamed(context, '/preferences');
              }),
              _buildButton('個人資料', _showComingSoon),
              _buildButton('通知', _showComingSoon),
              _buildButton('音效', _showComingSoon),
              _buildButton('其他設置', _showComingSoon),
              _buildButton('客服中心', _showComingSoon),
              const Spacer(),
              _buildButton(
                '登出',
                () async {
                  await authProvider.logout();
                  if (context.mounted) {
                    Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
                  }
                },
                color: _destructiveColor,
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 5),
    );
  }
}