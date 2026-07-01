import 'package:flutter/material.dart';
import '../stores/favorite_store.dart';

/// 收藏直接加;取消收藏时二次确认,防误触把攒的收藏点没了
Future<void> toggleFavoriteWithConfirm(
  BuildContext context,
  FavoriteStore store,
  String recipeId, {
  String? name,
}) async {
  if (!store.isFavorite(recipeId)) {
    await store.toggle(recipeId); // 收藏:直接加,不打扰
    return;
  }
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('取消收藏'),
      content: Text(
        '确定不再收藏${name != null && name.isNotEmpty ? '「$name」' : '这道菜'}了吗?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('再想想'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('取消收藏', style: TextStyle(color: Colors.red)),
        ),
      ],
    ),
  );
  if (ok == true) await store.toggle(recipeId);
}
