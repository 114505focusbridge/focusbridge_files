// lib/models/diary_overview.dart
class DiaryOverview {
  final DateTime date;
  final String? mood;
  final String? colorHex;
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
