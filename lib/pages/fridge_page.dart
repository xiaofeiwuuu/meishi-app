import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../theme/colors.dart';
import 'fridge_result_page.dart';

class IngredientCategory {
  final String name;
  final List<String> items;

  IngredientCategory({required this.name, required this.items});

  factory IngredientCategory.fromJson(Map<String, dynamic> json) {
    return IngredientCategory(
      name: json['name'],
      items: List<String>.from(json['items']),
    );
  }
}

class FridgePage extends StatefulWidget {
  const FridgePage({super.key});

  @override
  State<FridgePage> createState() => _FridgePageState();
}

class _FridgePageState extends State<FridgePage> {
  static const String _baseUrl = 'https://cdn.jsdelivr.net/gh/xiaofeiwuuu/recipe@main';

  final TextEditingController _controller = TextEditingController();
  final List<String> _selectedIngredients = [];
  List<IngredientCategory> _categories = [];
  List<String> _allIngredients = []; // 所有可搜索的食材
  bool _isLoading = true;
  String? _error;

  // 分类图标映射
  IconData _getCategoryIcon(String name) {
    switch (name) {
      case '蔬菜':
        return Icons.eco;
      case '菌菇':
        return Icons.grass;
      case '肉类':
        return Icons.restaurant;
      case '水产':
        return Icons.set_meal;
      case '蛋奶豆':
        return Icons.egg;
      case '调味料':
        return Icons.opacity;
      case '主食':
        return Icons.rice_bowl;
      case '干货':
        return Icons.inventory_2;
      default:
        return Icons.category;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadIngredients();
  }

  Future<void> _loadIngredients() async {
    try {
      final dio = Dio();
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      // 并行加载预设分类和完整食材索引
      final responses = await Future.wait([
        dio.get('$_baseUrl/ingredients.json?t=$timestamp'),
        dio.get('$_baseUrl/ingredient-index.json?t=$timestamp'),
      ]);

      // 解析预设分类
      final catData = responses[0].data is String
          ? json.decode(responses[0].data)
          : responses[0].data;
      final categories = (catData['categories'] as List)
          .map((c) => IngredientCategory.fromJson(c))
          .toList();

      // 解析完整食材列表（从索引中提取所有食材名）
      final indexData = responses[1].data is String
          ? json.decode(responses[1].data)
          : responses[1].data;
      final allIngredients = (indexData['index'] as Map<String, dynamic>)
          .keys
          .toList();

      if (mounted) {
        setState(() {
          _categories = categories;
          _allIngredients = allIngredients;
          _isLoading = false;
          _error = null;
        });
      }
    } catch (e) {
      debugPrint('Failed to load ingredients: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = '加载失败，请检查网络';
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleIngredient(String name) {
    setState(() {
      if (_selectedIngredients.contains(name)) {
        _selectedIngredients.remove(name);
      } else {
        _selectedIngredients.add(name);
      }
      _controller.clear();
    });
  }

  // 搜索过滤 - 从所有食材中搜索
  List<String> _getFilteredIngredients() {
    final query = _controller.text.trim().toLowerCase();
    if (query.isEmpty) return [];

    final results = <String>[];
    for (final item in _allIngredients) {
      if (item.toLowerCase().contains(query) &&
          !_selectedIngredients.contains(item)) {
        results.add(item);
      }
    }
    return results.take(30).toList(); // 增加到30个结果
  }

  @override
  Widget build(BuildContext context) {
    final filteredIngredients = _getFilteredIngredients();
    final showSearchResults = _controller.text.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: _selectedIngredients.isNotEmpty
          ? SafeArea(
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FridgeResultPage(
                          ingredients: List.from(_selectedIngredients),
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    '搜索 ${_selectedIngredients.length} 种食材的菜谱',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            )
          : null,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              color: Colors.white,
              child: Column(
                children: [
                  // Nav Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const Expanded(
                          child: Text(
                            '冰箱找菜',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 48),
                      ],
                    ),
                  ),

                  // Search Box
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.search, color: AppColors.textMuted, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _controller,
                              decoration: const InputDecoration(
                                hintText: '搜索食材...',
                                hintStyle: TextStyle(color: AppColors.textMuted),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                              style: const TextStyle(fontSize: 15),
                              onChanged: (value) {
                                setState(() {});
                              },
                            ),
                          ),
                          if (_controller.text.isNotEmpty)
                            GestureDetector(
                              onTap: () {
                                _controller.clear();
                                setState(() {});
                              },
                              child: const Icon(Icons.clear,
                                  color: AppColors.textMuted, size: 18),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Selected Ingredients Bar
            if (_selectedIngredients.isNotEmpty)
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '已选食材 (${_selectedIngredients.length})',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => setState(() => _selectedIngredients.clear()),
                          child: const Text(
                            '清空',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _selectedIngredients.map((name) {
                        return GestureDetector(
                          onTap: () => _toggleIngredient(name),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF0EB),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.close,
                                    size: 14, color: AppColors.primary),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

            // Content
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.primary))
                  : showSearchResults
                      ? _buildSearchResults(filteredIngredients)
                      : _buildCategoryList(),
            ),
          ],
        ),
      ),
    );
  }

  // 搜索结果
  Widget _buildSearchResults(List<String> results) {
    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text(
              '未找到 "${_controller.text}" 相关食材',
              style: const TextStyle(color: AppColors.textMuted),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: results.map((name) {
            return GestureDetector(
              onTap: () => _toggleIngredient(name),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // 分类列表
  Widget _buildCategoryList() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _categories.length,
      itemBuilder: (context, index) {
        final category = _categories[index];
        return _buildCategorySection(category);
      },
    );
  }

  // 分类区块
  Widget _buildCategorySection(IngredientCategory category) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 分类标题
          Row(
            children: [
              Icon(
                _getCategoryIcon(category.name),
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                category.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 食材列表
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: category.items.map((name) {
              final isSelected = _selectedIngredients.contains(name);
              return GestureDetector(
                onTap: () => _toggleIngredient(name),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFFFF0EB) : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: isSelected
                        ? Border.all(color: AppColors.primary.withValues(alpha: 0.3))
                        : null,
                    boxShadow: isSelected
                        ? null
                        : [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 4,
                            ),
                          ],
                  ),
                  child: Text(
                    name,
                    style: TextStyle(
                      fontSize: 13,
                      color: isSelected ? AppColors.primary : AppColors.textPrimary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
