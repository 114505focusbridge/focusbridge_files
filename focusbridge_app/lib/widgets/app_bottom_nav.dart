import 'dart:ui';
import 'package:flutter/material.dart';

class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int>? onTabChanged;
  const AppBottomNav({required this.currentIndex, this.onTabChanged, super.key});

  void _handleTap(BuildContext ctx, int idx) {
    if (onTabChanged != null) {
      onTabChanged!(idx);
    }
    // 導航到對應頁面
    switch (idx) {
      case 0: Navigator.pushReplacementNamed(ctx, '/home'); break;
      case 1: Navigator.pushReplacementNamed(ctx, '/achievements'); break;
      case 2: Navigator.pushReplacementNamed(ctx, '/calendar'); break;
      case 3: Navigator.pushReplacementNamed(ctx, '/profile'); break;
      case 4: Navigator.pushReplacementNamed(ctx, '/album'); break;
      case 5: Navigator.pushReplacementNamed(ctx, '/settings'); break;
    }
  }

  @override
  Widget build(BuildContext context) {
    const items = [
      _NavItem(icon: Icons.home_filled, label: '首頁'),
      _NavItem(icon: Icons.emoji_events_rounded, label: '成就'),
      _NavItem(icon: Icons.calendar_today_rounded, label: '日曆'),
      _NavItem(icon: Icons.person_rounded, label: '個人'),
      _NavItem(icon: Icons.image_rounded, label: '相簿'),
      _NavItem(icon: Icons.settings_rounded, label: '設定'),
    ];
    
    const double baseBarHeight = 65.0;
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;
    final containerHeight = baseBarHeight + bottomInset;

    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(28),
        topRight: Radius.circular(28),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20), // 調整模糊程度，讓效果更明顯
        child: Container(
          height: containerHeight,
          padding: EdgeInsets.only(bottom: bottomInset),
          // 使用單一的半透明白色作為背景，創造出乾淨的毛玻璃效果
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.4),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (index) {
              final isActive = index == currentIndex;
              final nav = items[index];
              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _handleTap(context, index),
                  child: SizedBox(
                    height: baseBarHeight,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // 圖示放大動畫
                        AnimatedScale(
                          duration: const Duration(milliseconds: 250),
                          scale: isActive ? 1.2 : 1.0,
                          curve: Curves.easeOut,
                          child: Icon(
                            nav.icon,
                            size: isActive ? 28 : 24,
                            // 高亮顏色和非活躍顏色
                            color: isActive ? Colors.lightBlue.shade700 : Colors.blueGrey.shade400,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // 文字大小與粗細變化
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOut,
                          style: TextStyle(
                            color: isActive ? Colors.lightBlue.shade700 : Colors.blueGrey.shade400,
                            fontSize: isActive ? 14 : 12,
                            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                          ),
                          child: Text(nav.label),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}