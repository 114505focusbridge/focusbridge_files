// lib/screens/calendar_screen.dart
//
// 日曆頁面：固定 6 行日曆（不可捲動）+ 半遮蓋的統計卡（Donut 圓餅圖 + legend）
// 已針對單日格子做 overflow 防護：使用 LayoutBuilder + FittedBox + Expanded
// 浮動統計卡已放大（statsHeight = 180.0）

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:focusbridge_app/widgets/app_bottom_nav.dart';
import 'package:focusbridge_app/services/diary_service.dart';
import 'package:focusbridge_app/widgets/glowing_button.dart';

/// 月曆格需要的最小資訊（概覽）
class DiaryOverview {
  final DateTime date;
  final String? mood; // 'sunny' | 'cloudy' | 'rain' | ...
  final String? colorHex; // 例: '#EEDC82'
  final bool hasDiary;
  final String? snippet;
  final int? diaryId;

  const DiaryOverview({
    required this.date,
    this.mood,
    this.colorHex,
    required this.hasDiary,
    this.snippet,
    this.diaryId,
  });
}

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _currentMonth = DateTime(DateTime.now().year, DateTime.now().month);
  bool _isLoading = false;

  /// 以 'yyyy-MM-dd' 當 key，方便查表
  final Map<String, DiaryOverview> _overviewByDate = {};

  // ===== 統計狀態 =====
  bool _statsLoading = false;
  int _pos = 0, _neu = 0, _neg = 0;
  int _daysWithDiary = 0;

  @override
  void initState() {
    super.initState();
    _loadMonthOverview();
  }

  // ====== 月份切換 ======
  void _prevMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
    });
    _loadMonthOverview();
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
    });
    _loadMonthOverview();
  }

  // ====== 載入該月概覽（呼叫後端 API） ======
  Future<void> _loadMonthOverview() async {
    setState(() => _isLoading = true);

    try {
      final yyyyMm =
          '${_currentMonth.year.toString().padLeft(4, '0')}-${_currentMonth.month.toString().padLeft(2, '0')}';

      final items = await DiaryService.fetchMonthOverview(yyyyMm);

      _overviewByDate.clear();
      for (final j in items) {
        final date = DateTime.parse(j['date']);
        final key = _fmt(date);
        _overviewByDate[key] = DiaryOverview(
          date: date,
          mood: (j['mood'] ?? j['emotion']) as String?,
          colorHex: (j['color'] ?? j['mood_color']) as String?,
          hasDiary: (j['has_diary'] ?? true) as bool,
          snippet: j['snippet'] as String?,
          diaryId: (j['id'] as num?)?.toInt(),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('載入月概覽失敗：$e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }

    // 先載到概覽，再根據有日記的日期做統計（async 取 sentiment）
    await _calcMonthStats();
  }

  // ====== 計算本月情緒統計（向後端查詳細 sentiment） ======
  Future<void> _calcMonthStats() async {
    setState(() {
      _statsLoading = true;
      _pos = _neu = _neg = 0;
      _daysWithDiary = 0;
    });

    try {
      final dates = _overviewByDate.values
          .where((v) => v.hasDiary)
          .map((v) => v.date)
          .toList()
        ..sort();

      _daysWithDiary = dates.length;

      for (final d in dates) {
        try {
          final detail = await DiaryService.fetchDiaryByDate(d);
          if (detail == null) continue;
          final s = (detail['sentiment'] ?? '').toString().toLowerCase();
          if (s == 'positive') {
            _pos++;
          } else if (s == 'negative') {
            _neg++;
          } else {
            _neu++;
          }
        } catch (_) {
          // 單日失敗則嘗試從 overview 的 mood 判斷（fallback）
          final key = _fmt(d);
          final ov = _overviewByDate[key];
          final mood = ov?.mood?.toLowerCase() ?? '';
          if (mood == 'sunny' || mood == 'positive') _pos++;
          else if (mood == 'cloudy' || mood == 'neutral') _neu++;
          else _neg++;
        }
        if (!mounted) return;
        if ((_pos + _neu + _neg) % 5 == 0) setState(() {});
      }
    } finally {
      if (mounted) setState(() => _statsLoading = false);
    }
  }

void _onDayTap(DateTime date) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      // 使用 DraggableScrollableSheet，並把 scrollController 傳給 SingleChildScrollView
      return DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.35,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          final bottomInset = MediaQuery.of(context).viewInsets.bottom;
          final title = DateFormat('yyyy/MM/dd (EEE)', 'zh_TW').format(date);
          final ov = _overviewByDate[_fmt(date)];
          final noDiaryFromOverview = (ov == null || !ov.hasDiary);

          return Container(
            decoration: const BoxDecoration(
              color: Color.fromARGB(255, 255, 254, 242),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 12,
                bottom: bottomInset + 16,
              ),
              child: SingleChildScrollView(
                controller: scrollController, // <-- 關鍵：把 controller 傳入
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 上方的抓手與標題列
                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(157, 176, 176, 176),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    Row(
                      children: [
                        Text(title,
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w700)),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.blueGrey),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // FutureBuilder 負責動態載入日記內容
                    FutureBuilder<Map<String, dynamic>?>(
                      future: DiaryService.fetchDiaryByDate(date),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _skeletonCard(height: 68),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(child: _skeletonCard(height: 88)),
                                  const SizedBox(width: 12),
                                  Expanded(child: _skeletonCard(height: 88)),
                                ],
                              ),
                            ],
                          );
                        }

                        if (snapshot.hasError) {
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text('讀取失敗：${snapshot.error}',
                                  style: const TextStyle(fontSize: 14, color: Colors.red)),
                              const SizedBox(height: 16),
                              FilledButton(
                                onPressed: () => Navigator.pop(context),
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFF9CAF88),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14)),
                                ),
                                child: const Text('關閉'),
                              ),
                            ],
                          );
                        }

                        final detail = snapshot.data;
                        if (detail == null || noDiaryFromOverview) {
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text('這天尚未留下日記。', style: TextStyle(fontSize: 20)),
                              const SizedBox(height: 32),
                              FilledButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  Navigator.pushNamed(context, '/diary_entry',
                                      arguments: {
                                        'emotion': '',
                                        'color': Colors.transparent,
                                        'date': date,
                                      });
                                },
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFF9CAF88),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14)),
                                ),
                                child: const Text('補寫這天的日記', style:TextStyle(fontSize: 16)),
                              ),
                            ],
                          );
                        }

                        final mood = (detail['mood'] ?? detail['emotion']) as String?;
                        final colorHex = (detail['color'] ?? detail['mood_color']) as String?;
                        final emoji = _emoji(mood);
                        final moodColor = _hexColor(colorHex);
                        final content = (detail['content'] ?? '') as String? ?? '';
                        final titleText = (detail['title'] ?? '') as String? ?? '';
                        final aiText = (detail['ai_analysis'] ?? detail['ai_message'] ?? '（暫無 AI 分析）') as String?;
                        final diaryId = (detail['id'] as num?)?.toInt();

                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // 情緒標籤（與標題在同一行）
                            Row(
                              children: [
                                if (emoji.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: moodColor.withOpacity(.18),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: moodColor.withOpacity(.4)),
                                    ),
                                    child: Row(
                                      children: [
                                        Text(emoji, style: const TextStyle(fontSize: 16)),
                                        const SizedBox(width: 6),
                                        Text(mood ?? '', style: const TextStyle(fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                const Spacer(),
                              ],
                            ),
                            const SizedBox(height: 14),

                            // 日記內容
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFE5E5E5)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (titleText.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 6),
                                      child: Text(titleText,
                                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                                    ),
                                  Text(
                                    content.isEmpty ? '（無內容）' : content,
                                    style: const TextStyle(fontSize: 14, height: 1.5),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 12),

                            // AI 區塊（保留一張，顯示 AI 建議文字）
                            _AICard(title: 'AI 回饋', content: aiText ?? '（暫無 AI 回饋）'),

                            const SizedBox(height: 24),

                            // 動作
                            Row(
                              children: [
                                Expanded(
                                  child: GlowingButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      Navigator.pushNamed(context, '/diary_entry', arguments: {
                                        'emotion': mood ?? '',
                                        'color': moodColor,
                                        'date': date,
                                        'diaryId': diaryId,
                                      });
                                    },
                                    baseColor: const Color.fromARGB(255,111, 230, 252), 
                                    child: const Text(
                                      '查看 / 編輯',
                                      style: TextStyle(color: Color.fromARGB(255, 255, 255, 255), fontSize: 16, fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}


  // ====== Build ======
  @override
  Widget build(BuildContext context) {
    final monthLabel =
        DateFormat('yyyy年 M月', 'zh_TW').format(_currentMonth); // 月份標題顯示
    final daysInMonth =
        DateUtils.getDaysInMonth(_currentMonth.year, _currentMonth.month);
    final firstWeekday =
        DateTime(_currentMonth.year, _currentMonth.month, 1).weekday; // 1=Mon..7=Sun
    // 星期日為第一天，其 weekday = 7。計算偏移量時，7 % 7 = 0
    final startOffset = firstWeekday % 7;
    // 固定顯示 6 行 * 7 = 42 個格子
    const totalGridCells = 42;

    // 統計卡高度（已放大）
    const double statsHeight = 180.0;
    // 我們要讓卡片半遮蓋日曆 => 在 Column 中保留 statsHeight / 2 的空白區域
    final double reserveHeight = statsHeight / 2;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFDFF0DC), Colors.white], // 淺綠到白色的漸層
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // 主內容：日曆 + 下方預留空間（讓統計卡可半遮蓋）
              Column(
                children: [
                  // 月份列 + 星期列 + 日曆（占大多數高度）
                  Expanded(
                    child: Column(
                      children: [
                        // 月份切換列
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                          child: Row(
                            children: [
                              IconButton(
                                  icon: const Icon(Icons.arrow_back),
                                  onPressed: _prevMonth,
                                  color: Colors.blueGrey.shade800),
                              Expanded(
                                child: Center(
                                  child: Text(
                                    monthLabel,
                                    style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blueGrey.shade800),
                                  ),
                                ),
                              ),
                              IconButton(
                                  icon: const Icon(Icons.arrow_forward),
                                  onPressed: _nextMonth,
                                  color: Colors.blueGrey.shade800),
                            ],
                          ),
                        ),

                        // 星期標題
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: Row(
                            children: const ['日', '一', '二', '三', '四', '五', '六'].map((d) {
                              return Expanded(
                                child: Center(
                                  child: Text(d,
                                      style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF4C4C4C))),
                                ),
                              );
                            }).toList(),
                          ),
                        ),

                        // 日曆格（Grid 填滿剩餘）
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            child: GridView.builder(
                              physics: const NeverScrollableScrollPhysics(),
                              padding: EdgeInsets.zero,
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 7,
                                mainAxisSpacing: 6,
                                crossAxisSpacing: 6,
                                childAspectRatio: 0.8,
                              ),
                              itemCount: totalGridCells,
                              itemBuilder: (ctx, index) {
                                final dayNum = index - startOffset + 1;
                                final isInMonth = dayNum >= 1 && dayNum <= daysInMonth;

                                if (!isInMonth) {
                                  // 空白格（保留格子，維持排列）
                                  return Container();
                                }

                                final date = DateTime(_currentMonth.year,
                                    _currentMonth.month, dayNum);
                                final key = _fmt(date);
                                final ov = _overviewByDate[key];
                                final isToday = _fmt(date) == _fmt(DateTime.now());

                                return GestureDetector(
                                  onTap: () => _onDayTap(date),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 150),
                                    curve: Curves.easeOut,
                                    padding: const EdgeInsets.all(6), // 減少 padding
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isToday
                                            ? const Color(0xFF9CAF88)
                                            : Colors.transparent,
                                        width: isToday ? 1.6 : 0,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: isToday
                                              ? const Color(0xFF9CAF88).withOpacity(0.12)
                                              : Colors.black.withOpacity(0.03),
                                          blurRadius: isToday ? 8 : 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    // 使用 LayoutBuilder 控制內部元素大小，並避免 overflow
                                    child: LayoutBuilder(builder: (c, constraints) {
                                      // 預留給數字、emoji、顏色條的最大高度分配
                                      return Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // 日期數字（靠上）
                                          Text(
                                            '$dayNum',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.grey.shade800,
                                            ),
                                          ),

                                          // 小間隔
                                          const SizedBox(height: 4),

                                          // 中間區域：使用 Expanded 佔據可用空間，內部用 FittedBox 縮放 emoji
                                          Expanded(
                                            child: Center(
                                              child: ov?.hasDiary == true &&
                                                      _emoji(ov?.mood).isNotEmpty
                                                  ? FittedBox(
                                                      fit: BoxFit.scaleDown,
                                                      child: Text(
                                                        _emoji(ov?.mood),
                                                        // 大字體但會被 FittedBox 自動縮放到可用大小
                                                        style:
                                                            const TextStyle(fontSize: 48),
                                                      ),
                                                    )
                                                  : const SizedBox.shrink(),
                                            ),
                                          ),

                                          const SizedBox(height: 4),

                                          // 顏色條（固定高度，放在最下方）
                                          if (ov?.hasDiary == true)
                                            Container(
                                              height: 6,
                                              width: double.infinity,
                                              decoration: BoxDecoration(
                                                color: _hexColor(ov?.colorHex),
                                                borderRadius: BorderRadius.circular(5),
                                              ),
                                            )
                                          else
                                            // 若沒有日記，放一個小占位以保持格子一致
                                            SizedBox(height: 6),
                                        ],
                                      );
                                    }),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 在 Column 底部預留 statsHeight / 2 的空間（讓浮動卡片可半遮蓋）
                  SizedBox(height: reserveHeight),
                ],
              ),

              // 浮動的統計卡（半遮蓋日曆） -- 放大並往上微調
              Positioned(
                left: 16,
                right: 16,
                bottom: 36, // 提高一些以配合更大的卡片
                child: SizedBox(
                  height: statsHeight,
                  child: Material(
                    // 使用 Material 以便有陰影和點擊水波
                    color: Colors.transparent,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE5E5E5)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          )
                        ],
                      ),
                      child: Row(
                        children: [
                          // Donut 圓餅圖（放大）
                          SizedBox(
                            width: statsHeight - 24, // 留些 padding
                            height: statsHeight - 24,
                            child: _statsLoading
                                ? const Center(child: CircularProgressIndicator())
                                : PieMoodChart(
                                    positive: _pos,
                                    neutral: _neu,
                                    negative: _neg,
                                  ),
                          ),
                          const SizedBox(width: 12),

                          // legend / 詳細數字（簡潔排列）
                          Expanded(
                            child: _StatsLegend(
                              positive: _pos,
                              neutral: _neu,
                              negative: _neg,
                              totalDays: _daysWithDiary,
                              onRefresh: _calcMonthStats,
                              loading: _statsLoading,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 2),
    );
  }

  // ====== 工具 ======
  String _fmt(DateTime dt) => DateFormat('yyyy-MM-dd').format(dt);

  // 依 mood 給 emoji
  static String _emoji(String? mood) {
    if (mood == null) return '';
    switch (mood.toLowerCase()) {
      case 'sunny':
      case 'positive':
      case 'happy':
        return '☀️';
      case 'cloudy':
      case 'neutral':
        return '⛅';
      case 'rain':
      case 'negative':
      case 'sad':
        return '🌧️';
      case 'storm':
        return '⛈️';
      case 'windy':
        return '🌬️';
      default:
        return '';
    }
  }

  // 解析 #RRGGBB（安全）
  static Color _hexColor(String? hex, {Color fallback = const Color(0xFFE2E8D5)}) {
    if (hex == null || hex.isEmpty) return fallback;
    try {
      final h = hex.replaceAll('#', '');
      if (h.length != 6) return fallback;
      return Color(int.parse('FF$h', radix: 16));
    } catch (_) {
      return fallback;
    }
  }

  // 骨架卡片
  static Widget _skeletonCard({double height = 60}) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E5E5)),
      ),
      child: const Center(
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}

