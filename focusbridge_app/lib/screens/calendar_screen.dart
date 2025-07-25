// lib/screens/calendar_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:focusbridge_app/widgets/app_bottom_nav.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _currentMonth = DateTime.now();

  void _prevMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final monthLabel = DateFormat('MMMM').format(_currentMonth);
    return Scaffold(
      appBar: AppBar(
        title: const Text('月曆日記'),
        backgroundColor: const Color(0xFF9CAF88),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 月份切換
            Container(
              color: const Color(0xFF9CAF88),
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: _prevMonth,
                    color: Colors.white,
                  ),
                  Text(
                    monthLabel.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward),
                    onPressed: _nextMonth,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
            // 星期標題
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
                    .map((d) => Expanded(
                          child: Center(
                              child: Text(
                            d,
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w600),
                          )),
                        ))
                    .toList(),
              ),
            ),
            // 日曆格子
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final daysInMonth = DateUtils.getDaysInMonth(
                        _currentMonth.year, _currentMonth.month);
                    final firstWeekday = DateTime(
                            _currentMonth.year, _currentMonth.month, 1)
                        .weekday; // 1=Mon
                    final totalCells = ((firstWeekday - 1) + daysInMonth);
                    final rows = (totalCells / 7).ceil();

                    return Column(
                      children: List.generate(rows, (rowIndex) {
                        return Expanded(
                          child: Row(
                            children: List.generate(7, (colIndex) {
                              final cellIndex = rowIndex * 7 + colIndex;
                              final dayNum = cellIndex - (firstWeekday - 2);
                              final isInMonth = dayNum >= 1 && dayNum <= daysInMonth;
                              return Expanded(
                                child: Container(
                                  margin: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                      width: 0.5,
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Center(
                                    child: Text(
                                      isInMonth ? dayNum.toString() : '',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isInMonth
                                            ? Colors.black87
                                            : Colors.transparent,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                        );
                      }),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 8),
            // 寫今天日記按鈕
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
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF9CAF88),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24)),
                  ),
                  child: const Text('寫今日日記', style: TextStyle(fontSize: 16)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // AI 分析 & 建議
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('AI 分析',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w600)),
                          SizedBox(height: 8),
                          Text('系統會對您的日記進行情感與關鍵字分析。',
                              style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('AI 建議',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w600)),
                          SizedBox(height: 8),
                          Text('根據您的情緒與日記提供小建議。',
                              style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNav(currentIndex: 2),
    );
  }
}
