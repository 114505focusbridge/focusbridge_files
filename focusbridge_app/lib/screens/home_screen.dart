// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:focusbridge_app/providers/auth_provider.dart';
import 'package:focusbridge_app/widgets/app_bottom_nav.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

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
                    for (int i = 0; i < 3; i++)
                      _buildTextEmotionCircle(_emotionLabels[i], context),
                    for (int i = 0; i < 3; i++)
                      _buildIconEmotionCircle(_emotionIcons[i], _emotionLabels[i], context),
                    for (int i = 3; i < 6; i++)
                      _buildTextEmotionCircle(_emotionLabels[i], context),
                    for (int i = 3; i < 6; i++)
                      _buildIconEmotionCircle(_emotionIcons[i], _emotionLabels[i], context),
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

// 第一列 & 第三列：情緒文字標籤
const List<String> _emotionLabels = [
  '快樂', '憤怒', '悲傷',
  '恐懼', '驚訝', '厭惡',
];

// 第二列 & 第四列：情緒圖示資源路徑
const List<String> _emotionIcons = [
  'assets/images/emotion_sun.png',
  'assets/images/emotion_tornado.png',
  'assets/images/emotion_cloud.png',
  'assets/images/emotion_lightning.png',
  'assets/images/emotion_snowflake.png',
  'assets/images/emotion_rain.png',
];

/// 建構「文字情緒圓形」點擊後帶 emotionLabel 跳轉
Widget _buildTextEmotionCircle(String emotionLabel, BuildContext context) {
  return GestureDetector(
    onTap: () {
      Navigator.pushNamed(
        context,
        '/color_picker',
        arguments: emotionLabel,
      );
    },
    child: Container(
      decoration: const BoxDecoration(
        color: Color(0xFF9CAF88),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        emotionLabel,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
        ),
        textAlign: TextAlign.center,
      ),
    ),
  );
}

/// 建構「圖示情緒圓形」點擊後帶 emotionLabel 跳轉
Widget _buildIconEmotionCircle(String assetPath, String emotionLabel, BuildContext context) {
  return GestureDetector(
    onTap: () {
      Navigator.pushNamed(
        context,
        '/color_picker',
        arguments: emotionLabel,
      );
    },
    child: Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        shape: BoxShape.circle,
      ),
      padding: const EdgeInsets.all(12),
      child: Image.asset(
        assetPath,
        fit: BoxFit.contain,
      ),
    ),
  );
}
