// lib/widgets/mood_display.dart
import 'package:flutter/material.dart';
import 'package:focusbridge_app/utils/mood_utils.dart';
import 'package:focusbridge_app/utils/color_extension.dart';

class MoodDisplay extends StatelessWidget {
  final String emotionLabel;
  final Color emotionColor;

  const MoodDisplay({super.key, required this.emotionLabel, required this.emotionColor});

  @override
  Widget build(BuildContext context) {
    final isValidMood = assetForMood(emotionLabel) != 'assets/images/emotion_cloud.png' || emotionLabel == '平靜';

    if (!isValidMood) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: emotionColor.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Image.asset(
                assetForMood(emotionLabel),
                color: emotionColor,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            emotionLabel,
            style: TextStyle(
              fontSize: 24,
              color: emotionColor.darken(15),
              fontWeight: FontWeight.w900,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
