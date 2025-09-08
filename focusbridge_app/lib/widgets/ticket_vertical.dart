
// ----------------------------------------
// 內嵌元件：TicketVertical（可拆成 lib/widgets/ticket_vertical.dart ）
// 變更重點：票根掉落動畫、移除黑色底色、提示文字顯示在票根上。
// 已修正：移除重複 state、補上剪裁器、替換已棄用 API、修正動畫 listener 移除。
// ----------------------------------------

import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class TicketVertical extends StatefulWidget {
  final int durationSeconds;
  final bool isRunning;
  final VoidCallback onStartPause;
  final VoidCallback onOpenPicker;
  final VoidCallback onTearComplete;

  const TicketVertical({
    required this.durationSeconds,
    required this.isRunning,
    required this.onStartPause,
    required this.onOpenPicker,
    required this.onTearComplete,
    super.key, required Column child,
  });

  @override
  State<TicketVertical> createState() => _TicketVerticalState();
}

class _TicketVerticalState extends State<TicketVertical> with TickerProviderStateMixin {
  double progress = 0.0; // 撕裂進度（0~1）
  late final AnimationController _ctrl;
  late final Animation<double> _anim;
  late final List<double> jaggies;

  // 掉落動畫控制器（nullable，較保險）
  AnimationController? _fallCtrl;
  Animation<double>? _fallAnim;

