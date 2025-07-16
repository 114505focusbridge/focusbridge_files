// lib/screens/breathing_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:focusbridge_app/widgets/app_bottom_nav.dart';

class BreathingScreen extends StatefulWidget {
  const BreathingScreen({super.key});
  @override
  State<BreathingScreen> createState() => _BreathingScreenState();
}

class _BreathingScreenState extends State<BreathingScreen> with TickerProviderStateMixin {
  late AnimationController _ctrl;
  String _phase = '吸氣';

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 4))
      ..repeat(reverse: true)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          setState(() => _phase = '屏息'); 
        } else if (status == AnimationStatus.dismissed) {
          setState(() => _phase = '吐氣');
        }
      });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('呼吸練習'),
        backgroundColor: const Color(0xFF9CAF88),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          AnimatedBuilder(
            animation: _ctrl,
            builder: (_, __) => Container(
              width: 100 + _ctrl.value * 100,
              height: 100 + _ctrl.value * 100,
              decoration: BoxDecoration(
                color: Colors.green.shade200,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(_phase, style: const TextStyle(fontSize: 24)),
        ]),
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 2),
    );
  }
}
