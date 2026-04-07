import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/colors.dart';
import '../stores/menu_store.dart';
import '../stores/share_history_store.dart';
import '../services/recipe_service.dart';
import '../models/recipe.dart';

class ShareMenuPage extends StatefulWidget {
  const ShareMenuPage({super.key});

  @override
  State<ShareMenuPage> createState() => _ShareMenuPageState();
}

class _ShareMenuPageState extends State<ShareMenuPage> {
  final GlobalKey _shareKey = GlobalKey();
  List<Recipe> _recipes = [];
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadRecipes();
  }

  Future<void> _loadRecipes() async {
    final menuStore = context.read<MenuStore>();
    final service = context.read<RecipeService>();
    final recipes = <Recipe>[];

    for (final id in menuStore.menuIds) {
      final recipe = await service.getRecipe(id);
      if (recipe != null) {
        recipes.add(recipe);
      }
    }

    if (mounted) {
      setState(() {
        _recipes = recipes;
        _isLoading = false;
      });
    }
  }

  String _generateQrData() {
    final menuStore = context.read<MenuStore>();
    // 格式: meishi://menu?ids=id1,id2,id3
    final ids = menuStore.menuIds.join(',');
    return 'meishi://menu?ids=$ids';
  }

  Future<void> _saveAndShare() async {
    setState(() => _isSaving = true);

    try {
      final boundary = _shareKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();

      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/menu_share.png');
      await file.writeAsBytes(bytes);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: '我的今日菜单',
      );

      // 分享成功后：保存到历史并清空菜单
      if (mounted) {
        final menuStore = context.read<MenuStore>();
        final shareHistoryStore = context.read<ShareHistoryStore>();

        // 保存到分享历史
        shareHistoryStore.addSharedMenu(menuStore.menuIds.toList());

        // 清空今日菜单
        menuStore.clear();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已分享并保存到历史')),
        );

        // 返回上一页
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('分享失败: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '分享菜单',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          if (!_isLoading && _recipes.isNotEmpty)
            TextButton(
              onPressed: _isSaving ? null : _saveAndShare,
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(
                      '分享',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _recipes.isEmpty
              ? const Center(
                  child: Text(
                    '菜单为空，请先添加菜谱',
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Center(
                    child: RepaintBoundary(
                      key: _shareKey,
                      child: Container(
                        width: 320,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Header
                            Row(
                              children: const [
                                Text('🍳', style: TextStyle(fontSize: 24)),
                                SizedBox(width: 8),
                                Text(
                                  '今日菜单',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                '共 ${_recipes.length} 道菜',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Divider(color: AppColors.divider),
                            const SizedBox(height: 12),

                            // Recipe List
                            ...List.generate(_recipes.length, (index) {
                              final recipe = _recipes[index];
                              final ingredients = recipe.ingredients.all
                                  .take(6)
                                  .map((i) => i.name)
                                  .join('、');
                              final hasMore = recipe.ingredients.all.length > 6;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: CachedNetworkImage(
                                            imageUrl: recipe.coverUrl,
                                            width: 50,
                                            height: 50,
                                            fit: BoxFit.cover,
                                            placeholder: (_, __) => Container(
                                              width: 50,
                                              height: 50,
                                              color: Colors.grey[200],
                                            ),
                                            errorWidget: (_, __, ___) => Container(
                                              width: 50,
                                              height: 50,
                                              color: Colors.grey[200],
                                              child: const Icon(Icons.restaurant),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                '${index + 1}. ${recipe.name}',
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppColors.textPrimary,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                '${recipe.steps.length}步骤 · ${recipe.estimatedTime}分钟',
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  color: AppColors.textMuted,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (ingredients.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFFF8E1),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          '食材: $ingredients${hasMore ? "..." : ""}',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Color(0xFF8D6E63),
                                            height: 1.3,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            }),

                            // 汇总食材清单
                            Builder(builder: (context) {
                              final allIngredients = <String, String>{};
                              for (final recipe in _recipes) {
                                for (final ing in recipe.ingredients.all) {
                                  if (ing.name.isNotEmpty) {
                                    // 合并相同食材
                                    if (allIngredients.containsKey(ing.name)) {
                                      if (ing.amount.isNotEmpty &&
                                          !allIngredients[ing.name]!.contains(ing.amount)) {
                                        allIngredients[ing.name] =
                                            '${allIngredients[ing.name]}+${ing.amount}';
                                      }
                                    } else {
                                      allIngredients[ing.name] = ing.amount;
                                    }
                                  }
                                }
                              }

                              if (allIngredients.isEmpty) {
                                return const SizedBox.shrink();
                              }

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Divider(color: AppColors.divider),
                                  const SizedBox(height: 12),
                                  const Row(
                                    children: [
                                      Icon(Icons.shopping_cart,
                                          size: 16, color: AppColors.primary),
                                      SizedBox(width: 6),
                                      Text(
                                        '购物清单',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: allIngredients.entries.map((e) {
                                      return Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFE8F5E9),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          e.value.isNotEmpty
                                              ? '${e.key}(${e.value})'
                                              : e.key,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Color(0xFF2E7D32),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                  const SizedBox(height: 12),
                                ],
                              );
                            }),

                            const Divider(color: AppColors.divider),
                            const SizedBox(height: 16),

                            // QR Code
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8F8F8),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                children: [
                                  QrImageView(
                                    data: _generateQrData(),
                                    version: QrVersions.auto,
                                    size: 120,
                                    backgroundColor: Colors.white,
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    '扫码导入菜单',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 16),
                            // Footer
                            const Text(
                              'Meishi App',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textMuted,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
    );
  }
}
