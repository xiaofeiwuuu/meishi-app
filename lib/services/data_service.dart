import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import '../stores/favorite_store.dart';
import '../stores/menu_store.dart';

class DataService {
  // 导出所有数据
  static String exportAllData({
    required FavoriteStore favoriteStore,
    required MenuStore menuStore,
  }) {
    return json.encode({
      'type': 'meishi_backup',
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'favorites': json.decode(favoriteStore.exportData()),
      'menu': json.decode(menuStore.exportData()),
    });
  }

  // 导入所有数据
  static Future<Map<String, int>> importAllData(
    String jsonStr, {
    required FavoriteStore favoriteStore,
    required MenuStore menuStore,
    bool merge = true,
  }) async {
    final Map<String, dynamic> data = json.decode(jsonStr);

    // 支持完整备份或单独导入
    if (data['type'] == 'meishi_backup') {
      final results = <String, int>{};

      if (data['favorites'] != null) {
        results['favorites'] = await favoriteStore.importData(
          json.encode(data['favorites']),
          merge: merge,
        );
      }
      if (data['menu'] != null) {
        results['menu'] = await menuStore.importData(
          json.encode(data['menu']),
          merge: merge,
        );
      }
      return results;
    } else if (data['type'] == 'favorites') {
      return {'favorites': await favoriteStore.importData(jsonStr, merge: merge)};
    } else if (data['type'] == 'menu') {
      return {'menu': await menuStore.importData(jsonStr, merge: merge)};
    }

    throw Exception('Unknown data type');
  }

  // 保存并分享文件
  static Future<void> exportAndShare({
    required BuildContext context,
    required FavoriteStore favoriteStore,
    required MenuStore menuStore,
  }) async {
    try {
      final jsonStr = exportAllData(
        favoriteStore: favoriteStore,
        menuStore: menuStore,
      );

      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${directory.path}/meishi_backup_$timestamp.json');
      await file.writeAsString(jsonStr);

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Meishi Backup',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导出失败: $e')),
        );
      }
    }
  }

  // 从文件导入
  static Future<Map<String, int>?> importFromFile({
    required BuildContext context,
    required FavoriteStore favoriteStore,
    required MenuStore menuStore,
    bool merge = true,
  }) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.isEmpty) return null;

      final file = File(result.files.single.path!);
      final jsonStr = await file.readAsString();

      return await importAllData(
        jsonStr,
        favoriteStore: favoriteStore,
        menuStore: menuStore,
        merge: merge,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导入失败: $e')),
        );
      }
      return null;
    }
  }
}
