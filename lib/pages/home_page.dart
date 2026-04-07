import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/colors.dart';
import '../widgets/food_card.dart';
import '../widgets/category_icon.dart';
import '../services/recipe_service.dart';
import '../stores/menu_store.dart';
import '../models/recipe.dart';
import 'recipe_detail_page.dart';
import 'search_page.dart';
import 'categories_page.dart';
import 'category_recipes_page.dart';
import '../utils/responsive.dart';
import '../widgets/background_decorations.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<RecipeSummary> _popularRecipes = [];
  bool _isLoading = true;
  int _lastLoadedCount = 0;  // 记录上次加载的数量

  @override
  void initState() {
    super.initState();
    // 延迟到下一帧执行，避免在build期间调用notifyListeners
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData({int? count}) async {
    final service = context.read<RecipeService>();
    // 强制刷新获取最新数据
    await service.loadCategories(forceRefresh: true);
    final limit = count ?? Responsive.getItemCount(context);
    final recipes = await service.getRandomRecipes(limit: limit);
    if (mounted) {
      setState(() {
        _popularRecipes = recipes;
        _isLoading = false;
        _lastLoadedCount = limit;
      });
    }
  }

  Future<void> _shuffleRecipes() async {
    setState(() => _isLoading = true);
    final service = context.read<RecipeService>();
    final limit = Responsive.getItemCount(context);
    final recipes = await service.getRandomRecipes(limit: limit);
    if (mounted) {
      setState(() {
        _popularRecipes = recipes;
        _isLoading = false;
        _lastLoadedCount = limit;
      });
    }
  }

  void _checkAndReloadIfNeeded() {
    final needed = Responsive.getItemCount(context);
    // 如果需要的数量比已加载的多，重新加载
    if (needed > _lastLoadedCount && !_isLoading) {
      _loadData(count: needed);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 检查是否需要根据屏幕尺寸重新加载数据
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkAndReloadIfNeeded());

    final service = context.watch<RecipeService>();
    final menuStore = context.watch<MenuStore>();
    final categories = service.categories.take(4).toList();
    final itemCount = Responsive.getItemCount(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: BackgroundDecorations(
        variant: 1,
        hasTabBar: true,
        child: SafeArea(
          child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      '今天吃什么呀～ 🐱',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "一起来发现好吃的吧！🌸",
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),

              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SearchPage()),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                      children: const [
                        Icon(Icons.search, color: AppColors.textMuted, size: 20),
                        SizedBox(width: 10),
                        Text(
                          '搜索菜谱...',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Categories Section
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Categories',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CategoriesPage()),
                      ),
                      child: const Text(
                        'See all',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Category Icons - 使用自定义动物图标
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: categories.map((cat) {
                    return CategoryIcon(
                      emoji: CategoryConfig.getEmoji(cat.id),
                      label: cat.name,
                      bgColor: CategoryConfig.getBgColor(cat.id),
                      animalType: CategoryConfig.getAnimalType(cat.id),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CategoryRecipesPage(
                            categoryId: cat.id,
                            categoryName: cat.name,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              // Popular Section
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Popular',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    GestureDetector(
                      onTap: _shuffleRecipes,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.shuffle, size: 16, color: AppColors.primary),
                          SizedBox(width: 4),
                          Text(
                            'Shuffle',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Food Grid
              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: Responsive.getGridColumns(context),
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      childAspectRatio: Responsive.getCardAspectRatio(context),
                    ),
                    itemCount: min(_popularRecipes.length, itemCount),
                    itemBuilder: (context, index) {
                      final recipe = _popularRecipes[index];
                      return FoodCard(
                        id: recipe.id,
                        imageUrl: recipe.coverUrl,
                        title: recipe.name,
                        time: '15分钟',
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
        ),
      ),
      ),
    );
  }
}
