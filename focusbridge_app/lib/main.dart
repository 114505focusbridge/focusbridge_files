// lib/main.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:focusbridge_app/screens/calendar_screen.dart';
import 'package:focusbridge_app/screens/achievements_screen.dart';
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
import 'package:focusbridge_app/screens/album_screen.dart';
import 'package:focusbridge_app/screens/profile_screen.dart';

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

          // 全域頁面切換動畫設定
          pageTransitionsTheme: const PageTransitionsTheme(
            builders: {
              TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
              TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
            },
          ),
        ),
        initialRoute: '/',
        routes: {
          '/': (c) => const WelcomeScreen(),
          '/login': (c) => const LoginScreen(),
          '/register': (c) => const RegisterScreen(),
          '/home': (c) => const HomeScreen(),
          '/settings': (c) => const SettingsScreen(),
          '/color_picker': (c) => const ColorPickerScreen(),
          '/diary_entry': (c) => const DiaryEntryScreen(),
          '/profile': (c) => const ProfileScreen(),
          '/post_entry': (c) => const PostEntryScreen(
                emotionLabel: '',
                emotionColor: Colors.transparent,
                entryContent: '',
              ),
          '/album': (c) => const AlbumScreen(),
          '/achievements': (c) => const AchievementsScreen(),
          '/forgot_password': (c) => const ForgotPasswordScreen(),
          '/calendar': (c) => const CalendarScreen(),
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
