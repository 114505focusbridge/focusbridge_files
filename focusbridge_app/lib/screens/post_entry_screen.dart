// lib/screens/post_entry_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:focusbridge_app/widgets/app_bottom_nav.dart';
import 'package:focusbridge_app/services/auth_service.dart';
import 'package:focusbridge_app/widgets/glowing_button.dart';
import 'package:focusbridge_app/models/achievement.dart'; // 要使用 AchievementItem 版本

// 實機+USB: http://127.0.0.1:8000（先 adb reverse tcp:8000 tcp:8000）
// 模擬器:     http://10.0.2.2:8000
const String _base = 'http://127.0.0.1:8000';

// 定義你的顏色
const Color _bgColor = Color.fromRGBO(255, 253, 246, 1); // 背景色
const Color _cardBgColor = Color.fromRGBO(250, 246, 233, 1); // 卡片背景色
const Color _borderColor = Color.fromRGBO(221, 235, 157, 1); // 邊框/次要強調色
const Color _primaryColor = Color.fromRGBO(160, 200, 120, 1); // 主色調（綠色）

class PostEntryScreen extends StatefulWidget {
  final String emotionLabel;
  final Color emotionColor;
  final String entryContent;
  final String aiLabel;
  final String aiMessage;

  const PostEntryScreen({
    super.key,
    required this.emotionLabel,
    required this.emotionColor,
    required this.entryContent,
    required this.aiLabel,
    required this.aiMessage,
  });

  @override
  State<PostEntryScreen> createState() => _PostEntryScreenState();
}

class _PostEntryScreenState extends State<PostEntryScreen> {
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
      final items = raw
          .map((e) => AchievementItem.fromJson(e as Map<String, dynamic>))
          .toList();

      // 找出目前「可領取」的成就（每日或里程碑）
      final claimables = items.where((a) => a.claimable == true).toList();

      if (!mounted || claimables.isEmpty) return;

      // 顯示引導使用者前往「成就頁」領取
      final top = claimables.take(2).toList(); // 最多列兩項，避免太長
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: _bgColor, // 對話框背景色
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: _borderColor, width: 2), // 增加邊框
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
              style: TextButton.styleFrom(foregroundColor: _primaryColor), // 按鈕文字顏色
              child: const Text('稍後'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/achievements');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor, // 主色調按鈕
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
      // 靜默失敗即可，避免影響主流程
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
    final aiMessageText =
        widget.aiMessage.trim().isNotEmpty ? widget.aiMessage : '（AI 尚未回應建議）';

    return Scaffold(
      // 使用漸層背景
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color.fromARGB(175, 222, 255, 216),Colors.white,], // 亮綠色到米白色的漸層
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // 頂部成功訊息區塊
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
                    const SizedBox(height: 20),
                    const Text(
                      '日記已成功送出！',
                      style: TextStyle(
                        fontSize: 32,
                        color: Color.fromARGB(255, 70, 166, 36),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // 情緒標記
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(0.4)),
                        // 動態生成發光陰影
                        boxShadow: [
                          BoxShadow(
                            color: widget.emotionColor.withOpacity(0.6),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '你標記的情緒：「${widget.emotionLabel}」',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: widget.emotionColor,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white.withOpacity(0.6), width: 1.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24), // 增加間距
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'AI 分析結果',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // AI 情緒評估卡片
                        _buildInfoCard(
                          icon: Icons.insights_rounded, // 更現代的圖標
                          title: '情緒評估',
                          content: translatedLabel,
                          iconColor: _primaryColor.darken(20), // 顏色調整
                        ),
                        const SizedBox(height: 16),
                        // AI 心理師建議卡片
                        _buildInfoCard(
                          icon: Icons.lightbulb_outline_rounded, // 更現代的圖標
                          title: 'AI 心理師建議',
                          content: aiMessageText,
                          iconColor: Colors.orange.shade400, // 顏色調整
                        ),
                        const SizedBox(height: 20), // 增加間距

                        // 發光的查看按鈕
                        SizedBox(
                          width: double.infinity,
                          child: GlowingButton(
                            onPressed: () {
                              Navigator.pushNamed(context, '/calendar');
                            },
                            baseColor: Colors.orange, // 設定為橘光
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

  // 輔助函式，用於建立信息卡片 (修改樣式)
  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String content,
    required Color iconColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20), // 增加內邊距
      decoration: BoxDecoration(
        color: _cardBgColor, // 使用卡片背景色
        borderRadius: BorderRadius.circular(16), // 更大的圓角
        border: Border.all(color: _borderColor, width: 1.5), // 邊框
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
          Icon(icon, color: iconColor, size: 28), // 圖標尺寸增大
          const SizedBox(width: 16), // 間距增大
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87)),
                const SizedBox(height: 8), // 間距增大
                Text(content, style: const TextStyle(fontSize: 15, color: Colors.black54, height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// 擴展 Color 類別，增加 darken 方法
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