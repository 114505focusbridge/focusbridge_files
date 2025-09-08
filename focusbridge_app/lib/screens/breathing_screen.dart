// lib/screens/breathing_screen.dart

import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

enum BreathingState { initial, breathing, finished }

class BreathingScreen extends StatefulWidget {
  const BreathingScreen({super.key});
  @override
  State<BreathingScreen> createState() => _BreathingScreenState();
}

class _BreathingScreenState extends State<BreathingScreen> with TickerProviderStateMixin {
  // 動畫控制器
  late AnimationController _animationController;
  late Animation<double> _sizeAnimation;
  late Animation<Color?> _colorAnimation;

  // 狀態管理
  BreathingState _screenState = BreathingState.initial;
  String _phase = '準備開始';
  int _countdown = 4;

  // 計時器
  Timer? _sessionTimer;
  Timer? _countdownTimer;
  bool _cycleActive = false;

  // 呼吸節奏設定 (秒)
  static const int _inhaleDuration = 4;
  static const int _holdAfterInhaleDuration = 4;
  static const int _exhaleDuration = 6;
  static const int _totalSessionDuration = 60;

  @override
  void initState() {
    super.initState();

    // 初始化動畫 controller（duration 會在每階段動態設定）
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
      value: 0.0, // 初始小球在最小
    );

    _sizeAnimation = Tween<double>(begin: 120, end: 280).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _colorAnimation = ColorTween(
      begin: Colors.teal.shade200,
      end: Colors.cyan.shade300,
    ).animate(_animationController);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _sessionTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  // 開始整段呼吸練習（會啟動總時長計時器 + 循環）
  void _startBreathingSession() {
    if (_screenState == BreathingState.breathing) return;

    setState(() => _screenState = BreathingState.breathing);
    _cycleActive = true;

    // 取消舊的 session timer
    _sessionTimer?.cancel();
    _sessionTimer = Timer(const Duration(seconds: _totalSessionDuration), _finishBreathingSession);

    // 啟動循環（非同步順序執行）
    _runBreathingCycle();
  }

  // 非同步循環：吸氣 -> 屏息 -> 吐氣 -> 重複
  Future<void> _runBreathingCycle() async {
    while (_cycleActive && mounted) {
      // 吸氣（含動畫 forward）
      await _doPhase('吸氣', _inhaleDuration, animateForward: true);
      if (!_cycleActive || !mounted) break;

      // 屏息（保持最大）
      await _doPhase('屏息', _holdAfterInhaleDuration);
      if (!_cycleActive || !mounted) break;

      // 吐氣（含動畫 reverse）
      await _doPhase('吐氣', _exhaleDuration, animateReverse: true);
    }
  }

