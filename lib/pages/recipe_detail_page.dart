import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/colors.dart';
import '../services/recipe_service.dart';
import '../stores/favorite_store.dart';
import '../stores/menu_store.dart';
import '../models/recipe.dart';

class RecipeDetailPage extends StatefulWidget {
  final String recipeId;

  const RecipeDetailPage({super.key, required this.recipeId});

  @override
  State<RecipeDetailPage> createState() => _RecipeDetailPageState();
}

class _RecipeDetailPageState extends State<RecipeDetailPage> {
  Recipe? _recipe;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecipe();
  }

  Future<void> _loadRecipe() async {
    final service = context.read<RecipeService>();
    final recipe = await service.getRecipe(widget.recipeId);
    if (mounted) {
      setState(() {
        _recipe = recipe;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final favoriteStore = context.watch<FavoriteStore>();
    final menuStore = context.watch<MenuStore>();
    final isFavorite = favoriteStore.isFavorite(widget.recipeId);
    final isInMenu = menuStore.isInMenu(widget.recipeId);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _recipe == null
              ? const Center(child: Text('菜谱不存在'))
              : Stack(
                  children: [
                    SingleChildScrollView(
                      child: Column(
                        children: [
                          // Hero Image with overlay card
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              SizedBox(
                                height: 320,
                                width: double.infinity,
                                child: _recipe!.coverUrl.isNotEmpty
                                    ? CachedNetworkImage(
                                        imageUrl: _recipe!.coverUrl,
                                        fit: BoxFit.cover,
                                        placeholder: (_, __) =>
                                            Container(color: Colors.grey[200]),
                                        errorWidget: (_, __, ___) =>
                                            Container(color: Colors.grey[200]),
                                      )
                                    : Container(color: Colors.grey[200]),
                              ),
                              // Nav Buttons
                              Positioned(
                                top: MediaQuery.of(context).padding.top + 8,
                                left: 16,
                                right: 16,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    _buildNavButton(
                                      icon: Icons.arrow_back,
                                      onTap: () => Navigator.pop(context),
                                    ),
                                    _buildNavButton(
                                      icon: isFavorite
                                          ? Icons.favorite
                                          : Icons.favorite_border,
                                      iconColor:
                                          isFavorite ? AppColors.primary : null,
                                      onTap: () =>
                                          favoriteStore.toggle(widget.recipeId),
                                    ),
                                  ],
                                ),
                              ),
                              // 圆角白色背景覆盖在图片底部
                              Positioned(
                                left: 0,
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  height: 30,
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(28),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          // Content Card
                          Container(
                            color: Colors.white,
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Title Row
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          _recipe!.name,
                                          style: const TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.primarySoft,
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                        child: const Text(
                                          '简单',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 12),

                                  // Meta Row
                                  Row(
                                    children: [
                                      const Icon(Icons.local_fire_department,
                                          size: 16, color: AppColors.primary),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${_recipe!.steps.length} 步骤',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      const Icon(Icons.access_time,
                                          size: 16, color: AppColors.blue),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${_recipe!.estimatedTime}分钟',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 20),
                                  const Divider(color: AppColors.divider),
                                  const SizedBox(height: 20),

                                  // Ingredients Section
                                  const Text(
                                    '食材清单',
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  ..._recipe!.ingredients.main.map(
                                    (ing) => _buildIngredientRow(ing),
                                  ),
                                  if (_recipe!.ingredients.sub.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    const Text(
                                      '辅料',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    ..._recipe!.ingredients.sub.map(
                                      (ing) => _buildIngredientRow(ing),
                                    ),
                                  ],

                                  const SizedBox(height: 20),
                                  const Divider(color: AppColors.divider),
                                  const SizedBox(height: 20),

                                  // Steps Section
                                  const Text(
                                    '烹饪步骤',
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  ..._recipe!.steps.asMap().entries.map(
                                        (entry) => _buildStepRow(
                                          entry.key,
                                          entry.value,
                                        ),
                                      ),

                                  // Tips
                                  if (_recipe!.tips.isNotEmpty) ...[
                                    const SizedBox(height: 20),
                                    const Divider(color: AppColors.divider),
                                    const SizedBox(height: 20),
                                    const Text(
                                      '小贴士',
                                      style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Container(
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFF9F0),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        _recipe!.tips,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: AppColors.textSecondary,
                                          height: 1.6,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),

                    // CTA Button
                    Positioned(
                      left: 20,
                      right: 20,
                      bottom: 30,
                      child: GestureDetector(
                        onTap: () {
                          menuStore.toggle(widget.recipeId);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                isInMenu ? '已从菜单移除' : '已加入今日菜单',
                              ),
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        },
                        child: Container(
                          height: 54,
                          decoration: BoxDecoration(
                            color: isInMenu ? AppColors.primarySoft : AppColors.primary,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: isInMenu
                                ? null
                                : [
                                    BoxShadow(
                                      color: AppColors.primary.withValues(alpha: 0.4),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                isInMenu ? Icons.remove : Icons.add,
                                color: isInMenu ? AppColors.primary : Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                isInMenu ? '从菜单移除' : '加入今日菜单',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: isInMenu ? AppColors.primary : Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildNavButton({
    required IconData icon,
    Color? iconColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
            ),
          ],
        ),
        child: Icon(icon, color: iconColor ?? AppColors.textPrimary, size: 22),
      ),
    );
  }

  Widget _buildIngredientRow(Ingredient ing) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                ing.name,
                style: const TextStyle(
                  fontSize: 15,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          Text(
            ing.amount.isEmpty ? '适量' : ing.amount,
            style: const TextStyle(
              fontSize: 15,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepRow(int index, RecipeStep step) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: index == 0 ? AppColors.primary : const Color(0xFFF0F0F0),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: index == 0 ? Colors.white : AppColors.textMuted,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.desc,
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppColors.textPrimary,
                    height: 1.6,
                  ),
                ),
                if (step.imageUrl.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: CachedNetworkImage(
                      imageUrl: step.imageUrl,
                      width: double.infinity,
                      height: 180,
                      fit: BoxFit.cover,
                      placeholder: (_, __) =>
                          Container(height: 180, color: Colors.grey[200]),
                      errorWidget: (_, __, ___) =>
                          Container(height: 180, color: Colors.grey[200]),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
