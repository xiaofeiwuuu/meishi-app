import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/colors.dart';
import '../widgets/food_card.dart';
import '../services/recipe_service.dart';
import '../stores/menu_store.dart';
import '../models/recipe.dart';
import 'recipe_detail_page.dart';
import '../utils/responsive.dart';
import '../widgets/background_decorations.dart';

class CategoryRecipesPage extends StatefulWidget {
  final String categoryId;
  final String categoryName;

  const CategoryRecipesPage({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  State<CategoryRecipesPage> createState() => _CategoryRecipesPageState();
}

class _CategoryRecipesPageState extends State<CategoryRecipesPage> {
  List<RecipeSummary> _recipes = [];
  bool _isLoading = true;
  int _currentPage = 1;
  bool _hasMore = true;
  bool _showBackToTop = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadRecipes());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // 显示/隐藏回到顶部按钮
    final showButton = _scrollController.position.pixels > 500;
    if (showButton != _showBackToTop) {
      setState(() => _showBackToTop = showButton);
    }

    // 加载更多
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  Future<void> _loadRecipes() async {
    setState(() => _isLoading = true);

    final service = context.read<RecipeService>();
    final recipes = await service.getRecipesByCategory(
      widget.categoryId,
      page: 1,
      forceRefresh: true,
    );

    if (mounted) {
      setState(() {
        _recipes = recipes;
        _isLoading = false;
        _currentPage = 1;
        _hasMore = recipes.length >= 20;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_isLoading || !_hasMore) return;

    final service = context.read<RecipeService>();
    final nextPage = _currentPage + 1;
    final recipes = await service.getRecipesByCategory(
      widget.categoryId,
      page: nextPage,
    );

    if (mounted && recipes.isNotEmpty) {
      setState(() {
        _recipes.addAll(recipes);
        _currentPage = nextPage;
        _hasMore = recipes.length >= 20;
      });
    } else {
      _hasMore = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final menuStore = context.watch<MenuStore>();

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: _showBackToTop
          ? FloatingActionButton(
              mini: true,
              backgroundColor: AppColors.primary,
              onPressed: _scrollToTop,
              child: const Icon(Icons.arrow_upward, color: Colors.white),
            )
          : null,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.categoryName,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: BackgroundDecorations(
        variant: 3,
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
          : _recipes.isEmpty
              ? const Center(
                  child: Text(
                    '暂无菜谱',
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadRecipes,
                  color: AppColors.primary,
                  child: GridView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(20),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: Responsive.getGridColumns(context),
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      childAspectRatio: Responsive.getCardAspectRatio(context),
                    ),
                    itemCount: _recipes.length + (_hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _recipes.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(
                              color: AppColors.primary,
                              strokeWidth: 2,
                            ),
                          ),
                        );
                      }

                      final recipe = _recipes[index];
                      return FoodCard(
                        id: recipe.id,
                        imageUrl: recipe.coverUrl,
                        title: recipe.name,
                        time: '15分钟',
                        isAdded: menuStore.isInMenu(recipe.id),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                RecipeDetailPage(recipeId: recipe.id),
                          ),
                        ),
                        onAddTap: () => menuStore.toggle(recipe.id),
                      );
                    },
                  ),
                ),
      ),
    );
  }
}
