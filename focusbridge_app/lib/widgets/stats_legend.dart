// lib/widgets/stats_legend.dart
import 'package:flutter/material.dart';

// ------------------ 統計 Legend 與數字 ------------------
class StatsLegend extends StatelessWidget {
final int positive;
final int neutral;
final int negative;
final int totalDays;
final Future<void> Function()? onRefresh;
final bool loading;

const StatsLegend({
required this.positive,
required this.neutral,
required this.negative,
required this.totalDays,
this.onRefresh,
required this.loading,
});

double _ratio(int v, int total) {
if (total <= 0) return 0.0;
return (v / total).clamp(0.0, 1.0);
}

@override
Widget build(BuildContext context) {
final total = positive + neutral + negative;
return Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
// 標題 + refresh
Row(
children: [
const Text('情緒占比', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
const Spacer(),
if (loading)
const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
else
IconButton(
padding: EdgeInsets.zero,
constraints: const BoxConstraints(),
onPressed: onRefresh,
icon: const Icon(Icons.refresh, size: 18),
tooltip: '重新統計',
),
],
),
Text(total > 0 ? '已統計 $total 天' : '本月尚無日記', style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
const SizedBox(height: 6),

// 三個 legend（字級縮小）
_legendRow('正向', Colors.green.shade400, positive, total),
const SizedBox(height: 8),
_legendRow('中性', const Color.fromARGB(255, 187, 232, 255), neutral, total),
const SizedBox(height: 8),
_legendRow('負向', Colors.red.shade400, negative, total),
],
);
}

Widget _legendRow(String label, Color color, int count, int total) {
final pct = total > 0 ? (_ratio(count, total) * 100).round() : 0;
return Row(
children: [
Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
const SizedBox(width: 8),
Expanded(child: Text(label, style: const TextStyle(fontSize: 12))),
Text('$count 天', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
const SizedBox(width: 6),
Text('$pct%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
],
);
}
}