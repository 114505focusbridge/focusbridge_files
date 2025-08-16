// lib/screens/calendar_screen.dart
//
// 更新：把底部兩張靜態 AI 卡，改成「本月情緒統計」統計卡。
// 統計流程：先取當月 overview -> 找出有日記的日期 -> 逐日 call by-date 抓 sentiment 累計。
// 依賴：DiaryService.fetchMonthOverview / fetchDiaryByDate

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:focusbridge_app/widgets/app_bottom_nav.dart';
import 'package:focusbridge_app/services/diary_service.dart';

/// 月曆格需要的最小資訊（概覽）
class DiaryOverview {
  final DateTime date;
  final String? mood;       // 'sunny' | 'cloudy' | 'rain' | ...
  final String? colorHex;   // 例: '#EEDC82'
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

    // 先載到概覽，再根據有日記的日期做統計
    _calcMonthStats();
  }

  // ====== 計算本月情緒統計 ======
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
          // 單日失敗略過
        }
        if (!mounted) return;
        // 每 N 筆刷新一次，避免長時間不更新 UI
        if ((_pos + _neu + _neg) % 5 == 0) {
          setState(() {});
        }
      }
    } finally {
      if (mounted) setState(() => _statsLoading = false);
    }
  }

  // ====== 互動：點某天顯示 BottomSheet（內含 FutureBuilder 取全文） ======
  void _onDayTap(DateTime date) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFF6F4E9),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final title = DateFormat('yyyy/MM/dd (EEE)', 'zh_TW').format(date);
        final ov = _overviewByDate[_fmt(date)];
        final noDiaryFromOverview = (ov == null || !ov.hasDiary);

        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            top: 16,
          ),
          child: FutureBuilder<Map<String, dynamic>?>(
            future: DiaryService.fetchDiaryByDate(date),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Text(title,
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w700)),
                        const Spacer(),
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
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
                    Text(title,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Text('讀取失敗：${snapshot.error}',
                        style:
                            const TextStyle(fontSize: 14, color: Colors.red)),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () => Navigator.pop(ctx),
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
                    Text(title,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    const Text('這天尚未留下日記。', style: TextStyle(fontSize: 14)),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () {
                        Navigator.pop(ctx);
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
                      child: const Text('補寫這天的日記'),
                    ),
                  ],
                );
              }

              final mood = (detail['mood'] ?? detail['emotion']) as String?;
              final colorHex =
                  (detail['color'] ?? detail['mood_color']) as String?;
              final emoji = _emoji(mood);
              final moodColor = _hexColor(colorHex);
              final content = (detail['content'] ?? '') as String? ?? '';
              final titleText = (detail['title'] ?? '') as String? ?? '';
              final aiText = (detail['ai_analysis'] ??
                      detail['ai_message'] ??
                      '（暫無 AI 分析）') as String?;

              final diaryId = (detail['id'] as num?)?.toInt();

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Text(title,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w700)),
                      const Spacer(),
                      if (emoji.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: moodColor.withOpacity(.18),
                            borderRadius: BorderRadius.circular(20),
                            border:
                                Border.all(color: moodColor.withOpacity(.4)),
                          ),
                          child: Row(
                            children: [
                              Text(emoji, style: const TextStyle(fontSize: 16)),
                              const SizedBox(width: 6),
                              Text(mood ?? '',
                                  style: const TextStyle(fontSize: 12)),
                            ],
                          ),
                        ),
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
                                style: const TextStyle(
                                    fontSize: 15, fontWeight: FontWeight.w700)),
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
                  _AICard(
                    title: 'AI 回饋',
                    content: aiText ?? '（暫無 AI 回饋）',
                  ),

                  const SizedBox(height: 14),

                  // 動作
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            Navigator.pushNamed(context, '/diary_entry',
                                arguments: {
                                  'emotion': mood ?? '',
                                  'color': moodColor,
                                  'date': date,
                                  'diaryId': diaryId,
                                });
                          },
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                                color:
                                    const Color(0xFF9CAF88).withOpacity(.8)),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          child: const Text('查看 / 編輯'),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
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
    final totalCells = ((firstWeekday - 1) + daysInMonth);
    final rows = (totalCells / 7).ceil();

    return Scaffold(
      appBar: AppBar(
        title: const Text('月曆日記'),
        backgroundColor: const Color(0xFF9CAF88),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 月份切換列
            Container(
              color: const Color(0xFF9CAF88),
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: _prevMonth,
                      color: Colors.white),
                  Text(monthLabel,
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                  IconButton(
                      icon: const Icon(Icons.arrow_forward),
                      onPressed: _nextMonth,
                      color: Colors.white),
                ],
              ),
            ),

            // 星期標題（週一到週日）
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  '一', '二', '三', '四', '五', '六', '日'
                ].map((d) {
                  return Expanded(
                    child: Center(
                      child: Text(d,
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                  );
                }).toList(),
              ),
            ),

            // 日曆格
            Expanded(
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      children: List.generate(rows, (rowIndex) {
                        return Expanded(
                          child: Row(
                            children: List.generate(7, (colIndex) {
                              final cellIndex = rowIndex * 7 + colIndex;
                              final dayNum = cellIndex - (firstWeekday - 2);
                              final isInMonth =
                                  dayNum >= 1 && dayNum <= daysInMonth;

                              if (!isInMonth) {
                                return const Expanded(child: SizedBox.shrink());
                              }

                              final date = DateTime(_currentMonth.year,
                                  _currentMonth.month, dayNum);
                              final key = _fmt(date);
                              final ov = _overviewByDate[key];
                              final isToday = _fmt(date) == _fmt(DateTime.now());

                              return Expanded(
                                child: GestureDetector(
                                  onTap: () => _onDayTap(date),
                                  child: Container(
                                    margin: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: isToday
                                            ? const Color(0xFF9CAF88)
                                            : Colors.grey.shade300,
                                        width: isToday ? 1.2 : 0.5,
                                      ),
                                      borderRadius: BorderRadius.circular(6),
                                      color: Colors.white,
                                    ),
                                    child: Stack(
                                      children: [
                                        // 日期數字
                                        Positioned(
                                          top: 4,
                                          left: 6,
                                          child: Text(
                                            '$dayNum',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.grey.shade800,
                                            ),
                                          ),
                                        ),

                                        // 情緒 emoji（有日記才顯示）
                                        if (ov?.hasDiary == true &&
                                            _emoji(ov?.mood).isNotEmpty)
                                          Positioned(
                                            right: 6,
                                            bottom: 20,
                                            child: Text(_emoji(ov?.mood),
                                                style: const TextStyle(
                                                    fontSize: 16)),
                                          ),

                                        // 顏色條（代表當天的心情色調）
                                        if (ov?.hasDiary == true)
                                          Positioned(
                                            left: 4,
                                            right: 4,
                                            bottom: 6,
                                            child: Container(
                                              height: 5,
                                              decoration: BoxDecoration(
                                                color: _hexColor(ov?.colorHex),
                                                borderRadius:
                                                    BorderRadius.circular(3),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                        );
                      }),
                    ),
                  ),

                  // 載入中浮層
                  if (_isLoading)
                    Positioned.fill(
                      child: Container(
                        color: Colors.white.withOpacity(.4),
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // 寫今天日記
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                height: 48,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/diary_entry', arguments: {
                      'emotion': '',
                      'color': Colors.transparent,
                      'date': DateTime.now(),
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF9CAF88),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24)),
                  ),
                  child:
                      const Text('寫今日日記', style: TextStyle(fontSize: 16)),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // === 這裡：改成「本月情緒統計」卡 ===
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: EmotionStatsCard(
                pos: _pos,
                neu: _neu,
                neg: _neg,
                totalDays: _daysWithDiary,
                loading: _statsLoading,
                onRefresh: _calcMonthStats,
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 2),
    );
  }

  // ====== 工具 ======
  String _fmt(DateTime dt) => DateFormat('yyyy-MM-dd').format(dt);

  // 依 mood 給 emoji
  static String _emoji(String? mood) {
    switch (mood) {
      case 'sunny':
        return '☀️';
      case 'cloudy':
        return '⛅';
      case 'rain':
        return '🌧️';
      case 'storm':
        return '⛈️';
      case 'windy':
        return '🌬️';
      default:
        return '';
    }
  }

  // 解析 #RRGGBB
  static Color _hexColor(String? hex, {Color fallback = const Color(0xFFE2E8D5)}) {
    if (hex == null || hex.isEmpty) return fallback;
    final h = hex.replaceAll('#', '');
    if (h.length != 6) return fallback;
    return Color(int.parse('FF$h', radix: 16));
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

// 小元件：AI 卡（保留在每日詳情的 BottomSheet 內）
class _AICard extends StatelessWidget {
  final String title;
  final String content;
  const _AICard({required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF9CAF88).withOpacity(.18),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF9CAF88).withOpacity(.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(content, style: const TextStyle(fontSize: 12, height: 1.4)),
        ],
      ),
    );
  }
}

// 新元件：本月情緒統計卡
class EmotionStatsCard extends StatelessWidget {
  final int pos;
  final int neu;
  final int neg;
  final int totalDays;
  final bool loading;
  final Future<void> Function()? onRefresh;

  const EmotionStatsCard({
    super.key,
    required this.pos,
    required this.neu,
    required this.neg,
    required this.totalDays,
    required this.loading,
    this.onRefresh,
  });

  double _ratio(int v, int total) {
    if (total <= 0) return 0;
    final r = v / total;
    if (r.isNaN || r.isInfinite) return 0;
    return r.clamp(0.0, 1.0);
    }

  @override
  Widget build(BuildContext context) {
    final total = totalDays; // 以有日記的天數為分母

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E5E5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('本月情緒統計',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const Spacer(),
              if (loading)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                IconButton(
                  onPressed: onRefresh,
                  icon: const Icon(Icons.refresh, size: 18),
                  tooltip: '重新統計',
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            total > 0 ? '已統計 $total 天日記' : '本月尚未有日記',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 10),

          _barRow('😀 正向', pos, total,
              barColor: Colors.green.shade400),
          const SizedBox(height: 8),
          _barRow('😐 中立', neu, total,
              barColor: Colors.blueGrey.shade400),
          const SizedBox(height: 8),
          _barRow('😞 負向', neg, total,
              barColor: Colors.red.shade400),
        ],
      ),
    );
  }

  Widget _barRow(String label, int value, int total, {required Color barColor}) {
    final ratio = _ratio(value, total);
    final pctText = total > 0 ? '${(ratio * 100).round()}%' : '0%';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label,
                style:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const Spacer(),
            Text('$value 天 · $pctText',
                style: const TextStyle(fontSize: 12)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 8,
            backgroundColor: Colors.grey.shade200,
            color: barColor,
          ),
        ),
      ],
    );
  }
}
