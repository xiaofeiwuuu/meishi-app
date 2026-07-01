import 'package:flutter/foundation.dart';
import '../models/recipe.dart';
import 'api_client.dart';

/// 菜谱数据服务 —— 已迁移到自有后端 /app/* 接口(原 jsDelivr 静态文件下线)
class RecipeService extends ChangeNotifier {
  final _api = ApiClient.instance;

  List<RecipeCategory> _categories = [];
  final Map<String, Recipe> _recipeCache = {};
  final Map<String, List<RecipeSummary>> _categoryRecipesCache = {};

  bool _isLoading = false;
  String? _error;

  List<RecipeCategory> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void clearCache() {
    _categories.clear();
    _recipeCache.clear();
    _categoryRecipesCache.clear();
    notifyListeners();
  }

  Future<void> loadCategories({bool forceRefresh = false}) async {
    if (_categories.isNotEmpty && !forceRefresh) return;
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await _api.get('/app/categories');
      _categories = (data as List)
          .map((e) => RecipeCategory(
                id: e['id'] ?? '',
                name: e['name'] ?? '',
                parent: e['parent'],
                total: e['count'] ?? 0,
              ))
          .toList();
    } catch (e) {
      _error = '加载分类失败: $e';
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<Recipe?> getRecipe(String id) async {
    if (_recipeCache.containsKey(id)) return _recipeCache[id];
    try {
      final data = await _api.get('/app/recipes/$id');
      final recipe = Recipe.fromJson(Map<String, dynamic>.from(data));
      _recipeCache[id] = recipe;
      return recipe;
    } catch (e) {
      debugPrint('加载菜谱失败: $e');
      return null;
    }
  }

  Future<List<RecipeSummary>> getRecipesByCategory(
    String categoryId, {
    int page = 1,
    bool forceRefresh = false,
  }) async {
    final cacheKey = '$categoryId-$page';
    if (_categoryRecipesCache.containsKey(cacheKey) && !forceRefresh) {
      return _categoryRecipesCache[cacheKey]!;
    }
    try {
      final data = await _api.get('/app/recipes',
          query: {'category': categoryId, 'page': page, 'pageSize': 20});
      final list = _parseSummaries(data['items']);
      _categoryRecipesCache[cacheKey] = list;
      return list;
    } catch (e) {
      debugPrint('加载菜谱列表失败: $e');
      return [];
    }
  }

  /// 服务端搜索(替代前端全量下载)
  Future<List<RecipeSummary>> searchRecipes(String keyword,
      {int page = 1, int pageSize = 20}) async {
    if (keyword.trim().isEmpty) return [];
    try {
      final data = await _api.get('/app/recipes',
          query: {'keyword': keyword.trim(), 'page': page, 'pageSize': pageSize});
      return _parseSummaries(data['items']);
    } catch (e) {
      debugPrint('搜索失败: $e');
      return [];
    }
  }

  Future<List<RecipeSummary>> getPopularRecipes({int limit = 8}) async {
    try {
      final data = await _api.get('/app/recipes', query: {'pageSize': limit});
      return _parseSummaries(data['items']);
    } catch (_) {
      return [];
    }
  }

  /// 随机推荐:随机挑一个分类取一页打乱
  Future<List<RecipeSummary>> getRandomRecipes({int limit = 8}) async {
    if (_categories.isEmpty) await loadCategories();
    if (_categories.isEmpty) return getPopularRecipes(limit: limit);
    final cat = (_categories.toList()..shuffle()).first;
    final list = await getRecipesByCategory(cat.id, forceRefresh: true);
    list.shuffle();
    return list.take(limit).toList();
  }

  List<RecipeSummary> _parseSummaries(dynamic items) {
    return ((items as List?) ?? [])
        .map((e) => RecipeSummary(
              id: e['id']?.toString() ?? '',
              name: e['name'] ?? '',
              cover: e['cover'] ?? '',
              author: e['author'] ?? '',
              category: e['categoryId'],
            ))
        .toList();
  }
}
