import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/colors.dart';
import '../services/api_client.dart';
import '../services/recipe_service.dart';
import '../stores/menu_store.dart';
import '../models/recipe.dart';
import 'recipe_detail_page.dart';
import 'share_menu_page.dart';
import 'scan_page.dart';
import '../widgets/background_decorations.dart';

class MenuPage extends StatelessWidget {
  const MenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    final menuStore = context.watch<MenuStore>();
    final menuIds = menuStore.menuIds.toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: BackgroundDecorations(
        variant: 6,
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
                    '今日菜单',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Row(
                    children: [
                      // 扫码导入
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ScanPage()),
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          child: const Icon(
                            Icons.qr_code_scanner,
                            color: AppColors.textSecondary,
                            size: 22,
                          ),
                        ),
                      ),
                      // 分享
                      if (menuIds.isNotEmpty)
                        GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ShareMenuPage(),
                            ),
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            child: const Icon(
                              Icons.share,
                              color: AppColors.textSecondary,
                              size: 22,
                            ),
                          ),
                        ),
                      // 清空
                      if (menuIds.isNotEmpty)
                        GestureDetector(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('清空菜单'),
                                content: const Text('确定要清空今日菜单吗？'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx),
                                    child: const Text('取消'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      menuStore.clear();
                                      Navigator.pop(ctx);
                                    },
                                    child: const Text(
                                      '确定',
                                      style: TextStyle(color: AppColors.primary),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            child: const Icon(
                              Icons.delete_outline,
                              color: AppColors.textSecondary,
                              size: 22,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            // 家人想吃的(同家庭可见)
            const _FamilyMenuSection(),

            // Content(我的今日菜单)
            Expanded(
              child: menuIds.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.restaurant_menu,
                            size: 64,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            '还没有添加菜谱',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            '浏览菜谱并点击 + 添加到今日菜单',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 14,
                            ),
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
                            itemCount: menuIds.length,
                            itemBuilder: (context, index) {
                              final recipeId = menuIds[index];
                              return _MenuRecipeCard(
                                recipeId: recipeId,
                                onRemove: () => menuStore.remove(recipeId),
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
                            mainAxisSpacing: 0,
                            childAspectRatio: columns == 2 ? 1.6 : 1.8,
                          ),
                          itemCount: menuIds.length,
                          itemBuilder: (context, index) {
                            final recipeId = menuIds[index];
                            return _MenuRecipeCard(
                              recipeId: recipeId,
                              onRemove: () => menuStore.remove(recipeId),
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

// 家人想吃的:显示同家庭其他成员的今日菜单
class _FamilyMenuSection extends StatefulWidget {
  const _FamilyMenuSection();

  @override
  State<_FamilyMenuSection> createState() => _FamilyMenuSectionState();
}

class _FamilyMenuSectionState extends State<_FamilyMenuSection> {
  List<dynamic> _others = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await ApiClient.instance.get('/app/menu/family');
      final all = (data as List?) ?? [];
      final others = all
          .where((m) => m['isMe'] != true && (m['items'] as List).isNotEmpty)
          .toList();
      if (mounted) setState(() => _others = others);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (_others.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFE4A0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.family_restroom, size: 16, color: AppColors.primary),
              SizedBox(width: 4),
              Text('家人想吃的',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary)),
            ],
          ),
          const SizedBox(height: 8),
          ..._others.map((m) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${m['nickname'] ?? '家人'}:',
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.textSecondary)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: (m['items'] as List)
                            .map<Widget>((it) => GestureDetector(
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => RecipeDetailPage(
                                          recipeId: it['id'].toString()),
                                    ),
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12)),
                                    child: Text(it['name'] ?? '',
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textPrimary)),
                                  ),
                                ))
                            .toList(),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _MenuRecipeCard extends StatefulWidget {
  final String recipeId;
  final VoidCallback onRemove;

  const _MenuRecipeCard({
    required this.recipeId,
    required this.onRemove,
  });

  @override
  State<_MenuRecipeCard> createState() => _MenuRecipeCardState();
}

class _MenuRecipeCardState extends State<_MenuRecipeCard> {
  Recipe? _recipe;

  @override
  void initState() {
    super.initState();
    _loadRecipe();
  }

  Future<void> _loadRecipe() async {
    final service = context.read<RecipeService>();
    final recipe = await service.getRecipe(widget.recipeId);
    if (mounted) {
      setState(() => _recipe = recipe);
    }
  }

  String _getIngredientsText() {
    if (_recipe == null) return '';
    final all = _recipe!.ingredients.all;
    if (all.isEmpty) return '';
    return all.map((i) => '${i.name}${i.amount.isNotEmpty ? "(${i.amount})" : ""}').join('、');
  }

  @override
  Widget build(BuildContext context) {
    final ingredientsText = _getIngredientsText();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RecipeDetailPage(recipeId: widget.recipeId),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: SizedBox(
                      width: 70,
                      height: 70,
                      child: _recipe?.coverUrl.isNotEmpty == true
                          ? CachedNetworkImage(
                              imageUrl: _recipe!.coverUrl,
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
                          _recipe?.name ?? '加载中...',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${_recipe?.steps.length ?? 0} 步骤 · ${_recipe?.estimatedTime ?? 0}分钟',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: widget.onRemove,
                    icon: const Icon(
                      Icons.remove_circle_outline,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              // 食材列表
              if (ingredientsText.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F8F8),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.shopping_basket, size: 14, color: AppColors.primary),
                          SizedBox(width: 4),
                          Text(
                            '所需食材',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        ingredientsText,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
