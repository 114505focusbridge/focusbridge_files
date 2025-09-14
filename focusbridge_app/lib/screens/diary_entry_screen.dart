import 'package:flutter/material.dart';
import 'package:focusbridge_app/screens/re_post_entry_screen.dart';
import 'package:intl/intl.dart';
import 'package:focusbridge_app/screens/post_entry_screen.dart';
import 'package:focusbridge_app/screens/re_post_entry_screen.dart'; // 導入新的畫面
import 'package:focusbridge_app/services/diary_service.dart';
import 'package:focusbridge_app/widgets/glowing_button.dart';

class DiaryEntryScreen extends StatefulWidget {
  const DiaryEntryScreen({super.key});

  @override
  State<DiaryEntryScreen> createState() => _DiaryEntryScreenState();
}

class _DiaryEntryScreenState extends State<DiaryEntryScreen> {
  // 狀態
  late TextEditingController _controller;
  String _emotionLabel = '';
  Color _selectedColor = Colors.blue.shade200;
  DateTime _targetDate = DateTime.now();
  String _formattedDate = '';
  bool _isLoading = false; // 同時表示「載入/儲存中」，並用來阻止 race condition
  bool _isEditing = false;
  int? _diaryId;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _formattedDate = _formatChineseDate(_targetDate);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)!.settings.arguments;

    if (args is Map) {
      final DateTime? dateArg = args['date'] as DateTime?;
      final int? diaryIdArg = args['diaryId'] as int?;
      final Color? colorArg = args['color'] as Color?;
      final String? emotionArg = args['emotion'] as String?;

      if (dateArg != null) _targetDate = dateArg;
      if (colorArg != null) _selectedColor = colorArg;
      if (emotionArg != null) _emotionLabel = emotionArg;
      if (diaryIdArg != null) {
        _diaryId = diaryIdArg;
        _isEditing = true;
      }

      _formattedDate = _formatChineseDate(_targetDate);

      if (_isEditing) {
        // 延後一個 frame 去載入現有日記
        WidgetsBinding.instance.addPostFrameCallback((_) => _loadExistingDiary());
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// 載入既有日記（編輯用）
  /// 加入 guard：如果目前正在儲存/載入（_isLoading==true）就直接 return，
  /// 避免在儲存期間被覆蓋從而產生「先看到舊文字再跳回上一頁」的視覺閃爍。
  Future<void> _loadExistingDiary() async {
    // 若正在做其他網路操作（例如正在儲存），就不要去載入，避免覆蓋使用者編輯的內容
    if (_isLoading) return;

    setState(() => _isLoading = true);
    try {
      final detail = await DiaryService.fetchDiaryByDate(_targetDate);
      if (detail != null) {
        final content = (detail['content'] ?? '') as String? ?? '';

        // 只有在使用者尚未開始編輯（controller 為空）時才自動覆蓋文字
        // 這樣可以避免「載入完成後覆蓋使用者剛輸入的文字」
        if (_controller.text.isEmpty) {
          _controller.text = content;
        }

        final mood = (detail['mood'] ?? detail['emotion']) as String?;
        if (mood != null && mood.isNotEmpty) {
          _emotionLabel = mood;
        }

        final hex = (detail['color'] ?? detail['mood_color']) as String?;
        if (hex != null && hex.isNotEmpty) {
          _selectedColor = _hexToColor(hex);
        }

        _diaryId ??= (detail['id'] as num?)?.toInt();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('載入日記失敗：$e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveEntry() async {
    final content = _controller.text.trim();
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('請先輸入今日心情內容')),
      );
      return;
    }

    // 收起鍵盤
    FocusScope.of(context).unfocus();

    // 標記為 loading（會禁用按鈕與輸入）
    setState(() => _isLoading = true);

    try {
      if (_isEditing && _diaryId != null) {
        // 更新流程（編輯）
        final res = await DiaryService.updateDiary(
          id: _diaryId!,
          content: content,
          date: _targetDate,
          mood: _normalizeMoodToApi(_emotionLabel),
          moodColor: _colorToHex(_selectedColor),
        );

        if (!mounted) return;

        if (res['success'] == true) {
          // 樂觀更新 controller（確保畫面顯示為剛剛的內容）
          _controller.text = content;

          // 立即返回上一頁並傳回 true 表示已更新（避免在 pop 前被其他 reload 覆蓋）
          Navigator.pop(context, true);
          // 注意：pop 之後通常父頁面會依回傳值刷新，請在父頁面處理刷新節奏以避免卡頓
        } else {
          final msg = (res['error'] ?? '更新失敗，請稍後再試').toString();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
          }
        }
      } else {
        // 新增流程
        final result = await DiaryService.createDiary(
          content: content,
          date: _targetDate,
          mood: _normalizeMoodToApi(_emotionLabel),
          moodColor: _colorToHex(_selectedColor),
          title: null,
          emotion: _emotionLabel,
        );

        if (!mounted) return;

        if (result['success'] == true) {
          _controller.clear();
          final isToday = DateFormat('yyyy-MM-dd').format(_targetDate) == DateFormat('yyyy-MM-dd').format(DateTime.now());

          if (isToday) {
            // 如果是今天，導到 PostEntryScreen
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) => PostEntryScreen(
                  emotionLabel: _displayNameForMood(_emotionLabel),
                  emotionColor: _selectedColor,
                  entryContent: content,
                  aiLabel: (result['label'] ?? '').toString(),
                  aiMessage: (result['ai_message'] ?? '').toString(),
                ),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  const begin = Offset(0.0, -1.0);
                  const end = Offset.zero;
                  const curve = Curves.ease;
                  var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                  return SlideTransition(
                    position: animation.drive(tween),
                    child: child,
                  );
                },
                transitionDuration: const Duration(milliseconds: 600),
              ),
            );
          } else {
            // 如果是補寫，導到 RePostEntryScreen
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) => RePostEntryScreen(
                  entryContent: content,
                  aiLabel: (result['label'] ?? '').toString(),
                  aiMessage: (result['ai_message'] ?? '').toString(),
                ),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  const begin = Offset(0.0, -1.0);
                  const end = Offset.zero;
                  const curve = Curves.ease;
                  var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                  return SlideTransition(
                    position: animation.drive(tween),
                    child: child,
                  );
                },
                transitionDuration: const Duration(milliseconds: 600),
              ),
            );
          }
        } else {
          final errorMsg = result['error'] ?? '儲存失敗，請稍後再試';
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(errorMsg)),
            );
          }
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('錯誤：$e')),
      );
    } finally {
      // 儲存/載入流程結束：解除 loading（如果已經 pop，setState 不會執行）
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ===== UI =====
  @override
  Widget build(BuildContext context) {
    final displayEmotion = _displayNameForMood(_emotionLabel);
    final isToday = DateFormat('yyyy-MM-dd').format(_targetDate) == DateFormat('yyyy-MM-dd').format(DateTime.now());

    return Scaffold(
      // 將 Scaffold 的 body 改為包含漸層背景的 Container
      resizeToAvoidBottomInset: true, // 確保鍵盤彈出時可以自動調整大小
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFFFFF), Color(0xFFDFF0DC)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 頂部資訊區塊
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    const SizedBox(width: 2),
                    IconButton(
                      icon: Icon(Icons.arrow_back_ios_new, color: Color(0xFF4C4C4C)),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 10),
                          Text(
                            _formattedDate,
                            style: const TextStyle(
                              fontSize: 20,
                              color: Color(0xFF4C4C4C),
                            ),
                          ),
                          const SizedBox(height: 10),
                          if (isToday)
                            Text(
                              displayEmotion.isEmpty ? '今天' : '今天是「$displayEmotion」',
                              style: const TextStyle(
                                fontSize: 20,
                                color: Color(0xFF4C4C4C),
                              ),
                            ),
                          if (!isToday)
                            const SizedBox(height: 32),
                        ],
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
                if (isToday) ...[
                  const SizedBox(height: 24),
                  // 圓形情緒圖示
                  Center(
                    child: Container(
                      width: 135,
                      height: 135,
                      decoration: BoxDecoration(
                        color: Color.fromARGB(255, 255, 255, 255),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Color.fromARGB(26, 0, 0, 0), // 黑 0.1 opacity ≈ 26/255
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Image.asset(
                          _assetForEmotion(_emotionLabel),
                          color: _selectedColor,
                          colorBlendMode: BlendMode.srcIn,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                // 輸入框區塊
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Color.fromARGB(255, 255, 255, 255),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Color.fromARGB(26, 0, 0, 0),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: TextField(
                        controller: _controller,
                        enabled: !_isLoading, // 儲存/載入時禁用輸入，避免使用者在存檔時繼續編輯
                        keyboardType: TextInputType.multiline,
                        maxLines: null,
                        decoration: InputDecoration(
                          hintText: '請記錄下今天的心情日記...',
                          border: InputBorder.none,
                          hintStyle: TextStyle(
                            fontSize: 16,
                            color: const Color.fromARGB(255, 124, 124, 124),
                          ),
                        ),
                        style: const TextStyle(fontSize: 18, color: Colors.black87),
                        textInputAction: TextInputAction.newline,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // 發光按鈕
                GlowingButton(
                  onPressed: _isLoading ? null : _saveEntry,
                  baseColor: const Color.fromARGB(255, 102, 218, 76),
                  child: _isLoading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.2))
                      : Text(
                          _isEditing ? '更新日記' : '存入心情存摺',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper 方法（未變動）
  String _formatChineseDate(DateTime dt) {
    final ymd = DateFormat('yyyy年MM月dd日').format(dt);
    const weekdays = ['星期日', '星期一', '星期二', '星期三', '星期四', '星期五', '星期六'];
    final weekday = weekdays[dt.weekday % 7];
    return '$ymd $weekday';
  }

  String _displayNameForMood(String mood) {
    switch (mood) {
      case 'sunny':
        return '快樂';
      case 'storm':
        return '憤怒';
      case 'cloud':
        return '悲傷';
      case 'lightning':
        return '恐懼';
      case 'snowflake':
        return '驚訝';
      case 'rain':
        return '厭惡';
      default:
        return mood;
    }
  }

  // 【重要修改】修正中文心情名稱的轉換邏輯
  String? _normalizeMoodToApi(String? label) {
    if (label == null || label.isEmpty) return null;
    switch (label) {
      case '快樂':
      case 'sunny':
        return 'sunny';
      case '憤怒':
      case 'storm':
        return 'storm';
      case '悲傷':
      case 'cloud':
        return 'cloud';
      case '恐懼':
      case 'lightning':
        return 'lightning';
      case '驚訝':
      case 'snowflake':
        return 'snowflake';
      case '厭惡':
      case 'rain':
        return 'rain';
      default:
        return label;
    }
  }

  String _assetForEmotion(String emotion) {
    switch (emotion) {
      case '快樂':
      case 'sunny':
        return 'assets/images/emotion_sun.png';
      case '憤怒':
      case 'storm':
        return 'assets/images/emotion_tornado.png';
      case '悲傷':
      case 'cloud':
        return 'assets/images/emotion_cloud.png';
      case '恐懼':
      case 'lightning':
        return 'assets/images/emotion_lightning.png';
      case '驚訝':
      case 'snowflake':
        return 'assets/images/emotion_snowflake.png';
      case '厭惡':
      case 'rain':
        return 'assets/images/emotion_rain.png';
      default:
        return 'assets/images/emotion_cloud.png';
    }
  }

  String _colorToHex(Color c) {
    final rgb = c.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase();
    return '#$rgb';
  }

  Color _hexToColor(String hex) {
    final h = hex.replaceAll('#', '');
    if (h.length != 6) return Colors.blue.shade200;
    return Color(int.parse('FF$h', radix: 16));
  }
}
