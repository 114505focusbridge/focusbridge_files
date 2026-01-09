// lib/screens/album_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:focusbridge_app/widgets/app_bottom_nav.dart';
import 'package:focusbridge_app/services/photo_service.dart';

class AlbumScreen extends StatefulWidget {
  const AlbumScreen({super.key});

  @override
  State<AlbumScreen> createState() => _AlbumScreenState();
}

class _AlbumScreenState extends State<AlbumScreen> {
  static const List<String> _emotionLabels = [
    '快樂', '憤怒', '悲傷', '恐懼', '驚訝', '厭惡',
  ];

  /// 從後端獲得的照片列表，包含 id, url, emotion
  List<Map<String, dynamic>> _items = [];

  /// 目前選中的情緒分類。null = 全部
  String? _selectedEmotion;

  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _fetchRemotePhotos();
  }

  Future<void> _fetchRemotePhotos() async {
    setState(() { _isLoading = true; });
    try {
      final list = await PhotoService.fetchPhotos();
      // list: List<Map> 包含 {'id': int, 'image': String, 'emotion': String}
      final data = list.map((m) {
        return {
          'id': m['id'] as int,
          'url': m['image'] as String,
          'emotion': (m['emotion'] as String).trim(),
        };
      }).toList();
      setState(() { _items = data; });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('取得照片失敗：$e'))
      );
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  Future<void> _addPhoto(String emotion) async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    setState(() { _isLoading = true; });
    try {
      await PhotoService.uploadPhoto(
        imageFile: File(picked.path),
        emotion: emotion,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('📤 上傳成功'))
        );
        await _fetchRemotePhotos();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('⚠️ 上傳失敗：$e'))
      );
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  Future<String?> _chooseEmotion() {
    return showDialog<String>(
      context: context,
      builder: (_) => SimpleDialog(
        title: const Text('選擇情緒'),
        children: _emotionLabels.map((e) => SimpleDialogOption(
          onPressed: () => Navigator.pop(context, e),
          child: Text(e),
        )).toList(),
      ),
    );
  }

  /// 長按刪除
  Future<void> _confirmDelete(int id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('刪除照片？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('刪除')),
        ],
      ),
    );
    if (ok == true) {
      setState(() { _isLoading = true; });
      try {
        await PhotoService.deletePhoto(id);
        await _fetchRemotePhotos();
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('刪除失敗：$e'))
        );
      } finally {
        if (mounted) setState(() { _isLoading = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 根據分類篩選顯示資料
    final displayList = _selectedEmotion == null
      ? _items
      : _items.where((it) => it['emotion'] == _selectedEmotion).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('相簿'),
        backgroundColor: const Color(0xFF9CAF88),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text('全部'),
                  selected: _selectedEmotion == null,
                  onSelected: (_) => setState(() { _selectedEmotion = null; }),
                ),
                const SizedBox(width: 8),
                for (var emo in _emotionLabels) ...[
                  ChoiceChip(
                    label: Text(emo),
                    selected: _selectedEmotion == emo,
                    onSelected: (_) => setState(() { _selectedEmotion = emo; }),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          Expanded(
            child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 1,
                    ),
                    itemCount: displayList.length,
                    itemBuilder: (_, i) {
                      final item = displayList[i];
                      return GestureDetector(
                        onLongPress: () => _confirmDelete(item['id'] as int),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            item['url'] as String,
                            fit: BoxFit.cover,
                            loadingBuilder: (_, child, progress) =>
                              progress == null
                                ? child
                                : const Center(child: CircularProgressIndicator()),
                            errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
                          ),
                        ),
                      );
                    },
                  ),
                ),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 5),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final emo = _selectedEmotion ?? await _chooseEmotion();
          if (emo != null) await _addPhoto(emo);
        },
        child: const Icon(Icons.add_a_photo),
      ),
    );
  }
}
