import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class DiaryService {
  static const String baseUrl = 'https://focusbridge-backend1.onrender.com'; // 根據你的 Django IP 調整

  /// ✅ 修改：新增日記後回傳是否成功
  static Future<bool> createDiary({required String content, required String emotion,}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    print('🔍 [DiaryService] retrieved token: $token');

    if (token == null) {
      print('⚠️ 無 token，尚未登入');
      return false;
    }

    final url = Uri.parse('$baseUrl/api/diaries/');

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
      return true;
    } else {
      print('❌ 新增日記失敗：${response.statusCode} ${response.body}');
      return false;
    }
  }

  /// 取得所有日記
  static Future<List<Map<String, dynamic>>> fetchDiaries() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      throw Exception("尚未登入");
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
