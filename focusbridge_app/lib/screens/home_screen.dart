// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:focusbridge_app/widgets/app_bottom_nav.dart';

/// 主畫面：情緒格子 + 凸起動畫導航列
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('主頁'),
        backgroundColor: const Color(0xFF9CAF88),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 24),
            const Text(
              '今天情緒如何呢...？',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GridView.count(
                  crossAxisCount: 3,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1,
                  children: [
                    // 文字情緒按鈕
                    for (var label in _emotionLabels)
                      _TextEmotionCircle(label),
                    // 圖示情緒按鈕
                    for (var i = 0; i < _emotionIcons.length; i++)
                      _IconEmotionCircle(
                        _emotionIcons[i],
                        _emotionLabels[i],
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 0),
    );
  }
}

// 文字標籤
const List<String> _emotionLabels = [
  '快樂', '憤怒', '悲傷',
  '恐懼', '驚訝', '厭惡',
];

// 圖示資源
const List<String> _emotionIcons = [
  'assets/images/emotion_sun.png',
  'assets/images/emotion_tornado.png',
  'assets/images/emotion_cloud.png',
  'assets/images/emotion_lightning.png',
  'assets/images/emotion_snowflake.png',
  'assets/images/emotion_rain.png',
];

/// 文字圓形按鈕
class _TextEmotionCircle extends StatelessWidget {
  final String label;
  const _TextEmotionCircle(this.label);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/color_picker', arguments: label);
      },
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF9CAF88),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

/// 圖示圓形按鈕
class _IconEmotionCircle extends StatelessWidget {
  final String assetPath;
  final String label;
  const _IconEmotionCircle(this.assetPath, this.label);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/color_picker', arguments: label);
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          shape: BoxShape.circle,
        ),
        padding: const EdgeInsets.all(12),
        child: Image.asset(assetPath, fit: BoxFit.contain),
      ),
    );
  }
}
