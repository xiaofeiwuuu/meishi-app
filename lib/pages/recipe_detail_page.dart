import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/colors.dart';
import '../services/recipe_service.dart';
import '../stores/favorite_store.dart';
import '../stores/menu_store.dart';
import '../models/recipe.dart';
import '../widgets/background_decorations.dart';

// 波浪形状裁剪器 - 更多波浪
class WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 50);

    // 多个波浪曲线
    final waveHeight = 25.0;

    // 第一个波浪
    path.quadraticBezierTo(
      size.width * 0.15, size.height - waveHeight * 2,
      size.width * 0.3, size.height - waveHeight,
    );

    // 第二个波浪
    path.quadraticBezierTo(
      size.width * 0.45, size.height,
      size.width * 0.6, size.height - waveHeight,
    );

    // 第三个波浪
    path.quadraticBezierTo(
      size.width * 0.75, size.height - waveHeight * 2,
      size.width * 0.9, size.height - waveHeight,
    );

    // 结束
    path.quadraticBezierTo(
      size.width * 0.95, size.height - waveHeight * 0.5,
      size.width, size.height - waveHeight * 1.5,
    );

    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

// 黄色波浪背景
class WaveBackground extends StatelessWidget {
  final double height;

  const WaveBackground({super.key, this.height = 60});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(double.infinity, height),
      painter: WavePainter(),
    );
  }
}

class WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFFD93D)
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height);

    // 波浪从底部开始
    final waveHeight = 20.0;

    path.lineTo(0, waveHeight * 2);

    // 多个波浪
    path.quadraticBezierTo(
      size.width * 0.15, 0,
      size.width * 0.3, waveHeight,
    );

    path.quadraticBezierTo(
      size.width * 0.45, waveHeight * 2.5,
      size.width * 0.6, waveHeight,
    );

    path.quadraticBezierTo(
      size.width * 0.75, 0,
      size.width * 0.9, waveHeight,
    );

    path.quadraticBezierTo(
      size.width * 0.95, waveHeight * 1.5,
      size.width, waveHeight,
    );

    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class RecipeDetailPage extends StatefulWidget {
  final String recipeId;

  const RecipeDetailPage({super.key, required this.recipeId});

  @override
  State<RecipeDetailPage> createState() => _RecipeDetailPageState();
}

