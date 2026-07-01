import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config.dart';
import '../theme/colors.dart';
import '../widgets/food_card.dart';
import '../stores/menu_store.dart';
import '../services/api_client.dart';
import 'recipe_detail_page.dart';
import '../utils/responsive.dart';

class RecipeSummary {
  final String id;
  final String name;
  final String cover;
  final String cat;
  final int haveCount; // 你已有的主料数
  final int needCount; // 这道菜共需的主料数
  final List<String> missing; // 缺的料

  RecipeSummary({
    required this.id,
    required this.name,
    required this.cover,
    required this.cat,
    this.haveCount = 0,
    this.needCount = 0,
    this.missing = const [],
  });
}

class FridgeResultPage extends StatefulWidget {
  final List<String> ingredients;

  const FridgeResultPage({super.key, required this.ingredients});

  @override
  State<FridgeResultPage> createState() => _FridgeResultPageState();
}

class _FridgeResultPageState extends State<FridgeResultPage> {
  bool _isLoading = true;
  String? _error;
  List<RecipeSummary> _allResults = []; // 所有匹配结果
  List<RecipeSummary> _filteredResults = []; // 筛选后的结果
  bool _onlyComplete = false; // 只看能做全的
  String _selectedCategory = ''; // 空字符串表示全部

  // 可用的分类（从结果中提取）
  List<MapEntry<String, String>> _availableCategories = [];

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

  // 服务端按食材反查(替代前端下载大索引)
  Future<void> _loadAndSearch() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await ApiClient.instance.post('/app/fridge/match', data: {
        'ingredients': widget.ingredients,
        'onlyComplete': _onlyComplete,
        'pageSize': 50,
      });
      final items = (data['items'] as List?) ?? [];
      final results = items
          .map((e) => RecipeSummary(
                id: e['id']?.toString() ?? '',
                name: e['name'] ?? '',
                cover: e['cover'] ?? '',
                cat: e['categoryId'] ?? '',
                haveCount: (e['haveCount'] ?? 0) as int,
                needCount: (e['needCount'] ?? 0) as int,
                missing: ((e['missing'] as List?) ?? []).map((x) => x.toString()).toList(),
              ))
          .toList();

      // 结果分类统计
      final categoryCount = <String, int>{};
      for (final r in results) {
        if (r.cat.isNotEmpty) {
          categoryCount[r.cat] = (categoryCount[r.cat] ?? 0) + 1;
        }
      }
      const categoryNames = {
        'recai': '热菜',
        'liangcai': '凉菜',
        'tanggeng': '汤羹',
        'zhushi': '主食',
        'xiaochi': '小吃',
        'jiachang': '家常菜',
        'jiangpaoyancai': '泡酱腌菜',
      };
      final categories = <MapEntry<String, String>>[];
      categoryCount.forEach((cat, count) {
        categories.add(MapEntry(cat, '${categoryNames[cat] ?? cat}($count)'));
      });
      categories.sort((a, b) =>
          (categoryCount[b.key] ?? 0).compareTo(categoryCount[a.key] ?? 0));

      if (mounted) {
        setState(() {
          _allResults = results;
          _availableCategories = categories;
          _isLoading = false;
        });
        _applyFilter();
      }
    } catch (e) {
      debugPrint('Failed to match: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = '加载失败，请检查网络';
        });
      }
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

  void _toggleOnlyComplete() {
    setState(() {
      _onlyComplete = !_onlyComplete;
      _selectedCategory = '';
    });
    _loadAndSearch(); // 切换筛选需重新向服务端查询
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
                      onTap: _toggleOnlyComplete,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _onlyComplete ? AppColors.primary : AppColors.background,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _onlyComplete ? Icons.check_circle : Icons.check_circle_outline,
                              size: 13,
                              color: _onlyComplete ? Colors.white : AppColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '只看能做全的',
                              style: TextStyle(
                                fontSize: 12,
                                color: _onlyComplete ? Colors.white : AppColors.textSecondary,
                              ),
                            ),
                          ],
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
                                Text(
                                  _onlyComplete ? '没有能完全做出的菜谱' : '没有找到匹配的菜谱',
                                  style: const TextStyle(color: AppColors.textMuted),
                                ),
                                if (_onlyComplete) ...[
                                  const SizedBox(height: 8),
                                  GestureDetector(
                                    onTap: _toggleOnlyComplete,
                                    child: const Text(
                                      '看看「还差几样」的菜谱',
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
                              final complete = recipe.missing.isEmpty;
                              final label = complete
                                  ? '食材齐 ✓'
                                  : (recipe.missing.length <= 2
                                      ? '缺:${recipe.missing.join("、")}'
                                      : '还差${recipe.missing.length}样');
                              return Stack(
                                children: [
                                  FoodCard(
                                    id: recipe.id,
                                    imageUrl: AppConfig.coverUrl(recipe.cover),
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
                                  ),
                                  Positioned(
                                    top: 8,
                                    left: 8,
                                    child: ConstrainedBox(
                                      constraints: const BoxConstraints(maxWidth: 150),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: complete
                                              ? const Color(0xFF66BB6A)
                                              : const Color(0xFFFF9800),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          label,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
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
