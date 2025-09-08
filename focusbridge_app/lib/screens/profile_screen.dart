// lib/screens/profile_screen.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:focusbridge_app/screens/breathing_screen.dart';
import 'package:focusbridge_app/screens/focus_screen.dart';
import 'package:focusbridge_app/screens/meditation_screen.dart';
import 'package:focusbridge_app/widgets/app_bottom_nav.dart';
import 'package:focusbridge_app/services/auth_service.dart';
import 'package:focusbridge_app/models/todo.dart';
import 'package:focusbridge_app/services/todo_service.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with TickerProviderStateMixin {
  // profile
  String? _name;
  String? _email;
  String? _gender;
  DateTime? _birthDate;
  String? _avatarPath; // local
  String? _avatarUrl; // remote fallback

  bool _isLoading = true;

  // wallet
  int _balance = 0;
  bool _walletLoading = false;
  String? _walletError;

  // todo + AnimatedList
  final TodoService _todoService = TodoService(
    baseUrl: 'http://140.131.115.111:8000/api',
    tokenProvider: AuthService.getToken,
  );
  bool _todoLoading = true;
  final List<Todo> _todos = [];
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();

  @override
  void initState() {
    super.initState();
    _loadLocalProfile().then((_) {
      _fetchProfile();
      _loadWallet();
      _loadTodayTodos();
    });
  }

  /// local profile
  Future<void> _loadLocalProfile() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _name = prefs.getString('profile_name') ?? _name;
      _email = prefs.getString('profile_email') ?? _email;
      _gender = prefs.getString('profile_gender') ?? _gender;
      final b = prefs.getString('profile_birth');
      if (b != null && b.isNotEmpty) _birthDate = DateTime.tryParse(b) ?? _birthDate;
      final avatar = prefs.getString('profile_avatar') ?? '';
      if (avatar.isNotEmpty && File(avatar).existsSync()) _avatarPath = avatar;
    });
  }

  /// pick avatar
  Future<void> _pickAvatar() async {
    try {
      final picker = ImagePicker();
      final XFile? file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (file == null) return;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('profile_avatar', file.path);
      setState(() => _avatarPath = file.path);
      _showSnack('已更新頭貼');
    } catch (e) {
      _showSnack('選擇頭貼失敗：$e');
    }
  }

  /// fetch profile from backend (non-destructive towards local)
  Future<void> _fetchProfile() async {
    final token = await AuthService.getToken();
    if (token == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    final url = Uri.parse('http://140.131.115.111:8000/api/moodlogs/');
    try {
      final response = await http.get(url, headers: {'Authorization': 'Token $token', 'Accept': 'application/json'});
      if (!mounted) return;
      if (response.statusCode == 200) {
        final ct = response.headers['content-type'] ?? '';
        if (!ct.contains('application/json')) {
          setState(() => _isLoading = false);
          return;
        }
        final List data = jsonDecode(utf8.decode(response.bodyBytes));
        if (data.isNotEmpty) {
          final user = data.last as Map<String, dynamic>;
          setState(() {
            _name = (_name != null && _name!.isNotEmpty) ? _name : (user['name']?.toString() ?? _name);
            _gender = (_gender != null && _gender!.isNotEmpty) ? _gender : (user['gender']?.toString() ?? _gender);
            final birthFromServer = user['birth']?.toString();
            if ((_birthDate == null || _birthDate.toString().isEmpty) && birthFromServer != null && birthFromServer.isNotEmpty) {
              final parsed = DateTime.tryParse(birthFromServer);
              if (parsed != null) _birthDate = parsed;
            }
            final avatarUrl = user['avatar_url']?.toString();
            if (avatarUrl != null && avatarUrl.isNotEmpty) _avatarUrl = avatarUrl;
          });
        }
      }
    } catch (e) {
      debugPrint('Profile fetch error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // wallet
  Future<void> _loadWallet() async {
    setState(() {
      _walletLoading = true;
      _walletError = null;
    });
    try {
      final token = await AuthService.getToken();
      if (token == null) throw Exception('尚未登入');
      final url = Uri.parse('http://140.131.115.111:8000/api/wallet/');
      final res = await http.get(url, headers: {'Authorization': 'Token $token', 'Accept': 'application/json'});
      if (!mounted) return;
      if (res.statusCode == 200) {
        final data = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
        final bal = (data['balance'] as num?)?.toInt() ?? 0;
        setState(() => _balance = bal);
      } else {
        setState(() => _walletError = '取得錢包失敗（${res.statusCode}）');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _walletError = '取得錢包失敗：$e');
    } finally {
      if (mounted) setState(() => _walletLoading = false);
    }
  }

  // todos: load into AnimatedList with insert animations
  Future<void> _loadTodayTodos() async {
    setState(() => _todoLoading = true);
    try {
      final list = await _todoService.fetchTodayTodos();
      if (!mounted) return;

      // clear existing
      for (int i = _todos.length - 1; i >= 0; i--) {
        final removed = _todos.removeAt(i);
        _listKey.currentState?.removeItem(i, (c, a) => _buildRemovedAnimatedTile(removed, a), duration: const Duration(milliseconds: 1));
      }

      // insert new with animation
      for (int i = 0; i < list.length; i++) {
        final item = list[i];
        _todos.insert(i, item);
        _listKey.currentState?.insertItem(i, duration: const Duration(milliseconds: 300));
      }
    } catch (e) {
      _showSnack('載入待辦失敗：$e');
    } finally {
      if (mounted) setState(() => _todoLoading = false);
    }
  }

  /// create todo: use backend then reload
  Future<void> _createTodo(String title, {TimeOfDay? time}) async {
    try {
      // 呼叫後端建立待辦
      await _todoService.createTodo(title: title, date: DateTime.now(), time: time);
      if (!mounted) return;

      // 成功後，重新載入整個今日待辦清單，確保畫面與後端同步
      await _loadTodayTodos();

    } catch (e) {
      _showSnack('新增失敗：$e');
    }
  }

  /// optimistic toggle by id with reorder animations
  Future<void> _optimisticToggleById(int id, bool newVal) async {
    final idx = _todos.indexWhere((e) => e.id == id);
    if (idx == -1) return;
    final old = _todos[idx];
    final updatedLocal = old.copyWith(isDone: newVal);
    _todos[idx] = updatedLocal;

    // compute new index after sort
    final copy = List<Todo>.from(_todos)..sort(Todo.compare);
    final newIndex = copy.indexWhere((e) => e == updatedLocal);

    if (newIndex != idx) {
      final removed = _todos.removeAt(idx);
      _listKey.currentState?.removeItem(idx, (c, a) => _buildRemovedAnimatedTile(removed, a), duration: const Duration(milliseconds: 250));
      final insertAt = newIndex.clamp(0, _todos.length);
      _todos.insert(insertAt, updatedLocal);
      _listKey.currentState?.insertItem(insertAt, duration: const Duration(milliseconds: 300));
    } else {
      setState(() {});
    }

    // call backend and reconcile
    try {
      final updatedFromServer = await _todoService.toggleDone(id: id, isDone: newVal);
      if (!mounted) return;
      final replaceIdx = _todos.indexWhere((e) => e.id == updatedFromServer.id);
      if (replaceIdx >= 0) setState(() => _todos[replaceIdx] = updatedFromServer);
      _todos.sort(Todo.compare);
    } catch (e) {
      // rollback
      if (!mounted) return;
      final pos = _todos.indexWhere((e) => e.id == id);
      if (pos >= 0) {
        setState(() => _todos[pos] = old);
        _todos.sort(Todo.compare);
      }
      _showSnack('更新失敗：$e');
    }
  }

  /// delete by id with optimistic remove (reinsert on failure)
  Future<void> _deleteTodoById(int id) async {
    final idx = _todos.indexWhere((e) => e.id == id);
    if (idx == -1) return;
    final removed = _todos.removeAt(idx);
    _listKey.currentState?.removeItem(idx, (c, a) => _buildRemovedAnimatedTile(removed, a), duration: const Duration(milliseconds: 300));
    try {
      await _todoService.deleteTodo(id);
      _showSnack('已刪除「${removed.title}」');
    } catch (e) {
      if (!mounted) return;
      final reInsertIndex = idx.clamp(0, _todos.length);
      _todos.insert(reInsertIndex, removed);
      _listKey.currentState?.insertItem(reInsertIndex, duration: const Duration(milliseconds: 300));
      _showSnack('刪除失敗：$e');
    }
  }

  // wrappers for older function names
  Future<void> _toggleDone(Todo t, bool isDone) async {
    if (t.id != null) {
      await _optimisticToggleById(t.id!, isDone);
    } else {
      final idx = _todos.indexWhere((e) => e == t);
      if (idx >= 0) setState(() => _todos[idx] = _todos[idx].copyWith(isDone: isDone));
    }
  }
 
  Future<void> _deleteTodo(Todo t) async {
    if (t.id != null) {
      await _deleteTodoById(t.id!);
    } else {
      final idx = _todos.indexWhere((e) => e == t);
      if (idx >= 0) {
        final removed = _todos.removeAt(idx);
        _listKey.currentState?.removeItem(idx, (c, a) => _buildRemovedAnimatedTile(removed, a), duration: const Duration(milliseconds: 250));
        _showSnack('已刪除');
      }
    }
  }

  // snack
  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // iOS-style time wheel modal (Cancel left, Confirm right)
  Future<TimeOfDay?> _showCupertinoTimePickerModal({TimeOfDay? initial}) async {
    TimeOfDay picked = initial ?? TimeOfDay.now();
    final res = await showModalBottomSheet<TimeOfDay>(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      builder: (ctx) {
        return SafeArea(
          child: Container(
            height: 320,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      CupertinoButton(padding: EdgeInsets.zero, child: const Text('取消'), onPressed: () => Navigator.of(ctx).pop(null)),
                      const Spacer(),
                      CupertinoButton(padding: EdgeInsets.zero, child: const Text('確定'), onPressed: () => Navigator.of(ctx).pop(picked)),
                    ],
                  ),
                ),
                const Divider(height: 1),
                SizedBox(
                  height: 240,
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.time,
                    initialDateTime: DateTime(0, 0, 0, initial?.hour ?? TimeOfDay.now().hour, initial?.minute ?? TimeOfDay.now().minute),
                    use24hFormat: true,
                    onDateTimeChanged: (dt) {
                      picked = TimeOfDay(hour: dt.hour, minute: dt.minute);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    return res;
  }

  // === Dialog-based add (restored)
  Future<void> _showAddTodoDialog() async {
    final titleCtrl = TextEditingController();
    TimeOfDay? pickedTime;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setSB) {
          return AlertDialog(
            title: const Text('新增待辦'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: '內容', hintText: '例如：複習資料結構'),
                  autofocus: true,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('時間（可選）：'),
                    const SizedBox(width: 8),
                    Text(pickedTime == null ? '未設定' : '${_pad2(pickedTime!.hour)}:${_pad2(pickedTime!.minute)}'),
                    const Spacer(),
                    TextButton(
                      onPressed: () async {
                        final t = await _showCupertinoTimePickerModal(initial: pickedTime);
                        if (t != null) setSB(() => pickedTime = t);
                      },
                      child: const Text('選擇'),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
              ElevatedButton(
                onPressed: () {
                  if (titleCtrl.text.trim().isEmpty) {
                    _showSnack('請輸入內容');
                    return;
                  }
                  Navigator.pop(context, true);
                },
                child: const Text('新增'),
              ),
            ],
          );
        });
      },
    );

    if (ok == true) {
      await _createTodo(titleCtrl.text.trim(), time: pickedTime);
    }
  }

// === UI ===
@override
Widget build(BuildContext context) {
  return Scaffold(
    // 整體背景色維持原樣，不影響卡片
    backgroundColor: Colors.lightBlue.shade50,
    appBar: AppBar(
      backgroundColor: Colors.transparent, // 背景設為透明
      elevation: 0,
      automaticallyImplyLeading: false,
      title: const Text(
        '個人檔案',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white),
          onPressed: () async {
            await Future.wait([_fetchProfile(), _loadWallet(), _loadTodayTodos()]);
            _showSnack('已更新');
          },
          tooltip: '刷新',
        ),
      ],
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.cyan.shade300, // 從淺綠藍色
              Colors.lightBlue.shade400, // 到淺藍色
            ],
            begin: Alignment.bottomLeft,
            end: Alignment.topRight,
          ),
        ),
      ),
    ),
    body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  // 個人檔案區塊
                  Card(
                    elevation: 4, // 增加陰影
                    color: Colors.white, // **修正：背景色改為白色**
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), // 更大的圓角
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: _pickAvatar,
                            child: CircleAvatar(
                              radius: 40,
                              backgroundColor: Colors.cyan.shade100,
                              backgroundImage: _avatarPath != null
                                  ? FileImage(File(_avatarPath!)) as ImageProvider
                                  : (_avatarUrl != null ? NetworkImage(_avatarUrl!) : null),
                              child: (_avatarPath == null && _avatarUrl == null)
                                  ? Icon(Icons.person_outline, size: 40, color: Colors.cyan.shade600) // 更換圖標
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_name ?? '未設定姓名', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
                                const SizedBox(height: 4),
                                Text(_email ?? 'email not found.', style: TextStyle(color: Colors.grey[700], fontSize: 14)),
                                const SizedBox(height: 2),
                                Text(
                                  _birthDate != null ? '生日: ${_birthDate!.year}/${_birthDate!.month}/${_birthDate!.day}' : '未設定生日',
                                  style: TextStyle(color: Colors.grey[700], fontSize: 14),
                                ),
                                const SizedBox(height: 2),
                                Text('性別: ${_gender ?? '未設定'}', style: TextStyle(color: Colors.grey[700], fontSize: 14)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                  _walletCard(),
                  const SizedBox(height: 24),

                  // 小工具標題
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '小工具',
                      style: Theme.of(context).textTheme.titleLarge!.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.blueGrey.shade700,
                          ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildToolButton(context, Icons.center_focus_strong, '專注', const FocusScreen(), Color.fromARGB(255, 110, 188, 255)),
                      const SizedBox(width: 12),
                      _buildToolButton(context, Icons.self_improvement, '冥想', const MeditationScreen(),  Color.fromARGB(255, 120, 210, 255)),
                      const SizedBox(width: 12),
                      _buildToolButton(context, Icons.favorite, '呼吸', const BreathingScreen(), const Color.fromARGB(255, 150, 230, 255)),
                    ],
                  ),
                  const SizedBox(height: 24),

                  _buildTodoCard(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
    bottomNavigationBar: const AppBottomNav(currentIndex: 3),
  );
}

