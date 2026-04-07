import 'package:flutter/material.dart';
import '../theme/colors.dart';

class CategoryIcon extends StatelessWidget {
  final String label;
  final int? count;
  final VoidCallback? onTap;
  final String? iconAsset;

  const CategoryIcon({
    super.key,
    required this.label,
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
          SizedBox(
            width: 60,
            height: 60,
            child: iconAsset != null
                ? Image.asset(
                    iconAsset!,
                    width: 60,
                    height: 60,
                    fit: BoxFit.contain,
                  )
                : const Icon(Icons.restaurant, size: 28),
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
    'xican': {'name': '沙拉', 'icon': 'assets/icons/salad.png'},
    'recai': {'name': '热菜', 'icon': 'assets/icons/recai.png'},
    'liangcai': {'name': '凉菜', 'icon': 'assets/icons/liangcai.png'},
    'tanggeng': {'name': '汤羹', 'icon': 'assets/icons/tanggeng.png'},
    'zhushi': {'name': '主食', 'icon': 'assets/icons/zhushi.png'},
    'xiaochi': {'name': '小吃', 'icon': 'assets/icons/xiaochi.png'},
    'jiachang': {'name': '家常菜', 'icon': 'assets/icons/jiachang.png'},
    'jiangpaoyancai': {'name': '泡酱腌菜', 'icon': null},
  };

  static String getName(String id) {
    return config[id]?['name'] ?? id;
  }

  static String? getIconAsset(String id) {
    return config[id]?['icon'];
  }
}
