import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class DiaryService {
  // 真機連本機（USB）：http://127.0.0.1:8000/（記得 adb reverse）
  // 區網或雲端：改成你的 http(s) 網址
  static const String baseUrl = 'http://127.0.0.1:8000';

  /// 建立日記並取得 AI 分析結果
  static Future<Map<String, dynamic>> createDiary({
    required String content,
    required String emotion,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) {
      return {'success': false, 'error': '尚未登入，請重新登入後再試一次'};
    }

    final url = Uri.parse('$baseUrl/api/diaries/');
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Token $token',
        },
        body: jsonEncode({'content': content, 'emotion': emotion}),
      );

      if (response.statusCode == 201) {
        // 關鍵：用 bodyBytes 再用 UTF-8 解
        final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        return {
          'success': true,
          'label': (data['label'] ?? '').toString(),
          'ai_message': (data['ai_message'] ?? '').toString(),
        };
      } else {
        // 也用 UTF-8 解錯誤內容，避免錯誤訊息本身亂碼
        final errText = utf8.decode(response.bodyBytes);
        return {'success': false, 'error': '儲存失敗（${response.statusCode}）：$errText'};
      }
    } catch (e) {
      return {'success': false, 'error': '無法連線到伺服器，請稍後再試：$e'};
    }
  }

  /// 取得所有日記列表
  static Future<List<Map<String, dynamic>>> fetchDiaries() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) {
      throw Exception('尚未登入，無法取得日記。');
    }

    final url = Uri.parse('$baseUrl/api/diaries/');
    final response = await http.get(
      url,
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Token $token',
      },
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      return List<Map<String, dynamic>>.from(decoded as List);
    } else {
      final errText = utf8.decode(response.bodyBytes);
      throw Exception('取得日記失敗（${response.statusCode}）：$errText');
    }
  }
}
