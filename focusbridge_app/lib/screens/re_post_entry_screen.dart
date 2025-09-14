// lib/screens/re_post_entry_scren.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import 'package:focusbridge_app/widgets/app_bottom_nav.dart';
import 'package:focusbridge_app/services/auth_service.dart';
import 'package:focusbridge_app/widgets/glowing_button.dart';
import 'package:focusbridge_app/models/achievement.dart';

// 實機+USB: http://127.0.0.1:8000（先 adb reverse tcp:8000 tcp:8000）
// 模擬器:     http://10.0.2.2:8000
const String _base = 'http://127.0.0.1:8000';

// 定義你的顏色
const Color _bgColor = Color.fromRGBO(255, 253, 246, 1);
const Color _cardBgColor = Color.fromRGBO(250, 246, 233, 1);
const Color _borderColor = Color.fromRGBO(221, 235, 157, 1);
const Color _primaryColor = Color.fromRGBO(160, 200, 120, 1);

class RePostEntryScreen extends StatefulWidget {
  final String entryContent;
  final String aiLabel;
  final String aiMessage;

  const RePostEntryScreen({
    super.key,
    required this.entryContent,
    required this.aiLabel,
    required this.aiMessage,
  });

  @override
  State<RePostEntryScreen> createState() => _RePostEntryScreenState();
}

class _RePostEntryScreenState extends State<RePostEntryScreen> {
  @override
  void initState() {
    super.initState();
    _maybePromptClaimables();
  }

  Future<void> _maybePromptClaimables() async {
    final token = await AuthService.getToken();
    if (token == null) return;

    final url = Uri.parse('$_base/api/achievements/');
    try {
      final res = await http.get(url, headers: {'Authorization': 'Token $token'});
      if (res.statusCode != 200) return;

      final List raw = jsonDecode(utf8.decode(res.bodyBytes)) as List;
      final items = raw.map((e) => AchievementItem.fromJson(e as Map<String, dynamic>)).toList();

      final claimables = items.where((a) => a.claimable == true).toList();

      if (!mounted || claimables.isEmpty) return;

      final top = claimables.take(2).toList();
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: _bgColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: _borderColor, width: 2),
          ),
          title: const Text('🎉 有獎勵可以領！', style: TextStyle(color: Colors.black87)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('以下成就已達成，記得前往領取情緒餘額：', style: TextStyle(color: Colors.black87)),
              const SizedBox(height: 8),
              ...top.map((a) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text('• ${a.title}（+${a.amount}）', style: const TextStyle(color: Colors.black87)),
                  )),
              if (claimables.length > top.length)
                Text('…還有 ${claimables.length - top.length} 項', style: const TextStyle(color: Colors.black54)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(foregroundColor: _primaryColor),
              child: const Text('稍後'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/achievements');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('去領取', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    } catch (_) {
      // 靜默失敗
    }
  }

  String _translateLabel(String label) {
    switch (label.toLowerCase()) {
      case 'positive':
        return '😀 正向';
      case 'neutral':
        return '😐 中立';
      case 'negative':
        return '😞 負向';
      default:
        return '（無效的分析結果）';
    }
  }

  @override
  Widget build(BuildContext context) {
    final translatedLabel = _translateLabel(widget.aiLabel);
    final aiMessageText = widget.aiMessage.trim().isNotEmpty ? widget.aiMessage : '（AI 尚未回應建議）';

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color.fromARGB(175, 222, 255, 216), Colors.white],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
                child: Column(
                  children: [
                    const Icon(
                      Icons.check_circle_outline,
                      color: Color.fromARGB(255, 70, 166, 36),
                      size: 90,
                    ),
                    const SizedBox(height: 36),
                    const Text(
                      '日記已成功送出！',
                      style: TextStyle(
                        fontSize: 32,
                        color: Color.fromARGB(255, 70, 166, 36),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 12),
                        const Text(
                          'AI 分析結果',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildInfoCard(
                          icon: Icons.insights_rounded,
                          title: '情緒評估',
                          content: translatedLabel,
                          iconColor: _primaryColor.darken(20),
                        ),
                        const SizedBox(height: 16),
                        _buildInfoCard(
                          icon: Icons.lightbulb_outline_rounded,
                          title: 'AI 心理師建議',
                          content: aiMessageText,
                          iconColor: Colors.orange.shade400,
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: GlowingButton(
                            onPressed: () {
                              Navigator.pushNamedAndRemoveUntil(context, '/calendar', (route) => false);
                            },
                            baseColor: Colors.orange,
                            child: const Text(
                              '查看最近的心情',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 0),
    );
  }

  // ===== 輔助函式 =====

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String content,
    required Color iconColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardBgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  content,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.black54,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 因為是補寫日誌，所以不需要這個方法
  // Widget _buildMoodCard({
  //   required String title,
  //   required String emotionLabel,
  //   required Color emotionColor,
  // }) {
  //   // ... (省略原始程式碼)
  // }

  String _assetForEmotion(String emotion) {
    switch (emotion) {
      case '快樂':
        return 'assets/images/emotion_sun.png';
      case '悲傷':
        return 'assets/images/emotion_cloud.png';
      case '恐懼':
        return 'assets/images/emotio_lightning.png';
      case '憤怒':
        return 'assets/images/emotion_tornado.png';
      case '驚訝':
        return 'assets/images/emotion_snowflake.png';
      default:
        return 'assets/images/emotion_rain.png';
    }
  }

  Color _hexToColor(String hex) {
    final h = hex.replaceAll('#', '');
    if (h.length != 6) return Colors.blue.shade200;
    return Color(int.parse('FF$h', radix: 16));
  }
}

extension ColorExtension on Color {
  Color darken([int percent = 10]) {
    assert(1 <= percent && percent <= 100);
    final f = 1 - percent / 100;
    return Color.fromARGB(
      alpha,
      (red * f).round(),
      (green * f).round(),
      (blue * f).round(),
    );
  }
}
