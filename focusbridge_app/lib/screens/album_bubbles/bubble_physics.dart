// lib/screens/album_bubbles/bubble_physics.dart

import 'dart:math';
import 'package:flutter/material.dart';

// 調整這些參數來控制泡泡行為
const double _kFriction = 1; // 摩擦力，數字越小泡泡越快停下來
const double _kCollisionForce = 0; // 碰撞時彈開的力量，數字越小彈開越輕柔
const double _kBoundaryRepulsion = 0; // 邊界反彈力量，數字越大反彈越強

class BubblePhysics {
  final double width;
  final double height;
  BubblePhysics({required this.width, required this.height});

  void update(List<Bubble> bubbles) {
    _applyForces(bubbles);
    _checkCollisions(bubbles);
    _applyMovement(bubbles);
  }

  void _applyForces(List<Bubble> bubbles) {
    for (var bubble in bubbles) {
      // 應用摩擦力
      bubble.vx *= _kFriction;
      bubble.vy *= _kFriction;

      // 應用邊界排斥力
      if (bubble.position.dx < bubble.size / 2) {
        bubble.vx += _kBoundaryRepulsion;
      } else if (bubble.position.dx > width - bubble.size / 2) {
        bubble.vx -= _kBoundaryRepulsion;
      }
      if (bubble.position.dy < bubble.size / 2) {
        bubble.vy += _kBoundaryRepulsion;
      } else if (bubble.position.dy > height - bubble.size / 2) {
        bubble.vy -= _kBoundaryRepulsion;
      }
    }
  }

  void _checkCollisions(List<Bubble> bubbles) {
    for (int i = 0; i < bubbles.length; i++) {
      for (int j = i + 1; j < bubbles.length; j++) {
        final bubble1 = bubbles[i];
        final bubble2 = bubbles[j];
        final dx = bubble1.position.dx - bubble2.position.dx;
        final dy = bubble1.position.dy - bubble2.position.dy;
        final distance = sqrt(dx * dx + dy * dy);
        final minDistance = (bubble1.size + bubble2.size) / 2;

        if (distance < minDistance) {
          final angle = atan2(dy, dx);
          final overlap = minDistance - distance;
          
          // 處理位置重疊
          final moveX = overlap * cos(angle) * 0.5;
          final moveY = overlap * sin(angle) * 0.5;
          bubble1.position += Offset(moveX, moveY);
          bubble2.position -= Offset(moveX, moveY);

          // 模擬彈開
          final totalMass = 1.0; // 簡化處理
          final impulseX = (bubble2.vx - bubble1.vx) * _kCollisionForce / totalMass;
          final impulseY = (bubble2.vy - bubble1.vy) * _kCollisionForce / totalMass;
          
          bubble1.vx -= impulseX;
          bubble1.vy -= impulseY;
          bubble2.vx += impulseX;
          bubble2.vy += impulseY;
        }
      }
    }
  }

  void _applyMovement(List<Bubble> bubbles) {
    for (var bubble in bubbles) {
      if (!bubble.isDragging) {
        // 運動更新
        bubble.position += Offset(bubble.vx, bubble.vy);
        // 隨機微小運動，這裡增加了幅度
        bubble.vx += (Random().nextDouble() - 0.5) * 0.2;
        bubble.vy += (Random().nextDouble() - 0.5) * 0.2;
      }
      
      // 限制泡泡位置在畫面範圍內
      bubble.position = Offset(
        bubble.position.dx.clamp(bubble.size / 2, width - bubble.size / 2),
        bubble.position.dy.clamp(bubble.size / 2, height - bubble.size / 2),
      );
    }
  }
}

class Bubble {
  final double size;
  final String photoUrl;
  final String emotion;
  Offset position;
  double vx = 0;
  double vy = 0;
  bool isDragging = false;

  Bubble({
    required this.size,
    required this.photoUrl,
    required this.emotion,
    required this.position,
  });
}