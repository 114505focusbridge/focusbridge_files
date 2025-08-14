import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:focusbridge_app/screens/post_entry_screen.dart';
import 'package:focusbridge_app/widgets/app_bottom_nav.dart';
import 'package:focusbridge_app/services/diary_service.dart';

class DiaryEntryScreen extends StatefulWidget {
  const DiaryEntryScreen({super.key});

  @override
  State<DiaryEntryScreen> createState() => _DiaryEntryScreenState();
}

class _DiaryEntryScreenState extends State<DiaryEntryScreen> {
  // 狀態
  late TextEditingController _controller;
  String _emotionLabel = '';     // 可能是中文(快樂…)或英文鍵(sunny…)
  Color _selectedColor = Colors.blue.shade200;
  DateTime _targetDate = DateTime.now();
  String _formattedDate = '';
  bool _isLoading = false;
  bool _isEditing = false;
  int? _diaryId;                 // 有值代表編輯模式

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
      // 讀進路由帶來的參數
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

      // 編輯模式 → 載入當日全文（用 by-date）
      if (_isEditing) {
        // 避免在 build 中 setState：延後到 frame 後執行
        WidgetsBinding.instance.addPostFrameCallback((_) => _loadExistingDiary());
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // 讀取既有日記（編輯模式）
  Future<void> _loadExistingDiary() async {
    setState(() => _isLoading = true);
    try {
      final detail = await DiaryService.fetchDiaryByDate(_targetDate);
      if (detail != null) {
        // 預填內容
        final content = (detail['content'] ?? '') as String? ?? '';
        _controller.text = content;

        // 情緒（可能是英文鍵）
        final mood = (detail['mood'] ?? detail['emotion']) as String?;
        if (mood != null && mood.isNotEmpty) {
          _emotionLabel = mood; // 先存原始（可能英文），顯示時再轉中文
        }

        // 顏色
        final hex = (detail['color'] ?? detail['mood_color']) as String?;
        if (hex != null && hex.isNotEmpty) {
          _selectedColor = _hexToColor(hex);
        }

        // 如果沒傳 diaryId，從 detail 帶
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

  // 儲存（新增 or 編輯）
  Future<void> _saveEntry() async {
    final content = _controller.text.trim();
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('請先輸入今日心情內容')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_isEditing && _diaryId != null) {
        // 編輯模式
        final res = await DiaryService.updateDiary(
          id: _diaryId!,
          content: content,
          date: _targetDate,
          mood: _normalizeMoodToApi(_emotionLabel),
          moodColor: _colorToHex(_selectedColor),
        );

        if (!mounted) return;

        if (res['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('已更新日記')),
          );
          Navigator.pop(context); // 返回月曆
        } else {
          final msg = (res['error'] ?? '更新失敗，請稍後再試').toString();
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
        }
      } else {
        // 新增模式
        final result = await DiaryService.createDiary(
          content: content,
          date: _targetDate,
          mood: _normalizeMoodToApi(_emotionLabel),
          moodColor: _colorToHex(_selectedColor),
          title: null,
          emotion: _emotionLabel, // 為了相容舊欄位（後端不需要也無妨）
        );

        if (!mounted) return;

        if (result['success'] == true) {
          _controller.clear();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PostEntryScreen(
                emotionLabel: _displayNameForMood(_emotionLabel),
                emotionColor: _selectedColor,
                entryContent: content,
                aiLabel: (result['label'] ?? '').toString(),
                aiMessage: (result['ai_message'] ?? '').toString(),
              ),
            ),
          );
        } else {
          final errorMsg = result['error'] ?? '儲存失敗，請稍後再試';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMsg)),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('錯誤：$e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ===== UI =====
  @override
  Widget build(BuildContext context) {
    final displayEmotion = _displayNameForMood(_emotionLabel); // 顯示用中文
    return Scaffold(
      appBar: AppBar(
        title: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_formattedDate, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 4),
            Text(
              displayEmotion.isEmpty ? '今天' : '今天是「$displayEmotion」',
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF9CAF88),
        centerTitle: true,
        toolbarHeight: 80,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Image.asset(
                  _assetForEmotion(_emotionLabel),
                  width: 120,
                  height: 120,
                  color: _selectedColor,
                  colorBlendMode: BlendMode.srcIn,
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: TextField(
                  controller: _controller,
                  keyboardType: TextInputType.multiline,
                  maxLines: null,
                  decoration: InputDecoration(
                    hintText: '用一句話記下今天的心情小記...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveEntry,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF9CAF88),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(_isEditing ? '更新日記' : '存入心情存摺',
                          style: const TextStyle(fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 2),
    );
  }

  // ===== Helper =====

  // 中文日期（含星期）
  String _formatChineseDate(DateTime dt) {
    final ymd = DateFormat('yyyy年MM月dd日').format(dt);
    const weekdays = ['星期日', '星期一', '星期二', '星期三', '星期四', '星期五', '星期六'];
    final weekday = weekdays[dt.weekday % 7];
    return '$ymd $weekday';
  }

  // 顯示用中文名稱（把英文鍵轉中文；若原本就是中文則原樣）
  String _displayNameForMood(String mood) {
    switch (mood) {
      case 'sunny':
        return '快樂';
      case 'cloudy':
        return '平靜';
      case 'rain':
        return '悲傷';
      case 'storm':
        return '憤怒';
      case 'windy':
        return '不安';
      default:
        return mood; // 已是中文或空字串
    }
  }

  // 傳給 API 的情緒鍵（把中文轉成英文鍵；若已是英文鍵則原樣）
  String? _normalizeMoodToApi(String? label) {
    if (label == null || label.isEmpty) return null;
    switch (label) {
      case '快樂':
        return 'sunny';
      case '平靜':
        return 'cloudy';
      case '悲傷':
        return 'rain';
      case '憤怒':
      case '恐懼':
        return 'storm';
      case '驚訝':
      case '不安':
        return 'windy';
      default:
        return label; // 可能已經是 'sunny' 等
    }
  }

  // 圖示資源：同時支援中文與英文鍵
  String _assetForEmotion(String emotion) {
    switch (emotion) {
      case '快樂':
      case 'sunny':
        return 'assets/images/emotion_sun.png';
      case '憤怒':
      case 'storm':
      case '恐懼':
        return 'assets/images/emotion_lightning.png';
      case '悲傷':
      case 'rain':
        return 'assets/images/emotion_rain.png';
      case '驚訝':
      case 'windy':
        return 'assets/images/emotion_snowflake.png';
      case '厭惡':
      case 'cloudy':
      case '平靜':
        return 'assets/images/emotion_cloud.png';
      default:
        return 'assets/images/emotion_cloud.png';
    }
  }

  // Color -> '#RRGGBB'
  String _colorToHex(Color c) {
    final rgb = c.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase();
    return '#$rgb';
  }

  // '#RRGGBB' -> Color
  Color _hexToColor(String hex) {
    final h = hex.replaceAll('#', '');
    if (h.length != 6) return Colors.blue.shade200;
    return Color(int.parse('FF$h', radix: 16));
  }
}
