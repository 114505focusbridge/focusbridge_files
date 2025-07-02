// lib/models/achievement.dart

class Achievement {
  final String id;
  final String title;
  final String description;
  final double progress; // 0.0～1.0
  final bool unlocked;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    this.progress = 0,
    this.unlocked = false,
  });
}
