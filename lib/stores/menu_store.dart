import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MenuStore extends ChangeNotifier {
  static const String _storageKey = 'menu_ids';

  final Set<String> _menuIds = {};
  bool _isLoaded = false;

  Set<String> get menuIds => _menuIds;

  MenuStore() {
    _loadFromStorage();
  }

  Future<void> _loadFromStorage() async {
    if (_isLoaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_storageKey);
      if (jsonStr != null) {
        final List<dynamic> list = json.decode(jsonStr);
        _menuIds.clear();
        _menuIds.addAll(list.cast<String>());
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Failed to load menu: $e');
    }
    _isLoaded = true;
  }

  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = json.encode(_menuIds.toList());
      await prefs.setString(_storageKey, jsonStr);
    } catch (e) {
      debugPrint('Failed to save menu: $e');
    }
  }

  bool isInMenu(String id) => _menuIds.contains(id);

  void toggle(String id) {
    if (_menuIds.contains(id)) {
      _menuIds.remove(id);
    } else {
      _menuIds.add(id);
    }
    notifyListeners();
    _saveToStorage();
  }

  void add(String id) {
    _menuIds.add(id);
    notifyListeners();
    _saveToStorage();
  }

  void remove(String id) {
    _menuIds.remove(id);
    notifyListeners();
    _saveToStorage();
  }

  void clear() {
    _menuIds.clear();
    notifyListeners();
    _saveToStorage();
  }

  // 导出数据
  String exportData() {
    return json.encode({
      'type': 'menu',
      'version': 1,
      'data': _menuIds.toList(),
      'exportedAt': DateTime.now().toIso8601String(),
    });
  }

  // 导入数据
  Future<int> importData(String jsonStr, {bool merge = true}) async {
    try {
      final Map<String, dynamic> imported = json.decode(jsonStr);
      if (imported['type'] != 'menu') {
        throw Exception('Invalid data type');
      }
      final List<dynamic> dataList = imported['data'];

      if (!merge) {
        _menuIds.clear();
      }

      int addedCount = 0;
      for (final id in dataList) {
        if (!_menuIds.contains(id)) {
          _menuIds.add(id);
          addedCount++;
        }
      }

      notifyListeners();
      await _saveToStorage();
      return addedCount;
    } catch (e) {
      debugPrint('Failed to import menu: $e');
      rethrow;
    }
  }
}
