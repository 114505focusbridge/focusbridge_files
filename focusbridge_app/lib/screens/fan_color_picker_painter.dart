// lib/widgets/fan_color_picker_painter.dart
import 'package:flutter/material.dart';
import 'dart:math' as math;

class FanColorPickerPainter extends CustomPainter {
  final double animationValue;
  final List<Color> colors;
  final int? activeIndex;

  FanColorPickerPainter({
    required this.animationValue,
    required this.colors,
    this.activeIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 扇形展開的中心點
    final center = Offset(size.width * 0.5, size.height * 0.8); 
    // 展開的總角度（弧度）
    final totalAngle = math.pi * 0.9; 
    // 每張卡片之間的角度
    final anglePerItem = totalAngle / (colors.length - 1); 

    // 繪製陰影，讓扇形有立體感
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.2)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 10.0);

    for (int i = 0; i < colors.length; i++) {
      final isLastItem = i == colors.length - 1;
      final isFirstItem = i == 0;
      final angle = -totalAngle / 2 + i * anglePerItem;

      // 根據動畫值和索引計算位置
      final cardAngle = angle * animationValue;
      final radius = size.width * 0.3 + (isFirstItem || isLastItem ? 20 : 0); // 調整半徑
      final cardCenter = Offset(
        center.dx + radius * math.cos(cardAngle),
        center.dy + radius * math.sin(cardAngle),
      );

      final cardRect = Rect.fromCenter(
        center: cardCenter,
        width: 100 * (0.8 + 0.2 * animationValue), // 放大效果
        height: 60 * (0.8 + 0.2 * animationValue),
      );

      final cardPath = Path()
        ..addRRect(RRect.fromRectAndRadius(cardRect, const Radius.circular(15)));

      // 繪製陰影
      canvas.drawPath(cardPath.shift(const Offset(0, 5)), shadowPaint);
      
      // 繪製卡片
      final cardPaint = Paint()..color = colors[i]..style = PaintingStyle.fill;
      canvas.drawPath(cardPath, cardPaint);
    }
  }

  @override
  bool shouldRepaint(covariant FanColorPickerPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue || oldDelegate.activeIndex != activeIndex;
  }
}