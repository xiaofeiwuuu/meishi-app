import 'package:flutter/foundation.dart';
import '../services/api_client.dart';

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
}

/// 分享历史(云端同步,替代原本地 SharedPreferences)
class ShareHistoryStore extends ChangeNotifier {
  static const int maxHistory = 50;

  final List<SharedMenu> _history = [];

  List<SharedMenu> get history => _history;

  // 分享排行榜(按分享次数降序)
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
      if (menu.recipeIds.contains(recipeId)) count++;
    }
    return count;
  }

  SharedMenu? getById(String id) {
    try {
      return _history.firstWhere((h) => h.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> load() async {
    try {
      final data = await ApiClient.instance.get('/app/share-history');
      _history
        ..clear()
        ..addAll((data as List? ?? []).map((e) => SharedMenu(
              id: e['id'].toString(),
              recipeIds: List<String>.from(e['recipeIds'] ?? []),
              sharedAt: DateTime.tryParse(e['createTime']?.toString() ?? '') ?? DateTime.now(),
            )));
      notifyListeners();
    } catch (e) {
      debugPrint('加载分享历史失败: $e');
    }
  }

  void clearLocal() {
    _history.clear();
    notifyListeners();
  }

  // 新增一条分享记录(POST 成功后按服务端 id 插入)
  Future<void> addSharedMenu(List<String> recipeIds) async {
    if (recipeIds.isEmpty) return;
    try {
      final res = await ApiClient.instance
          .post('/app/share-history', data: {'recipeIds': recipeIds});
      final id = res?['id']?.toString() ??
          DateTime.now().millisecondsSinceEpoch.toString();
      _history.insert(
        0,
        SharedMenu(id: id, recipeIds: List.from(recipeIds), sharedAt: DateTime.now()),
      );
      if (_history.length > maxHistory) {
        _history.removeRange(maxHistory, _history.length);
      }
      notifyListeners();
    } catch (e) {
      debugPrint('保存分享历史失败: $e');
    }
  }

  Future<void> removeSharedMenu(String id) async {
    final idx = _history.indexWhere((h) => h.id == id);
    if (idx < 0) return;
    final backup = _history[idx];
    _history.removeAt(idx);
    notifyListeners();
    try {
      await ApiClient.instance.delete('/app/share-history/$id');
    } catch (e) {
      _history.insert(idx, backup);
      notifyListeners();
      debugPrint('删除分享历史失败: $e');
    }
  }

  Future<void> clearHistory() async {
    final backup = List<SharedMenu>.from(_history);
    _history.clear();
    notifyListeners();
    try {
      await ApiClient.instance.delete('/app/share-history');
    } catch (e) {
      _history.addAll(backup);
      notifyListeners();
      debugPrint('清空分享历史失败: $e');
    }
  }
}
