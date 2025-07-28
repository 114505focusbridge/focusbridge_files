// lib/screens/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:focusbridge_app/providers/auth_provider.dart';
import 'package:focusbridge_app/widgets/app_bottom_nav.dart'; // 引入共用導航

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // 「設定」在底部導航的索引
  static const int _settingsIndex = 4;

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
  Widget _buildButton(String label, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF9CAF88),
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
      appBar: AppBar(
        title: const Text('設定'),
        backgroundColor: const Color(0xFF9CAF88),
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
              _buildButton('個人資料', () {
               Navigator.pushNamed(context, '/profile_settings');
             }),
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
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
      // 使用共用底部導航
      bottomNavigationBar: AppBottomNav(currentIndex: 4),
    );
  }
}
