import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import '../theme/colors.dart';
import '../stores/favorite_store.dart';
import '../stores/menu_store.dart';
import '../widgets/background_decorations.dart';
import 'recipe_detail_page.dart';

class RecipeSummaryItem {
  final String id;
  final String name;
  final String cover;
  final String cat;
  final String catName;

  RecipeSummaryItem({
    required this.id,
    required this.name,
    required this.cover,
    required this.cat,
    required this.catName,
  });

  factory RecipeSummaryItem.fromJson(Map<String, dynamic> json) {
    return RecipeSummaryItem(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      cover: json['cover'] ?? '',
      cat: json['cat'] ?? '',
      catName: json['catName'] ?? '',
    );
  }
}

class SavedPage extends StatefulWidget {
  const SavedPage({super.key});

  @override
  State<SavedPage> createState() => _SavedPageState();
}

class _SavedPageState extends State<SavedPage> {
  static const String _baseUrl = 'https://cdn.jsdelivr.net/gh/xiaofeiwuuu/recipe@main';
  static const String _rawUrl = 'https://raw.githubusercontent.com/xiaofeiwuuu/recipe/main';

  Map<String, RecipeSummaryItem> _recipeMap = {};
  bool _isLoading = true;
  String _selectedCategory = '';

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
    _loadRecipeSummaries();
  }

  void _handleMenuAction(BuildContext context, String action, FavoriteStore favoriteStore) {
    switch (action) {
      case 'export':
        _exportFavorites(context, favoriteStore);
        break;
      case 'import':
        _showImportDialog(context, favoriteStore);
        break;
    }
  }

  void _exportFavorites(BuildContext context, FavoriteStore favoriteStore) {
    final data = favoriteStore.exportData();
    Clipboard.setData(ClipboardData(text: data));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('已复制到剪贴板'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showImportDialog(BuildContext context, FavoriteStore favoriteStore) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('导入收藏'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '粘贴导出的收藏数据：',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: '粘贴数据...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () async {
                final data = await Clipboard.getData(Clipboard.kTextPlain);
                if (data?.text != null) {
                  controller.text = data!.text!;
                }
              },
              child: const Text('从剪贴板粘贴'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isEmpty) return;
              try {
                final count = await favoriteStore.importData(controller.text);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('成功导入 $count 个收藏'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('导入失败，请检查数据格式'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('导入'),
          ),
        ],
      ),
    );
  }

  Future<void> _loadRecipeSummaries() async {
    try {
      final dio = Dio();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final response = await dio.get('$_rawUrl/recipe-summaries.json?t=$timestamp');

      final data = response.data is String
          ? json.decode(response.data)
          : response.data;

      final map = <String, RecipeSummaryItem>{};
      for (final item in data['recipes']) {
        final recipe = RecipeSummaryItem.fromJson(item);
        map[recipe.id] = recipe;
      }

      if (mounted) {
        setState(() {
          _recipeMap = map;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Failed to load recipe summaries: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final favoriteStore = context.watch<FavoriteStore>();
    final menuStore = context.watch<MenuStore>();
    final favoriteIds = favoriteStore.favoriteIds.toList();

    // 获取收藏的菜谱信息
    final favoriteRecipes = <RecipeSummaryItem>[];
    final categoryCount = <String, int>{};

    for (final id in favoriteIds) {
      final recipe = _recipeMap[id];
      if (recipe != null) {
        favoriteRecipes.add(recipe);
        if (recipe.cat.isNotEmpty) {
          categoryCount[recipe.cat] = (categoryCount[recipe.cat] ?? 0) + 1;
        }
      }
    }

    // 筛选
    final filteredRecipes = _selectedCategory.isEmpty
        ? favoriteRecipes
        : favoriteRecipes.where((r) => r.cat == _selectedCategory).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: BackgroundDecorations(
        variant: 5,
        hasTabBar: true,
        child: SafeArea(
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '收藏',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (favoriteIds.isNotEmpty)
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
                      onSelected: (value) => _handleMenuAction(context, value, favoriteStore),
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'export',
                          child: Row(
                            children: [
                              Icon(Icons.upload, size: 20),
                              SizedBox(width: 12),
                              Text('导出收藏'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'import',
                          child: Row(
                            children: [
                              Icon(Icons.download, size: 20),
                              SizedBox(width: 12),
                              Text('导入收藏'),
                            ],
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),

            // 分类筛选
            if (categoryCount.isNotEmpty && favoriteRecipes.isNotEmpty)
              Container(
                height: 44,
                margin: const EdgeInsets.only(bottom: 8),
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    // 全部
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedCategory = ''),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: _selectedCategory.isEmpty
                                ? AppColors.primary
                                : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            '全部(${favoriteRecipes.length})',
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
                    ...categoryCount.entries.map((entry) {
                      final isSelected = _selectedCategory == entry.key;
                      final catName = _categoryNames[entry.key] ?? entry.key;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedCategory = entry.key),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary
                                  : Colors.white,
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

            // Content
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    )
                  : favoriteIds.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.favorite_border,
                                size: 64,
                                color: Colors.grey[300],
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                '还没有收藏菜谱',
                                style: TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                '点击菜谱详情页的 ❤️ 收藏喜欢的菜谱',
                                style: TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        )
                      : filteredRecipes.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.filter_list_off,
                                    size: 48,
                                    color: Colors.grey[300],
                                  ),
                                  const SizedBox(height: 12),
                                  const Text(
                                    '该分类下没有收藏',
                                    style: TextStyle(color: AppColors.textMuted),
                                  ),
                                ],
                              ),
                            )
                          : LayoutBuilder(
                              builder: (context, constraints) {
                                // 根据宽度决定列数
                                final width = constraints.maxWidth;
                                final columns = width > 900 ? 3 : (width > 600 ? 2 : 1);

                                if (columns == 1) {
                                  // 手机：单列列表
                                  return ListView.builder(
                                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                                    itemCount: filteredRecipes.length,
                                    itemBuilder: (context, index) {
                                      final recipe = filteredRecipes[index];
                                      return _SavedRecipeCard(
                                        recipe: recipe,
                                        baseUrl: _baseUrl,
                                        menuStore: menuStore,
                                        favoriteStore: favoriteStore,
                                      );
                                    },
                                  );
                                }

                                // 平板：多列网格
                                return GridView.builder(
                                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: columns,
                                    crossAxisSpacing: 12,
                                    mainAxisSpacing: 12,
                                    childAspectRatio: 2.8, // 横向卡片比例
                                  ),
                                  itemCount: filteredRecipes.length,
                                  itemBuilder: (context, index) {
                                    final recipe = filteredRecipes[index];
                                    return _SavedRecipeCard(
                                      recipe: recipe,
                                      baseUrl: _baseUrl,
                                      menuStore: menuStore,
                                      favoriteStore: favoriteStore,
                                    );
                                  },
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

class _SavedRecipeCard extends StatelessWidget {
  final RecipeSummaryItem recipe;
  final String baseUrl;
  final MenuStore menuStore;
  final FavoriteStore favoriteStore;

  const _SavedRecipeCard({
    required this.recipe,
    required this.baseUrl,
    required this.menuStore,
    required this.favoriteStore,
  });

  @override
  Widget build(BuildContext context) {
    final coverUrl = recipe.cover.isNotEmpty ? '$baseUrl/${recipe.cover}' : '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RecipeDetailPage(recipeId: recipe.id),
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
              ),
            ],
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 70,
                  height: 70,
                  child: coverUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: coverUrl,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(color: Colors.grey[200]),
                          errorWidget: (_, __, ___) => Container(
                            color: Colors.grey[200],
                            child: const Icon(Icons.restaurant),
                          ),
                        )
                      : Container(
                          color: Colors.grey[200],
                          child: const Icon(Icons.restaurant),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipe.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (recipe.catName.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primarySoft,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          recipe.catName,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () => menuStore.toggle(recipe.id),
                    icon: Icon(
                      menuStore.isInMenu(recipe.id)
                          ? Icons.check_circle
                          : Icons.add_circle_outline,
                      color: AppColors.primary,
                    ),
                  ),
                  IconButton(
                    onPressed: () => favoriteStore.toggle(recipe.id),
                    icon: const Icon(
                      Icons.favorite,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
