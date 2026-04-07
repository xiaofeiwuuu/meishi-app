import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:provider/provider.dart';
import '../theme/colors.dart';
import '../widgets/food_card.dart';
import '../stores/menu_store.dart';
import 'recipe_detail_page.dart';
import '../utils/responsive.dart';

class RecipeSummary {
  final String id;
  final String name;
  final String cover;
  final String cat;
  final String catName;

  RecipeSummary({
    required this.id,
    required this.name,
    required this.cover,
    required this.cat,
    required this.catName,
  });

  factory RecipeSummary.fromJson(Map<String, dynamic> json) {
    return RecipeSummary(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      cover: json['cover'] ?? '',
      cat: json['cat'] ?? '',
      catName: json['catName'] ?? '',
    );
  }
}

class FridgeResultPage extends StatefulWidget {
  final List<String> ingredients;

  const FridgeResultPage({super.key, required this.ingredients});

  @override
  State<FridgeResultPage> createState() => _FridgeResultPageState();
}

class _FridgeResultPageState extends State<FridgeResultPage> {
  static const String _baseUrl = 'https://cdn.jsdelivr.net/gh/xiaofeiwuuu/recipe@main';

  bool _isLoading = true;
  String? _error;
  List<RecipeSummary> _allResults = []; // 所有匹配结果
  List<RecipeSummary> _filteredResults = []; // 筛选后的结果
  bool _matchAll = false;
  String _selectedCategory = ''; // 空字符串表示全部

  // 可用的分类（从结果中提取）
  List<MapEntry<String, String>> _availableCategories = [];

  // 缓存
  static Map<String, List<String>>? _ingredientIndex;
  static Map<String, RecipeSummary>? _recipeSummaries;

