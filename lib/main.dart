// lib/main.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:focusbridge_app/providers/auth_provider.dart';
import 'package:focusbridge_app/screens/welcome_screen.dart';
import 'package:focusbridge_app/screens/login_screen.dart';
import 'package:focusbridge_app/screens/register_screen.dart';
import 'package:focusbridge_app/screens/home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AuthProvider>(
      // 一進入 App，就建立一個 AuthProvider，負責管理登入狀態、token
      create: (_) => AuthProvider(),
      child: MaterialApp(
        title: 'All Day Health Diary',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.green,
          scaffoldBackgroundColor: const Color(0xFFFFFADD), // 淡黃背景
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => const WelcomeScreen(),
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/home': (context) => const HomeScreen(),
        },
      ),
    );
  }
}
