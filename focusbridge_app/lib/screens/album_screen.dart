// lib/screens/album_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:focusbridge_app/widgets/app_bottom_nav.dart';
import 'package:focusbridge_app/services/photo_service.dart';
import 'package:intl/intl.dart';

class AlbumScreen extends StatefulWidget {
  const AlbumScreen({super.key});

  @override
  State<AlbumScreen> createState() => _AlbumScreenState();
}

class _AlbumScreenState extends State<AlbumScreen> {
  // 情緒標籤與對應的圖示
  static const List<Map<String, String>> _emotionOptions = [
    {'label': '快樂', 'icon': 'assets/images/emotion_sun.png'},
    {'label': '憤怒', 'icon': 'assets/images/emotion_tornado.png'},
    {'label': '悲傷', 'icon': 'assets/images/emotion_cloud.png'},
    {'label': '恐懼', 'icon': 'assets/images/emotion_lightning.png'},
    {'label': '驚訝', 'icon': 'assets/images/emotion_snowflake.png'},
    {'label': '厭惡', 'icon': 'assets/images/emotion_rain.png'},
  ];

  /// 從後端獲得的照片列表，包含 id, url, emotion
  List<Map<String, dynamic>> _items = [];

  /// 目前選中的情緒分類。null = 全部
  String? _selectedEmotion;

  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();

  // 拍立得風格 UI 配色
  final Color _backgroundColor = const Color.fromARGB(255, 250, 246, 221);
  final Color _primaryColor = const Color(0xFF67B7D1);
  final Color _boxChooseColor = const Color.fromARGB(255, 197, 240, 255);
  final Color _textColor = const Color(0xFF4A415A);
  final Color _boxColor = const Color.fromARGB(255, 255, 255, 255);


  @override
  void initState() {
    super.initState();
    _fetchRemotePhotos();
  }

  Future<void> _fetchRemotePhotos() async {
    setState(() { _isLoading = true; });
    try {
      final list = await PhotoService.fetchPhotos();
      final data = list.map((m) {
        DateTime? createdAt;
        // 嘗試安全地解析日期，如果失敗則設為 null
        try {
          if (m['created_at'] != null) {
            createdAt = DateTime.parse(m['created_at'] as String);
          }
        } catch (e) {
          // 如果解析失敗，在控制台印出錯誤以便偵錯
          print('無法解析日期：${m['created_at']}，錯誤：$e');
        }

        return {
          'id': m['id'] as int,
          'url': m['image'] as String,
          'emotion': (m['emotion'] as String).trim(),
          'created_at': createdAt, // 存入解析後或為 null 的日期
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
      builder: (_) => AlertDialog(
        backgroundColor: _boxChooseColor,
        title: const Text('選擇照片情緒', textAlign: TextAlign.center),
        content: SizedBox(
          width: double.maxFinite,
          child: GridView.builder(
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1,
            ),
            itemCount: _emotionOptions.length,
            itemBuilder: (context, index) {
              final option = _emotionOptions[index];
              return InkWell(
                onTap: () => Navigator.pop(context, option['label']),
                child: Card(
                  elevation: 2,
                  color: _boxColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        option['icon']!,
                        width: 40,
                        height: 40,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        option['label']!,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: _textColor,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  /// 長按刪除
  Future<void> _confirmDelete(int id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('刪除照片？', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('這張照片將被永久刪除，確定要繼續嗎？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade400,
            ),
            child: const Text('刪除', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok == true) {
      setState(() { _isLoading = true; });
      try {
        await PhotoService.deletePhoto(id);
        await _fetchRemotePhotos();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ 刪除成功'))
          );
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('刪除失敗：$e'))
        );
      } finally {
        if (mounted) setState(() { _isLoading = false; });
      }
    }
  }

  void _showPhoto(Map<String, dynamic> item) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: Center(
            child: InteractiveViewer(
              panEnabled: true,
              minScale: 0.5,
              maxScale: 2.5,
              child: Image.network(
                item['url'] as String,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 根據分類篩選顯示資料
    final displayList = _selectedEmotion == null
      ? _items
      : _items.where((it) => it['emotion'] == _selectedEmotion).toList();

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: Text('我的相簿', style: TextStyle(fontWeight: FontWeight.bold, color: _textColor)),
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          // 拍立得風格的標籤雲
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
            child: Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: [
                _buildFilterChip('全部', null, null),
                ..._emotionOptions.map((e) => _buildFilterChip(e['label'], e['label'], e['icon'])).toList(),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
              ? Center(child: CircularProgressIndicator(color: _primaryColor))
              : displayList.isEmpty
                ? Center(
                    child: Text(
                      _selectedEmotion == null ? '目前沒有任何照片' : '沒有找到關於「$_selectedEmotion」的照片',
                      style: const TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 24,
                        childAspectRatio: 0.85,
                      ),
                      itemCount: displayList.length,
                      itemBuilder: (_, i) {
                        final item = displayList[i];
                        return _buildPolaroidPhoto(item);
                      },
                    ),
                  ),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 4),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final emo = await _chooseEmotion();
          if (emo != null) await _addPhoto(emo);
        },
        backgroundColor: _primaryColor,
        child: const Icon(Icons.add_a_photo, color: Colors.white),
      ),
    );
  }

  Widget _buildFilterChip(String? label, String? emotion, String? iconPath) {
    final isSelected = _selectedEmotion == emotion;
    // 移除不透明度調整
    final opacity = 1.0;

    return GestureDetector(
      onTap: () => setState(() { _selectedEmotion = emotion; }),
      child: AnimatedOpacity(
        opacity: opacity,
        duration: const Duration(milliseconds: 300),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? _primaryColor : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (iconPath != null)
                Image.asset(iconPath, width: 20, height: 20),
              if (iconPath != null) const SizedBox(width: 8),
              Text(
                label!,
                style: TextStyle(
                  fontSize: 14,
                  color: isSelected ? Colors.white : _textColor,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPolaroidPhoto(Map<String, dynamic> item) {
    return GestureDetector(
      onTap: () => _showPhoto(item),
      onLongPress: () => _confirmDelete(item['id'] as int),
      child: Hero(
        tag: item['id'],
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 1,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: AspectRatio(
                    aspectRatio: 1.0, // 確保圖片顯示為1:1正方形
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.network(
                        item['url'] as String,
                        fit: BoxFit.cover,
                        loadingBuilder: (_, child, progress) =>
                          progress == null
                            ? child
                            : Center(child: CircularProgressIndicator(color: _primaryColor)),
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.grey.shade200,
                          child: const Center(
                            child: Icon(Icons.broken_image, color: Colors.grey, size: 40),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}