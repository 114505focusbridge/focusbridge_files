// lib/screens/focus_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:focusbridge_app/widgets/app_bottom_nav.dart';

class FocusScreen extends StatefulWidget {
  const FocusScreen({super.key});
  @override
  State<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends State<FocusScreen> {
  static const defaultSeconds = 25 * 60; 
  int _secondsLeft = defaultSeconds;
  Timer? _timer;

  void _startTimer() {
    if (_timer != null) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_secondsLeft <= 0) {
        _timer?.cancel();
        _timer = null;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('專注時間到！休息一下吧😊')),
        );
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  void _reset() {
    _timer?.cancel();
    _timer = null;
    setState(() => _secondsLeft = defaultSeconds);
  }

  String _formatTime(int sec) {
    final m = sec ~/ 60;
    final s = sec % 60;
    return '${m.toString().padLeft(2,'0')}:${s.toString().padLeft(2,'0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('專注定時'),
        backgroundColor: const Color(0xFF9CAF88),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_formatTime(_secondsLeft),
                style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(onPressed: _startTimer, child: const Text('開始')),
                const SizedBox(width: 12),
                ElevatedButton(onPressed: _reset, child: const Text('重設')),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 0),
    );
  }
}
