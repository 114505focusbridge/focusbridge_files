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
import 'package:focusbridge_app/widgets/pie_mood_chart.dart'; 
import 'package:focusbridge_app/widgets/stats_legend.dart';

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

String _translateMood(String? mood) {
  if (mood == null) return '';
  switch (mood.toLowerCase()) {
    case 'sunny':
      return '快樂';
    case 'storm':
      return '憤怒';
    case 'cloud':
      return '悲傷';
    case 'lightning':
      return '恐懼';
    case 'snowflake':
      return '驚訝';
    case 'rain':
      return '厭惡';
    default:
      return '';
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
                        final moodColor = _hexColor(colorHex);
                        final content = (detail['content'] ?? '') as String? ?? '';
                        final titleText = (detail['title'] ?? '') as String? ?? '';
                        final aiText = (detail['ai_analysis'] ?? detail['ai_message'] ?? '（暫無 AI 分析）') as String?;
                        final diaryId = (detail['id'] as num?)?.toInt();

                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start, // 統一靠左對齊
                          children: [
                            // --- 情緒標題與圖示 ---
                            if (mood != null && mood.isNotEmpty)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // 情緒標題 (文字)
                                  Text(
                                    _translateMood(mood), // 使用翻譯後的中文標題
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 8.0),

                                  // 情緒圖示 (帶有底色的正方形外框)
                                  Container(
                                    width: 150,
                                    height: 150,
                                    decoration: BoxDecoration(
                                      color: moodColor.withOpacity(0.18),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: moodColor.withOpacity(0.5), width: 1.5),
                                    ),
                                    alignment: Alignment.center,
                                    child: Image.asset(
                                      _assetForEmotion(mood),
                                      width: 100,
                                      height: 100,
                                      color: moodColor,
                                    ),
                                  ),
                                ],
                              ),

                            const SizedBox(height: 16), // 在圖示區塊和日記內容之間增加間距

                            // --- 日記內容卡片 ---
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
                                      child: Text(
                                        titleText,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  Text(
                                    content.isEmpty ? '（無內容）' : content,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      height: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),

                            // --- AI 區塊 ---
                            _AICard(title: 'AI 回饋', content: aiText ?? '（暫無 AI 回饋）'),

                            const SizedBox(height: 24),

                            // --- 動作按鈕 ---
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
                                    baseColor: const Color.fromARGB(188, 24, 220, 255),
                                    child: const Text(
                                      '編輯心情日記',
                                      style: TextStyle(
                                        color: Color.fromARGB(255, 255, 255, 255),
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                      ),
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
                                    padding: const EdgeInsets.all(6),
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
                                    child: LayoutBuilder(builder: (c, constraints) {
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

                                          // --- 新增情緒圖示 ---
                                          Expanded(
                                            child: Center(
                                              child: ov?.hasDiary == true && _assetForEmotion(ov?.mood ?? '').isNotEmpty
                                                  ? FittedBox(
                                                      fit: BoxFit.scaleDown,
                                                      child: Image.asset(
                                                        _assetForEmotion(ov!.mood!),
                                                        width: 50,
                                                        height: 50,
                                                        color: _hexColor(ov.colorHex),
                                                      ),
                                                    )
                                                  : const SizedBox.shrink(),
                                            ),
                                          ),

                                          // 如果沒有日記，放一個佔位用的 SizedBox，保持格子高度一致
                                          const SizedBox(height: 6),
                                        ],
                                      );
                                    }
                                   ),
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
                            child: StatsLegend(
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

  String _assetForEmotion(String emotion) {
  switch (emotion) {
    case 'sunny':
      return 'assets/images/emotion_sun.png';
    case 'storm':
      return 'assets/images/emotion_tornado.png';
    case 'cloud':
        return 'assets/images/emotion_cloud.png';
    case 'lightning':
      return 'assets/images/emotion_lightning.png';
    case 'snowflake':
      return 'assets/images/emotion_snowflake.png';
    case 'rain':
        return 'assets/images/emotion_rain.png';
    
    default:
      // 如果沒有匹配到任何情緒，回傳一個預設的圖片
      return 'assets/images/emotion_foggy.png';
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

// ------------------ 小元件：AI 卡 (已修改) ------------------
class _AICard extends StatelessWidget {
  final String title;
  final String content;
  final String? emotion;
  final String? moodColor;

  const _AICard({
    required this.title,
    required this.content,
    this.emotion,
    this.moodColor,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasEmotion = emotion != null && emotion!.isNotEmpty && _assetForEmotion(emotion!) != 'assets/images/emotion_cloud.png';

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
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ),
              if (hasEmotion)
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(6.0),
                    child: Image.asset(
                      _assetForEmotion(emotion!),
                      color: moodColor != null ? _hexToColor(moodColor!) : null,
                      colorBlendMode: BlendMode.srcIn,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(content, style: const TextStyle(fontSize: 16, height: 1.4)),
        ],
      ),
    );
  }

  String _assetForEmotion(String emotion) {
    switch (emotion) {
      case 'sunny':
      return 'assets/images/emotion_sun.png';
    case 'storm':
      return 'assets/images/emotion_tornado.png';
    case 'cloud':
        return 'assets/images/emotion_cloud.png';
    case 'lightning':
      return 'assets/images/emotion_lightning.png';
    case 'snowflake':
      return 'assets/images/emotion_snowflake.png';
    case 'rain':
        return 'assets/images/emotion_rain.png';
      default:
        return 'assets/images/emotion_foggy.png';
    }
  }

  Color _hexToColor(String hex) {
    final h = hex.replaceAll('#', '');
    if (h.length != 6) return Colors.blue.shade200;
    return Color(int.parse('FF$h', radix: 16));
  }
}

