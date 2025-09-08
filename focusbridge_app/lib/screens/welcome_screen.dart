// lib/screens/welcome_screen.dart

import 'package:flutter/material.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5), // 跟登入頁統一淡色背景
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 60),

              // 標題
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
              const SizedBox(height: 40),

              // 中央圖示
              CircleAvatar(
                radius: 60,
                backgroundColor: Colors.grey.shade200,
                backgroundImage: const AssetImage('assets/images/LOGO.png'),
              ),
              const SizedBox(height: 60),

              // 「使用者登入」按鈕
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/login');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF9CAF88),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    elevation: 0, // 跟登入頁一致
                  ),
                  child: const Text(
                    '使用者登入',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 「註冊」按鈕
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/register');
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF9CAF88)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    backgroundColor: Colors.white, // 註冊按鈕白底
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
        ),
      ),
    );
  }
}
