import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/colors.dart';
import '../widgets/food_card.dart';
import '../models/recipe.dart';
import '../services/recipe_service.dart';
import '../stores/menu_store.dart';
import '../utils/responsive.dart';
import 'recipe_detail_page.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});
  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final _scrollController = ScrollController();
  Timer? _debounce;

  List<RecipeSummary> _results = [];
  bool _searching = false;
  bool _showBackToTop = false;
  String _lastQuery = '';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      final show = _scrollController.offset > 300;
      if (show != _showBackToTop) setState(() => _showBackToTop = show);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusNode.requestFocus());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () => _search(value));
  }

  Future<void> _search(String query) async {
    final q = query.trim();
    _lastQuery = q;
    if (q.isEmpty) {
      setState(() {
        _results = [];
        _searching = false;
      });
      return;
    }
    setState(() => _searching = true);
    final res = await context.read<RecipeService>().searchRecipes(q, pageSize: 30);
    if (!mounted || q != _lastQuery) return; // 已被更新的搜索覆盖
    setState(() {
      _results = res;
      _searching = false;
    });
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
        title: TextField(
          controller: _controller,
          focusNode: _focusNode,
          decoration: const InputDecoration(
            hintText: '搜索菜谱...',
            hintStyle: TextStyle(color: AppColors.textMuted),
            border: InputBorder.none,
          ),
          style: const TextStyle(fontSize: 16, color: AppColors.textPrimary),
          onChanged: _onChanged,
          onSubmitted: _search,
        ),
        actions: [
          if (_controller.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear, color: AppColors.textMuted),
              onPressed: () {
                _controller.clear();
                _search('');
              },
            ),
        ],
      ),
      body: _buildBody(menuStore),
      floatingActionButton: _showBackToTop
          ? FloatingActionButton(
              mini: true,
              backgroundColor: AppColors.primary,
              onPressed: () => _scrollController.animateTo(0,
                  duration: const Duration(milliseconds: 300), curve: Curves.easeOut),
              child: const Icon(Icons.arrow_upward, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildBody(MenuStore menuStore) {
    if (_controller.text.trim().isEmpty) {
      return _hint(Icons.search, '输入关键词搜索菜谱');
    }
    if (_searching) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (_results.isEmpty) {
      return _hint(Icons.search_off, '没有找到 "${_controller.text}" 相关的菜谱');
    }
    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          alignment: Alignment.centerLeft,
          child: Text('找到 ${_results.length} 个菜谱',
              style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
        ),
        Expanded(
          child: GridView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(20),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: Responsive.getGridColumns(context),
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: Responsive.getCardAspectRatio(context),
            ),
            itemCount: _results.length,
            itemBuilder: (context, index) {
              final r = _results[index];
              return FoodCard(
                id: r.id,
                imageUrl: r.coverUrl,
                title: r.name,
                time: '',
                isAdded: menuStore.isInMenu(r.id),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => RecipeDetailPage(recipeId: r.id)),
                ),
                onAddTap: () => menuStore.toggle(r.id),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _hint(IconData icon, String text) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(text, style: const TextStyle(color: AppColors.textMuted, fontSize: 16)),
          ],
        ),
      );
}
