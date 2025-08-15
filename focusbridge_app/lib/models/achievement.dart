// lib/models/achievement.dart
class AchievementItem {
  final String id;
  final String title;        // 後端: "title"
  final String desc;         // 後端: "desc"
  final int amount;          // 後端: "amount"（情緒餘額）
  final bool isDaily;        // 後端: "is_daily"
  final bool claimable;      // 後端: "claimable"
  final bool claimedToday;   // 後端: "claimed_today"（僅每日型用）
  final bool unlocked;       // 後端: "unlocked"（里程碑是否已領）

  AchievementItem({
    required this.id,
    required this.title,
    required this.desc,
    required this.amount,
    required this.isDaily,
    required this.claimable,
    required this.claimedToday,
    required this.unlocked,
  });

  factory AchievementItem.fromJson(Map<String, dynamic> json) {
    return AchievementItem(
      id: json['id'] as String,
      title: (json['title'] ?? '').toString(),
      desc: (json['desc'] ?? '').toString(),
      amount: (json['amount'] as num?)?.toInt() ?? 0,
      isDaily: json['is_daily'] as bool? ?? false,
      claimable: json['claimable'] as bool? ?? false,
      claimedToday: json['claimed_today'] as bool? ?? false,
      unlocked: json['unlocked'] as bool? ?? false,
    );
  }
}
