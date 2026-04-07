import 'package:flutter/material.dart';

class Responsive {
  /// 根据屏幕宽度计算网格列数
  /// - 手机 (<600): 2列
  /// - 小平板 (600-900): 3列
  /// - 大平板 (>900): 4列
  static int getGridColumns(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 900) return 4;
    if (width > 600) return 3;
    return 2;
  }

  /// 根据屏幕宽度计算卡片宽高比
  static double getCardAspectRatio(BuildContext context) {
    final columns = getGridColumns(context);
    // 列数越多，卡片越小，可以稍微调整比例
    if (columns >= 4) return 0.8;
    if (columns >= 3) return 0.78;
    return 0.75;
  }

  /// 根据列数计算需要的数据量（保持 2 行整齐）
  /// - 2列 → 4个
  /// - 3列 → 6个
  /// - 4列 → 8个
  static int getItemCount(BuildContext context, {int rows = 2}) {
    return getGridColumns(context) * rows;
  }
}
