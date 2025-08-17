// lib/screens/preference_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:focusbridge_app/providers/preference_provider.dart';
import 'package:focusbridge_app/widgets/app_bottom_nav.dart';

class PreferenceScreen extends StatelessWidget {
  const PreferenceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final pref = context.watch<PreferenceProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('文字大小設定'),
        backgroundColor: const Color(0xFF9CAF88),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '調整文字大小',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Center(
              child: Slider(
                min: 0.8,
                max: 1.4,
                divisions: 6,
                label: '${(pref.fontScale * 100).round()}%',
                value: pref.fontScale,
                onChanged: pref.setFontScale,
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                '目前文字大小： ${(pref.fontScale * 100).round()}%',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNav(currentIndex: 3),
    );
  }
}
