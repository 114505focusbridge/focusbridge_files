// lib/screens/album_bubbles/bubble_photo.dart

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:focusbridge_app/screens/album_bubbles/bubble_physics.dart';
import 'package:collection/collection.dart';

class BubblePhotoScreen extends StatefulWidget {
  final List<Map<String, dynamic>> photos;
  final Function(String) onBubbleTap;

  const BubblePhotoScreen({
    super.key,
    required this.photos,
    required this.onBubbleTap,
  });

  @override
  State<BubblePhotoScreen> createState() => _BubblePhotoScreenState();
}

class _BubblePhotoScreenState extends State<BubblePhotoScreen> with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  BubblePhysics? _physics; 
  final List<Bubble> _bubbles = [];

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_handleTick);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_physics == null) {
      // 將泡泡的活動範圍底部固定在離畫面底部 200 像素處
      final screenHeightWithOffset = MediaQuery.of(context).size.height - 200;

      _physics = BubblePhysics(
        width: MediaQuery.of(context).size.width,
        height: screenHeightWithOffset,
      );
      _createBubbles(widget.photos);
      _ticker.start();
    }
  }

  void _handleTick(Duration elapsed) {
    if (!mounted || _physics == null) {
      _ticker.stop();
      return;
    }
    setState(() {
      _physics!.update(_bubbles);
    });
  }

  @override
  void didUpdateWidget(covariant BubblePhotoScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.photos.length != oldWidget.photos.length) {
      _createBubbles(widget.photos);
    }
  }

  void _createBubbles(List<Map<String, dynamic>> photos) {
    final random = Random();
    final usedPositions = <Rect>[];
    _bubbles.clear();
    
    final photosToUse = photos.take(20).toList();

    for (final photo in photosToUse) {
      final size = 80.0 + random.nextDouble() * 40.0;
      Offset position;
      Rect bubbleRect;
      bool isOverlapping;
      int attempts = 0;

      do {
        position = Offset(
          random.nextDouble() * (_physics!.width - size),
          random.nextDouble() * (_physics!.height - size),
        );
        bubbleRect = Rect.fromCircle(center: position, radius: size / 2);
        isOverlapping = false;
        
        for (final usedRect in usedPositions) {
          if (bubbleRect.inflate(10).overlaps(usedRect.inflate(10))) {
            isOverlapping = true;
            break;
          }
        }
        attempts++;
      } while (isOverlapping && attempts < 100);

      if (!isOverlapping) {
        usedPositions.add(bubbleRect);
        _bubbles.add(
          Bubble(
            size: size,
            photoUrl: photo['url'] as String,
            emotion: photo['emotion'] as String,
            position: position,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: _bubbles.map((bubble) {
        return Positioned(
          left: bubble.position.dx - bubble.size / 2,
          top: bubble.position.dy - bubble.size / 2,
          child: GestureDetector(
            onTap: () => widget.onBubbleTap(bubble.emotion),
            onPanStart: (details) {
              setState(() {
                bubble.isDragging = true;
                bubble.vx = 0;
                bubble.vy = 0;
              });
            },
            onPanUpdate: (details) {
              if (bubble.isDragging && _physics != null) {
                final newPosition = bubble.position + details.delta;
                
                bubble.position = Offset(
                  newPosition.dx.clamp(bubble.size / 2, _physics!.width - bubble.size / 2),
                  newPosition.dy.clamp(bubble.size / 2, _physics!.height - bubble.size / 2),
                );
              }
            },
            onPanEnd: (_) {
              setState(() {
                bubble.isDragging = false;
              });
            },
            child: Hero(
              tag: 'bubble-photo-${bubble.emotion}',
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: bubble.size,
                  height: bubble.size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          bubble.photoUrl,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            );
                          },
                        ),
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            color: Colors.black.withOpacity(0.5),
                            child: Text(
                              bubble.emotion,
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

extension on Iterable<Bubble> {
  Bubble? firstWhereOrNull(bool Function(Bubble) test) {
    for (var element in this) {
      if (test(element)) {
        return element;
      }
    }
    return null;
  }
}