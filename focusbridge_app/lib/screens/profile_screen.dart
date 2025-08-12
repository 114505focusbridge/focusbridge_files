// lib/screens/profile_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:focusbridge_app/widgets/app_bottom_nav.dart';
import 'package:focusbridge_app/services/auth_service.dart';
import 'package:http/http.dart' as http;

// ⬇️ Todo 模型與服務
import 'package:focusbridge_app/models/todo.dart';
import 'package:focusbridge_app/services/todo_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? _name;
  String? _gender;
  String? _birth;
  String? _avatarUrl;
  int _balance = 0;
  bool _isLoading = true;

  // ⬇️ 今日備忘錄狀態
  final TodoService _todoService = TodoService(
    // USB 実機 + adb reverse ➜ 用 127.0.0.1:8000/api
    baseUrl: 'http://127.0.0.1:8000/api',
    tokenProvider: AuthService.getToken,
  );
  bool _todoLoading = true;
  List<Todo> _todos = [];

  @override
  void initState() {
    super.initState();
    _fetchProfile();
    _loadTodayTodos();
  }

  Future<void> _fetchProfile() async {
    final token = await AuthService.getToken();
    if (token == null) return;

    // ✅ 打到 DRF 的 /api/moodlogs/
    final url = Uri.parse('http://127.0.0.1:8000/api/moodlogs/');
    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Token $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        // 確保是 JSON List
        final ct = response.headers['content-type'] ?? '';
        if (!ct.contains('application/json')) {
          debugPrint('⚠️ 非 JSON 回應：$ct\n${response.body.substring(0, 200)}');
          setState(() => _isLoading = false);
          return;
        }
        final List data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          final user = data.last;
          setState(() {
            _name = user['name'] ?? '';
            _gender = user['gender'] ?? '';
            _birth = user['birth'] ?? '';
            _avatarUrl = null; // 如需後端支援大頭貼，這邊接上 URL
            _isLoading = false;
          });
        } else {
          setState(() => _isLoading = false);
        }
      } else {
        debugPrint('⚠️ Profile 載入失敗: ${response.statusCode} / ${response.body}');
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('❌ Profile 載入錯誤: $e');
      setState(() => _isLoading = false);
    }
  }

  // ===== Todo：資料操作 =====
  Future<void> _loadTodayTodos() async {
    setState(() => _todoLoading = true);
    try {
      final list = await _todoService.fetchTodayTodos();
      setState(() {
        _todos = list..sort(Todo.compare);
      });
    } catch (e) {
      _showSnack('載入待辦失敗：$e');
    } finally {
      if (mounted) setState(() => _todoLoading = false);
    }
  }

  Future<void> _createTodo(String title, {TimeOfDay? time}) async {
    try {
      final created = await _todoService.createTodo(
        title: title,
        date: DateTime.now(), // ✅ 一定帶今天，避免時區不同
        time: time,
      );
      setState(() {
        _todos.add(created);
        _todos.sort(Todo.compare);
      });
    } catch (e) {
      _showSnack('新增失敗：$e');
    }
  }

  Future<void> _toggleDone(Todo t, bool isDone) async {
    try {
      final updated = await _todoService.toggleDone(id: t.id!, isDone: isDone);
      setState(() {
        final idx = _todos.indexWhere((e) => e.id == updated.id);
        if (idx >= 0) _todos[idx] = updated;
        _todos.sort(Todo.compare);
      });
    } catch (e) {
      _showSnack('更新失敗：$e');
    }
  }

  Future<void> _deleteTodo(Todo t) async {
    try {
      await _todoService.deleteTodo(t.id!);
      setState(() {
        _todos.removeWhere((e) => e.id == t.id);
      });
      _showSnack('已刪除「${t.title}」');
    } catch (e) {
      _showSnack('刪除失敗：$e');
    }
  }

  // ===== Todo：UI 動作 =====
  Future<void> _showAddTodoDialog() async {
    final titleCtrl = TextEditingController();
    TimeOfDay? pickedTime;

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('新增待辦'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(
                  labelText: '內容',
                  hintText: '例如：複習資料結構',
                ),
                autofocus: true,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text('時間（可選）：'),
                  const SizedBox(width: 8),
                  Text(pickedTime == null
                      ? '未設定'
                      : '${_pad2(pickedTime!.hour)}:${_pad2(pickedTime!.minute)}'),
                  const Spacer(),
                  TextButton(
                    onPressed: () async {
                      final now = TimeOfDay.now();
                      final t = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay(hour: now.hour, minute: now.minute),
                      );
                      if (t != null) {
                        setState(() {}); // 觸發外層 rebuild
                        pickedTime = t;
                        // 用重開 Dialog 的方式保留輸入
                        Navigator.of(context).pop(false);
                        await _showAddTodoDialogWithPrefill(titleCtrl.text, pickedTime);
                      }
                    },
                    child: const Text('選擇'),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消'),
            ),
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
      },
    );

    if (ok == true) {
      await _createTodo(titleCtrl.text.trim(), time: pickedTime);
    }
  }

  // 讓選完時間後，Dialog 可以保留之前輸入
  Future<void> _showAddTodoDialogWithPrefill(String title, TimeOfDay? picked) async {
    final titleCtrl = TextEditingController(text: title);
    TimeOfDay? pickedTime = picked;

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
                  decoration: const InputDecoration(
                    labelText: '內容',
                    hintText: '例如：複習資料結構',
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('時間（可選）：'),
                    const SizedBox(width: 8),
                    Text(pickedTime == null
                        ? '未設定'
                        : '${_pad2(pickedTime!.hour)}:${_pad2(pickedTime!.minute)}'),
                    const Spacer(),
                    TextButton(
                      onPressed: () async {
                        final now = TimeOfDay.now();
                        final t = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay(hour: now.hour, minute: now.minute),
                        );
                        if (t != null) setSB(() => pickedTime = t);
                      },
                      child: const Text('選擇'),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('取消'),
              ),
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

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('個人'),
        backgroundColor: const Color(0xFF9CAF88),
        automaticallyImplyLeading: false,
        actions: [
          // 右上角新增待辦
          IconButton(
            icon: const Icon(Icons.add_task_outlined),
            tooltip: '新增待辦',
            onPressed: _showAddTodoDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // ✅ 沒有資產時用 Icon 當預設頭像，避免報錯
                    CircleAvatar(
                      radius: 48,
                      backgroundImage: _avatarUrl != null ? NetworkImage(_avatarUrl!) : null,
                      child: _avatarUrl == null ? const Icon(Icons.person, size: 48) : null,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _name ?? '未設定姓名',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '@you',
                      style: TextStyle(fontSize: 14, color: Colors.black54),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_birth ?? '未設定生日'}  |  ${_gender ?? '未設定性別'}',
                      style: const TextStyle(fontSize: 14, color: Colors.black54),
                    ),
                    const SizedBox(height: 16),
                    const Divider(thickness: 1),
                    const SizedBox(height: 16),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '小工具',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '💰 情緒餘額: \$$_balance',
                            style: const TextStyle(fontSize: 14),
                          ),
                          IconButton(
                            onPressed: () {
                              // TODO: 前往商店購買
                            },
                            icon: const Icon(Icons.shopping_cart_outlined),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _buildToolButton(context, Icons.center_focus_strong, '專注', '/focus'),
                        const SizedBox(width: 8),
                        _buildToolButton(context, Icons.self_improvement, '冥想', '/meditation'),
                        const SizedBox(width: 8),
                        _buildToolButton(context, Icons.favorite, '呼吸', '/breathing'),
                      ],
                    ),

                    const SizedBox(height: 24),
                    _buildTodoCard(),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: AppBottomNav(currentIndex: 3),
    );
  }

  Widget _buildToolButton(
      BuildContext context, IconData icon, String label, String routeName) {
    return Expanded(
      child: ElevatedButton(
        onPressed: () => Navigator.pushNamed(context, routeName),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green.shade100,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12),
          elevation: 0,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.green.shade800),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: Colors.green.shade800)),
          ],
        ),
      ),
    );
  }

  // ===== 今日備忘錄 Card =====
  Widget _buildTodoCard() {
    return Card(
      elevation: 0,
      color: Colors.green.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Column(
          children: [
            Row(
              children: [
                const Text('今日備忘錄', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(
                  tooltip: '新增待辦',
                  onPressed: _showAddTodoDialog,
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_todoLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_todos.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  '今天沒有待辦，點右上角「＋」新增一個吧！',
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              )
            else
              Column(
                children: _todos.map(_buildTodoTile).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodoTile(Todo t) {
    final timeText = t.timeText.isEmpty ? null : t.timeText;

    return Dismissible(
      key: ValueKey('todo_${t.id}_${t.dateText}_${t.timeText}'),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: Colors.red.shade300,
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => _deleteTodo(t),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Checkbox(
              value: t.isDone,
              onChanged: (v) {
                if (t.id == null) return;
                _toggleDone(t, v ?? false);
              },
              shape: const CircleBorder(),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                t.title,
                style: TextStyle(
                  fontSize: 15,
                  decoration: t.isDone ? TextDecoration.lineThrough : null,
                  color: t.isDone ? Colors.grey : Colors.black87,
                ),
              ),
            ),
            if (timeText != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  timeText,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green.shade900,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

String _pad2(int n) => n.toString().padLeft(2, '0');
