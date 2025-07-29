import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class DiaryService {
  static const String baseUrl = 'http://10.0.2.2:8000'; // ✅ 根據本地 Django IP 調整

  /// ✅ 建立日記並取得 AI 分析結果
  static Future<Map<String, dynamic>> createDiary({
    required String content,
    required String emotion,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    print('🔍 [DiaryService] Retrieved token: $token');

    if (token == null) {
      print('⚠️ 無 token，尚未登入');
      return {
        'success': false,
        'error': '尚未登入，請重新登入後再試一次',
      };
    }

    final url = Uri.parse('$baseUrl/api/diaries/');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
        body: jsonEncode({
          'content': content,
          'emotion': emotion,
        }),
      );

      if (response.statusCode == 201) {
        print('✅ 日記新增成功');
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'label': data['label'] ?? '',
          'ai_message': data['ai_message'] ?? '',
        };
      } else {
        print('❌ 新增日記失敗：${response.statusCode} ${response.body}');
        return {
          'success': false,
          'error': '儲存失敗，伺服器回傳 ${response.statusCode}：${response.body}',
        };
      }
    } catch (e) {
      print('❌ 發生例外錯誤：$e');
      return {
        'success': false,
        'error': '無法連線到伺服器，請稍後再試：$e',
      };
    }
  }

  /// ✅ 取得所有日記列表
  static Future<List<Map<String, dynamic>>> fetchDiaries() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      throw Exception("尚未登入，無法取得日記。");
    }

    final url = Uri.parse('$baseUrl/api/diaries/');
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Token $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data);
    } else {
      throw Exception("取得日記失敗：${response.body}");
    }
  }
}
