// lib/screens/achievements_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:focusbridge_app/models/achievement.dart';
import 'package:focusbridge_app/widgets/app_bottom_nav.dart';
import 'package:focusbridge_app/services/auth_service.dart';

// 說明：
// - 實機 + USB 反向： http://127.0.0.1:8000 （先 adb reverse tcp:8000 tcp:8000）
// - Android 模擬器：  http://10.0.2.2:8000
// - 區網/雲端：       換成你的伺服器位址
const String _base = 'http://140.131.115.111:8000';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  bool _loading = false;
  String? _error;

  int? _balance;
  List<AchievementItem> _daily = [];
  List<AchievementItem> _locked = [];
  List<AchievementItem> _unlocked = [];

  // 定義新的配色方案，全部使用 ARGB 格式，移除黃色
  final Color _lightBlueGreen = const Color.fromARGB(255, 148, 217, 236); // 柔和藍綠色
  final Color _paleBeige = const Color.fromARGB(255, 236, 238, 223); // 淺米色
  final Color _mediumBrown = const Color.fromARGB(255, 217, 196, 176); // 中度棕色
  final Color _lightBrown = const Color.fromARGB(255, 181, 140, 106); // 淺棕色 / 卡其色
  final Color _darkBrownText = const Color.fromARGB(255, 90, 70, 50); // 深棕色文字

  // 情緒餘額格子的特定綠色 (保持不變)
  final Color _balanceLightGreen = const Color.fromARGB(255, 223, 255, 210);
  final Color _balanceDarkGreen = const Color.fromARGB(255, 142, 255, 89);
  final Color _balanceIconGreen = const Color.fromARGB(255, 28, 188, 0);

  @override
  void initState() {
    super.initState();
    _refreshAll();
  }

  Future<void> _refreshAll() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await Future.wait([_loadAchievements(), _fetchWallet()]);
    } catch (e) {
      _error = '載入失敗：$e';
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _loadAchievements() async {
    final token = await AuthService.getToken();
    if (token == null) throw '尚未登入（沒有 token）';

    final url = Uri.parse('$_base/api/achievements/');
    final res = await http.get(url, headers: {'Authorization': 'Token $token'});

    if (res.statusCode != 200) {
      final txt = utf8.decode(res.bodyBytes);
      throw '取得成就失敗（${res.statusCode}）：$txt';
    }

    final List raw = jsonDecode(utf8.decode(res.bodyBytes)) as List;
    final items = raw.map((e) => AchievementItem.fromJson(e as Map<String, dynamic>)).toList();

    final daily = <AchievementItem>[];
    final locked = <AchievementItem>[];
    final unlocked = <AchievementItem>[];

    for (final a in items) {
      if (a.isDaily) {
        daily.add(a);
      } else if (a.unlocked) {
        unlocked.add(a);
      } else {
        locked.add(a);
      }
    }

    if (!mounted) return;
    setState(() {
      _daily = daily;
      _locked = locked;
      _unlocked = unlocked;
    });
  }

  Future<void> _fetchWallet() async {
    final token = await AuthService.getToken();
    if (token == null) throw '尚未登入（沒有 token）';

    final url = Uri.parse('$_base/api/wallet/');
    final res = await http.get(url, headers: {'Authorization': 'Token $token'});

    if (res.statusCode != 200) {
      final txt = utf8.decode(res.bodyBytes);
      throw '取得錢包失敗（${res.statusCode}）：$txt';
    }

    final data = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    if (!mounted) return;
    setState(() {
      _balance = (data['balance'] as num?)?.toInt();
    });
  }

  Future<void> _claim(AchievementItem a) async {
    final token = await AuthService.getToken();
    if (token == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('尚未登入')),
      );
      return;
    }

    final url = Uri.parse('$_base/api/achievements/claim/');
    final res = await http.post(
      url,
      headers: {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({'id': a.id}),
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      final amount = (data['amount'] as num?)?.toInt() ?? 0;
      final balance = (data['balance'] as num?)?.toInt();

      if (mounted) {
        setState(() {
          _balance = balance ?? _balance;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('領取成功：+$amount 情緒餘額')),
        );
      }

      await _loadAchievements();
    } else {
      final txt = utf8.decode(res.bodyBytes);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('領取失敗（${res.statusCode}）：$txt')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('任務與成就', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24)),
        backgroundColor: _lightBlueGreen, // **App Bar 背景色改為柔和藍綠色**
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, _paleBeige], // **背景漸層使用淺米色和柔和藍綠色**
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: _loading
              ? Center(child: CircularProgressIndicator(color: _lightBrown)) // **載入指示器顏色**
              : _error != null
                  ? _errorCard(_error!)
                  : RefreshIndicator(
                      onRefresh: _refreshAll,
                      color: _lightBrown, // **刷新指示器顏色**
                      child: ListView(
                        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                        children: [
                          _buildSectionTitle('每日任務'),
                          const SizedBox(height: 12),
                          if (_daily.isEmpty)
                            _emptyHint('目前沒有每日任務')
                          else
                            ..._daily.map(_buildAchievementRow),

                          if (_balance != null)
                            const SizedBox(height: 24),
                          if (_balance != null)
                            _buildBalanceCard(), // 情緒餘額卡片
                          
                          const SizedBox(height: 32),
                          _buildSectionTitle('未解鎖的成就'),
                          if (_locked.isEmpty)
                            _emptyHint('還沒有可挑戰的成就或都已解鎖')
                          else
                            ..._locked.map(_buildAchievementRow),
                          
                          const SizedBox(height: 32),
                          _buildSectionTitle('已達成的成就'),
                          if (_unlocked.isEmpty)
                            _emptyHint('還沒有已解鎖的成就')
                          else
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: _unlocked.map(_buildBadge).toList(),
                            ),
                        ],
                      ),
                    ),
        ),
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 1),
    );
  }

  Widget _errorCard(String msg) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Card(
        color: _paleBeige,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text('⚠️ $msg', style: TextStyle(color: _darkBrownText)),
        ),
      ),
    );
  }

  Widget _emptyHint(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(text, style: TextStyle(color: _darkBrownText.withOpacity(0.6))),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _darkBrownText)),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _balanceLightGreen, // 淺綠色 (保持不變)
            _balanceDarkGreen, // 較深的綠色 (保持不變)
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Color.fromARGB(25, 0, 0, 0),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start, // **情緒餘額靠左對齊**
        children: [
          Icon(Icons.monetization_on, color: _balanceIconGreen, size: 36),
          const SizedBox(width: 12),
          Text(
            '情緒餘額：$_balance',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _darkBrownText),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewCard() {
    final anyDailyClaimable = _daily.any((t) => t.claimable);
    final allDailyClaimed = _daily.isNotEmpty && _daily.every((t) => !t.claimable && t.claimedToday);

    String emoji = '🎯';
    String title = '今日任務';
    String subtitle = '完成每日任務可領取情緒幣。';
    Color startColor = _lightBrown; // 任務卡片使用淺棕色
    Color endColor = _lightBrown.withOpacity(0.8);

    if (anyDailyClaimable) {
      emoji = '🎉';
      title = '可以領獎了！';
      subtitle = '今日任務達成，記得點擊「領取」按鈕。';
      startColor = _lightBrown;
      endColor = _lightBrown.withOpacity(0.8);
    } else if (allDailyClaimed) {
      emoji = '✅';
      title = '今日任務已領取';
      subtitle = '做得好，明天也別忘了來喔！';
      startColor = _lightBlueGreen.withOpacity(0.8); // 已達成狀態改為淺藍綠色漸層
      endColor = _lightBlueGreen.withOpacity(0.6);
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [startColor, endColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Color.fromARGB(38, 0, 0, 0),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 36)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(fontSize: 14, color: Colors.white)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementRow(AchievementItem a) {
    final isClaimable = a.claimable;
    final isDaily = a.isDaily;
    final alreadyClaimed = isDaily ? a.claimedToday : a.unlocked;

    Widget trailing;
    if (isClaimable) {
      trailing = ElevatedButton(
        onPressed: () => _claim(a),
        style: ElevatedButton.styleFrom(
          backgroundColor: _lightBrown, // 按鈕背景色改為淺棕色
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        ),
        child: Text('領取 +${a.amount}'),
      );
    } else if (alreadyClaimed) {
      trailing = Chip(
        label: const Text('已達成'),
        backgroundColor: _lightBlueGreen.withOpacity(0.4), // 已達成 Chip 背景色改為淺藍綠色
        labelStyle: TextStyle(color: _darkBrownText), // 文字顏色改為深棕色
      );
    } else {
      trailing = Chip(
        label: const Text('尚未達成'),
        backgroundColor: const Color.fromARGB(255, 238, 238, 238),
        labelStyle: const TextStyle(color: Color.fromARGB(255, 158, 158, 158)),
      );
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              Icons.stars,
              size: 36,
              color: alreadyClaimed ? _lightBrown : const Color.fromARGB(255, 158, 158, 158), // 圖示顏色
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    a.title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _darkBrownText,
                      decoration: alreadyClaimed ? TextDecoration.lineThrough : null,
                      decorationThickness: 2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    a.desc,
                    style: TextStyle(fontSize: 14, color: _darkBrownText.withOpacity(0.8)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            trailing,
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(AchievementItem a) {
    return Container(
      width: 170,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _mediumBrown, // 徽章背景色改為中度棕色
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _lightBrown, width: 2), // 邊框改為淺棕色
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.military_tech, color: const Color.fromARGB(255, 255, 234, 0), size: 36), // 圖示白色
          const SizedBox(height: 12),
          Text(a.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 6),
          Text(a.desc, style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.8))),
          const SizedBox(height: 8),
          Text(
            '+${a.amount} 情緒幣',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
          ),
        ],
      ),
    );
  }
}