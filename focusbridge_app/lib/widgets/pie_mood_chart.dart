// lib/widgets/pie_mood_chart.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';

// ------------------ 圓形圖：PieMoodChart ------------------
class PieMoodChart extends StatelessWidget {
final int positive;
final int neutral;
final int negative;

const PieMoodChart({
super.key,
required this.positive,
required this.neutral,
required this.negative,
});

@override
Widget build(BuildContext context) {
final total = positive + neutral + negative;
if (total == 0) {
return Center(
child: Text(
'0',
style: TextStyle(fontSize: 60, color: Colors.grey.shade700),
),
);
}

return CustomPaint(
painter: _PiePainter(positive: positive, neutral: neutral, negative: negative),
child: Center(
child: Text(
'$total',
style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
),
),
);
}
}

class _PiePainter extends CustomPainter {
final int positive;
final int neutral;
final int negative;

_PiePainter({required this.positive, required this.neutral, required this.negative});

@override
void paint(Canvas canvas, Size size) {
final total = (positive + neutral + negative);
if (total == 0) return;

final Paint paint = Paint()..style = PaintingStyle.fill;
final Rect rect = Rect.fromLTWH(0, 0, size.width, size.height);
double startAngle = -math.pi / 2;

final values = [positive, neutral, negative];
final colors = [Colors.green.shade400, const Color.fromARGB(255, 187, 232, 255), Colors.red.shade400];

for (int i = 0; i < values.length; i++) {
final sweep = 2 * math.pi * (values[i] / total);
paint.color = colors[i];
canvas.drawArc(rect, startAngle, sweep, true, paint);
startAngle += sweep;
}

// 繪製內圈（切出 donut 形狀）
final double holeRadius = size.width * 0.32;
final Paint holePaint = Paint()..color = Colors.white;
canvas.drawCircle(Offset(size.width / 2, size.height / 2), holeRadius, holePaint);
}

@override
bool shouldRepaint(covariant _PiePainter oldDelegate) {
return oldDelegate.positive != positive ||
oldDelegate.neutral != neutral ||
oldDelegate.negative != negative;
}
}