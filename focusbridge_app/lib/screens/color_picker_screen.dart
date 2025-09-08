import 'package:flutter/material.dart';
import 'dart:math' as math;

class ColorPickerScreen extends StatefulWidget {
  const ColorPickerScreen({super.key});

  @override
  State<ColorPickerScreen> createState() => _ColorPickerScreenState();
}

class _ColorPickerScreenState extends State<ColorPickerScreen> {
  final List<Color> colors = const [
    Color(0xFFFF3117), // 憤怒的紅
    Color(0xFFFF8313), // 緊張的橘
    Color(0xFFFFC665), // 快樂的黃
    Color(0xFF60BC04), // 平靜的綠
    Color(0xFF8BD2FF), // 舒緩的淺藍
    Color(0xFF2763FF), // 憂鬱的深藍
    Color(0xFF865BFF), // 迷茫的紫
    Color(0xFFFF9AD6), // 溫暖的粉
    Color(0xFFA46421), // 沉重的棕
    Color(0xFFEBEBEB), // 中性的灰
    Color(0xFF929292), // 壓抑的深灰
    Color(0xFF212121), // 絕望的黑
  ];

  int? _activeIndex;

  // 調整卡片尺寸以符合更柔和的視覺風格
  static const double cardWidth = 180;
  static const double cardHeight = 100;

  // 垂直間距（卡片從左側直列露出）
  static const double verticalSpacing = 36.0;

  // 外層高度
  static const double containerHeight = 620;

  // 透過垂直坐標來計算 index（用於拖曳時選取）
  void _handlePanUpdate(DragUpdateDetails details, BuildContext context) {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;
    // 與 build 中相同的總高度與 baseTop 計算
    final double totalStackHeight =
        cardHeight + (colors.length - 1) * verticalSpacing;
    final double baseTop = (containerHeight - totalStackHeight) / 2;

    // 取得 local dy
    double dy = details.localPosition.dy;
    // map dy to index
    double relative = (dy - baseTop) / verticalSpacing;
    int index = relative.round();
    index = index.clamp(0, colors.length - 1);

    if (_activeIndex != index) {
      setState(() {
        _activeIndex = index;
      });
    }
  }

  // 點擊或拖曳結束後觸發跳頁動畫與導頁
  void _activateAndNavigate(int index, String emotionLabel) {
    setState(() {
      _activeIndex = index;
    });
    Future.delayed(const Duration(milliseconds: 350), () {
      Navigator.pushNamed(
        context,
        '/diary_entry',
        arguments: {
          'emotion': emotionLabel,
          'color': colors[index],
        },
      );
      // 重置選取（如果回到此頁會顯示）
      setState(() {
        _activeIndex = null;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments;
    final String emotionLabel = args is String ? args : '';

    return Scaffold(
      backgroundColor: Colors.white, // 將背景設為純白色
      appBar: AppBar(
        backgroundColor: Colors.transparent, // 背景設為透明
        elevation: 0, // 移除陰影
        automaticallyImplyLeading: false,
        title: Text(
          '你的「$emotionLabel」\n是什麼顏色呢？',
          textAlign: TextAlign.center,
        ),
        toolbarHeight: 100,
        titleTextStyle: TextStyle(
          fontSize: 24, // 調整字體大小與主頁一致
          fontWeight: FontWeight.w800,
          color: Colors.blueGrey.shade800,
          height: 1.3,
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: Colors.blueGrey.shade800),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: GestureDetector(
          onPanStart: (details) => _handlePanUpdate(
            DragUpdateDetails(
              globalPosition: details.globalPosition,
              localPosition: details.localPosition,
            ),
            context,
          ),
          onPanUpdate: (details) => _handlePanUpdate(details, context),
          onPanEnd: (_) {
            if (_activeIndex != null) {
              _activateAndNavigate(_activeIndex!, emotionLabel);
            } else {
              setState(() {
                _activeIndex = null;
              });
            }
          },
          onPanCancel: () {
            setState(() {
              _activeIndex = null;
            });
          },
          child: SizedBox(
            height: containerHeight,
            child: LayoutBuilder(builder: (context, constraints) {
              final double width = constraints.maxWidth;

              // 計算垂直堆疊位置
              final double totalStackHeight =
                  cardHeight + (colors.length - 1) * verticalSpacing;
              final double baseTop = (containerHeight - totalStackHeight) / 2;

              // 未選中時卡片露出在左側
              final double hiddenLeft = -cardWidth * 0.45;
              // 選中時移到中右，位置更動態
              final double targetLeft = width * 0.45;

              return Stack(
                children: List.generate(colors.length, (index) {
                  final double regularTop = baseTop + index * verticalSpacing;
                  final bool isActive = _activeIndex == index;

                  return AnimatedPositioned(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                    left: isActive ? targetLeft : hiddenLeft,
                    top: regularTop,
                    width: cardWidth,
                    height: cardHeight,
                    child: GestureDetector(
                      onTap: () => _activateAndNavigate(index, emotionLabel),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeInOut,
                        transform: isActive
                            ? (Matrix4.identity()..translate(10.0, -8.0)..scale(1.05))
                            : Matrix4.identity(),
                        transformAlignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: colors[index],
                          borderRadius: BorderRadius.circular(20), // 圓角更圓潤
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(isActive ? 0.35 : 0.15),
                              blurRadius: isActive ? 20 : 10,
                              offset: Offset(0, isActive ? 10 : 5),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              );
            }),
          ),
        ),
      ),
    );
  }
}