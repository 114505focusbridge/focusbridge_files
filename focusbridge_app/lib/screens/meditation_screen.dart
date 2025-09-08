import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class MeditationScreen extends StatefulWidget {
  const MeditationScreen({super.key});
  @override
  State<MeditationScreen> createState() => _MeditationScreenState();
}

class _MeditationScreenState extends State<MeditationScreen>
    with SingleTickerProviderStateMixin {
  int _initialSeconds = 5 * 60; // 初始時間 (5 分鐘)
  int _seconds = 5 * 60;
  Timer? _timer;
  bool _pickerShown = false;
  bool _running = false;

  late final AnimationController _breathCtrl;
  late Animation<double> _scaleAnim;

  String _breathText = "吸氣";

  @override
  void initState() {
    super.initState();

    // 呼吸動畫控制器 (一輪 12 秒 = 吸氣 4s + 吐氣 8s)
    _breathCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    // 0~0.33: 吸氣 (scale 0.8 → 1.2)
    // 0.33~1.0: 吐氣 (scale 1.2 → 0.8)
    _scaleAnim = TweenSequence([
      TweenSequenceItem(
        tween: Tween(begin: 0.8, end: 1.2)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 4, // 吸氣 4 秒
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.2, end: 0.8)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 8, // 吐氣 8 秒
      ),
    ]).animate(_breathCtrl);

    // 監聽動畫進度，更新文字提示
    _breathCtrl.addListener(() {
      final progress = _breathCtrl.value;
      if (progress < 4 / 12) {
        if (_breathText != "吸氣") {
          setState(() => _breathText = "吸氣");
        }
      } else {
        if (_breathText != "吐氣") {
          setState(() => _breathText = "吐氣");
        }
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_pickerShown) _showTimePicker();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _breathCtrl.dispose();
    super.dispose();
  }

  Future<void> _showTimePicker() async {
    _pickerShown = true;
    Duration temp = Duration(seconds: _initialSeconds);
    final picked = await showModalBottomSheet<Duration>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          height: 340,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('取消')),
                    const Text('設定冥想時間',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextButton(
                        onPressed: () => Navigator.of(context).pop(temp),
                        child: const Text('完成')),
                  ],
                ),
              ),
              Expanded(
                child: CupertinoTimerPicker(
                  mode: CupertinoTimerPickerMode.ms,
                  initialTimerDuration: Duration(seconds: _initialSeconds),
                  minuteInterval: 1,
                  secondInterval: 1,
                  onTimerDurationChanged: (d) => temp = d,
                ),
              ),
            ],
          ),
        );
      },
    );

    if (!mounted) return;
    if (picked != null && picked.inSeconds > 0) {
      setState(() {
        _initialSeconds = picked.inSeconds;
        _seconds = picked.inSeconds;
        _running = true;
      });
      _startTimer();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    if (_seconds <= 0) return;
    setState(() => _running = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_seconds <= 1) {
        t.cancel();
        setState(() {
          _seconds = 0;
          _running = false;
        });
        _onSessionComplete();
      } else {
        setState(() => _seconds--);
      }
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    setState(() => _running = false);
  }

  void _onSessionComplete() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('冥想結束'),
        content: const Text('恭喜你完成冥想。'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              if (mounted) Navigator.of(context).maybePop();
            },
            child: const Text('確定'),
          ),
        ],
      ),
    );
  }

  Future<bool> _confirmDoubleEnd() async {
    final first = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('結束冥想？'),
        content: const Text('是否要結束本次冥想？'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('結束')),
        ],
      ),
    );

    if (first != true) return false;


    return first == true;
  }

  String _fmt(int sec) {
    final m = sec ~/ 60, s = sec % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_initialSeconds > 0) ? _seconds / _initialSeconds : 0.0;
    final bgStart = const Color(0xFF0B1020);
    final bgEnd = const Color(0xFF0F2540);
    final bgColor = Color.lerp(bgStart, bgEnd, 1 - progress)!;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                '冥想練習',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),

              Container(
                width: 300,
                height: 500,
                decoration: BoxDecoration(
                  color: const Color(0xFF0F2540),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                        color: Colors.black38,
                        blurRadius: 20,
                        offset: Offset(0, 12))
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 倒數時間
                    Text(
                      _fmt(_seconds),
                      style: const TextStyle(
                        fontSize: 72,
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 呼吸球
                    ScaleTransition(
                      scale: _scaleAnim,
                      child: Container(
                        width: 140,
                        height: 140,
                        decoration: const BoxDecoration(
                          color: Colors.white24,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    const SizedBox(height: 42),
                    Text(
                      _breathText,
                      style: const TextStyle(
                        fontSize: 22,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 40),
                    ElevatedButton(
                      onPressed: () {
                        if (_running) {
                          _pauseTimer();
                        } else {
                          if (_seconds == 0 && _initialSeconds > 0) {
                            setState(() => _seconds = _initialSeconds);
                          }
                          _startTimer();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black87,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text(_running ? '暫停' : '開始'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 48),
              Text(
                '若要退出請按「結束冥想」並確認',
                style: TextStyle(color: Colors.white.withOpacity(0.85)),
              ),
              const SizedBox(height: 28),

              ElevatedButton(
                onPressed: () async {
                  final ok = await _confirmDoubleEnd();
                  if (ok) {
                    _timer?.cancel();
                    _timer = null;
                    if (mounted) Navigator.of(context).maybePop();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black87,
                ),
                child: const Text('結束冥想'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
