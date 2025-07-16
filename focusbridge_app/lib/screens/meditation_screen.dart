// lib/screens/meditation_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:focusbridge_app/widgets/app_bottom_nav.dart';

class MeditationScreen extends StatefulWidget {
  const MeditationScreen({super.key});
  @override
  State<MeditationScreen> createState() => _MeditationScreenState();
}

class _MeditationScreenState extends State<MeditationScreen> {
  int _seconds = 5 * 60; // 預設 5 分鐘
  Timer? _timer;

  void _toggle() {
    if (_timer == null) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (_seconds <= 0) {
          _timer?.cancel();
          _timer = null;
        } else {
          setState(() => _seconds--);
        }
      });
    } else {
      _timer?.cancel();
      _timer = null;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _fmt(int sec) {
    final m = sec ~/ 60, s = sec % 60;
    return '${m.toString().padLeft(2,'0')}:${s.toString().padLeft(2,'0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('冥想練習'),
        backgroundColor: const Color(0xFF9CAF88),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_fmt(_seconds),
                style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ElevatedButton(
                onPressed: _toggle,
                child: Text(_timer == null ? '開始冥想' : '暫停')),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 1),
    );
  }
}
