// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:focusbridge_app/providers/auth_provider.dart';
import 'package:focusbridge_app/providers/preference_provider.dart';

import 'package:focusbridge_app/screens/welcome_screen.dart';
import 'package:focusbridge_app/screens/login_screen.dart';
import 'package:focusbridge_app/screens/register_screen.dart';
import 'package:focusbridge_app/screens/home_screen.dart';
import 'package:focusbridge_app/screens/settings_screen.dart';
import 'package:focusbridge_app/screens/preference_screen.dart';
import 'package:focusbridge_app/screens/achievements_screen.dart';
import 'package:focusbridge_app/screens/calendar_screen.dart';
import 'package:focusbridge_app/screens/diary_entry_screen.dart';
import 'package:focusbridge_app/screens/post_entry_screen.dart';
import 'package:focusbridge_app/screens/album_screen.dart';
import 'package:focusbridge_app/screens/profile_screen.dart';
import 'package:focusbridge_app/screens/color_picker_screen.dart';
import 'package:focusbridge_app/screens/focus_screen.dart';
import 'package:focusbridge_app/screens/meditation_screen.dart';
import 'package:focusbridge_app/screens/breathing_screen.dart';
import 'package:focusbridge_app/screens/forgot_password_screen.dart';
import 'package:focusbridge_app/screens/reset_password_screen.dart';
import 'package:focusbridge_app/screens/profile_settings_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => PreferenceProvider()),
      ],
      child: Consumer<PreferenceProvider>(
        builder: (context, pref, _) {
          return MaterialApp(
            title: 'All Day Health Diary',
            debugShowCheckedModeBanner: false,

            // 依使用者偏好限制整體字體縮放
            builder: (context, child) {
              return MediaQuery.withClampedTextScaling(
                minScaleFactor: pref.fontScale,
                maxScaleFactor: pref.fontScale,
                child: child!,
              );
            },

            // 主題：加入中文字型 fallback，避免亂碼
            theme: ThemeData(
              primarySwatch: Colors.green,
              scaffoldBackgroundColor: const Color(0xFFFFFADD),
              pageTransitionsTheme: const PageTransitionsTheme(
                builders: {
                  TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
                  TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
                },
              ),
              fontFamilyFallback: const [
                // Android 常見
                'Noto Sans CJK TC',
                'Noto Sans TC',
                'Noto Sans',
                'Roboto',
                // iOS 常見
                'PingFang TC',
                'Heiti TC',
                // Windows（如有桌面測）
                'Microsoft JhengHei',
              ],
            ),

            initialRoute: '/',
            routes: {
              '/': (c) => const WelcomeScreen(),
              '/login': (c) => const LoginScreen(),
              '/register': (c) => const RegisterScreen(),
              '/home': (c) => const HomeScreen(),
              '/settings': (c) => const SettingsScreen(),
              '/preferences': (c) => const PreferenceScreen(),
              '/achievements': (c) => const AchievementsScreen(),
              '/calendar': (c) => const CalendarScreen(),
              '/diary_entry': (c) => const DiaryEntryScreen(),
              '/album': (c) => const AlbumScreen(),
              '/profile': (c) => const ProfileScreen(),
              '/color_picker': (c) => const ColorPickerScreen(),
              '/focus': (c) => const FocusScreen(),
              '/meditation': (c) => const MeditationScreen(),
              '/breathing': (c) => const BreathingScreen(),
              '/forgot_password': (c) => const ForgotPasswordScreen(),
              '/profile_settings': (c) => const ProfileSettingsScreen(),
            },

            // 動態路由
            onGenerateRoute: (settings) {
              final name = settings.name ?? '';

              // /post_entry（帶參數）
              if (name == '/post_entry') {
                final args =
                    (settings.arguments as Map<String, dynamic>?) ?? const {};
                return MaterialPageRoute(
                  builder: (_) => PostEntryScreen(
                    emotionLabel: args['emotionLabel'],
                    emotionColor: args['emotionColor'],
                    entryContent: args['entryContent'],
                    aiLabel: args['aiLabel'],
                    aiMessage: args['aiMessage'],
                  ),
                );
              }

              // /reset_password/:uid/:token
              if (name.startsWith('/reset_password/')) {
                final seg = Uri.parse(name).pathSegments; // [reset_password, uid, token]
                if (seg.length == 3 && seg[0] == 'reset_password') {
                  final uid = seg[1];
                  final token = seg[2];
                  return MaterialPageRoute(
                    builder: (_) => ResetPasswordScreen(uid: uid, token: token),
                  );
                }
              }

              // 交回 routes；若沒對應，會落到 onUnknownRoute
              return null;
            },

            // 找不到路由時的保底頁
            onUnknownRoute: (settings) => MaterialPageRoute(
              builder: (_) => const Scaffold(
                body: Center(child: Text('找不到頁面（404）')),
              ),
            ),
          );
        },
      ),
    );
  }
}
