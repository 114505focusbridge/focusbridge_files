import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class DiaryService {
  static const String baseUrl = 'http://10.0.2.2:8000'; // 根據你的 Django IP 調整

  /// 新增日記（只有 content）
  static Future<void> createDiary({required String content}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    print('🔍 [DiaryService] retrieved token: $token');

    if (token == null) {
      throw Exception("尚未登入，無法新增日記");
    }

    final url = Uri.parse('$baseUrl/api/diaries/'); // ✅ 修改成複數 diaries

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Token $token',
      },
      body: jsonEncode({
        'content': content,
      }),
    );

    if (response.statusCode != 201) {
      throw Exception("新增日記失敗：${response.body}");
    }
  }

  /// 取得所有日記
  static Future<List<Map<String, dynamic>>> fetchDiaries() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      throw Exception("尚未登入");
    }

    final url = Uri.parse('$baseUrl/api/diaries/'); // ✅ 修改成複數 diaries
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
