import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:focusbridge_app/services/auth_service.dart';

/// 實機 + USB 反向：先執行 adb reverse tcp:8000 tcp:8000 後可用 127.0.0.1
/// Android 模擬器：10.0.2.2
const String _base = 'http://140.131.115.111:8000';

class WalletService {
  static Future<int> fetchBalance() async {
    final token = await AuthService.getToken();
    if (token == null) throw Exception('尚未登入');

    final url = Uri.parse('$_base/api/wallet/');
    final res = await http.get(url, headers: {'Authorization': 'Token $token'});

    if (res.statusCode != 200) {
      final txt = utf8.decode(res.bodyBytes);
      throw Exception('取得錢包失敗（${res.statusCode}）：$txt');
    }

    final data = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    return (data['balance'] as num?)?.toInt() ?? 0;
  }

  static Future<List<Map<String, dynamic>>> fetchRecent({int limit = 30}) async {
    final token = await AuthService.getToken();
    if (token == null) throw Exception('尚未登入');

    final url = Uri.parse('$_base/api/wallet/');
    final res = await http.get(url, headers: {'Authorization': 'Token $token'});

    if (res.statusCode != 200) {
      final txt = utf8.decode(res.bodyBytes);
      throw Exception('取得錢包失敗（${res.statusCode}）：$txt');
    }

    final data = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    final recent = List<Map<String, dynamic>>.from(data['recent'] as List? ?? []);
    if (recent.length > limit) {
      return recent.take(limit).toList();
    }
    return recent;
  }
}