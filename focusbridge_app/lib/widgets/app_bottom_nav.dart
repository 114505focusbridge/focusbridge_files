// lib/widgets/app_bottom_nav.dart

import 'package:flutter/material.dart';
import 'package:convex_bottom_bar/convex_bottom_bar.dart';

/// 使用 ConvexAppBar 打造動畫導航列（固定樣式）
class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  const AppBottomNav({required this.currentIndex, super.key});

  /// 點擊事件：依 index 導航
  void _onTap(BuildContext ctx, int i) {
    switch (i) {
      case 0:
        Navigator.pushReplacementNamed(ctx, '/home');
        break;
      case 1:
        Navigator.pushReplacementNamed(ctx, '/achievements');
        break;
      case 2:
        Navigator.pushReplacementNamed(ctx, '/diary_entry');
        break;
      case 3:
        Navigator.pushReplacementNamed(ctx, '/profile');
        break;
      case 4:
        Navigator.pushReplacementNamed(ctx, '/settings');
        break;
      case 5:
        Navigator.pushReplacementNamed(ctx, '/album');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ConvexAppBar(
      style: TabStyle.reactCircle,               // 改為固定樣式，允許偶數項目
      backgroundColor: const Color(0xFF9CAF88),
      activeColor: Colors.white,
      color: Colors.grey.shade200,
      elevation: 8,
      curveSize: 75,                       // 中央波峰寬度（保留設定）
      height: 60,
      initialActiveIndex: currentIndex,
      items: const [
        TabItem(icon: Icons.home, title: '首頁'),
        TabItem(icon: Icons.emoji_events, title: '成就'),
        TabItem(icon: Icons.book, title: '日記'),
        TabItem(icon: Icons.person, title: '個人'),
        TabItem(icon: Icons.settings, title: '設定'),
        TabItem(icon: Icons.mood, title: '相簿'),
      ],
      onTap: (i) => _onTap(context, i),
    );
  }
}
