import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FavoriteStore extends ChangeNotifier {
  static const String _storageKey = 'favorite_ids';

  final Set<String> _favoriteIds = {};
  bool _isLoaded = false;

  Set<String> get favoriteIds => _favoriteIds;

  FavoriteStore() {
    _loadFromStorage();
  }

  Future<void> _loadFromStorage() async {
    if (_isLoaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_storageKey);
      if (jsonStr != null) {
        final List<dynamic> list = json.decode(jsonStr);
        _favoriteIds.clear();
        _favoriteIds.addAll(list.cast<String>());
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Failed to load favorites: $e');
    }
    _isLoaded = true;
  }

  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = json.encode(_favoriteIds.toList());
      await prefs.setString(_storageKey, jsonStr);
    } catch (e) {
      debugPrint('Failed to save favorites: $e');
    }
  }

  bool isFavorite(String id) => _favoriteIds.contains(id);

  void toggle(String id) {
    if (_favoriteIds.contains(id)) {
      _favoriteIds.remove(id);
    } else {
      _favoriteIds.add(id);
    }
    notifyListeners();
    _saveToStorage();
  }

  void add(String id) {
    _favoriteIds.add(id);
    notifyListeners();
    _saveToStorage();
  }

  void remove(String id) {
    _favoriteIds.remove(id);
    notifyListeners();
    _saveToStorage();
  }

  void clear() {
    _favoriteIds.clear();
    notifyListeners();
    _saveToStorage();
  }

  // 导出数据
  String exportData() {
    return json.encode({
      'type': 'favorites',
      'version': 1,
      'data': _favoriteIds.toList(),
      'exportedAt': DateTime.now().toIso8601String(),
    });
  }

  // 导入数据
  Future<int> importData(String jsonStr, {bool merge = true}) async {
    try {
      final Map<String, dynamic> imported = json.decode(jsonStr);
      if (imported['type'] != 'favorites') {
        throw Exception('Invalid data type');
      }
      final List<dynamic> dataList = imported['data'];

      if (!merge) {
        _favoriteIds.clear();
      }

      int addedCount = 0;
      for (final id in dataList) {
        if (!_favoriteIds.contains(id)) {
          _favoriteIds.add(id);
          addedCount++;
        }
      }

      notifyListeners();
      await _saveToStorage();
      return addedCount;
    } catch (e) {
      debugPrint('Failed to import favorites: $e');
      rethrow;
    }
  }
}
