// lib/providers/preference_provider.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 目前僅保留字體縮放功能
class PreferenceProvider extends ChangeNotifier {
  double _fontScale = 1.0;
  double get fontScale => _fontScale;

  PreferenceProvider() {
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _fontScale = prefs.getDouble('fontScale') ?? 1.0;
    notifyListeners();
  }

  /// 設定全局文字縮放比例
  Future<void> setFontScale(double scale) async {
    _fontScale = scale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('fontScale', scale);
    notifyListeners();
  }
}
