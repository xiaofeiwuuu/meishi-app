import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../services/api_client.dart';

/// 今日菜单(云端同步,登录后从后端加载;替代原本地 SharedPreferences)
class MenuStore extends ChangeNotifier {
  final Set<String> _menuIds = {};

  Set<String> get menuIds => _menuIds;
  bool isInMenu(String id) => _menuIds.contains(id);

  Future<void> load() async {
    try {
      final data = await ApiClient.instance.get('/app/menu/ids');
      _menuIds
        ..clear()
        ..addAll(List<String>.from(data ?? []));
      notifyListeners();
    } catch (e) {
      debugPrint('加载今日菜单失败: $e');
    }
  }

  void clearLocal() {
    _menuIds.clear();
    notifyListeners();
  }

  Future<void> toggle(String id) async {
    if (_menuIds.contains(id)) {
      await remove(id);
    } else {
      await add(id);
    }
  }

  Future<void> add(String id) async {
    if (_menuIds.contains(id)) return;
    _menuIds.add(id);
    notifyListeners();
    try {
      await ApiClient.instance.post('/app/menu/$id');
    } catch (e) {
      _menuIds.remove(id);
      notifyListeners();
      debugPrint('加入今日菜单失败: $e');
    }
  }

  Future<void> remove(String id) async {
    if (!_menuIds.contains(id)) return;
    _menuIds.remove(id);
    notifyListeners();
    try {
      await ApiClient.instance.delete('/app/menu/$id');
    } catch (e) {
      _menuIds.add(id);
      notifyListeners();
      debugPrint('移除今日菜单失败: $e');
    }
  }

  Future<void> clear() async {
    final backup = Set<String>.from(_menuIds);
    _menuIds.clear();
    notifyListeners();
    try {
      await ApiClient.instance.delete('/app/menu');
    } catch (e) {
      _menuIds.addAll(backup);
      notifyListeners();
      debugPrint('清空今日菜单失败: $e');
    }
  }

  // 导出(备份用)
  String exportData() => json.encode({
        'type': 'menu',
        'version': 1,
        'data': _menuIds.toList(),
        'exportedAt': DateTime.now().toIso8601String(),
      });

  // 导入:逐个同步到云端
  Future<int> importData(String jsonStr, {bool merge = true}) async {
    final Map<String, dynamic> imported = json.decode(jsonStr);
    if (imported['type'] != 'menu') {
      throw Exception('Invalid data type');
    }
    final List<dynamic> dataList = imported['data'];
    if (!merge) await clear();
    int added = 0;
    for (final raw in dataList) {
      final id = raw.toString();
      if (!_menuIds.contains(id)) {
        _menuIds.add(id);
        added++;
        try {
          await ApiClient.instance.post('/app/menu/$id');
        } catch (_) {}
      }
    }
    notifyListeners();
    return added;
  }
}