  bool _isFalling = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 360));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    jaggies = _buildJaggies(count: 36, seed: 42, amplitude: 8);

    // 初始化掉落動畫控制器
    _fallCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _fallAnim = CurvedAnimation(parent: _fallCtrl!, curve: Curves.easeIn);
  }

  List<double> _buildJaggies({int count = 30, int seed = 1, double amplitude = 8}) {
    final rng = math.Random(seed);
    return List.generate(count, (_) => (rng.nextDouble() * 2 - 1) * amplitude);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _fallCtrl?.dispose();
    super.dispose();
  }

  void _onPanUpdate(DragUpdateDetails d, double height) {
    if (_isFalling) return; // 撕開完成後不再回應拖動
    final dy = d.delta.dy;
    final delta = dy / (height * 0.45); // 拖約 45% 高度即撕開
    setState(() {
      progress = (progress + delta).clamp(0.0, 1.0);
    });
  }

  void _onPanEnd(double velocity) {
    if (_isFalling) return;
    final target = progress > 0.5 || velocity > 700 ? 1.0 : 0.0;
    final begin = progress;
    _ctrl.stop();
    _ctrl.reset();

    // 使用可移除的 listener 參考，確保可以正確移除
    late final VoidCallback listener;
    listener = () {
      setState(() {
        progress = ui.lerpDouble(begin, target, _anim.value)!;
      });
    };
    _ctrl.addListener(listener);
    _ctrl.forward().whenComplete(() {
      _ctrl.removeListener(listener);
      if (target == 1.0) {
        // 觸發掉落動畫，完成後再關閉頁面
        _startFall();
      }
    });
  }

  void _startFall() {
    // 若 _fallCtrl 未初始化（理論上不會，但以防萬一），直接結束
    if (_fallCtrl == null) {
      widget.onTearComplete();
      return;
    }
    _isFalling = true;
    _fallCtrl!.forward().whenComplete(() {
      widget.onTearComplete();
    });
  }

  String _fmt(int sec) {
    final m = sec ~/ 60, s = sec % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    const w = 260.0, h = 420.0;
    final perforationY = h * 0.78; // 虛線靠近底部

    return GestureDetector(
      onPanUpdate: (d) => _onPanUpdate(d, h),
      onPanEnd: (d) => _onPanEnd(d.velocity.pixelsPerSecond.dy.abs()),
      child: SizedBox(
        width: w,
        height: h + 8,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            // 陰影
            Positioned(top: 8, child: _TicketShadow(size: Size(w, h))),

            // 上半（主卡） - 保持靜止
            ClipPath(
              clipper: _HorizontalTearClipper(
                size: Size(w, h),
                isTop: true,
                progress: progress,
                jaggies: jaggies,
                perforationY: perforationY,
              ),
              child: Container(
                width: w,
                height: h,
                decoration: BoxDecoration(
                  color: const Color(0xFF0F2540), // 深藍
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(_fmt(widget.durationSeconds), style: const TextStyle(fontSize: 48, color: Colors.white, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: widget.onStartPause,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black87),
                      child: Text(widget.isRunning ? '暫停' : '開始'),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // 下半（票根） - 這個部分會掉落；顏色與上半一致以去除黑色區塊
            AnimatedBuilder(
              // 若 fallAnim 尚未建立，使用主動畫作為 fallback
              animation: _fallAnim ?? _anim,
              builder: (context, child) {
                final fallT = (_fallAnim?.value ?? 0.0);
                final extraY = fallT * 520; // 跌落距離
                final rot = ui.lerpDouble(0, 0.8, fallT)!; // 旋轉角度
                final opacity = (1 - fallT).clamp(0.0, 1.0);

                return Positioned(
                  top: (perforationY) + (progress * 130) + extraY,
                  child: Transform.rotate(
                    angle: rot,
                    alignment: Alignment.center,
                    child: Opacity(
                      opacity: opacity,
                      child: child,
                    ),
                  ),
                );
              },
              child: ClipPath(
                clipper: _HorizontalTearClipper(
                  size: Size(w, h),
                  isTop: false,
                  progress: progress,
                  jaggies: jaggies,
                  perforationY: perforationY,
                ),
                child: Container(
                  width: w,
                  height: h,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F2540), // 與上半相同深藍色
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: SizedBox(
                    height: h,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const SizedBox(height: 8),
                        // 提示文字放在票根上
                        Opacity(
                          opacity: (1 - progress).clamp(0.0, 1.0),
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 18.0),
                            // 改用 withAlpha 以避開已棄用的 withOpacity
                            child: Text('若要退出請撕下此票根', style: TextStyle(color: Colors.white.withAlpha(242))),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // 虛線（固定在票卡上）
            Positioned(
              top: perforationY - 6,
              child: CustomPaint(
                size: Size(w, 1),
                painter: _HorizontalDashPainter(width: w, dashWidth: 8, gap: 6, color: Colors.white70),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TicketShadow extends StatelessWidget {
  final Size size;
  const _TicketShadow({required this.size});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: size.width,
      height: size.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(blurRadius: 20, color: Colors.black54, offset: Offset(0, 20))],
      ),
    );
  }
}

class _HorizontalDashPainter extends CustomPainter {
  final double width;
  final double dashWidth;
  final double gap;
  final Color color;
  _HorizontalDashPainter({required this.width, required this.dashWidth, required this.gap, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    double x = 0;
    while (x < width) {
      canvas.drawLine(Offset(x, 0), Offset((x + dashWidth).clamp(0, width), 0), paint);
      x += dashWidth + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _HorizontalDashPainter oldDelegate) => false;
}

/// 剪裁器：在指定 perforationY 處繪製鋸齒邊，根據 isTop 決定剪裁上半或下半
class _HorizontalTearClipper extends CustomClipper<Path> {
  final Size size;
  final bool isTop;
  final double progress; // 0..1
  final List<double> jaggies;
  final double perforationY;

  _HorizontalTearClipper({
    required this.size,
    required this.isTop,
    required this.progress,
    required this.jaggies,
    required this.perforationY,
  });

  @override
  Path getClip(Size _size) {
    final w = size.width;
    final h = size.height;
    final path = Path();

    // 把撕裂的深度與 jaggies 放大縮放
    final tearDepth = 24.0 * progress; // 最大 24 px 的撕裂偏移
    final samples = jaggies.length;
    // 根據 isTop 決定基準 Y：上半剪裁到 perforationY - tearDepth，底半從 perforationY + tearDepth 開始
    final baseY = isTop ? (perforationY - tearDepth) : (perforationY + tearDepth);

    if (isTop) {
      path.moveTo(0, 0);
      path.lineTo(w, 0);
      // 右側到基準 y
      path.lineTo(w, baseY);

      // 繪製鋸齒邊從右到左
      for (int i = samples - 1; i >= 0; i--) {
        final t = i / (samples - 1);
        final x = t * w;
        final offset = jaggies[i] * 0.35 * progress; // scale jaggies with progress
        final y = baseY + offset;
        path.lineTo(x, y);
      }

      path.lineTo(0, baseY);
      path.close();
    } else {
      // bottom half: 從左上角的基準點往右繪製，包含鋸齒
      path.moveTo(0, baseY);
      // 鋸齒從左到右
      for (int i = 0; i < samples; i++) {
        final t = i / (samples - 1);
        final x = t * w;
        final offset = jaggies[i] * 0.35 * progress;
        final y = baseY + offset;
        path.lineTo(x, y);
      }
      path.lineTo(w, baseY);
      path.lineTo(w, h);
      path.lineTo(0, h);
      path.close();
    }

    return path;
  }

  @override
  bool shouldReclip(covariant _HorizontalTearClipper old) {
    return old.progress != progress || old.jaggies != jaggies || old.perforationY != perforationY;
  }
}
