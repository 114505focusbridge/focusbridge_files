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
  static const List<String> _emotionLabels = ['快樂','憤怒','悲傷','恐懼','驚訝','厭惡'];

  List<String> _allPhotos = [];
  Map<String, List<String>> _remoteAlbums = { for (var e in _emotionLabels) e: <String>[] };
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
      debugPrint('🔍 fetchPhotos returned: ${list.length} items');
      final tmp = { for (var e in _emotionLabels) e: <String>[] };
      final all = <String>[];
      for (var item in list) {
        final urlRaw = item['image'];
        final emoRaw = item['emotion'];
        if (urlRaw == null) continue;
        final url = urlRaw.toString();
        all.add(url);
        final emoStr = emoRaw?.toString().trim() ?? '';
        debugPrint('📌 photo emotion: "$emoStr"');
        if (tmp.containsKey(emoStr)) {
          tmp[emoStr]!.add(url);
        } else {
          debugPrint('⚠️ unknown emotion: "$emoStr", skip');
        }
      }
      setState(() {
        _allPhotos = all;
        _remoteAlbums = tmp;
      });
    } catch (e) {
      debugPrint('🔴 fetchRemotePhotos error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('取得照片失敗：$e')),
        );
      }
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  Future<void> _addPhoto(String emotion) async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    setState(() { _isLoading = true; });
    try {
      await PhotoService.uploadPhoto(imageFile: File(picked.path), emotion: emotion);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('📤 上傳成功')),
        );
        await _fetchRemotePhotos();
      }
    } catch (e) {
      debugPrint('🔴 uploadPhoto error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('⚠️ 上傳失敗：$e')),
        );
      }
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

  @override
  Widget build(BuildContext context) {
    final urls = _selectedEmotion == null
      ? _allPhotos
      : (_remoteAlbums[_selectedEmotion] ?? []);

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
                    itemCount: urls.length,
                    itemBuilder: (_, i) => ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        urls[i],
                        fit: BoxFit.cover,
                        loadingBuilder: (_, child, progress) =>
                          progress == null
                            ? child
                            : const Center(child: CircularProgressIndicator()),
                        errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
                      ),
                    ),
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
