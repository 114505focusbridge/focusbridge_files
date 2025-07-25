// lib/screens/achievements_screen.dart

import 'package:flutter/material.dart';
import 'package:focusbridge_app/models/achievement.dart';
import 'package:focusbridge_app/widgets/app_bottom_nav.dart';


class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  // 假資料：每日任務
  List<Achievement> get _dailyTasks => [
        Achievement(
          id: 'write_note',
          title: '小記開張',
          description: '今天的小記字數達到 50 字！',
          progress: 0.9,
          unlocked: false,
        ),
        Achievement(
          id: 'photo_master',
          title: '攝影大師',
          description: '新增一張你拍的照片。',
          progress: 1.0,
          unlocked: true,
        ),
        Achievement(
          id: 'revisit_memory',
          title: '重溫回憶',
          description: '回顧至少一次小記。',
          progress: 0.6,
          unlocked: false,
        ),
      ];

  // 假資料：已解鎖的成就
  List<Achievement> get _unlockedAchievements => [
        Achievement(
          id: 'first_note',
          title: '萬事起頭難',
          description: '第一次記錄自己的心情。',
          unlocked: true,
        ),
        Achievement(
          id: 'happy_collector',
          title: '快樂收藏家',
          description: '記錄過 10 次「快樂」情緒。',
          unlocked: true,
        ),
        Achievement(
          id: 'consistent_keep',
          title: '堅持不懈者',
          description: '連續記錄 7 天以上。',
          unlocked: true,
        ),
        // …更多
      ];

  @override
  Widget build(BuildContext context) {
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
            // 每日任務
            const Text(
              '每日任務',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            for (var task in _dailyTasks)
              _buildTaskCard(task),
            const SizedBox(height: 24),

            // 已達成的成就
            const Text(
              '已達成的成就',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
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
      bottomNavigationBar: AppBottomNav(currentIndex: 1), // achievements 索引
    );
  }

  // 任務區塊：卡片 + 進度條
  Widget _buildTaskCard(Achievement task) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Row(
          children: [
            Icon(
              Icons.emoji_events,
              size: 32,
              color: task.unlocked ? Colors.orange : Colors.grey,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight:
                          task.unlocked ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(task.description, style: const TextStyle(fontSize: 14)),
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
            Text(
              '${(task.progress * 100).round()}%',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  // 成就徽章：小卡片
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
          Icon(Icons.emoji_events, color: Colors.green, size: 28),
          const SizedBox(height: 8),
          Text(
            ach.title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(ach.description, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
