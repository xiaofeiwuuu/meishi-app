import 'package:flutter/material.dart';

class BackgroundDecorations extends StatelessWidget {
  final int variant; // 1-7
  final Widget child;
  final bool hasTabBar; // 是否有底部 TabBar

  const BackgroundDecorations({
    super.key,
    required this.variant,
    required this.child,
    this.hasTabBar = false,
  });

  @override
  Widget build(BuildContext context) {
    // TabBar 高度约 80 (56 + 安全区域)
    final bottomPadding = hasTabBar ? 80.0 : 0.0;

    return Stack(
      children: [
        // 内容
        child,
        // 装饰图片在最上层，可穿透点击
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          bottom: bottomPadding,
          child: IgnorePointer(
            child: Image.asset(
              'assets/images/bg_decorations$variant.png',
              fit: BoxFit.fitHeight,
              opacity: const AlwaysStoppedAnimation(0.6),
            ),
          ),
        ),
      ],
    );
  }
}
