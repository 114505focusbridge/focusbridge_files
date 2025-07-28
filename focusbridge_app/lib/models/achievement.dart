// lib/models/achievement.dart
class Achievement {
  final String id;
  final String achTitle;
  final String achContent;
  final double progress;
  final bool unlocked;
  final bool isDaily;

  Achievement({
    required this.id,
    required this.achTitle,
    required this.achContent,
    required this.progress,
    required this.unlocked,
    required this.isDaily,
  });

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'] as String,
      achTitle: json['ach_title'] as String,
      achContent: json['ach_content'] as String,
      progress: (json['progress'] as num).toDouble(),
      unlocked: json['unlocked'] as bool,
      isDaily: json['is_daily'] as bool,
    );
  }
}

