// lib/screens/album_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:focusbridge_app/widgets/app_bottom_nav.dart'; // 共用導航

class AlbumScreen extends StatefulWidget {
  const AlbumScreen({super.key});

  @override
  State<AlbumScreen> createState() => _AlbumScreenState();
}

class _AlbumScreenState extends State<AlbumScreen> {
  // 與 HomeScreen 同步的情緒標籤
  static const List<String> _emotionLabels = [
    '快樂', '憤怒', '悲傷', '恐懼', '驚訝', '厭惡',
  ];

  // 各情緒對應的照片列表
  late final Map<String, List<File>> _emotionAlbums;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _emotionAlbums = {for (var e in _emotionLabels) e: <File>[]};
  }

  Future<void> _addPhoto(String emotion) async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _emotionAlbums[emotion]!.add(File(picked.path));
      });
    }
  }

  Future<void> _renameEmotion(String oldName) async {
    final controller = TextEditingController(text: oldName);
    final newName = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('重新命名情緒'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: '輸入新的情緒名稱'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          ElevatedButton(
            onPressed: () {
              final v = controller.text.trim();
              if (v.isNotEmpty && !_emotionAlbums.containsKey(v)) Navigator.pop(context, v);
            },
            child: const Text('確定'),
          ),
        ],
      ),
    );
    if (newName != null && newName != oldName) {
      setState(() {
        final photos = _emotionAlbums.remove(oldName)!;
        _emotionAlbums[newName] = photos;
      });
    }
  }

  Future<void> _addNewEmotion() async {
    final controller = TextEditingController();
    final newEmotion = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('新增情緒分類'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: '輸入情緒名稱'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          ElevatedButton(
            onPressed: () {
              final v = controller.text.trim();
              if (v.isNotEmpty && !_emotionAlbums.containsKey(v)) Navigator.pop(context, v);
            },
            child: const Text('新增'),
          ),
        ],
      ),
    );
    if (newEmotion != null) {
      setState(() {
        _emotionAlbums[newEmotion] = [];
      });
    }
  }

  void _removePhoto(String emotion, int idx) {
    setState(() {
      _emotionAlbums[emotion]!.removeAt(idx);
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 12),
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
      bottomNavigationBar: const AppBottomNav(currentIndex: 5) // 對應「個人」索引, // 修正為相簿索引=4
    );
  }

  Widget _buildEmotionSection(String emotion) {
    final photos = _emotionAlbums[emotion]!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => _renameEmotion(emotion),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(emotion, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 100,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: photos.length + 1,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (c, i) {
                if (i < photos.length) {
                  return _buildPhotoTile(emotion, i);
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

  Widget _buildPhotoTile(String emotion, int idx) {
    final file = _emotionAlbums[emotion]![idx];
    return GestureDetector(
      onLongPress: () {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('刪除照片'),
            content: const Text('確定要刪除此照片？'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
              ElevatedButton(onPressed: () { Navigator.pop(context); _removePhoto(emotion, idx); }, child: const Text('刪除')),
            ],
          ),
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
