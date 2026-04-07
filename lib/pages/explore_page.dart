import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/colors.dart';
import '../widgets/food_card.dart';
import '../services/recipe_service.dart';
import '../stores/menu_store.dart';
import '../models/recipe.dart';
import 'recipe_detail_page.dart';
import 'search_page.dart';
import '../utils/responsive.dart';

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  String _currentCategory = 'all';
  List<RecipeSummary> _recipes = [];
  bool _isLoading = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadRecipes());
  }

  Future<void> _loadRecipes() async {
    setState(() => _isLoading = true);

    final service = context.read<RecipeService>();
    await service.loadCategories();

    if (_currentCategory == 'all' && service.categories.isNotEmpty) {
      // 加载第一个分类的菜谱
      _recipes = await service.getRecipesByCategory(service.categories.first.id);
    } else if (_currentCategory != 'all') {
      _recipes = await service.getRecipesByCategory(_currentCategory);
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<RecipeService>();
    final menuStore = context.watch<MenuStore>();

    final tabs = [
      {'label': '全部', 'value': 'all'},
      ...service.categories.map((c) => {'label': c.name, 'value': c.id}),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                children: [
                  const Text(
                    '分类',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SearchPage()),
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F0F0),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Row(
                          children: const [
                            Icon(Icons.search, size: 16, color: AppColors.textMuted),
                            SizedBox(width: 8),
                            Text(
                              '搜索菜谱...',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Filter Tabs
            SizedBox(
              height: 44,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: tabs.length,
                itemBuilder: (context, index) {
                  final tab = tabs[index];
                  final isSelected = _currentCategory == tab['value'];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _currentCategory = tab['value']!);
                        _loadRecipes();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? AppColors.primary : const Color(0xFFE0E0E0),
                          ),
                        ),
                        child: Text(
                          tab['label']!,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: isSelected ? Colors.white : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 12),

            // Recipe Grid
            Expanded(
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
                      : GridView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: Responsive.getGridColumns(context),
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 14,
                            childAspectRatio: Responsive.getCardAspectRatio(context),
                          ),
                          itemCount: _recipes.length,
                          itemBuilder: (context, index) {
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
    );
  }
}
