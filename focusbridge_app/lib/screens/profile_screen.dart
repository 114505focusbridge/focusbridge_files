// lib/screens/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:focusbridge_app/widgets/app_bottom_nav.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: 之後可由 Provider 動態取得
    const avatarUrl = 'https://via.placeholder.com/150';
    const userName = 'Evan Fang';
    const userHandle = '@fang.tonxue';
    const birthInfo = '1998/10/24  |  男';
    const balance = 10000;

    return Scaffold(
      appBar: AppBar(
        title: const Text('個人'),
        backgroundColor: const Color(0xFF9CAF88),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 大頭貼與基本資訊
              CircleAvatar(
                radius: 48,
                backgroundImage: NetworkImage(avatarUrl),
              ),
              const SizedBox(height: 12),
              const Text(
                userName,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text(
                userHandle,
                style: TextStyle(fontSize: 14, color: Colors.black54),
              ),
              const SizedBox(height: 4),
              const Text(
                birthInfo,
                style: TextStyle(fontSize: 14, color: Colors.black54),
              ),

              const SizedBox(height: 16),
              const Divider(thickness: 1),
              const SizedBox(height: 16),

              // 小工具區
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
                      '💰 情緒餘額: \$${balance}',
                      style: const TextStyle(fontSize: 14),
                    ),
                    IconButton(
                      onPressed: () {
                        // TODO: 購買商店
                      },
                      icon: const Icon(Icons.shopping_cart_outlined),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 工具按鈕
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildToolButton(context, Icons.center_focus_strong, '專注'),
                  _buildToolButton(context, Icons.self_improvement, '冥想'),
                  _buildToolButton(context, Icons.favorite, '呼吸'),
                ],
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 3),
    );
  }

  /// 建構工具按鈕
  Widget _buildToolButton(BuildContext context, IconData icon, String label) {
    return Expanded(
      child: ElevatedButton(
        onPressed: () {
          // TODO: 實作各小工具功能
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$label 功能暫未實作')),
          );
        },
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
