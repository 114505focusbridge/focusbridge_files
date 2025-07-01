// lib/widgets/app_bottom_nav.dart

import 'package:flutter/material.dart';

/// 底部共用導覽列，6 個按鈕：首頁、日記（月曆）、個人、設定、相簿
class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  const AppBottomNav({required this.currentIndex, super.key});

  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/home');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/diary_entry');
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/profile');
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/settings');
        break;
      case 4:
        Navigator.pushReplacementNamed(context, '/album');
        break;
      case 5:
        Navigator.pushReplacementNamed(context, '/home');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      type: BottomNavigationBarType.fixed,
      backgroundColor: const Color(0xFF9CAF88),
      selectedItemColor: Colors.white,
      unselectedItemColor: Colors.grey.shade300,
      onTap: (i) => _onTap(context, i),
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: '首頁'),
        BottomNavigationBarItem(icon: Icon(Icons.book_outlined), activeIcon: Icon(Icons.book), label: '日記'),
        BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: '個人'),
        BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), activeIcon: Icon(Icons.settings), label: '設定'),
        BottomNavigationBarItem(icon: Icon(Icons.mood_outlined), activeIcon: Icon(Icons.mood), label: '相簿'),
        BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: ''), // 保留第六格空位
      ],
    );
  }
}