class _RecipeDetailPageState extends State<RecipeDetailPage> {
  Recipe? _recipe;
  bool _isLoading = true;
  bool _showBackToTop = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadRecipe();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
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
      backgroundColor: const Color(0xFFFFF7E1),
      body: BackgroundDecorations(
        variant: 4,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : _recipe == null
                ? const Center(child: Text('菜谱不存在'))
                : Stack(
                  children: [
                    SingleChildScrollView(
                      controller: _scrollController,
                      child: Column(
                        children: [
                          // Hero Image with wave effect
                          Stack(
                            children: [
                              // 奶油色背景
                              Container(
                                height: 480,
                                color: const Color(0xFFFFF7E1),
                              ),
                              // 图片带波浪裁剪
                              ClipPath(
                                clipper: WaveClipper(),
                                child: Container(
                                  height: 440,
                                  width: double.infinity,
                                  color: Colors.white,
                                  child: _recipe!.coverUrl.isNotEmpty
                                      ? CachedNetworkImage(
                                          imageUrl: _recipe!.coverUrl,
                                          fit: BoxFit.fitWidth,
                                          placeholder: (_, __) =>
                                              Container(color: Colors.grey[200]),
                                          errorWidget: (_, __, ___) =>
                                              Container(color: Colors.grey[200]),
                                        )
                                      : Container(color: Colors.grey[200]),
                                ),
                              ),
                              // 返回按钮
                              Positioned(
                                top: MediaQuery.of(context).padding.top + 8,
                                left: 16,
                                child: _buildNavButton(
                                  icon: Icons.arrow_back,
                                  onTap: () => Navigator.pop(context),
                                ),
                              ),
                            ],
                          ),

                          // Content
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Title Row with favorite button
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        _recipe!.name,
                                        style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    // 收藏按钮 - 粉色圆形
                                    GestureDetector(
                                      onTap: () => favoriteStore.toggle(widget.recipeId),
                                      child: Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFEDEE7),
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(0xFFFEDEE7).withValues(alpha: 0.5),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Icon(
                                          isFavorite ? Icons.favorite : Icons.favorite_border,
                                          color: const Color(0xFFFF6B8A),
                                          size: 24,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 16),

                                // Meta Row with tags
                                Wrap(
                                  spacing: 10,
                                  runSpacing: 8,
                                  children: [
                                    // 步骤数
                                    _buildTag(
                                      icon: Icons.restaurant_menu,
                                      text: '${_recipe!.steps.length} 步骤',
                                      color: const Color(0xFFFF6B6B),
                                      bgColor: const Color(0xFFFFE8E8),
                                    ),
                                    // 时间
                                    _buildTag(
                                      icon: Icons.access_time,
                                      text: '${_recipe!.estimatedTime}分钟',
                                      color: const Color(0xFF4ECDC4),
                                      bgColor: const Color(0xFFE8FAF8),
                                    ),
                                    // 难度
                                    _buildTag(
                                      icon: Icons.signal_cellular_alt,
                                      text: '简单',
                                      color: const Color(0xFFFFD93D),
                                      bgColor: const Color(0xFFFFF8E1),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 24),
                                const Divider(color: AppColors.divider),
                                const SizedBox(height: 24),

                                // Ingredients Section
                                _buildSectionTitle('食材清单', Icons.shopping_basket),
                                const SizedBox(height: 16),
                                ..._recipe!.ingredients.main.map(
                                  (ing) => _buildIngredientRow(ing),
                                ),
                                if (_recipe!.ingredients.sub.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  const Text(
                                    '辅料',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  ..._recipe!.ingredients.sub.map(
                                    (ing) => _buildIngredientRow(ing),
                                  ),
                                ],

                                const SizedBox(height: 24),
                                const Divider(color: AppColors.divider),
                                const SizedBox(height: 24),

                                // Steps Section
                                _buildSectionTitle('烹饪步骤', Icons.menu_book),
                                const SizedBox(height: 16),
                                ..._recipe!.steps.asMap().entries.map(
                                      (entry) => _buildStepRow(
                                        entry.key,
                                        entry.value,
                                      ),
                                    ),

                                // Tips
                                if (_recipe!.tips.isNotEmpty) ...[
                                  const SizedBox(height: 24),
                                  const Divider(color: AppColors.divider),
                                  const SizedBox(height: 24),
                                  _buildSectionTitle('小贴士', Icons.lightbulb_outline),
                                  const SizedBox(height: 16),
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFF9E6),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: const Color(0xFFFFE082),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('💡', style: TextStyle(fontSize: 20)),
                                        const SizedBox(width: 12),
                                        Expanded(
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
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: isInMenu
                                ? const LinearGradient(
                                    colors: [Color(0xFF4ECDC4), Color(0xFF44B8AC)],
                                  )
                                : const LinearGradient(
                                    colors: [Color(0xFFFFD93D), Color(0xFFFFB800)],
                                  ),
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: isInMenu
                                    ? const Color(0xFF4ECDC4).withValues(alpha: 0.4)
                                    : AppColors.primary.withValues(alpha: 0.4),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                isInMenu ? Icons.check : Icons.add,
                                color: Colors.white,
                                size: 22,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                isInMenu ? '已加入菜单' : '加入今日菜单',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // 回到顶部按钮
                    if (_showBackToTop)
                      Positioned(
                        right: 20,
                        bottom: 100,
                        child: FloatingActionButton(
                          mini: true,
                          backgroundColor: AppColors.primary,
                          onPressed: _scrollToTop,
                          child: const Icon(Icons.arrow_upward, color: Colors.white),
                        ),
                      ),
                  ],
                ),
      ),
    );
  }

  Widget _buildNavButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
            ),
          ],
        ),
        child: Icon(icon, color: AppColors.textPrimary, size: 22),
      ),
    );
  }

  Widget _buildTag({
    required IconData icon,
    required String text,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildIngredientRow(Ingredient ing) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.restaurant,
                  size: 16,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                ing.name,
                style: const TextStyle(
                  fontSize: 15,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              ing.amount.isEmpty ? '适量' : ing.amount,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepRow(int index, RecipeStep step) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: index == 0
                  ? const LinearGradient(
                      colors: [Color(0xFFFFD93D), Color(0xFFFFB800)],
                    )
                  : null,
              color: index == 0 ? null : const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: index == 0 ? Colors.white : AppColors.textMuted,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.desc,
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppColors.textPrimary,
                    height: 1.7,
                  ),
                ),
                if (step.imageUrl.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: CachedNetworkImage(
                      imageUrl: step.imageUrl,
                      fit: BoxFit.contain,
                      placeholder: (_, __) =>
                          Container(height: 150, color: Colors.grey[200]),
                      errorWidget: (_, __, ___) =>
                          Container(height: 150, color: Colors.grey[200]),
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
