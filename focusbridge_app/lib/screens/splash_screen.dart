import 'package:flutter/material.dart';
import 'package:focusbridge_app/screens/login_screen.dart'; // 導入 LoginScreen
import 'package:focusbridge_app/screens/register_screen.dart'; // 導入 RegisterScreen

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _logoPositionAnimation;
  late final Animation<double> _buttonsOpacityAnimation;
  late final Animation<double> _loadingOpacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3800), // 延長總動畫時間
    );

    // 第一階段：載入指示器淡出，時間間隔延長
    _loadingOpacityAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );

    // 第二階段：圖標上移，在載入指示器淡出後開始
    _logoPositionAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.0),
      end: const Offset(0.0, -0.1),
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 0.8, curve: Curves.easeInOut),
      ),
    );

    // 第三階段：按鈕淡入，在圖標上移後開始
    _buttonsOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.8, 1.0, curve: Curves.easeIn),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                left: 0,
                right: 0,
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, _logoPositionAnimation.value.dy * MediaQuery.of(context).size.height),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 60),
                            const Text(
                              'All Day',
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF333333),
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Health Diary',
                              style: TextStyle(
                                fontSize: 20,
                                color: Color(0xFF666666),
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              '紀錄每一天的健康點滴',
                              style: TextStyle(
                                fontSize: 16,
                                color: Color(0xFF999999),
                              ),
                            ),
                            const SizedBox(height: 40),
                            CircleAvatar(
                              radius: 60,
                              backgroundColor: Colors.grey.shade200,
                              backgroundImage: const AssetImage('assets/images/LOGO.png'),
                            ),
                            const SizedBox(height: 60),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              // 轉圈圈的載入指示器
              Positioned(
                bottom: MediaQuery.of(context).size.height * 0.2,
                left: 0,
                right: 0,
                child: Center(
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _loadingOpacityAnimation.value,
                        child: const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF9CAF88)),
                          strokeWidth: 4,
                        ),
                      );
                    },
                  ),
                ),
              ),
              // 按鈕區塊，動畫控制其透明度
              Positioned(
                bottom: 32,
                left: 0,
                right: 0,
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _buttonsOpacityAnimation.value,
                      child: Column(
                        children: [
                          // 「登入」按鈕
                          SizedBox(
                            width: MediaQuery.of(context).size.width * 0.8,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  PageRouteBuilder(
                                    pageBuilder: (context, animation, secondaryAnimation) => const LoginScreen(),
                                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                      const begin = 0.0;
                                      const end = 1.0;
                                      const curve = Curves.ease;
                                      final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                                      return FadeTransition(
                                        opacity: animation.drive(tween),
                                        child: child,
                                      );
                                    },
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF9CAF88),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                elevation: 4,
                                shadowColor: const Color(0xFF9CAF88).withOpacity(0.5),
                              ),
                              child: const Text(
                                '登入',
                                style: TextStyle(fontSize: 18, color: Colors.white),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // 「註冊」按鈕
                          SizedBox(
                            width: MediaQuery.of(context).size.width * 0.8,
                            height: 48,
                            child: OutlinedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  PageRouteBuilder(
                                    pageBuilder: (context, animation, secondaryAnimation) => const RegisterScreen(),
                                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                      const begin = 0.0;
                                      const end = 1.0;
                                      const curve = Curves.ease;
                                      final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                                      return FadeTransition(
                                        opacity: animation.drive(tween),
                                        child: child,
                                      );
                                    },
                                  ),
                                );
                              },
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFF9CAF88)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                backgroundColor: Colors.white,
                                elevation: 0,
                              ),
                              child: const Text(
                                '註冊',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Color(0xFF9CAF88),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
