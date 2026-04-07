import 'package:flutter/material.dart';
import '../theme/colors.dart';
import 'animal_icons.dart';

class CategoryIcon extends StatelessWidget {
  final String emoji;
  final String label;
  final Color bgColor;
  final int? count;
  final VoidCallback? onTap;
  final AnimalType? animalType;  // 使用自定义动物图标

  const CategoryIcon({
    super.key,
    required this.emoji,
    required this.label,
    this.bgColor = const Color(0xFFFFF5E6),  // 温暖奶黄
    this.count,
    this.onTap,
    this.animalType,
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
              child: animalType != null
                  ? AnimalIcon(
                      type: animalType!,
                      size: 44,
                      backgroundColor: Colors.transparent,
                    )
                  : Text(
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
  // 萌系配色 + 自定义动物图标映射
  static const Map<String, Map<String, dynamic>> config = {
    'recai': {'emoji': '🐔', 'bgColor': Color(0xFFFFE4B5), 'name': '热菜', 'animal': AnimalType.chicken},
    'liangcai': {'emoji': '🐰', 'bgColor': Color(0xFFE8F5E9), 'name': '凉菜', 'animal': AnimalType.bunny},
    'tanggeng': {'emoji': '🐻', 'bgColor': Color(0xFFFFE4E1), 'name': '汤羹', 'animal': AnimalType.bear},
    'zhushi': {'emoji': '🐱', 'bgColor': Color(0xFFFFF8DC), 'name': '主食', 'animal': AnimalType.cat},
    'xiaochi': {'emoji': '🐷', 'bgColor': Color(0xFFFFE4EC), 'name': '小吃', 'animal': AnimalType.pig},
    'hongbei': {'emoji': '🐮', 'bgColor': Color(0xFFF3E5F5), 'name': '烘焙', 'animal': AnimalType.cow},
    'yinpin': {'emoji': '🦆', 'bgColor': Color(0xFFFFF9C4), 'name': '饮品', 'animal': AnimalType.duck},
    'jiangchangcai': {'emoji': '🐟', 'bgColor': Color(0xFFE3F2FD), 'name': '家常菜', 'animal': AnimalType.fish},
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

  static AnimalType? getAnimalType(String id) {
    return config[id]?['animal'];
  }
}
