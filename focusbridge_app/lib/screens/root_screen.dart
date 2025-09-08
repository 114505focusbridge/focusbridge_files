// lib/screens/root_screen.dart
import 'package:flutter/material.dart';
import 'package:focusbridge_app/widgets/app_bottom_nav.dart'; // 請替換成你的檔案路徑

// 引入你的各個頁面
import 'package:focusbridge_app/screens/home_screen.dart';
import 'package:focusbridge_app/screens/achievements_screen.dart';
import 'package:focusbridge_app/screens/calendar_screen.dart';
import 'package:focusbridge_app/screens/profile_screen.dart';
import 'package:focusbridge_app/screens/album_screen.dart';
import 'package:focusbridge_app/screens/settings_screen.dart';

class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const HomeScreen(),
    const AchievementsScreen(),
    const CalendarScreen(),
    const ProfileScreen(),
    const AlbumScreen(),
    const SettingsScreen(),
  ];

  void _onTabChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: _currentIndex,
        onTabChanged: _onTabChanged,
      ),
    );
  }
}