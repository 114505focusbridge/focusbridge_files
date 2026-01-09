// lib/screens/achievements_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:focusbridge_app/models/achievement.dart'; // 要用 AchievementItem 版本
import 'package:focusbridge_app/widgets/app_bottom_nav.dart';
import 'package:focusbridge_app/services/auth_service.dart';

// 說明：
// - 實機 + USB 反向： http://127.0.0.1:8000 （先 adb reverse tcp:8000 tcp:8000）
// - Android 模擬器：  http://10.0.2.2:8000
// - 區網/雲端：       換成你的伺服器位址
const String _base = 'http://127.0.0.1:8000';

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

      // 重新載入列表狀態
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
        title: const Text('成就'),
        backgroundColor: const Color(0xFF9CAF88),
        automaticallyImplyLeading: false,
        actions: [
          if (_balance != null)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: Text(
                  '情緒餘額：$_balance',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _errorCard(_error!)
                : RefreshIndicator(
                    onRefresh: _refreshAll,
                    child: ListView(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                      children: [
                        _buildOverviewCard(),
                        const SizedBox(height: 24),
                        _buildSectionTitle('每日任務'),
                        if (_daily.isEmpty)
                          _emptyHint('目前沒有每日任務')
                        else
                          ..._daily.map(_buildAchievementRow),
                        const SizedBox(height: 24),
                        _buildSectionTitle('未解鎖的成就'),
                        if (_locked.isEmpty)
                          _emptyHint('還沒有可挑戰的成就或都已解鎖')
                        else
                          ..._locked.map(_buildAchievementRow),
                        const SizedBox(height: 24),
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
      bottomNavigationBar: const AppBottomNav(currentIndex: 1),
    );
  }

  Widget _errorCard(String msg) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Card(
        color: Colors.red.shade50,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text('⚠️ $msg'),
        ),
      ),
    );
  }

  Widget _emptyHint(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(text, style: TextStyle(color: Colors.grey.shade600)),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildOverviewCard() {
    final anyDailyClaimable = _daily.any((t) => t.claimable);
    final allDailyClaimed = _daily.isNotEmpty && _daily.every((t) => !t.claimable && t.claimedToday);

    String emoji = '📌';
    String title = '今日任務';
    String subtitle = '完成每日任務可領取情緒餘額';

    if (anyDailyClaimable) {
      emoji = '🎯';
      title = '可以領獎了！';
      subtitle = '今日任務達成，記得按「領取」。';
    } else if (allDailyClaimed) {
      emoji = '🎉';
      title = '今日任務已領取';
      subtitle = '做得好，明天也別忘了來喔！';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F8E9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 32)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(fontSize: 14)),
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
          backgroundColor: const Color(0xFF9CAF88),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        child: Text('領取 +${a.amount}'),
      );
    } else if (alreadyClaimed) {
      trailing = const Chip(label: Text('已領取'));
    } else {
      trailing = const Chip(label: Text('尚未達成'));
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.emoji_events, size: 32, color: alreadyClaimed ? Colors.orange : Colors.grey),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(a.title, style: TextStyle(fontSize: 16, fontWeight: alreadyClaimed ? FontWeight.bold : FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(a.desc, style: const TextStyle(fontSize: 14)),
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
      width: 160,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.emoji_events, color: Colors.green, size: 28),
          const SizedBox(height: 8),
          Text(a.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(a.desc, style: const TextStyle(fontSize: 12)),
          const SizedBox(height: 6),
          Text('+${a.amount}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