  // 單一階段處理：設定文字、倒數，並可選擇啟動動畫 forward/reverse
  Future<void> _doPhase(String phase, int seconds, {bool animateForward = false, bool animateReverse = false}) async {
    // 設定初始顯示
    setState(() {
      _phase = phase;
      _countdown = seconds;
    });

    // 取消舊倒數，建立新的倒數（確保完整顯示到 1）
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 1) {
        setState(() => _countdown--);
      } else {
        // 顯示最後一秒（1）之後取消
        setState(() => _countdown = 1);
        timer.cancel();
      }
    });

    // 與動畫同步：如果需要動畫，設定 duration 並 await 完成
    if (animateForward) {
      _animationController.duration = Duration(seconds: seconds);
      await _animationController.forward(from: 0.0);
    } else if (animateReverse) {
      _animationController.duration = Duration(seconds: seconds);
      await _animationController.reverse(from: 1.0);
    } else {
      // 無動畫，單純等待階段時間
      await Future.delayed(Duration(seconds: seconds));
    }

    // 階段完成後取消倒數 timer（保險）
    _countdownTimer?.cancel();
    _countdownTimer = null;
  }

  // 結束整段練習：停止循環、停止 animation、顯示結果 dialog
  void _finishBreathingSession() {
    _sessionTimer?.cancel();
    _countdownTimer?.cancel();
    _cycleActive = false;
    _animationController.stop();

    setState(() {
      _screenState = BreathingState.finished;
      _phase = '練習結束';
      _countdown = 0;
    });

    // 延遲彈出回饋（確保畫面已更新）
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      _showFeedbackDialog();
    });
  }

  /// 輔助：安全停止目前 session（取消 timers、停止動畫、停止循環）
  void _stopSession() {
    _sessionTimer?.cancel();
    _sessionTimer = null;
    _countdownTimer?.cancel();
    _countdownTimer = null;
    _cycleActive = false;
    try {
      _animationController.stop();
    } catch (_) {}
    setState(() {
      _screenState = BreathingState.initial;
      _phase = '準備開始';
      _countdown = 4;
    });
  }

  /// 顯示回饋（平台自適應：iOS action sheet + fade, Android alert）
  Future<void> _showFeedbackDialog() async {
    String? choice;

    if (Platform.isIOS) {
      // iOS：用 CupertinoActionSheet 並包 TweenAnimationBuilder 做淡入
      choice = await showCupertinoModalPopup<String?>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) {
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 260),
            builder: (context, v, child) => Opacity(opacity: v, child: child),
            child: CupertinoActionSheet(
              title: const Text('現在感覺怎麼樣？', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              message: const Text('選擇一個表情來記錄你現在的心情吧。'),
              actions: [
                CupertinoActionSheetAction(
                  onPressed: () => Navigator.of(ctx).pop('calm'),
                  child: const Text('😊 平靜多了', style: TextStyle(color: CupertinoColors.activeBlue)),
                ),
                CupertinoActionSheetAction(
                  onPressed: () => Navigator.of(ctx).pop('better'),
                  child: const Text('🙂 好一點了', style: TextStyle(color: CupertinoColors.activeBlue)),
                ),
                CupertinoActionSheetAction(
                  onPressed: () => Navigator.of(ctx).pop('same'),
                  child: const Text('😐 沒什麼變化', style: TextStyle(color: CupertinoColors.activeBlue)),
                ),
              ]
            ),
          );
        },
      );
    } else {
      // Android：AlertDialog
      choice = await showDialog<String?>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text('現在感覺怎麼樣？', textAlign: TextAlign.center),
          content: const Text('選擇一個表情來記錄你現在的心情吧。', textAlign: TextAlign.center),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop('calm'), child: const Text('😊 平靜多了')),
            TextButton(onPressed: () => Navigator.of(ctx).pop('better'), child: const Text('🙂 好一點了')),
            TextButton(onPressed: () => Navigator.of(ctx).pop('same'), child: const Text('😐 沒什麼變化')),
          ],
        ),
      );
    }

    if (!mounted) return;

    switch (choice) {
      case 'calm':
        // 使用者平靜多了：停止 session 並嘗試離開頁面
        _stopSession();
        if (Navigator.of(context).canPop()) Navigator.of(context).maybePop();
        break;

      case 'better':
        // 「好一點了」：詢問是否再練習一次（平台自適應）
        final retry = await _showRetryConfirm();
        if (!mounted) return;

        if (retry == true) {
          _stopSession();
          await Future.delayed(const Duration(milliseconds: 200));
          _startBreathingSession();
        } else {
          _stopSession();
          if (Navigator.of(context).canPop()) Navigator.of(context).maybePop();
        }
        break;

      case 'same':
        // 沒什麼變化：立即重新開始（不離開）
        _stopSession();
        await Future.delayed(const Duration(milliseconds: 150));
        _startBreathingSession();
        break;

      default:
        // 取消或未選擇：回到初始
        _stopSession();
        break;
    }
  }

  /// 平台自適應的「要再練習一次嗎？」確認（iOS action sheet with fade, Android dialog）
  Future<bool?> _showRetryConfirm() async {
    if (Platform.isIOS) {
      final res = await showCupertinoModalPopup<String?>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) {
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 260),
            builder: (context, v, child) => Opacity(opacity: v, child: child),
            child: CupertinoActionSheet(
              title: const Text('要再練習一次嗎？'),
              message: const Text('如果你還想再練習一段，按「再練一次」。否則按「離開」。'),
              actions: [
                CupertinoActionSheetAction(
                  onPressed: () => Navigator.of(ctx).pop('retry'),
                  isDefaultAction: true,
                  child: const Text('再練一次', style: TextStyle(color: CupertinoColors.activeBlue)),
                ),
                CupertinoActionSheetAction(
                  onPressed: () => Navigator.of(ctx).pop('leave'),
                  isDestructiveAction: true,
                  child: const Text('離開'),
                ),
              ],
            ),
          );
        },
      );

      if (res == 'retry') return true;
      if (res == 'leave') return false;
      return null;
    } else {
      final res = await showDialog<bool?>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text('要再練習一次嗎？'),
          content: const Text('如果你還想再練習一段，按「再練一次」。否則按「離開」。'),
          actionsAlignment: MainAxisAlignment.end,
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('離開')),
            ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('再練一次')),
          ],
        ),
      );
      return res;
    }
  }

@override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('呼吸練習'),
        backgroundColor: const Color(0xFFBBDEFF),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade100, Colors.teal.shade50],
          ),
        ),
        child: Center(child: _buildContent()),
      ),
    );
  }

  Widget _buildContent() {
    switch (_screenState) {
      case BreathingState.initial:
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 占位符，讓按鈕和頁面中央對齊
              const Spacer(flex: 1),
              
              // 主要開始按鈕
              ElevatedButton(
                onPressed: _startBreathingSession,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.teal.shade700,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: const Text('開始 1 分鐘呼吸練習', style: TextStyle(fontSize: 18)),
              ),
              const SizedBox(height: 2),
              const Spacer(flex: 1),
              // 新增的取消按鈕
              OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color.fromARGB(255, 211, 47, 47),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  side: BorderSide(color: const Color.fromARGB(255, 211, 47, 47), width: 1.5),
                ),
                child: const Text('取消', style: TextStyle(fontSize: 18)),
              ),
          const SizedBox(height: 70),
            ],
          ),
        );


      case BreathingState.breathing:
      case BreathingState.finished:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 呼吸球（跟動畫同步）
            AnimatedBuilder(
              animation: _animationController,
              builder: (_, __) {
                final size = _sizeAnimation.value;
                final color = _colorAnimation.value ?? Colors.teal.shade200;
                return Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [color, color.withOpacity(0.5)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(color: color.withOpacity(0.5), blurRadius: 40, spreadRadius: 10),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 40),

            // 階段文字 + 完整倒數（例如： 吸氣... 4）
            Text(
              _screenState == BreathingState.breathing ? '$_phase... $_countdown' : _phase,
              style: TextStyle(fontSize: 32, color: Colors.teal.shade800, fontWeight: FontWeight.w300),
            ),
          ],
        );
    }
  }
}