// ------------------ 小元件：AI 卡 ------------------
class _AICard extends StatelessWidget {
  final String title;
  final String content;
  const _AICard({required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 96, 243, 162).withOpacity(.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF9CAF88).withOpacity(.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(content, style: const TextStyle(fontSize: 16, height: 1.4)),
        ],
      ),
    );
  }
}

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
          style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
        ),
      );
    }

    return CustomPaint(
      painter: _PiePainter(positive: positive, neutral: neutral, negative: negative),
      child: Center(
        child: Text(
          '$total',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
    final colors = [Colors.green.shade400, Colors.blueGrey.shade400, Colors.red.shade400];

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

// ------------------ 統計 Legend 與數字 ------------------
class _StatsLegend extends StatelessWidget {
  final int positive;
  final int neutral;
  final int negative;
  final int totalDays;
  final Future<void> Function()? onRefresh;
  final bool loading;

  const _StatsLegend({
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
            const Text('情緒占比', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
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
        const SizedBox(height: 4),
        Text(total > 0 ? '已統計 $total 天' : '本月尚無日記', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
        const SizedBox(height: 6),

        // 三個 legend（字級縮小）
        _legendRow('正向', Colors.green.shade400, positive, total),
        const SizedBox(height: 4),
        _legendRow('中性', Colors.blueGrey.shade400, neutral, total),
        const SizedBox(height: 4),
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
        Text('$count 天', style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
        const SizedBox(width: 6),
        Text('$pct%', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
