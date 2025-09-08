// lib/screens/focus_screen.dart

import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class FocusScreen extends StatefulWidget {
  const FocusScreen({super.key});
  @override
  State<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends State<FocusScreen> {
  // ====== 預設設定 ======
  static const int _defaultFocusSeconds = 25 * 60; // 預設專注 25 分鐘
  static const int _defaultBreakSeconds = 5 * 60;  // 預設休息 5 分鐘

  // 使用者實際設定值（秒）
  int _focusSeconds = _defaultFocusSeconds;
  int _breakSeconds = _defaultBreakSeconds;

  // 當前階段剩餘秒數
  late int _secondsLeft;

  // 計時器
  Timer? _timer;
  bool _pickerShown = false; // 是否已顯示過設定（進入頁面時顯示一次）
  bool _running = false;     // 計時器是否正在跑
  bool _isFocusPhase = true; // true = 專注階段；false = 休息階段

  // ====== 句子輪播（上方提示文字） ======
  final List<String> _focusSentences = [
    '專注於一件事，輕柔且堅定。',
    '放下雜念，回到當下。',
    '慢慢呼吸，讓眼睛微閉。',
    '溫柔但堅持地保持專注。',
  ];
  final List<String> _breakSentences = [
    '放鬆肩頸，深深伸展。',
    '閉眼幾秒，讓身體放鬆。',
    '喝口水，補充能量。',
    '微笑一下，讓心情放鬆。',
  ];
  int _sentenceIndex = 0;
  Timer? _sentenceTimer;
  static const int _sentenceIntervalSeconds = 10; // 每隔多少秒切換句子

  @override
  void initState() {
    super.initState();
    // 初始剩餘時間為專注時間
    _secondsLeft = _focusSeconds;

    // 頁面載入後自動顯示設定選單（只顯示一次）
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_pickerShown) _showDurationPickers();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _sentenceTimer?.cancel();
    super.dispose();
  }

  // ====== 時間選擇（專注 + 休息） ======
  Future<void> _showDurationPickers() async {
    _pickerShown = true;

    // 設定專注時間
    final pickedFocusMinutes = await showModalBottomSheet<int?>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return _buildMinutePickerSheet(
          title: '設定專注時間 (分鐘)',
          initialMinutes: _focusSeconds ~/ 60,
          onConfirm: (m) => Navigator.of(context).pop(m),
        );
      },
    );

    if (!mounted) return;
    if (pickedFocusMinutes != null && pickedFocusMinutes > 0) {
      _focusSeconds = pickedFocusMinutes * 60; // 轉為秒
    }

    // 設定休息時間
    final pickedBreakMinutes = await showModalBottomSheet<int?>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return _buildMinutePickerSheet(
          title: '設定休息時間 (分鐘)',
          initialMinutes: _breakSeconds ~/ 60,
          onConfirm: (m) => Navigator.of(context).pop(m),
        );
      },
    );

    if (!mounted) return;
    if (pickedBreakMinutes != null && pickedBreakMinutes >= 0) {
      _breakSeconds = pickedBreakMinutes * 60; // 轉為秒
    }

    // 設定完成：切回專注階段並更新UI
    setState(() {
      _isFocusPhase = true;
      _secondsLeft = _focusSeconds;
      _running = false;
      _sentenceIndex = 0;
    });

    // 設定完不自動開始，讓使用者點擊開始按鈕
    _restartSentenceTimerIfNeeded();
  }

  Widget _buildMinutePickerSheet({
    required String title,
    required int initialMinutes,
    required void Function(int) onConfirm,
  }) {
    final minMinutes = 0;
    final maxMinutes = 120;
    int temp = initialMinutes.clamp(minMinutes, maxMinutes);
    return Container(
      height: 340,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('取消')),
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                TextButton(onPressed: () => onConfirm(temp), child: const Text('完成')),
              ],
            ),
          ),
          Expanded(
            child: CupertinoPicker(
              itemExtent: 32,
              onSelectedItemChanged: (int index) {
                temp = minMinutes + index;
              },
              scrollController: FixedExtentScrollController(
                initialItem: temp - minMinutes,
              ),
              children: List<Widget>.generate(
                maxMinutes - minMinutes + 1,
                (int index) => Center(child: Text('${minMinutes + index}')),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ====== 句子輪播控制 ======
  void _restartSentenceTimerIfNeeded() {
    _sentenceTimer?.cancel();
    _sentenceTimer = null;
    if (_running) {
      _sentenceTimer = Timer.periodic(
        const Duration(seconds: _sentenceIntervalSeconds),
        (_) => _advanceSentence(),
      );
    }
  }

  void _advanceSentence() {
    setState(() {
      final list = _isFocusPhase ? _focusSentences : _breakSentences;
      if (list.isNotEmpty) {
        _sentenceIndex = (_sentenceIndex + 1) % list.length;
      }
    });
  }

  // ====== 計時器邏輯（專注 / 休息流程） ======
  void _startTimer() {
    if (_running) return;
    if (_secondsLeft <= 0) {
      _secondsLeft = _isFocusPhase ? _focusSeconds : _breakSeconds;
      if (_secondsLeft <= 0) return;
    }

    setState(() {
      _running = true;
      _sentenceIndex = 0;
    });
    _restartSentenceTimerIfNeeded();

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_secondsLeft <= 1) {
        _timer?.cancel();
        _timer = null;
        setState(() => _running = false);

        if (_isFocusPhase) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('專注時間到！開始休息吧😊')),
          );
          setState(() {
            _isFocusPhase = false;
            _secondsLeft = _breakSeconds;
            _sentenceIndex = 0;
          });
          if (_breakSeconds > 0) {
            WidgetsBinding.instance.addPostFrameCallback((_) => _startTimer());
          } else {
            setState(() {
              _isFocusPhase = true;
              _secondsLeft = _focusSeconds;
            });
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('休息結束，回到專注狀態（可手動開始）✨')),
          );
          setState(() {
            _isFocusPhase = true;
            _secondsLeft = _focusSeconds;
            _sentenceIndex = 0;
          });
        }
        _sentenceTimer?.cancel();
        _sentenceTimer = null;
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  Future<void> _confirmAndAbort() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('放棄計時？'),
        content: const Text('你確定要放棄本次專注並離開嗎？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('放棄')),
        ],
      ),
    );

    if (confirm == true) {
      _timer?.cancel();
      _timer = null;
      _sentenceTimer?.cancel();
      _sentenceTimer = null;
      if (mounted) Navigator.of(context).maybePop();
    }
  }

  // 用於「結束」按鈕，重置整個狀態回到初始
  void _resetToFocus() {
    _timer?.cancel();
    _timer = null;
    _sentenceTimer?.cancel();
    _sentenceTimer = null;
    setState(() {
      _isFocusPhase = true;
      _running = false;
      _secondsLeft = _focusSeconds;
      _sentenceIndex = 0;
    });
  }

  String _formatTime(int sec) {
    final m = sec ~/ 60;
    final s = sec % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Future<void> _showPickersManual() async {
    await _showDurationPickers();
  }

// ====== UI (全新現代扁平化風格) ======
  @override
  Widget build(BuildContext context) {
    final bgColor = const Color(0xFFBEE9FF);
    final cardColor = const Color(0xFF0F2540);

    final currentSentenceList = _isFocusPhase ? _focusSentences : _breakSentences;
    final currentSentence = currentSentenceList.isNotEmpty
        ? currentSentenceList[_sentenceIndex % currentSentenceList.length]
        : (_isFocusPhase ? '專注中' : '休息中');

    final helperText = _isFocusPhase
        ? '專注 ${(_focusSeconds / 60).toStringAsFixed(0)} 分鐘，休息 ${(_breakSeconds / 60).toStringAsFixed(0)} 分鐘'
        : '休息 ${(_breakSeconds / 60).toStringAsFixed(0)} 分鐘';

    // ============ 【主要修改區域開始】 ============
    // 根據當前狀態決定按鈕的文字、顏色和行為
    final String mainButtonText;
    final Color mainButtonColor;
    final VoidCallback onMainButtonPressed;
    final bool showStartAndCancelButtons;

    if (_running) {
      // 狀態：計時中
      showStartAndCancelButtons = false;
      if (_isFocusPhase) {
        // 專注階段，按鈕是「放棄」
        mainButtonText = '放棄';
        mainButtonColor = const Color(0xFFD32F2F);
        onMainButtonPressed = _confirmAndAbort;
      } else {
        // 休息階段，按鈕是「結束」
        mainButtonText = '結束';
        mainButtonColor = const Color(0xFFD32F2F);
        onMainButtonPressed = _resetToFocus;
      }
    } else {
      // 狀態：未計時
      showStartAndCancelButtons = true;
      mainButtonText = '開始';
      mainButtonColor = cardColor;
      onMainButtonPressed = () {
        if (_secondsLeft <= 0) {
          _secondsLeft = _isFocusPhase ? _focusSeconds : _breakSeconds;
        }
        _startTimer();
      };
    }
    // ============ 【主要修改區域結束】 ============

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Spacer(flex: 2),
                const Text(
                  '專注定時',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F2540),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  currentSentence,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    color: const Color(0xFF0F2540).withOpacity(0.8),
                  ),
                ),
                const Spacer(flex: 1),
                GestureDetector(
                  onTap: _running ? null : _showPickersManual,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(32),
                    ),
                    child: Opacity(
                      opacity: _running ? 1.0 : 0.9,
                      child: Column(
                        children: [
                          Text(
                            _formatTime(_secondsLeft),
                            style: const TextStyle(
                              fontSize: 64,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            helperText,
                            style: const TextStyle(color: Colors.white70, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const Spacer(flex: 3),
                if (_running)
                  // 在計時中，只顯示一個大按鈕
                  ElevatedButton(
                    onPressed: onMainButtonPressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: mainButtonColor,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(200, 56),
                      shape: const StadiumBorder(),
                      elevation: 0,
                    ),
                    child: Text(
                      mainButtonText,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  )
                else
                  // 未計時，顯示「開始」與「取消」按鈕
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: onMainButtonPressed,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: mainButtonColor,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(140, 56),
                          shape: const StadiumBorder(),
                          elevation: 0,
                        ),
                        child: const Text(
                          '開始',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(), // 返回上一頁
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD32F2F),
                          foregroundColor: Colors.white,
                          minimumSize: const Size(140, 56),
                          shape: const StadiumBorder(),
                          elevation: 0,
                        ),
                        child: const Text(
                          '取消',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                const Spacer(flex: 1),
              ],
            ),
          ),
        ),
      ),
    );
  }
}