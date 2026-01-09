// lib/services/diary_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class DiaryService {
  // 模擬器： http://10.0.2.2:8000
  // 真機 + adb reverse： http://127.0.0.1:8000
  // 區網/雲端： http://<你的IP或網域>:8000
  static const String baseUrl = 'http://127.0.0.1:8000'; // ← 沒有尾斜線

  // ---------------- 工具 ----------------
  static Future<Map<String, String>> _authHeaders({bool json = true}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) {
      throw Exception('尚未登入，請重新登入後再試一次');
    }
    final headers = <String, String>{
      'Accept': 'application/json',
      'Authorization': 'Token $token',
    };
    if (json) headers['Content-Type'] = 'application/json';
    return headers;
  }

  static dynamic _jsonDecodeUtf8(http.Response r) =>
      jsonDecode(utf8.decode(r.bodyBytes));

  static String _fmtDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  // ---------------- 建立 / 更新同一天（後端 upsert） ----------------
  /// 建立或更新當天日記，並回傳 AI 分析結果
  /// - [date] 不傳則後端以今天為準
  static Future<Map<String, dynamic>> createDiary({
    required String content,
    String? emotion, // 相容舊欄位
    DateTime? date,
    String? mood,
    String? moodColor,     // 例：'#EEDC82'
    String? weatherIcon,   // 例：'sunny'
    String? title,
  }) async {
    try {
      final headers = await _authHeaders(json: true);
      final url = Uri.parse('$baseUrl/api/diaries/');

      final body = <String, dynamic>{
        'content': content,
        if (title != null) 'title': title,
        if (emotion != null) 'emotion': emotion,
        if (date != null) 'date': _fmtDate(date),
        if (mood != null) 'mood': mood,
        if (moodColor != null) 'mood_color': moodColor,
        if (weatherIcon != null) 'weather_icon': weatherIcon,
      };

      final response =
          await http.post(url, headers: headers, body: jsonEncode(body));

      final text = utf8.decode(response.bodyBytes);
      final Map<String, dynamic> data =
          text.isNotEmpty ? (jsonDecode(text) as Map<String, dynamic>) : {};

      // 成功：新增(201) 或 更新(200)
      if (response.statusCode == 201 || response.statusCode == 200) {
        return {
          'success': true,
          'id': data['id'],
          'label': (data['label'] ?? '').toString(),
          'ai_message': (data['ai_message'] ?? '').toString(),
          'updated': data['updated'] == true, // true 代表這次是更新
        };
      }

      // 可選：若後端改成 409 表示已存在
      if (response.statusCode == 409) {
        return {
          'success': false,
          'exists': true,
          'diaryId': data['id'],
          'error': '當天已經有日記',
        };
      }

      return {
        'success': false,
        'error': '儲存失敗（${response.statusCode}）：$text',
      };
    } catch (e) {
      return {'success': false, 'error': '無法連線到伺服器，請稍後再試：$e'};
    }
  }

  // ---------------- 更新（PATCH） ----------------
  static Future<Map<String, dynamic>> updateDiary({
    required int id,
    String? content,
    String? title,
    DateTime? date,
    String? mood,
    String? moodColor,
    String? weatherIcon,
  }) async {
    try {
      final headers = await _authHeaders(json: true);
      final url = Uri.parse('$baseUrl/api/diaries/$id/');

      final body = <String, dynamic>{
        if (content != null) 'content': content,
        if (title != null) 'title': title,
        if (date != null) 'date': _fmtDate(date),
        if (mood != null) 'mood': mood,
        if (moodColor != null) 'mood_color': moodColor,
        if (weatherIcon != null) 'weather_icon': weatherIcon,
      };

      final response =
          await http.patch(url, headers: headers, body: jsonEncode(body));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = _jsonDecodeUtf8(response) as Map<String, dynamic>;
        return {'success': true, 'data': data};
      } else {
        final errText = utf8.decode(response.bodyBytes);
        return {'success': false, 'error': '更新失敗（${response.statusCode}）：$errText'};
      }
    } catch (e) {
      return {'success': false, 'error': '無法連線到伺服器：$e'};
    }
  }

  // ---------------- 取得全部列表（可選） ----------------
  static Future<List<Map<String, dynamic>>> fetchDiaries() async {
    final headers = await _authHeaders(json: false);
    final url = Uri.parse('$baseUrl/api/diaries/');
    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      final decoded = _jsonDecodeUtf8(response);
      return List<Map<String, dynamic>>.from(decoded as List);
    } else {
      final errText = utf8.decode(response.bodyBytes);
      throw Exception('取得日記失敗（${response.statusCode}）：$errText');
    }
  }

  // ---------------- 月概覽（給月曆） ----------------
  /// GET /api/diaries/overview/?month=YYYY-MM
  static Future<List<Map<String, dynamic>>> fetchMonthOverview(
      String yyyyMm) async {
    final headers = await _authHeaders(json: false);
    final url = Uri.parse('$baseUrl/api/diaries/overview/?month=$yyyyMm');
    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      final decoded = _jsonDecodeUtf8(response);
      return List<Map<String, dynamic>>.from(decoded as List);
    } else {
      final errText = utf8.decode(response.bodyBytes);
      throw Exception('取得月概覽失敗（${response.statusCode}）：$errText');
    }
  }

  // ---------------- 依日期取全文 ----------------
  /// GET /api/diaries/by-date/YYYY-MM-DD/
  /// 找不到（404）時回傳 null
  static Future<Map<String, dynamic>?> fetchDiaryByDate(DateTime date) async {
    final headers = await _authHeaders(json: false);
    final url = Uri.parse('$baseUrl/api/diaries/by-date/${_fmtDate(date)}/');
    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(
          _jsonDecodeUtf8(response) as Map<String, dynamic>);
    } else if (response.statusCode == 404) {
      return null;
    } else {
      final errText = utf8.decode(response.bodyBytes);
      throw Exception('取得當日全文失敗（${response.statusCode}）：$errText');
    }
  }
}
