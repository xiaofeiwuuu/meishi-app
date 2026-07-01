import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/colors.dart';
import '../widgets/food_card.dart';
import '../models/recipe.dart';
import '../services/recipe_service.dart';
import '../services/search_history.dart';
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
  List<String> _history = [];
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
    SearchHistory.load().then((list) {
      if (mounted) setState(() => _history = list);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusNode.requestFocus());
  }

  // 缓存一条搜索词
  Future<void> _saveHistory(String q) async {
    if (q.trim().isEmpty) return;
    final list = await SearchHistory.add(q);
    if (mounted) setState(() => _history = list);
  }

  // 点历史标签:回填并搜索
  void _applyHistory(String q) {
    _controller.text = q;
    _controller.selection = TextSelection.collapsed(offset: q.length);
    _debounce?.cancel();
    _search(q);
    _saveHistory(q); // 提到最前
  }

  Future<void> _removeHistory(String q) async {
    final list = await SearchHistory.remove(q);
    if (mounted) setState(() => _history = list);
  }

  Future<void> _clearHistory() async {
    await SearchHistory.clear();
    if (mounted) setState(() => _history = []);
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
        _showBackToTop = false; // 列表空了,回到顶部按钮也要收起
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
          onSubmitted: (q) {
            _search(q);
            _saveHistory(q);
          },
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
      floatingActionButton: (_showBackToTop && _results.isNotEmpty)
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
      return _buildEmptyState();
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
                onTap: () {
                  _saveHistory(_lastQuery); // 点开结果=有效搜索,缓存词条
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => RecipeDetailPage(recipeId: r.id)),
                  );
                },
                onAddTap: () => menuStore.toggle(r.id),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    if (_history.isEmpty) {
      return _hint(Icons.search, '输入关键词搜索菜谱');
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('最近搜索',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary)),
              GestureDetector(
                onTap: _clearHistory,
                behavior: HitTestBehavior.opaque,
                child: const Row(
                  children: [
                    Icon(Icons.delete_outline, size: 16, color: AppColors.textMuted),
                    SizedBox(width: 2),
                    Text('清空',
                        style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _history.map(_historyChip).toList(),
          ),
        ],
      ),
    );
  }

  Widget _historyChip(String kw) {
    return GestureDetector(
      onTap: () => _applyHistory(kw),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 8, 10, 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(kw,
                style: const TextStyle(fontSize: 14, color: AppColors.textPrimary)),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: () => _removeHistory(kw),
              behavior: HitTestBehavior.opaque,
              child: const Icon(Icons.close, size: 15, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
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
