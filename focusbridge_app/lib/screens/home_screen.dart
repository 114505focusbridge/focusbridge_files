// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:focusbridge_app/providers/auth_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // 底部選單目前選中的索引 (0～5)
  int _currentIndex = 0;

  // 第一列 & 第三列：情緒文字標籤
  static const List<String> _emotionLabels = [
    '快樂', '憤怒', '悲傷',
    '恐懼', '驚訝', '厭惡',
  ];

  // 第二列 & 第四列：情緒圖示資源路徑
  static const List<String> _emotionIcons = [
    'assets/images/emotion_sun.png',        // 快樂
    'assets/images/emotion_tornado.png',    // 憤怒
    'assets/images/emotion_cloud.png',      // 悲傷（雲朵）
    'assets/images/emotion_lightning.png',  // 恐懼
    'assets/images/emotion_snowflake.png',  // 驚訝
    'assets/images/emotion_rain.png',       // 厭惡
  ];

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('主頁'),
        backgroundColor: const Color(0xFF9CAF88),
        // 關閉自動顯示的「返回箭頭」
        automaticallyImplyLeading: false,
        // 移除右上角所有 action 按鈕
        actions: const [],
      ),

      // 根據 _currentIndex 決定 body 內容
      body: SafeArea(
        child: IndexedStack(
          index: _currentIndex,
          children: [
            // index = 0：展示情緒格子主畫面
            _buildMoodGrid(),
            // index = 1：成就頁 (暫留白)
            Center(child: Text('成就頁面（暫未實作）', style: TextStyle(fontSize: 18))),
            // index = 2：日記頁 (暫留白)
            Center(child: Text('日記頁面（暫未實作）', style: TextStyle(fontSize: 18))),
            // index = 3：個人頁 (暫留白)
            Center(child: Text('個人頁面（暫未實作）', style: TextStyle(fontSize: 18))),
            // index = 4：設定頁 (會由 onTap 跳轉，IndexedStack 上不顯示)
            Center(child: Text('設定頁面（已跳轉）', style: TextStyle(fontSize: 18))),
            // index = 5：情緒紀錄頁 (暫留白)
            Center(child: Text('情緒紀錄頁面（暫未實作）', style: TextStyle(fontSize: 18))),
          ],
        ),
      ),

      // 底部導覽列，總共 6 個按鈕
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF9CAF88),
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.grey.shade300,
        currentIndex: _currentIndex,
        onTap: (index) {
          if (index == 4) {
            // 按到「設定」時，跳轉到 SettingsScreen
            Navigator.pushNamed(context, '/settings');
            // 保持 _currentIndex 不變，避免 IndexedStack 跳到 index=4
            return;
          }
          // 其他 index 則更新選中狀態
          setState(() => _currentIndex = index);
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: '首頁',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.emoji_events_outlined),
            activeIcon: Icon(Icons.emoji_events),
            label: '成就',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book_outlined),
            activeIcon: Icon(Icons.book),
            label: '月曆',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: '個人',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: '設定',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.mood_outlined),
            activeIcon: Icon(Icons.mood),
            label: '相簿',
          ),
        ],
      ),
    );
  }

  /// 建構「主畫面情緒格子」(4x3)
  Widget _buildMoodGrid() {
    return Column(
      children: [
        const SizedBox(height: 24),
        const Text(
          '今天情緒如何呢...？',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 24),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GridView.count(
              crossAxisCount: 3,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1,
              children: [
                // 第一列：文字圓形按鈕 (快樂、憤怒、悲傷)
                for (int i = 0; i < 3; i++)
                  _buildTextEmotionCircle(_emotionLabels[i]),

                // 第二列：圖片圓形按鈕 (太陽、龍捲風、雲朵)
                for (int i = 0; i < 3; i++)
                  _buildIconEmotionCircle(_emotionIcons[i], _emotionLabels[i]),

                // 第三列：文字圓形按鈕 (恐懼、驚訝、厭惡)
                for (int i = 3; i < 6; i++)
                  _buildTextEmotionCircle(_emotionLabels[i]),

                // 第四列：圖片圓形按鈕 (雷電、雪花、雨滴雲)
                for (int i = 3; i < 6; i++)
                  _buildIconEmotionCircle(_emotionIcons[i], _emotionLabels[i]),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  /// 建構「文字情緒圓形」(深綠底 + 白色文字)，點擊後帶 emotionLabel 跳轉
  Widget _buildTextEmotionCircle(String emotionLabel) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          '/color_picker',
          arguments: emotionLabel,
        );
      },
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF9CAF88), // 深綠色
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Text(
          emotionLabel,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  /// 建構「圖示情緒圓形」(淺灰底 + 圖片)，點擊後帶 emotionLabel 跳轉
  Widget _buildIconEmotionCircle(String assetPath, String emotionLabel) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          '/color_picker',
          arguments: emotionLabel,
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          shape: BoxShape.circle,
        ),
        padding: const EdgeInsets.all(12),
        child: Image.asset(
          assetPath,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