// 錢包卡片 (修正後)
Widget _walletCard() {
  if (_walletLoading) {
    return Card(
      elevation: 4, // 增加陰影
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: const ListTile(
        leading: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
        title: Text('讀取情緒餘額中...'),
      ),
    );
  }
  if (_walletError != null) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: Colors.red.shade50,
      child: ListTile(
        leading: const Icon(Icons.error, color: Colors.red),
        title: const Text('無法取得情緒餘額'),
        subtitle: Text(_walletError ?? ''),
        trailing: IconButton(icon: const Icon(Icons.refresh), onPressed: _loadWallet),
      ),
    );
  }
  return Card(
    elevation: 4,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    child: Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        // 使用綠色系的漸層背景 (修正後)
        gradient: LinearGradient(
          colors: [
            const Color.fromARGB(255, 223, 255, 210), // 淺綠色
            const Color.fromARGB(255, 142, 255, 89), // 較深的綠色
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: ListTile(
        leading: Icon(Icons.monetization_on, color: const Color(0xFF4F8C6F), size: 36),
        title: Text(
          '情緒餘額',
          style: TextStyle(fontWeight: FontWeight.bold, color: const Color(0xFF4F8C6F)),
        ),
        subtitle: Text(
          '\$ $_balance',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        trailing: IconButton(icon: const Icon(Icons.refresh, color: Color(0xFF4F8C6F)), onPressed: _loadWallet),
      ),
    ),
  );
}

// 小工具按鈕 (新增顏色參數)
// 新的函式簽名
Widget _buildToolButton(BuildContext ctx, IconData icon, String label, Widget page, Color iconColor) {
  return Expanded(
    child: Card(
      elevation: 4, // 增加陰影
      color: Colors.white, // **修正：背景色改為白色**
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), // 更大的圓角
      child: InkWell(
        onTap: () {
                  Navigator.push(
                    ctx,
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) => page, // 這裡直接使用傳入的 page Widget
                      transitionsBuilder: (context, animation, secondaryAnimation, child) {
                        return FadeTransition(
                          opacity: CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeIn,
                          ),
                          child: child,
                        );
                      },
                      transitionDuration: const Duration(milliseconds: 600),
                    ),
                  );
                },
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            children: [
              Icon(icon, color: iconColor, size: 36),
              const SizedBox(height: 10),
              Text(
                label,
                style: TextStyle(
                  color: Colors.blueGrey.shade700,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

// 待辦事項卡片
Widget _buildTodoCard() {
  return Card(
    elevation: 4, // 增加陰影
    color: Colors.white, // **修正：背景色改為白色**
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), // 更大的圓角
    child: Padding(
      padding: const EdgeInsets.all(20), // 增加內邊距
      child: Column(
        children: [
          Row(
            children: [
              Text(
                '今日待辦',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey.shade700,
                ),
              ),
              const Spacer(),
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.blue.shade50, // 淺藍色背景
                ),
                child: IconButton(
                  icon: Icon(Icons.add, color: Colors.blue.shade600),
                  onPressed: _showAddTodoDialog,
                ),
              ),
            ],
          ),
          const Divider(height: 30),
          if (_todoLoading)
            const Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator())
          else if (_todos.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Text(
                '今天沒有待辦，新增一個吧！',
                style: TextStyle(color: Colors.grey[500], fontStyle: FontStyle.italic, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            )
          else
            AnimatedList(
              key: _listKey,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              initialItemCount: _todos.length,
              itemBuilder: (context, index, animation) {
                final t = _todos[index];
                return SizeTransition(
                  sizeFactor: animation,
                  child: _buildDismissibleTile(index),
                );
              },
            ),
        ],
      ),
    ),
  );
}

// 可滑動刪除的待辦項目
Widget _buildDismissibleTile(int index) {
  if (index < 0 || index >= _todos.length) return const SizedBox();
  final t = _todos[index];
  final timeText = t.timeText.isEmpty ? null : t.timeText;
  final stableKey = t.id != null ? 'id_${t.id}' : 'idx_$index';

  return Dismissible(
    key: ValueKey(stableKey),
    direction: DismissDirection.endToStart,
    background: Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(color: Colors.red.shade400, borderRadius: BorderRadius.circular(16)),
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: const Icon(Icons.delete_sweep, color: Colors.white, size: 30),
    ),
    onDismissed: (_) {
      final current = (index < _todos.length) ? _todos[index] : null;
      if (current == null) return;
      if (current.id != null) {
        _deleteTodoById(current.id!);
      } else {
        final removed = _todos.removeAt(index);
        _listKey.currentState?.removeItem(index, (c, a) => _buildRemovedAnimatedTile(removed, a), duration: const Duration(milliseconds: 250));
        _showSnack('已刪除');
      }
    },
    child: Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(250, 246, 233, 1), // **修正：使用更黃的米色**
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Transform.scale(
            scale: 1.2,
            child: Checkbox(
              value: t.isDone,
              onChanged: (v) {
                final newVal = v ?? false;
                if (t.id != null) {
                  _optimisticToggleById(t.id!, newVal);
                } else {
                  setState(() => _todos[index] = _todos[index].copyWith(isDone: newVal));
                }
              },
              shape: const CircleBorder(),
              activeColor: Colors.blue.shade600,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              t.title,
              style: TextStyle(
                fontSize: 17,
                decoration: t.isDone ? TextDecoration.lineThrough : null,
                color: t.isDone ? Colors.grey[500] : Colors.black87,
              ),
            ),
          ),
          if (timeText != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                timeText,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.blue.shade900,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

// 刪除時的動畫
Widget _buildRemovedAnimatedTile(Todo t, Animation<double> animation) {
  return SizeTransition(
    sizeFactor: animation,
    child: Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
          color: const Color.fromRGBO(250, 246, 233, 1), // **修正：使用更黃的米色**
          borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Transform.scale(
            scale: 1.2,
            child: Checkbox(value: t.isDone, onChanged: null, shape: const CircleBorder()),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              t.title,
              style: TextStyle(
                fontSize: 17,
                decoration: TextDecoration.lineThrough,
                color: Colors.grey[500],
              ),
            ),
          ),
          if (t.timeText.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: Colors.blue.shade100, borderRadius: BorderRadius.circular(10)),
              child: Text(t.timeText, style: TextStyle(fontSize: 14, color: Colors.blue.shade900, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    ),
  );
}

String _pad2(int n) => n.toString().padLeft(2, '0');
}