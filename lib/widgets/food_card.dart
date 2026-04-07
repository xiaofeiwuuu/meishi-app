import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/colors.dart';

class FoodCard extends StatefulWidget {
  final String id;
  final String imageUrl;
  final String title;
  final String time;
  final bool isAdded;
  final VoidCallback? onTap;
  final VoidCallback? onAddTap;

  const FoodCard({
    super.key,
    required this.id,
    required this.imageUrl,
    required this.title,
    this.time = '',
    this.isAdded = false,
    this.onTap,
    this.onAddTap,
  });

  @override
  State<FoodCard> createState() => _FoodCardState();
}

class _FoodCardState extends State<FoodCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.8), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.8, end: 1.15), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.15, end: 1.0), weight: 30),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _rotationAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.1), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 0.1, end: 0.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleAddTap() {
    _controller.forward(from: 0);
    widget.onAddTap?.call();
  }

  // 解析时间字符串获取分钟数
  int _parseMinutes(String time) {
    final match = RegExp(r'(\d+)').firstMatch(time);
    return match != null ? int.tryParse(match.group(1)!) ?? 30 : 30;
  }

  // 根据时间返回背景色
  Color _getTimeColor(String time) {
    final minutes = _parseMinutes(time);
    if (minutes <= 15) {
      return const Color(0xFFE8F5E9); // 浅绿 - 快速
    } else if (minutes <= 30) {
      return const Color(0xFFFFF8E1); // 浅黄 - 中等
    } else if (minutes <= 60) {
      return const Color(0xFFFFF3E0); // 浅橙 - 较长
    } else {
      return const Color(0xFFFFEBEE); // 浅粉红 - 很长
    }
  }

  // 根据时间返回文字/图标色
  Color _getTimeTextColor(String time) {
    final minutes = _parseMinutes(time);
    if (minutes <= 15) {
      return const Color(0xFF66BB6A); // 绿
    } else if (minutes <= 30) {
      return const Color(0xFFFFB300); // 黄
    } else if (minutes <= 60) {
      return const Color(0xFFFF9800); // 橙
    } else {
      return const Color(0xFFEF5350); // 红
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image - 用 Expanded 填充剩余空间
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: SizedBox(
                  width: double.infinity,
                  child: widget.imageUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: widget.imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: Colors.grey[200],
                          child: const Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.grey[200],
                          child: const Icon(Icons.restaurant, color: Colors.grey),
                        ),
                      )
                    : Container(
                        color: Colors.grey[200],
                        child: const Icon(Icons.restaurant, color: Colors.grey),
                      ),
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (widget.time.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getTimeColor(widget.time),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 12,
                                color: _getTimeTextColor(widget.time),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                widget.time,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: _getTimeTextColor(widget.time),
                                ),
                              ),
                            ],
                          ),
                        ),
                      const Spacer(),
                      GestureDetector(
                        onTap: _handleAddTap,
                        child: AnimatedBuilder(
                          animation: _controller,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _scaleAnimation.value,
                              child: Transform.rotate(
                                angle: _rotationAnimation.value,
                                child: child,
                              ),
                            );
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: widget.isAdded ? AppColors.primarySoft : AppColors.primary,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: widget.isAdded
                                  ? null
                                  : [
                                      BoxShadow(
                                        color: AppColors.primary.withValues(alpha: 0.3),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                            ),
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              transitionBuilder: (child, animation) {
                                return ScaleTransition(
                                  scale: animation,
                                  child: child,
                                );
                              },
                              child: Icon(
                                widget.isAdded ? Icons.check : Icons.add,
                                key: ValueKey(widget.isAdded),
                                size: 18,
                                color: widget.isAdded ? AppColors.primaryDark : AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
