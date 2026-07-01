import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/colors.dart';
import '../widgets/background_decorations.dart';
import '../services/api_client.dart';
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

  // 分类柔和颜色映射
  Color _getCategoryColor(String name) {
    switch (name) {
      case '蔬菜':
        return const Color(0xFFE8F5E9);  // 浅绿
      case '菌菇':
        return const Color(0xFFF5F0E6);  // 浅米
      case '肉类':
        return const Color(0xFFFFEBEE);  // 浅粉红
      case '水产':
        return const Color(0xFFE3F2FD);  // 浅蓝
      case '蛋奶豆':
        return const Color(0xFFFFF8E1);  // 浅黄
      case '调味料':
        return const Color(0xFFFFF3E0);  // 浅橙
      case '主食':
        return const Color(0xFFFCE4EC);  // 浅桃
      case '干货':
        return const Color(0xFFF3E5F5);  // 浅紫
      default:
        return const Color(0xFFFAFAFA);
    }
  }

  // 分类图标颜色
  Color _getCategoryIconColor(String name) {
    switch (name) {
      case '蔬菜':
        return const Color(0xFF66BB6A);  // 绿
      case '菌菇':
        return const Color(0xFFA1887F);  // 棕
      case '肉类':
        return const Color(0xFFEF5350);  // 红
      case '水产':
        return const Color(0xFF42A5F5);  // 蓝
      case '蛋奶豆':
        return const Color(0xFFFFCA28);  // 黄
      case '调味料':
        return const Color(0xFFFF9800);  // 橙
      case '主食':
        return const Color(0xFFEC407A);  // 桃红
      case '干货':
        return const Color(0xFFAB47BC);  // 紫
      default:
        return AppColors.primary;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadIngredients();
    _loadFridge();
  }

  // "我的冰箱":本地记住上次选的食材,下次进来自动带上
  static const _fridgeKey = 'my_fridge';

  Future<void> _loadFridge() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_fridgeKey) ?? [];
    if (saved.isNotEmpty && mounted) {
      setState(() {
        for (final s in saved) {
          if (!_selectedIngredients.contains(s)) _selectedIngredients.add(s);
        }
      });
    }
  }

  Future<void> _saveFridge() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_fridgeKey, _selectedIngredients);
  }

  Future<void> _loadIngredients() async {
    try {
      // /app/ingredients 返回按分类分组的食材 [{category, items}]
      final data = await ApiClient.instance.get('/app/ingredients');
      final categories = (data as List)
          .map((c) => IngredientCategory(
                name: c['category'] ?? '',
                items: List<String>.from(c['items'] ?? []),
              ))
          .toList();
      final allIngredients = categories.expand((c) => c.items).toList();

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
    _saveFridge(); // 记住"我的冰箱"
  }

  // 查找食材所属分类
  String _getCategoryForIngredient(String ingredientName) {
    for (final category in _categories) {
      if (category.items.contains(ingredientName)) {
        return category.name;
      }
    }
    return '';  // 未找到分类（可能是搜索添加的）
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
      body: BackgroundDecorations(
        variant: 2,
        hasTabBar: true,
        child: SafeArea(
          child: Column(
          children: [
            // Header
            Container(
              color: Colors.white,
              child: Column(
                children: [
                  // Nav Bar
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                    child: Text(
                      '冰箱找菜 🐰',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
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
                          onTap: () {
                            setState(() => _selectedIngredients.clear());
                            _saveFridge();
                          },
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
                        final categoryName = _getCategoryForIngredient(name);
                        final bgColor = _getCategoryColor(categoryName);
                        final textColor = _getCategoryIconColor(categoryName);
                        return GestureDetector(
                          onTap: () => _toggleIngredient(name),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: bgColor,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: textColor.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  name,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: textColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(Icons.close,
                                    size: 14, color: textColor),
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
    final categoryColor = _getCategoryColor(category.name);
    final iconColor = _getCategoryIconColor(category.name);

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 分类标题 - 胶囊样式
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: categoryColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getCategoryIcon(category.name),
                  size: 16,
                  color: iconColor,
                ),
                const SizedBox(width: 6),
                Text(
                  category.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: iconColor,
                  ),
                ),
              ],
            ),
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
                    color: isSelected ? categoryColor : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: isSelected
                        ? Border.all(color: iconColor.withValues(alpha: 0.4))
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
                      color: isSelected ? iconColor : AppColors.textPrimary,
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
