import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:provider/provider.dart';
import '../theme/colors.dart';
import '../widgets/food_card.dart';
import '../stores/menu_store.dart';
import '../utils/responsive.dart';
import 'recipe_detail_page.dart';

class RecipeSearchItem {
  final String id;
  final String name;
  final String cover;
  final String cat;
  final String catName;

  RecipeSearchItem({
    required this.id,
    required this.name,
    required this.cover,
    required this.cat,
    required this.catName,
  });

  factory RecipeSearchItem.fromJson(Map<String, dynamic> json) {
    return RecipeSearchItem(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      cover: json['cover'] ?? '',
      cat: json['cat'] ?? '',
      catName: json['catName'] ?? '',
    );
  }
}

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  static const String _baseUrl = 'https://cdn.jsdelivr.net/gh/xiaofeiwuuu/recipe@main';
  static const String _rawUrl = 'https://raw.githubusercontent.com/xiaofeiwuuu/recipe/main';

  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  List<RecipeSearchItem> _allRecipes = [];
  List<RecipeSearchItem> _searchResults = [];
  List<RecipeSearchItem> _filteredResults = [];
  bool _isLoadingData = true;
  bool _isSearching = false;
  bool _showBackToTop = false;
  String? _error;
  String _selectedCategory = ''; // 空字符串表示全部

  // 分类统计
  Map<String, int> _categoryCount = {};

  static const Map<String, String> _categoryNames = {
    'recai': '热菜',
    'liangcai': '凉菜',
    'tanggeng': '汤羹',
    'zhushi': '主食',
    'xiaochi': '小吃',
  };

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
    _loadRecipeData();
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
    _controller.dispose();
    _focusNode.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadRecipeData() async {
    try {
      final dio = Dio();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final response = await dio.get('$_rawUrl/recipe-summaries.json?t=$timestamp');

      final data = response.data is String
          ? json.decode(response.data)
          : response.data;

      final recipes = <RecipeSearchItem>[];
      for (final item in data['recipes']) {
        recipes.add(RecipeSearchItem.fromJson(item));
      }

      if (mounted) {
        setState(() {
          _allRecipes = recipes;
          _isLoadingData = false;
        });
      }
    } catch (e) {
      debugPrint('Failed to load recipe data: $e');
      if (mounted) {
        setState(() {
          _isLoadingData = false;
          _error = '加载失败，请检查网络';
        });
      }
    }
  }

  void _performSearch(String query) {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _filteredResults = [];
        _categoryCount = {};
        _selectedCategory = '';
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    final lowerQuery = query.toLowerCase().trim();
    final results = <RecipeSearchItem>[];
    final catCount = <String, int>{};

    for (final recipe in _allRecipes) {
      if (recipe.name.toLowerCase().contains(lowerQuery)) {
        results.add(recipe);
        if (recipe.cat.isNotEmpty) {
          catCount[recipe.cat] = (catCount[recipe.cat] ?? 0) + 1;
        }
      }
    }

    setState(() {
      _searchResults = results;
      _categoryCount = catCount;
      _selectedCategory = '';
      _isSearching = false;
    });

    _applyFilter();
  }

  void _applyFilter() {
    setState(() {
      if (_selectedCategory.isEmpty) {
        _filteredResults = _searchResults;
      } else {
        _filteredResults = _searchResults
            .where((r) => r.cat == _selectedCategory)
            .toList();
      }
    });
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
        title: TextField(
          controller: _controller,
          focusNode: _focusNode,
          decoration: const InputDecoration(
            hintText: '搜索菜谱...',
            hintStyle: TextStyle(color: AppColors.textMuted),
            border: InputBorder.none,
          ),
          style: const TextStyle(
            fontSize: 16,
            color: AppColors.textPrimary,
          ),
          onChanged: (value) {
            _performSearch(value);
          },
          onSubmitted: (value) {
            _performSearch(value);
          },
        ),
        actions: [
          if (_controller.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear, color: AppColors.textMuted),
              onPressed: () {
                _controller.clear();
                _performSearch('');
              },
            ),
        ],
      ),
      body: _buildBody(menuStore),
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

  Widget _buildBody(MenuStore menuStore) {
    // 加载中
    if (_isLoadingData) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    // 加载错误
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: AppColors.textMuted)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isLoadingData = true;
                  _error = null;
                });
                _loadRecipeData();
              },
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    // 未输入搜索词
    if (_controller.text.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 64,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            const Text(
              '输入关键词搜索菜谱',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '共 ${_allRecipes.length} 个菜谱',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    // 搜索中
    if (_isSearching) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    // 无结果
    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              '没有找到 "${_controller.text}" 相关的菜谱',
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    // 搜索结果
    return Column(
      children: [
        // 结果数量
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              Text(
                '找到 ${_filteredResults.length} 个菜谱',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
        // 分类筛选
        if (_categoryCount.isNotEmpty)
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
                        '全部(${_searchResults.length})',
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
                ..._categoryCount.entries.map((entry) {
                  final isSelected = _selectedCategory == entry.key;
                  final catName = _categoryNames[entry.key] ?? entry.key;
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
                          '$catName(${entry.value})',
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
          child: GridView.builder(
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
    );
  }
}
