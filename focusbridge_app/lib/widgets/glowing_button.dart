// lib/widgets/glowing_button.dart
import 'package:flutter/material.dart';

class GlowingButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final Color baseColor;

  const GlowingButton({
    super.key,
    required this.onPressed,
    required this.child,
    required this.baseColor,
  });

  @override
  State<GlowingButton> createState() => _GlowingButtonState();
}

class _GlowingButtonState extends State<GlowingButton> {
  // 紀錄按鈕是否被按下的狀態
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // 點擊開始時，改變狀態
      onTapDown: (_) {
        setState(() {
          _isPressed = true;
        });
      },
      // 點擊結束時，恢復狀態
      onTapUp: (_) {
        setState(() {
          _isPressed = false;
        });
      },
      // 點擊取消時，恢復狀態
      onTapCancel: () {
        setState(() {
          _isPressed = false;
        });
      },
      // 實際點擊事件
      onTap: widget.onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeInOut,
        height: 56,
        decoration: BoxDecoration(
          color: widget.baseColor,
          borderRadius: BorderRadius.circular(28),
          // 根據按下的狀態動態調整陰影
          boxShadow: [
            BoxShadow(
              color: widget.baseColor.withOpacity(0.6),
              // 按下時陰影擴散更大，模擬發光效果
              blurRadius: _isPressed ? 20 : 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Center(child: widget.child),
      ),
    );
  }
}