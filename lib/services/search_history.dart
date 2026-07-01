import 'package:shared_preferences/shared_preferences.dart';

/// 本地搜索历史:最多 10 条,去重,最新在前
class SearchHistory {
  static const _key = 'search_history';
  static const _max = 10;

  static Future<List<String>> load() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_key) ?? [];
  }

  /// 加入一条(已存在则提到最前),返回更新后的列表
  static Future<List<String>> add(String keyword) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? [];
    final k = keyword.trim();
    if (k.isEmpty) return list;
    list.remove(k); // 去重
    list.insert(0, k); // 最新在前
    if (list.length > _max) list.removeRange(_max, list.length);
    await prefs.setStringList(_key, list);
    return list;
  }

  static Future<List<String>> remove(String keyword) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? [];
    list.remove(keyword);
    await prefs.setStringList(_key, list);
    return list;
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
