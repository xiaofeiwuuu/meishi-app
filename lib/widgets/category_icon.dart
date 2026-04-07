import 'package:flutter/material.dart';
import '../theme/colors.dart';

class CategoryIcon extends StatelessWidget {
  final String label;
  final Color bgColor;
  final int? count;
  final VoidCallback? onTap;
  final String? iconAsset;  // 使用图片资源

  const CategoryIcon({
    super.key,
    required this.label,
    this.bgColor = const Color(0xFFFFF5E6),
    this.count,
    this.onTap,
    this.iconAsset,
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
              child: iconAsset != null
                  ? Image.asset(
                      iconAsset!,
                      width: 44,
                      height: 44,
                      fit: BoxFit.contain,
                    )
                  : const Icon(Icons.restaurant, size: 28),
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
    'recai': {'bgColor': Color(0xFFFFE4B5), 'name': '热菜', 'icon': 'assets/icons/recai.png'},
    'liangcai': {'bgColor': Color(0xFFE8F5E9), 'name': '凉菜', 'icon': 'assets/icons/liangcai.png'},
    'tanggeng': {'bgColor': Color(0xFFFFE4E1), 'name': '汤羹', 'icon': 'assets/icons/tanggeng.png'},
    'zhushi': {'bgColor': Color(0xFFFFF8DC), 'name': '主食', 'icon': 'assets/icons/zhushi.png'},
    'xiaochi': {'bgColor': Color(0xFFFFE4EC), 'name': '小吃', 'icon': 'assets/icons/xiaochi.png'},
    'jiachang': {'bgColor': Color(0xFFE3F2FD), 'name': '家常菜', 'icon': 'assets/icons/jiachang.png'},
    'jiangpaoyancai': {'bgColor': Color(0xFFF3E5F5), 'name': '泡酱腌菜', 'icon': null},
    'xican': {'bgColor': Color(0xFFFFF9C4), 'name': '西餐', 'icon': 'assets/icons/salad.png'},
  };

  static Color getBgColor(String id) {
    return config[id]?['bgColor'] ?? const Color(0xFFF5F5F5);
  }

  static String getName(String id) {
    return config[id]?['name'] ?? id;
  }

  static String? getIconAsset(String id) {
    return config[id]?['icon'];
  }
}
