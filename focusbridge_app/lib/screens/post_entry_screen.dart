// lib/screens/post_entry_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:focusbridge_app/widgets/app_bottom_nav.dart';
import 'package:focusbridge_app/services/auth_service.dart';
import 'package:focusbridge_app/models/achievement.dart'; // 要使用 AchievementItem 版本

// 實機+USB: http://127.0.0.1:8000（先 adb reverse tcp:8000 tcp:8000）
// 模擬器:     http://10.0.2.2:8000
const String _base = 'http://127.0.0.1:8000';

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
          title: const Text('🎉 有獎勵可以領！'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('以下成就已達成，記得前往領取情緒餘額：'),
              const SizedBox(height: 8),
              ...top.map((a) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text('• ${a.title}（+${a.amount}）'),
                  )),
              if (claimables.length > top.length)
                Text('…還有 ${claimables.length - top.length} 項'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('稍後'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/achievements');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF9CAF88),
              ),
              child: const Text('去領取'),
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
      appBar: AppBar(
        title: const Text('存入成功！'),
        backgroundColor: const Color(0xFF9CAF88),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              color: const Color(0xFF9CAF88),
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              child: Column(
                children: [
                  const Text(
                    '日記已成功送出！',
                    style: TextStyle(
                      fontSize: 24,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '你標記的情緒：「${widget.emotionLabel}」',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: widget.emotionColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
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
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildInfoCard(
                        icon: Icons.insights,
                        title: '情緒評估',
                        content: translatedLabel,
                        iconColor: Colors.blue,
                      ),
                      const SizedBox(height: 16),
                      _buildInfoCard(
                        icon: Icons.favorite,
                        title: 'AI 心理師建議',
                        content: aiMessageText,
                        iconColor: Colors.pink,
                      ),
                      const SizedBox(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          OutlinedButton(
                            onPressed: () => Navigator.popUntil(
                              context,
                              ModalRoute.withName('/home'),
                            ),
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                            ),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              child: Text('返回主頁'),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pushNamed(context, '/diary_entry');
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF9CAF88),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                            ),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              child: Text('再次紀錄'),
                            ),
                          ),
                        ],
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
      bottomNavigationBar: const AppBottomNav(currentIndex: 0),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String content,
    required Color iconColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text(content, style: const TextStyle(fontSize: 15)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
