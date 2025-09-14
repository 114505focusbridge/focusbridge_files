// lib/widgets/ai_card.dart
import 'package:flutter/material.dart';
import 'package:focusbridge_app/utils/mood_utils.dart';
import 'package:focusbridge_app/utils/color_extension.dart';

class AICard extends StatelessWidget {
  final String title;
  final String content;
  final String? emotion;
  final String? moodColor;

  const AICard({
    super.key,
    required this.title,
    required this.content,
    this.emotion,
    this.moodColor,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasEmotion = emotion != null && emotion!.isNotEmpty && assetForMood(emotion!) != 'assets/images/emotion_cloud.png';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 96, 243, 162).withOpacity(.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF9CAF88).withOpacity(.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ),
              if (hasEmotion)
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(6.0),
                    child: Image.asset(
                      assetForMood(emotion!),
                      color: moodColor != null ? hexToColor(moodColor) : null,
                      colorBlendMode: BlendMode.srcIn,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(content, style: const TextStyle(fontSize: 16, height: 1.4)),
        ],
      ),
    );
  }
}
