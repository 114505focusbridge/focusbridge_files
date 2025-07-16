// lib/services/photo_service.dart
import 'dart:convert';   
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class PhotoService {
  static const String baseUrl = 'http://10.0.2.2:8000'; // 或你的區網 IP

  /// 上傳照片檔案到後端 /api/photos/
  /// imageFile: 實體或模擬器上的 File，path 是 local file path
  static Future<void> uploadPhoto({ required File imageFile }) async {
    // 1. 讀 token
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) {
      throw Exception('尚未登入，無法新增相片');
    }

    // 2. 建 MultipartRequest
    final uri = Uri.parse('$baseUrl/api/photos/');
    final req = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Token $token'
      // 3. 把檔案加進去 field 名稱要對應 serializers 裡的 ImageField 名稱，通常是 'image'
      ..files.add(await http.MultipartFile.fromPath('image', imageFile.path));

    // 4. 發送
    final rsp = await req.send();

    // 5. 檢查結果
    if (rsp.statusCode != 201) {
      final body = await rsp.stream.bytesToString();
      throw Exception('新增相片失敗：$body');
    }
  }

  /// 取得所有照片列表
  static Future<List<Map<String, dynamic>>> fetchPhotos() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) throw Exception('尚未登入');

    final uri = Uri.parse('$baseUrl/api/photos/');
    final rsp = await http.get(uri, headers: {
      'Authorization': 'Token $token',
    });

    if (rsp.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(rsp.body));
    } else {
      throw Exception('取得相片失敗：${rsp.body}');
    }
  }
}
