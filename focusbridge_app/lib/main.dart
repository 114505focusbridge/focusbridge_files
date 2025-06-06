// lib/main.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:focusbridge_app/providers/auth_provider.dart';
import 'package:focusbridge_app/screens/welcome_screen.dart';
import 'package:focusbridge_app/screens/login_screen.dart';
import 'package:focusbridge_app/screens/register_screen.dart';
import 'package:focusbridge_app/screens/home_screen.dart';
import 'package:focusbridge_app/screens/color_picker_screen.dart';
import 'package:focusbridge_app/screens/diary_entry_screen.dart';
import 'package:focusbridge_app/screens/post_entry_screen.dart';
import 'package:focusbridge_app/screens/forgot_password_screen.dart';
import 'package:focusbridge_app/screens/reset_password_screen.dart';
import 'package:focusbridge_app/screens/settings_screen.dart';
import 'package:focusbridge_app/screens/album_screen.dart'; // <- 加入 AlbumScreen

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AuthProvider>(
      create: (_) => AuthProvider(),
      child: MaterialApp(
        title: 'All Day Health Diary',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.green,
          scaffoldBackgroundColor: const Color(0xFFFFFADD),
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => const WelcomeScreen(),
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/home': (context) => const HomeScreen(),
          '/settings': (context) => const SettingsScreen(),
          '/color_picker': (context) => const ColorPickerScreen(),
          '/diary_entry': (context) => const DiaryEntryScreen(),
          '/album': (context) => const AlbumScreen(), // <- 已新增 AlbumScreen
          '/post_entry': (context) => const PostEntryScreen(
                emotionLabel: '',
                emotionColor: Colors.transparent,
                entryContent: '',
              ),
          '/forgot_password': (context) => const ForgotPasswordScreen(),
          // ResetPasswordScreen 需透過 onGenerateRoute 傳遞 uid & token
        },
        onGenerateRoute: (settings) {
          if (settings.name?.startsWith('/reset_password/') == true) {
            final uri = Uri.parse(settings.name!);
            final segments = uri.pathSegments;
            if (segments.length == 3 && segments[0] == 'reset_password') {
              final uid = segments[1];
              final token = segments[2];
              return MaterialPageRoute(
                builder: (_) => ResetPasswordScreen(uid: uid, token: token),
              );
            }
          }
          return null;
        },
      ),
    );
  }
}
