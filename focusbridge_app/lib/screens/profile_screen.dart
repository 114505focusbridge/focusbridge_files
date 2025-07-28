// lib/screens/profile_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:focusbridge_app/widgets/app_bottom_nav.dart';
import 'package:focusbridge_app/services/auth_service.dart';
import 'package:http/http.dart' as http;

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

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    final token = await AuthService.getToken();
    if (token == null) return;

    final url = Uri.parse('http://10.0.2.2:8000/api/moodlogs/');
    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Token $token',
        },
      );

      if (response.statusCode == 200) {
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
        }
      } else {
        debugPrint('⚠️ Profile 載入失敗: ${response.body}');
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('❌ Profile 載入錯誤: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('個人'),
        backgroundColor: const Color(0xFF9CAF88),
        automaticallyImplyLeading: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 48,
                      backgroundImage: _avatarUrl != null
                          ? NetworkImage(_avatarUrl!)
                          : const AssetImage('assets/default_avatar.png')
                              as ImageProvider,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _name ?? '未設定姓名',
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '@you',
                      style:
                          const TextStyle(fontSize: 14, color: Colors.black54),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_birth ?? '未設定生日'}  |  ${_gender ?? '未設定性別'}',
                      style:
                          const TextStyle(fontSize: 14, color: Colors.black54),
                    ),
                    const SizedBox(height: 16),
                    const Divider(thickness: 1),
                    const SizedBox(height: 16),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '小工具',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 16),
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
                            icon:
                                const Icon(Icons.shopping_cart_outlined),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _buildToolButton(context, Icons.center_focus_strong,
                            '專注', '/focus'),
                        const SizedBox(width: 8),
                        _buildToolButton(context, Icons.self_improvement,
                            '冥想', '/meditation'),
                        const SizedBox(width: 8),
                        _buildToolButton(
                            context, Icons.favorite, '呼吸', '/breathing'),
                      ],
                    ),
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
}
