// lib/models/todo.dart
import 'package:flutter/material.dart';

/// 今日備忘錄 / To-Do 資料模型
///
/// 對應後端 DRF 欄位：
/// - id: int
/// - user: int (唯讀，後端自動帶入；前端通常不需要傳)
/// - title: string
/// - date: "YYYY-MM-DD"
/// - time: "HH:MM" 或 "HH:MM:SS"（可為 null）
/// - is_done: bool
/// - created_at: ISO-8601 datetime
/// - remind_at: ISO-8601 datetime（可為 null；若未啟用可忽略）
class Todo {
  final int? id;
  final int? userId;
  final String title;
  final DateTime date;
  final TimeOfDay? time;
  final bool isDone;
  final DateTime? createdAt;
  final DateTime? remindAt;

  const Todo({
    this.id,
    this.userId,
    required this.title,
    required this.date,
    this.time,
    this.isDone = false,
    this.createdAt,
    this.remindAt,
  });

  /// 從 API JSON 轉模型
  factory Todo.fromJson(Map<String, dynamic> json) {
    final String? timeStr = json['time'];
    final String dateStr = json['date'];
    return Todo(
      id: json['id'],
      userId: json['user'], // 後端若未回傳可為 null
      title: (json['title'] ?? '').toString(),
      date: _parseApiDate(dateStr),
      time: _parseApiTime(timeStr),
      isDone: json['is_done'] == true,
      createdAt: _tryParseDateTime(json['created_at']),
      remindAt: _tryParseDateTime(json['remind_at']),
    );
  }

  /// 建立新 To-Do 的 payload（POST）
  Map<String, dynamic> toCreateJson() {
    final map = <String, dynamic>{
      'title': title.trim(),
      'date': dateToApi(date),
    };
    final t = timeOfDayToApi(time);
    if (t != null) map['time'] = t;
    // is_done 預設由後端給 false，不必傳
    return map;
  }

  /// 完整更新的 payload（PUT/PATCH）— 覆蓋所有欄位時可用
  Map<String, dynamic> toUpdateJson() {
    final map = <String, dynamic>{
      'title': title.trim(),
      'date': dateToApi(date),
      'is_done': isDone,
    };
    final t = timeOfDayToApi(time);
    map['time'] = t; // 允許為 null，以清空時間
    return map;
  }

  /// 僅切換完成狀態（PATCH）
  static Map<String, dynamic> patchIsDone(bool isDone) => {
        'is_done': isDone,
      };

  /// UI 友善：時間字串（例如 09:05；無時間則回傳空字串）
  String get timeText => time == null ? '' : '${_pad2(time!.hour)}:${_pad2(time!.minute)}';

  /// UI 友善：日期字串（YYYY-MM-DD）
  String get dateText => dateToApi(date);

  get hasTime => null;

  get completed => null;

  get done => null;

  /// 複製（immutable）
  Todo copyWith({
    int? id,
    int? userId,
    String? title,
    DateTime? date,
    TimeOfDay? time,
    bool? isDone,
    DateTime? createdAt,
    DateTime? remindAt,
  }) {
    return Todo(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      date: date ?? this.date,
      time: time ?? this.time,
      isDone: isDone ?? this.isDone,
      createdAt: createdAt ?? this.createdAt,
      remindAt: remindAt ?? this.remindAt,
    );
  }

  /// 依後端邏輯的排序：未完成在前 -> 時間（NULL 放最後）-> 建立時間
  static int compare(Todo a, Todo b) {
    // 未完成在前：false(0) < true(1)
    final doneA = a.isDone ? 1 : 0;
    final doneB = b.isDone ? 1 : 0;
    if (doneA != doneB) return doneA - doneB;

    // 時間：有時間在前、再比較時分；null 放最後
    final ta = a.time;
    final tb = b.time;
    if (ta == null && tb != null) return 1; // a 往後
    if (ta != null && tb == null) return -1; // a 在前
    if (ta != null && tb != null) {
      final ma = ta.hour * 60 + ta.minute;
      final mb = tb.hour * 60 + tb.minute;
      if (ma != mb) return ma - mb;
    }

    // 建立時間：早的在前
    final ca = a.createdAt?.millisecondsSinceEpoch ?? 0;
    final cb = b.createdAt?.millisecondsSinceEpoch ?? 0;
    return ca - cb;
  }
}

/// ===== 時間/日期 轉換工具 =====

/// 將 DateTime 轉成 API 需要的 "YYYY-MM-DD"
String dateToApi(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${_pad2(d.month)}-${_pad2(d.day)}';

/// 將 TimeOfDay 轉成 API 需要的 "HH:MM"；若為 null 回傳 null
String? timeOfDayToApi(TimeOfDay? t) =>
    t == null ? null : '${_pad2(t.hour)}:${_pad2(t.minute)}';

/// 解析 API 的日期字串（"YYYY-MM-DD"）
DateTime _parseApiDate(String s) => DateTime.parse(s);

/// 解析 API 的時間字串（"HH:MM" 或 "HH:MM:SS"）
TimeOfDay? _parseApiTime(String? s) {
  if (s == null || s.isEmpty) return null;
  final parts = s.split(':');
  if (parts.length < 2) return null;
  final h = int.tryParse(parts[0]) ?? 0;
  final m = int.tryParse(parts[1]) ?? 0;
  return TimeOfDay(hour: h, minute: m);
}

/// 嘗試解析 ISO-8601 日期時間（可能為 null）
DateTime? _tryParseDateTime(dynamic v) {
  if (v == null) return null;
  try {
    return DateTime.parse(v.toString());
  } catch (_) {
    return null;
  }
}

String _pad2(int n) => n.toString().padLeft(2, '0');
