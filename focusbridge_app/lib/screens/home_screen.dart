import 'package:flutter/material.dart';
import 'package:focusbridge_app/screens/color_picker_screen.dart';
import 'package:focusbridge_app/widgets/app_bottom_nav.dart';

/// 主畫面：左右滑動選擇情緒（大圖、置中、文字在下方，圓形圖案不裁切）
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _pageController = PageController(viewportFraction: 0.67);
  double _currentPage = 0.0;

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      setState(() {
        _currentPage = _pageController.page ?? _pageController.initialPage.toDouble();
      });
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double screenW = MediaQuery.of(context).size.width;
    final double imageSize = (screenW * 0.7).clamp(280.0, 380.0);

    return Scaffold(
      // 移除 AppBar，讓內容延伸到頂部
      // 你可以在 Column 的頂部新增一個自訂標題
      body: Container(
        width: double.infinity,
        // 使用漸層背景，讓畫面更柔和
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [const  Color(0xFFEEF7ED), Color.fromARGB(255, 229, 255, 227)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 52),
              // 標題區
              Text(
                '今天情緒如何呢...？',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Colors.blueGrey.shade800,
                ),
              ),
              const SizedBox(height: 48),

              // PageView 區域
              SizedBox(
                height: imageSize + 150,
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _emotionLabels.length,
                  itemBuilder: (context, index) {
                    final double difference = (_currentPage - index).abs();
                    // 控制卡片的縮放比例
                    final double scale = (1 - (difference * 0.15)).clamp(0.8, 1.0);
                    // 根據位置調整卡片的垂直位移，讓它在中間時輕微上浮
                    final double translateY = (1 - scale) * -100;

                    final label = _emotionLabels[index];
                    final icon = _emotionIcons[index];
                    final desc = _emotionDescriptions[index];

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Center(
                        child: Transform.translate(
                          offset: Offset(0, translateY), // 垂直位移動畫
                          child: Transform.scale(
                            scale: scale, // 縮放動畫
                            child: GestureDetector(
                              onTap: () {
                                    Navigator.push(
                                      context,
                                      PageRouteBuilder(
                                        pageBuilder: (context, animation, secondaryAnimation) => const ColorPickerScreen(),
                                        transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                          // 使用淡入動畫，動畫時長 400 毫秒
                                          return FadeTransition(
                                            opacity: CurvedAnimation(
                                              parent: animation,
                                              curve: Curves.easeIn,
                                            ),
                                            child: child,
                                          );
                                        },
                                        transitionDuration: const Duration(milliseconds: 300),
                                        // 傳遞參數給新頁面
                                        settings: RouteSettings(arguments: label), 
                                      ),
                                    );
                              },
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // 圓形背景容器，圖片完整顯示
                                  Card(
                                    elevation: 8, // 增加陰影
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(imageSize / 2),
                                    ),
                                    child: Container(
                                      width: imageSize,
                                      height: imageSize,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        
                                      ),
                                      padding: const EdgeInsets.all(24),
                                      child: Image.asset(
                                        icon,
                                        fit: BoxFit.contain, // 不裁切圖片
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 32),
                                  Text(
                                    label,
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.blueGrey.shade800,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                                    child: Text(
                                      desc,
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: Colors.grey.shade600,
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 32),
              _buildPageIndicator(),
              const SizedBox(height: 32),

              Expanded(child: Container()),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 0),
    );
  }

  Widget _buildPageIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_emotionLabels.length, (i) {
        final isActive = (_currentPage.round() == i);
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 5),
          width: isActive ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive ? Colors.lightBlue.shade400 : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(8),
          ),
        );
      }),
    );
  }
}

// 文字標籤
const List<String> _emotionLabels = [
  '快樂', '憤怒', '悲傷',
  '恐懼', '驚訝', '厭惡',
];

// 圖示資源
const List<String> _emotionIcons = [
  'assets/images/emotion_sun.png',
  'assets/images/emotion_tornado.png',
  'assets/images/emotion_cloud.png',
  'assets/images/emotion_lightning.png',
  'assets/images/emotion_snowflake.png',
  'assets/images/emotion_rain.png',
];

// 每個情緒對應的敘述
const List<String> _emotionDescriptions = [
  '愉快、輕鬆自在',
  '生氣、容易激動',
  '低落、想哭泣',
  '害怕、恐慌不安',
  '驚訝、出乎意料',
  '厭煩、令人討厭',
];