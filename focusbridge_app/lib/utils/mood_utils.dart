// lib/utils/mood_utils.dart
import 'package:flutter/material.dart';

String moodEmojiFor(String? mood) {
  if (mood == null) return '';
  switch (mood.toLowerCase()) {
    case 'sunny':
    case 'positive':
    case 'happy':
    case '快樂':
      return '☀️';
    case 'cloudy':
    case 'neutral':
    case '平靜':
      return '⛅';
    case 'rain':
    case 'negative':
    case 'sad':
    case '悲傷':
      return '🌧️';
    case 'storm':
    case '憤怒':
      return '⛈️';
    case 'windy':
    case '不安':
      return '🌬️';
    default:
      return '';
  }
}

Color hexToColor(String? hex, {Color fallback = const Color(0xFFE2E8D5)}) {
  if (hex == null || hex.isEmpty) return fallback;
  try {
    final h = hex.replaceAll('#', '');
    if (h.length != 6) return fallback;
    return Color(int.parse('FF$h', radix: 16));
  } catch (_) {
    return fallback;
  }
}

String assetForMood(String emotion) {
  switch (emotion) {
    case '快樂':
    case 'sunny':
      return 'assets/images/emotion_sun.png';
    case '平靜':
    case 'cloudy':
      return 'assets/images/emotion_cloud.png';
    case '悲傷':
    case 'rain':
      return 'assets/images/emotion_rain.png';
    case '憤怒':
    case 'storm':
      return 'assets/images/emotion_tornado.png';
    case '不安':
    case 'windy':
      return 'assets/images/emotion_wind.png';
    default:
      return 'assets/images/emotion_cloud.png';
  }
}
