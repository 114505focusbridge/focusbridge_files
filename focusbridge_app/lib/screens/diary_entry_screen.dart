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
  late String _emotionLabel;
  late Color _selectedColor;
  late TextEditingController _controller;
  late String _formattedDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    final now = DateTime.now();
    _formattedDate = _formatChineseDate(now);
    _emotionLabel = '';
    _selectedColor = Colors.blue.shade200;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)!.settings.arguments;
    if (args is Map<String, dynamic>) {
      _emotionLabel = args['emotion'] as String;
      _selectedColor = args['color'] as Color;
    }
    _formattedDate = _formatChineseDate(DateTime.now());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _assetForEmotion(String emotion) {
    switch (emotion) {
      case '快樂':
        return 'assets/images/emotion_sun.png';
      case '憤怒':
        return 'assets/images/emotion_tornado.png';
      case '悲傷':
        return 'assets/images/emotion_cloud.png';
      case '恐懼':
        return 'assets/images/emotion_lightning.png';
      case '驚訝':
        return 'assets/images/emotion_snowflake.png';
      case '厭惡':
        return 'assets/images/emotion_rain.png';
      default:
        return 'assets/images/emotion_cloud.png';
    }
  }

  String _formatChineseDate(DateTime dt) {
    final ymd = DateFormat('yyyy年MM月dd日').format(dt);
    const weekdays = ['星期日', '星期一', '星期二', '星期三', '星期四', '星期五', '星期六'];
    final weekday = weekdays[dt.weekday % 7];
    return '$ymd $weekday';
  }

  Future<void> _saveEntryAndNavigate() async {
    final content = _controller.text.trim();
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('請先輸入今日心情內容')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final success = await DiaryService.createDiary(
        content: content,
        emotion: _emotionLabel,
        );

      if (success) {
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PostEntryScreen(
              emotionLabel: _emotionLabel,
              emotionColor: _selectedColor,
              entryContent: content,
            ),
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('儲存失敗，請稍後再試')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('錯誤：${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text(_formattedDate, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 4),
            Text(
              '今天是："$_emotionLabel"',
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
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed:
                      _isLoading ? null : _saveEntryAndNavigate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF9CAF88),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(
                          color: Colors.white,
                        )
                      : const Text(
                          '存入心情存摺',
                          style: TextStyle(fontSize: 18),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: AppBottomNav(currentIndex: 2),
    );
  }
}
