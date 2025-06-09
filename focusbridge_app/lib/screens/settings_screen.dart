// lib/screens/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:focusbridge_app/providers/auth_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // 設定在底部導航列中設定對應的索引：0=首頁,1=成就,2=月曆,3=個人,4=設定,5=相簿
  final int _settingsIndex = 4;

  // 用於 Snackbar 顯示「尚未實作」訊息
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
              _buildButton('偏好設置', _showComingSoon),
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
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),

      // 底部導覽列
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _settingsIndex,
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF9CAF88),
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.grey.shade300,
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
              break;
            case 1:
              Navigator.pushNamed(context, '/achievements'); // 須已在 routes 註冊
              break;
            case 2:
              Navigator.pushNamed(context, '/calendar');     // 須已在 routes 註冊
              break;
            case 3:
              Navigator.pushNamed(context, '/profile');      // 須已在 routes 註冊
              break;
            case 4:
              // 已經在設定頁，不做事
              break;
            case 5:
              Navigator.pushNamed(context, '/album');        // 須已在 routes 註冊
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: '首頁',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.emoji_events_outlined),
            activeIcon: Icon(Icons.emoji_events),
            label: '成就',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book_outlined),
            activeIcon: Icon(Icons.book),
            label: '月曆',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: '個人',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: '設定',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.mood_outlined),
            activeIcon: Icon(Icons.mood),
            label: '相簿',
          ),
        ],
      ),
    );
  }
}