  // 滚动控制
  final ScrollController _scrollController = ScrollController();
  bool _showBackToTop = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadAndSearch();
  }

  void _onScroll() {
    final show = _scrollController.offset > 300;
    if (show != _showBackToTop) {
      setState(() => _showBackToTop = show);
    }
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadAndSearch() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final dio = Dio();
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      // 加载索引（如果未缓存）
      if (_ingredientIndex == null) {
        final indexResponse = await dio.get('$_baseUrl/ingredient-index.json?t=$timestamp');
        final indexData = indexResponse.data is String
            ? json.decode(indexResponse.data)
            : indexResponse.data;
        _ingredientIndex = {};
        (indexData['index'] as Map<String, dynamic>).forEach((key, value) {
          _ingredientIndex![key] = List<String>.from(value);
        });
      }

      // 加载摘要（如果未缓存）
      if (_recipeSummaries == null) {
        final summaryResponse = await dio.get('$_baseUrl/recipe-summaries.json?t=$timestamp');
        final summaryData = summaryResponse.data is String
            ? json.decode(summaryResponse.data)
            : summaryResponse.data;
        _recipeSummaries = {};
        for (final item in summaryData['recipes']) {
          final summary = RecipeSummary.fromJson(item);
          _recipeSummaries![summary.id] = summary;
        }
      }

      _performSearch();
    } catch (e) {
      debugPrint('Failed to load index: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = '加载失败，请检查网络';
        });
      }
    }
  }

  void _performSearch() {
    if (_ingredientIndex == null || _recipeSummaries == null) return;

    final matchedIds = <String, int>{};

    for (final ingredient in widget.ingredients) {
      final recipeIds = _ingredientIndex![ingredient] ?? [];
      for (final id in recipeIds) {
        matchedIds[id] = (matchedIds[id] ?? 0) + 1;
      }
    }

    List<String> resultIds;
    if (_matchAll) {
      resultIds = matchedIds.entries
          .where((e) => e.value == widget.ingredients.length)
          .map((e) => e.key)
          .toList();
    } else {
      final entries = matchedIds.entries.toList();
      entries.sort((a, b) => b.value.compareTo(a.value));
      resultIds = entries.map((e) => e.key).toList();
    }

    final results = <RecipeSummary>[];
    final categoryCount = <String, int>{};

    for (final id in resultIds) {
      final summary = _recipeSummaries![id];
      if (summary != null) {
        results.add(summary);
        if (summary.cat.isNotEmpty) {
          categoryCount[summary.cat] = (categoryCount[summary.cat] ?? 0) + 1;
        }
      }
    }

    // 提取可用分类
    final categories = <MapEntry<String, String>>[];
    final categoryNames = {
      'recai': '热菜',
      'liangcai': '凉菜',
      'tanggeng': '汤羹',
      'zhushi': '主食',
      'xiaochi': '小吃',
    };
    categoryCount.forEach((cat, count) {
      final name = categoryNames[cat] ?? cat;
      categories.add(MapEntry(cat, '$name($count)'));
    });
    // 按数量排序
    categories.sort((a, b) {
      final countA = categoryCount[a.key] ?? 0;
      final countB = categoryCount[b.key] ?? 0;
      return countB.compareTo(countA);
    });

    if (mounted) {
      setState(() {
        _allResults = results;
        _availableCategories = categories;
        _isLoading = false;
      });
      _applyFilter();
    }
  }

  void _applyFilter() {
    setState(() {
      if (_selectedCategory.isEmpty) {
        _filteredResults = _allResults;
      } else {
        _filteredResults = _allResults
            .where((r) => r.cat == _selectedCategory)
            .toList();
      }
    });
  }

  void _toggleMatchMode() {
    setState(() {
      _matchAll = !_matchAll;
      _selectedCategory = '';
    });
    _performSearch();
  }

  void _selectCategory(String cat) {
    setState(() {
      _selectedCategory = cat;
    });
    _applyFilter();
  }

  @override
  Widget build(BuildContext context) {
    final menuStore = context.watch<MenuStore>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '搜索结果',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // 顶部筛选区
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 食材标签
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: widget.ingredients.map((name) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF0EB),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        name,
                        style: const TextStyle(fontSize: 12, color: AppColors.primary),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                // 结果数量 + 匹配模式
                Row(
                  children: [
                    Text(
                      _isLoading
                          ? '搜索中...'
                          : '找到 ${_filteredResults.length} 个菜谱',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: _toggleMatchMode,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _matchAll ? AppColors.primary : AppColors.background,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _matchAll ? '全部匹配' : '任一匹配',
                          style: TextStyle(
                            fontSize: 12,
                            color: _matchAll ? Colors.white : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 分类筛选
          if (_availableCategories.isNotEmpty)
            Container(
              color: Colors.white,
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  // 全部
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                    child: GestureDetector(
                      onTap: () => _selectCategory(''),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: _selectedCategory.isEmpty
                              ? AppColors.primary
                              : AppColors.background,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          '全部(${_allResults.length})',
                          style: TextStyle(
                            fontSize: 13,
                            color: _selectedCategory.isEmpty
                                ? Colors.white
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // 各分类
                  ..._availableCategories.map((entry) {
                    final isSelected = _selectedCategory == entry.key;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                      child: GestureDetector(
                        onTap: () => _selectCategory(entry.key),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.background,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            entry.value,
                            style: TextStyle(
                              fontSize: 13,
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),

          // 结果列表
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline, size: 48, color: Colors.grey[300]),
                            const SizedBox(height: 12),
                            Text(_error!, style: const TextStyle(color: AppColors.textMuted)),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadAndSearch,
                              child: const Text('重试'),
                            ),
                          ],
                        ),
                      )
                    : _filteredResults.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.restaurant_menu, size: 48, color: Colors.grey[300]),
                                const SizedBox(height: 12),
                                const Text(
                                  '没有找到匹配的菜谱',
                                  style: TextStyle(color: AppColors.textMuted),
                                ),
                                if (_matchAll && widget.ingredients.length > 1) ...[
                                  const SizedBox(height: 8),
                                  GestureDetector(
                                    onTap: _toggleMatchMode,
                                    child: const Text(
                                      '试试「任一匹配」模式',
                                      style: TextStyle(color: AppColors.primary),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          )
                        : GridView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(20),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: Responsive.getGridColumns(context),
                              crossAxisSpacing: 14,
                              mainAxisSpacing: 14,
                              childAspectRatio: Responsive.getCardAspectRatio(context),
                            ),
                            itemCount: _filteredResults.length,
                            itemBuilder: (context, index) {
                              final recipe = _filteredResults[index];
                              final coverUrl = recipe.cover.isNotEmpty
                                  ? '$_baseUrl/${recipe.cover}'
                                  : '';
                              return FoodCard(
                                id: recipe.id,
                                imageUrl: coverUrl,
                                title: recipe.name,
                                time: '',
                                isAdded: menuStore.isInMenu(recipe.id),
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => RecipeDetailPage(recipeId: recipe.id),
                                  ),
                                ),
                                onAddTap: () => menuStore.toggle(recipe.id),
                              );
                            },
                          ),
          ),
        ],
      ),
      // 回到顶部按钮
      floatingActionButton: _showBackToTop
          ? FloatingActionButton(
              mini: true,
              backgroundColor: AppColors.primary,
              onPressed: _scrollToTop,
              child: const Icon(Icons.arrow_upward, color: Colors.white),
            )
          : null,
    );
  }
}
