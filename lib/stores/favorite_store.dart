import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../services/api_client.dart';

/// 收藏(云端同步,登录后从后端加载;替代原本地 SharedPreferences)
class FavoriteStore extends ChangeNotifier {
  final Set<String> _favoriteIds = {};

  Set<String> get favoriteIds => _favoriteIds;
  bool isFavorite(String id) => _favoriteIds.contains(id);

  /// 登录后加载云端收藏 id 列表
  Future<void> load() async {
    try {
      final data = await ApiClient.instance.get('/app/favorites/ids');
      _favoriteIds
        ..clear()
        ..addAll(List<String>.from(data ?? []));
      notifyListeners();
    } catch (e) {
      debugPrint('加载收藏失败: $e');
    }
  }

  /// 退出登录清空本地(不动云端)
  void clearLocal() {
    _favoriteIds.clear();
    notifyListeners();
  }

  /// 收藏/取消:乐观更新 + 同步后端,失败回滚
  Future<void> toggle(String id) async {
    final wasFav = _favoriteIds.contains(id);
    if (wasFav) {
      _favoriteIds.remove(id);
    } else {
      _favoriteIds.add(id);
    }
    notifyListeners();
    try {
      if (wasFav) {
        await ApiClient.instance.delete('/app/favorites/$id');
      } else {
        await ApiClient.instance.post('/app/favorites/$id');
      }
    } catch (e) {
      // 回滚
      if (wasFav) {
        _favoriteIds.add(id);
      } else {
        _favoriteIds.remove(id);
      }
      notifyListeners();
      debugPrint('收藏同步失败: $e');
    }
  }

  // 导出(备份用)
  String exportData() => json.encode({
        'type': 'favorites',
        'version': 1,
        'data': _favoriteIds.toList(),
        'exportedAt': DateTime.now().toIso8601String(),
      });

  // 导入:逐个同步到云端
  Future<int> importData(String jsonStr, {bool merge = true}) async {
    final Map<String, dynamic> imported = json.decode(jsonStr);
    if (imported['type'] != 'favorites') {
      throw Exception('Invalid data type');
    }
    final List<dynamic> dataList = imported['data'];
    if (!merge) _favoriteIds.clear();
    int added = 0;
    for (final raw in dataList) {
      final id = raw.toString();
      if (!_favoriteIds.contains(id)) {
        _favoriteIds.add(id);
        added++;
        try {
          await ApiClient.instance.post('/app/favorites/$id');
        } catch (_) {
          // 单条失败忽略
        }
      }
    }
    notifyListeners();
    return added;
  }
}
