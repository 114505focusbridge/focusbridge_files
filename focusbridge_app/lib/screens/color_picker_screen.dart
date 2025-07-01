// lib/screens/color_picker_screen.dart

import 'package:flutter/material.dart';
import 'package:focusbridge_app/widgets/app_bottom_nav.dart'; // ← 新增

class ColorPickerScreen extends StatelessWidget {
  const ColorPickerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 從路由參數取出被點擊的情緒標籤（如 "快樂"、"憤怒" 等）
    final args = ModalRoute.of(context)!.settings.arguments;
    final String emotionLabel = args is String ? args : '';

    // 建立顏色列表：使用 Material Colors 的不同深淺
    final List<Color> palette = [];
    for (final primary in Colors.primaries) {
      palette.add(primary[700]!);
      palette.add(primary[500]!);
      palette.add(primary[300]!);
      palette.add(primary[100]!);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '幫你的「\$emotionLabel」\n填自己的情緒顏色吧！',
          textAlign: TextAlign.center,
        ),
        backgroundColor: const Color(0xFF9CAF88),
        centerTitle: true,
        toolbarHeight: 80,
        titleTextStyle: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w500,
          color: Colors.white,
          height: 1.3,
        ),
        automaticallyImplyLeading: false, // 隱藏返回箭頭
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: GridView.builder(
          itemCount: palette.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 6,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1,
          ),
          itemBuilder: (context, index) {
            final color = palette[index];
            return GestureDetector(
              onTap: () {
                // 使用者選擇完顏色後，帶 emotionLabel 和 color 跳到日記輸入頁
                Navigator.pushNamed(
                  context,
                  '/diary_entry',
                  arguments: {
                    'emotion': emotionLabel,
                    'color': color,
                  },
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 0), // ← 加入共用導航
    );
  }
}
