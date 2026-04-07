import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 分享统计项
class ShareCountItem {
  final String recipeId;
  final int shareCount;

  ShareCountItem({required this.recipeId, required this.shareCount});
}

class SharedMenu {
  final String id;
  final List<String> recipeIds;
  final DateTime sharedAt;

  SharedMenu({
    required this.id,
    required this.recipeIds,
    required this.sharedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'recipeIds': recipeIds,
    'sharedAt': sharedAt.toIso8601String(),
  };

  factory SharedMenu.fromJson(Map<String, dynamic> json) => SharedMenu(
    id: json['id'],
    recipeIds: List<String>.from(json['recipeIds']),
    sharedAt: DateTime.parse(json['sharedAt']),
  );
}

class ShareHistoryStore extends ChangeNotifier {
  static const String _storageKey = 'share_history';
  static const int maxHistory = 50;

  final List<SharedMenu> _history = [];
  bool _isLoaded = false;

  List<SharedMenu> get history => _history;

  // 获取分享排行榜（按分享次数降序）
  List<ShareCountItem> get topShared {
    final counts = <String, int>{};
    for (final menu in _history) {
      for (final recipeId in menu.recipeIds) {
        counts[recipeId] = (counts[recipeId] ?? 0) + 1;
      }
    }
    final list = counts.entries
        .map((e) => ShareCountItem(recipeId: e.key, shareCount: e.value))
        .toList();
    list.sort((a, b) => b.shareCount.compareTo(a.shareCount));
    return list;
  }

  int getShareCount(String recipeId) {
    int count = 0;
    for (final menu in _history) {
      if (menu.recipeIds.contains(recipeId)) {
        count++;
      }
    }
    return count;
  }

  ShareHistoryStore() {
    _loadFromStorage();
  }

  Future<void> _loadFromStorage() async {
    if (_isLoaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_storageKey);
      if (jsonStr != null) {
        final List<dynamic> jsonList = json.decode(jsonStr);
        _history.clear();
        _history.addAll(jsonList.map((e) => SharedMenu.fromJson(e)));
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Failed to load share history: $e');
    }
    _isLoaded = true;
  }

  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = json.encode(_history.map((h) => h.toJson()).toList());
      await prefs.setString(_storageKey, jsonStr);
    } catch (e) {
      debugPrint('Failed to save share history: $e');
    }
  }

  // 添加分享记录
  void addSharedMenu(List<String> recipeIds) {
    if (recipeIds.isEmpty) return;

    final menu = SharedMenu(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      recipeIds: List.from(recipeIds),
      sharedAt: DateTime.now(),
    );

    _history.insert(0, menu);

    if (_history.length > maxHistory) {
      _history.removeRange(maxHistory, _history.length);
    }

    notifyListeners();
    _saveToStorage();
  }

  void removeSharedMenu(String id) {
    _history.removeWhere((h) => h.id == id);
    notifyListeners();
    _saveToStorage();
  }

  void clearHistory() {
    _history.clear();
    notifyListeners();
    _saveToStorage();
  }

  SharedMenu? getById(String id) {
    try {
      return _history.firstWhere((h) => h.id == id);
    } catch (_) {
      return null;
    }
  }
}
