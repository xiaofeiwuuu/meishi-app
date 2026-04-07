import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../models/recipe.dart';

class RecipeService extends ChangeNotifier {
  static const String baseUrl = 'https://cdn.jsdelivr.net/gh/xiaofeiwuuu/recipe@main';

  final Dio _dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  List<RecipeCategory> _categories = [];
  final Map<String, Recipe> _recipeCache = {};
  final Map<String, List<RecipeSummary>> _categoryRecipesCache = {};

  bool _isLoading = false;
  String? _error;

  List<RecipeCategory> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // 清除所有缓存
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
      // 添加时间戳绕过 CDN 缓存
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final url = '/index/categories.json?t=$timestamp';
      debugPrint('请求分类: $url');
      final response = await _dio.get(url);
      debugPrint('响应数据: ${response.data}');
      final data = response.data;
      if (data['categories'] != null) {
        _categories = (data['categories'] as List)
            .map((e) => RecipeCategory.fromJson(e))
            .toList();
      }
      debugPrint('>>> 加载分类成功: ${_categories.length} 个');
      for (var c in _categories) {
        debugPrint('  - ${c.id}: ${c.name}');
      }
    } catch (e) {
      _error = '加载分类失败: $e';
      debugPrint('>>> 加载分类失败: $e');
      // 使用测试数据
      _categories = [
        RecipeCategory(id: 'recai', name: '热菜', total: 5),
      ];
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<Recipe?> getRecipe(String id) async {
    if (_recipeCache.containsKey(id)) {
      return _recipeCache[id];
    }

    try {
      final response = await _dio.get('/recipes/$id.json');
      final recipe = Recipe.fromJson(response.data);
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
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final response = await _dio.get('/pages/$categoryId/$page.json?t=$timestamp');
      final data = response.data;
      final recipes = (data['items'] as List?)
              ?.map((e) => RecipeSummary.fromJson(e))
              .toList() ??
          [];
      _categoryRecipesCache[cacheKey] = recipes;
      return recipes;
    } catch (e) {
      debugPrint('加载菜谱列表失败: $e');
      return [];
    }
  }

  Future<List<RecipeSummary>> getPopularRecipes({int limit = 4}) async {
    // 从第一个分类获取热门菜谱
    if (_categories.isEmpty) {
      await loadCategories();
    }
    if (_categories.isNotEmpty) {
      final recipes = await getRecipesByCategory(_categories.first.id);
      return recipes.take(limit).toList();
    }
    return [];
  }

  Future<List<RecipeSummary>> getRandomRecipes({int limit = 4}) async {
    // 从所有分类中随机获取菜谱
    if (_categories.isEmpty) {
      await loadCategories();
    }
    if (_categories.isEmpty) return [];

    final allRecipes = <RecipeSummary>[];

    // 从每个分类获取菜谱
    for (final cat in _categories) {
      final recipes = await getRecipesByCategory(cat.id);
      allRecipes.addAll(recipes);
    }

    if (allRecipes.isEmpty) return [];

    // 随机打乱并取前 limit 个
    allRecipes.shuffle();
    return allRecipes.take(limit).toList();
  }

  List<String> getAllIngredients() {
    final Set<String> ingredients = {};
    for (final recipe in _recipeCache.values) {
      for (final ing in recipe.ingredients.all) {
        if (ing.name.isNotEmpty) {
          ingredients.add(ing.name);
        }
      }
    }
    return ingredients.toList()..sort();
  }

  List<Recipe> findRecipesByIngredients(List<String> ingredients) {
    if (ingredients.isEmpty) return [];

    final results = <MapEntry<Recipe, int>>[];

    for (final recipe in _recipeCache.values) {
      final recipeIngredients =
          recipe.ingredients.all.map((e) => e.name).toSet();
      final matchCount =
          ingredients.where((i) => recipeIngredients.contains(i)).length;
      if (matchCount > 0) {
        results.add(MapEntry(recipe, matchCount));
      }
    }

    results.sort((a, b) => b.value.compareTo(a.value));
    return results.map((e) => e.key).toList();
  }
}
