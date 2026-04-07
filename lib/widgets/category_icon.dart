import 'package:flutter/material.dart';
import '../theme/colors.dart';

class CategoryIcon extends StatelessWidget {
  final String emoji;
  final String label;
  final Color bgColor;
  final int? count;
  final VoidCallback? onTap;

  const CategoryIcon({
    super.key,
    required this.emoji,
    required this.label,
    this.bgColor = const Color(0xFFF5F5F5),
    this.count,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                emoji,
                style: const TextStyle(fontSize: 28),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (count != null)
            Text(
              '$count道',
              style: TextStyle(
                fontSize: 10,
                color: AppColors.textMuted.withValues(alpha: 0.8),
              ),
            ),
        ],
      ),
    );
  }
}

// 分类配置
class CategoryConfig {
  static const Map<String, Map<String, dynamic>> config = {
    'recai': {'emoji': '🍳', 'bgColor': Color(0xFFFFEBEE), 'name': '热菜'},
    'liangcai': {'emoji': '🥗', 'bgColor': Color(0xFFE8F5E9), 'name': '凉菜'},
    'tanggeng': {'emoji': '🍲', 'bgColor': Color(0xFFF3E5F5), 'name': '汤羹'},
    'zhushi': {'emoji': '🍚', 'bgColor': Color(0xFFFFF8E1), 'name': '主食'},
    'xiaochi': {'emoji': '🥟', 'bgColor': Color(0xFFE3F2FD), 'name': '小吃'},
    'hongbei': {'emoji': '🍰', 'bgColor': Color(0xFFFFF3E0), 'name': '烘焙'},
    'yinpin': {'emoji': '🍹', 'bgColor': Color(0xFFFCE4EC), 'name': '饮品'},
    'jiangchangcai': {'emoji': '🏠', 'bgColor': Color(0xFFEFEBE9), 'name': '家常菜'},
  };

  static String getEmoji(String id) {
    return config[id]?['emoji'] ?? '🍽️';
  }

  static Color getBgColor(String id) {
    return config[id]?['bgColor'] ?? const Color(0xFFF5F5F5);
  }

  static String getName(String id) {
    return config[id]?['name'] ?? id;
  }
}
