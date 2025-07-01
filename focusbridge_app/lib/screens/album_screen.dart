// lib/screens/album_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:focusbridge_app/widgets/app_bottom_nav.dart'; // ← 新增共用導航

class AlbumScreen extends StatefulWidget {
  const AlbumScreen({super.key});

  @override
  State<AlbumScreen> createState() => _AlbumScreenState();
}

class _AlbumScreenState extends State<AlbumScreen> {
  // 將情緒分類改成與 HomeScreen 一致的標籤
  static const List<String> _emotionLabels = [
    '快樂',
    '憤怒',
    '悲傷',
    '恐懼',
    '驚訝',
    '厭惡',
  ];

  // Map<情緒名稱, List<File>> 存放每個情緒對應的照片列表
  late final Map<String, List<File>> _emotionAlbums;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // 初始化時，針對每個情緒名稱都建立空的 List<File>
    _emotionAlbums = {for (var label in _emotionLabels) label: <File>[]};
  }

  /// 使用者點擊「+」要新增當下情緒的照片
  Future<void> _addPhoto(String emotion) async {
    final XFile? picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _emotionAlbums[emotion]!.add(File(picked.path));
      });
    }
  }

  /// 使用者點擊情緒名稱時可以重新命名
  Future<void> _renameEmotion(String oldName) async {
    final controller = TextEditingController(text: oldName);
    final newName = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('重新命名情緒'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: '輸入新的情緒名稱'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () {
                final value = controller.text.trim();
                if (value.isNotEmpty && !_emotionAlbums.containsKey(value)) {
                  Navigator.pop(context, value);
                }
              },
              child: const Text('確定'),
            ),
          ],
        );
      },
    );
    if (newName != null && newName != oldName) {
      setState(() {
        final photos = _emotionAlbums.remove(oldName)!;
        _emotionAlbums[newName] = photos;
      });
    }
  }

  /// 新增一個全新的情緒分類
  Future<void> _addNewEmotion() async {
    final controller = TextEditingController();
    final newEmotion = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('新增情緒分類'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: '輸入情緒名稱'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () {
                final value = controller.text.trim();
                if (value.isNotEmpty && !_emotionAlbums.containsKey(value)) {
                  Navigator.pop(context, value);
                }
              },
              child: const Text('新增'),
            ),
          ],
        );
      },
    );
    if (newEmotion != null) {
      setState(() {
        _emotionAlbums[newEmotion] = [];
      });
    }
  }

  /// 刪除單張照片
  void _removePhoto(String emotion, int index) {
    setState(() {
      _emotionAlbums[emotion]!.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('相簿'),
        backgroundColor: const Color(0xFF9CAF88),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: SingleChildScrollView(
            child: Column(
              children: [
                for (final emotion in _emotionAlbums.keys)
                  _buildEmotionSection(emotion),
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: _addNewEmotion,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: const Color(0xFF9CAF88),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Icon(Icons.add, size: 48, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 5), // ← 使用共用導航, 相簿索引=5
    );
  }

  Widget _buildEmotionSection(String emotion) {
    final photos = _emotionAlbums[emotion]!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => _renameEmotion(emotion),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                emotion,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 100,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              itemCount: photos.length + 1,
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                if (index < photos.length) {
                  return _buildPhotoTile(emotion, index);
                } else {
                  return GestureDetector(
                    onTap: () => _addPhoto(emotion),
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(8)),
                      child: const Center(child: Icon(Icons.add, size: 32, color: Colors.black54)),
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoTile(String emotion, int index) {
    final file = _emotionAlbums[emotion]![index];
    return GestureDetector(
      onLongPress: () {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('刪除照片'),
              content: const Text('確定要刪除此照片？'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
                ElevatedButton(onPressed: () { Navigator.pop(context); _removePhoto(emotion, index); }, child: const Text('刪除')),
              ],
            );
          },
        );
      },
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          image: DecorationImage(image: FileImage(file), fit: BoxFit.cover),
        ),
      ),
    );
  }
}
