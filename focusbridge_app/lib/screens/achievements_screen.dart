import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:focusbridge_app/models/achievement.dart';
import 'package:focusbridge_app/widgets/app_bottom_nav.dart';
import 'package:focusbridge_app/services/auth_service.dart'; // 引入 AuthService

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  List<Achievement> _dailyTasks = [];
  List<Achievement> _unlockedAchievements = [];
  List<Achievement> _lockedAchievements = [];
  Achievement? _justUnlocked;

  @override
  void initState() {
    super.initState();
    _loadAchievements();
  }

  Future<void> _loadAchievements() async {
    final token = await AuthService.getToken(); // ✅ 從 SharedPreferences 取得 token
    if (token == null) {
      debugPrint('⚠️ 尚未登入，無法取得 token');
      return;
    }

    final url = Uri.parse('http://10.0.2.2:8000/api/achievements/'); // ✅ 改正網址

    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Token $token'}, // ✅ 注意：Token 而不是 Bearer
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);

        final daily = <Achievement>[];
        final unlocked = <Achievement>[];
        final locked = <Achievement>[];
        Achievement? justUnlocked;

        for (var item in data) {
          final ach = Achievement.fromJson(item);
          if (ach.isDaily) {
            daily.add(ach);
          } else if (ach.unlocked) {
            unlocked.add(ach);
            if (item['just_unlocked'] == true) {
              justUnlocked = ach;
            }
          } else {
            locked.add(ach);
          }
        }

        setState(() {
          _dailyTasks = daily;
          _unlockedAchievements = unlocked;
          _lockedAchievements = locked;
          _justUnlocked = justUnlocked;
        });

        if (justUnlocked != null && context.mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
          });
        }
      } else {
        debugPrint('❌ 取得成就失敗：${response.body}');
      }
    } catch (e) {
      debugPrint('❌ 發生錯誤：$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final _ = _justUnlocked;
    return Scaffold(
      appBar: AppBar(
        title: const Text('成就'),
        backgroundColor: const Color(0xFF9CAF88),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          children: [
            _buildOverviewCard(),
            const SizedBox(height: 24),
            _buildSectionTitle('每日任務'),
            for (var task in _dailyTasks) _buildTaskCard(task),
            const SizedBox(height: 24),
            _buildSectionTitle('未解鎖的成就'),
            for (var ach in _lockedAchievements) _buildTaskCard(ach),
            const SizedBox(height: 24),
            _buildSectionTitle('已達成的成就'),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (var ach in _unlockedAchievements)
                  _buildAchievementBadge(ach),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNav(currentIndex: 1),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildOverviewCard() {
    final hasCompletedDaily =
        _dailyTasks.any((task) => task.unlocked == true);
    final emoji = hasCompletedDaily ? '🎉' : '📌';
    final title =
        hasCompletedDaily ? '今日任務完成！' : '還沒完成今日任務～';
    final subtitle = hasCompletedDaily
        ? '太棒了！繼續保持記錄好習慣～'
        : '記得去完成你的每日任務唷，加油！';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F8E9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 32)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(Achievement task) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Row(
          children: [
            Icon(Icons.emoji_events,
                size: 32, color: task.unlocked ? Colors.orange : Colors.grey),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(task.achTitle,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight:
                            task.unlocked ? FontWeight.bold : FontWeight.normal,
                      )),
                  const SizedBox(height: 4),
                  Text(task.achContent,
                      style: const TextStyle(fontSize: 14)),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: task.progress,
                    backgroundColor: Colors.grey.shade300,
                    color: task.unlocked ? Colors.orange : Colors.green,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text('${(task.progress * 100).round()}%',
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementBadge(Achievement ach) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.emoji_events, color: Colors.green, size: 28),
          const SizedBox(height: 8),
          Text(ach.achTitle,
              style:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(ach.achContent, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
