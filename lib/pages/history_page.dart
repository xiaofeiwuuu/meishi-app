import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:table_calendar/table_calendar.dart';
import '../theme/colors.dart';
import '../services/recipe_service.dart';
import '../services/data_service.dart';
import '../stores/menu_store.dart';
import '../stores/favorite_store.dart';
import '../stores/share_history_store.dart';
import '../models/recipe.dart';
import 'recipe_detail_page.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _handleMenuAction(String action) {
    final favoriteStore = context.read<FavoriteStore>();
    final menuStore = context.read<MenuStore>();

    switch (action) {
      case 'export':
        DataService.exportAndShare(
          context: context,
          favoriteStore: favoriteStore,
          menuStore: menuStore,
        );
        break;
      case 'import':
        _showImportDialog();
        break;
      case 'clear_share':
        _showClearDialog('分享历史', () => context.read<ShareHistoryStore>().clearHistory());
        break;
    }
  }

  void _showImportDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('导入数据'),
        content: const Text('选择导入方式：合并到现有数据，还是替换全部？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _importData(merge: false);
            },
            child: const Text('替换'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _importData(merge: true);
            },
            child: const Text('合并', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  Future<void> _importData({required bool merge}) async {
    final favoriteStore = context.read<FavoriteStore>();
    final menuStore = context.read<MenuStore>();

    final result = await DataService.importFromFile(
      context: context,
      favoriteStore: favoriteStore,
      menuStore: menuStore,
      merge: merge,
    );

    if (result != null && mounted) {
      final total = result.values.fold(0, (sum, v) => sum + v);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已导入 $total 条数据')),
      );
    }
  }

  void _showClearDialog(String title, VoidCallback onClear) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('清空$title'),
        content: Text('确定要清空所有$title吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              onClear();
              Navigator.pop(ctx);
            },
            child: const Text('清空', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final shareHistoryStore = context.watch<ShareHistoryStore>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 8, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '历史记录',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
                    onSelected: _handleMenuAction,
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'export',
                        child: Row(
                          children: [
                            Icon(Icons.upload, size: 20),
                            SizedBox(width: 12),
                            Text('导出数据'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'import',
                        child: Row(
                          children: [
                            Icon(Icons.download, size: 20),
                            SizedBox(width: 12),
                            Text('导入数据'),
                          ],
                        ),
                      ),
                      if (shareHistoryStore.history.isNotEmpty)
                        const PopupMenuItem(
                          value: 'clear_share',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline, size: 20, color: Colors.red),
                              SizedBox(width: 12),
                              Text('清空分享历史', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            // Tab Bar
            TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textMuted,
              indicatorColor: AppColors.primary,
              tabs: [
                Tab(text: '排行榜 (${shareHistoryStore.topShared.length})'),
                Tab(text: '分享 (${shareHistoryStore.history.length})'),
              ],
            ),

            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Ranking Tab - 分享排行榜
                  _RankingList(topShared: shareHistoryStore.topShared),
                  // Share History Tab
                  _ShareHistoryList(history: shareHistoryStore.history),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 分享排行榜
class _RankingList extends StatelessWidget {
  final List<ShareCountItem> topShared;

  const _RankingList({required this.topShared});

  @override
  Widget build(BuildContext context) {
    if (topShared.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.leaderboard, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            const Text(
              '暂无分享记录',
              style: TextStyle(color: AppColors.textMuted, fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              '分享菜谱后这里会显示排行榜',
              style: TextStyle(color: AppColors.textMuted, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
      itemCount: topShared.length,
      itemBuilder: (context, index) {
        final item = topShared[index];
        return _RankingCard(
          rank: index + 1,
          recipeId: item.recipeId,
          shareCount: item.shareCount,
        );
      },
    );
  }
}

// 分享历史日历视图
class _ShareHistoryList extends StatefulWidget {
  final List<SharedMenu> history;

  const _ShareHistoryList({required this.history});

  @override
  State<_ShareHistoryList> createState() => _ShareHistoryListState();
}

class _ShareHistoryListState extends State<_ShareHistoryList> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;

  // 获取某一天的分享记录
  List<SharedMenu> _getMenusForDay(DateTime day) {
    return widget.history.where((menu) {
      return isSameDay(menu.sharedAt, day);
    }).toList();
  }

  // 获取有分享记录的日期集合
  Map<DateTime, List<SharedMenu>> _getEvents() {
    final events = <DateTime, List<SharedMenu>>{};
    for (final menu in widget.history) {
      final day = DateTime(menu.sharedAt.year, menu.sharedAt.month, menu.sharedAt.day);
      if (events[day] == null) {
        events[day] = [];
      }
      events[day]!.add(menu);
    }
    return events;
  }

  @override
  Widget build(BuildContext context) {
    final events = _getEvents();
    final selectedMenus = _selectedDay != null ? _getMenusForDay(_selectedDay!) : <SharedMenu>[];

    return Column(
      children: [
        // 日历
        Container(
          margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
              ),
            ],
          ),
          child: TableCalendar<SharedMenu>(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            eventLoader: (day) {
              final normalizedDay = DateTime(day.year, day.month, day.day);
              return events[normalizedDay] ?? [];
            },
            startingDayOfWeek: StartingDayOfWeek.monday,
            calendarStyle: CalendarStyle(
              outsideDaysVisible: false,
              selectedDecoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              markerDecoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              markerSize: 6,
              markersMaxCount: 3,
            ),
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              leftChevronIcon: Icon(Icons.chevron_left, color: AppColors.textSecondary),
              rightChevronIcon: Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            onFormatChanged: (format) {
              setState(() {
                _calendarFormat = format;
              });
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
          ),
        ),

        const SizedBox(height: 12),

        // 选中日期的菜单列表
        Expanded(
          child: _selectedDay == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.touch_app, size: 48, color: Colors.grey[300]),
                      const SizedBox(height: 12),
                      const Text(
                        '点击日期查看分享记录',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 14),
                      ),
                    ],
                  ),
                )
              : selectedMenus.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.event_busy, size: 48, color: Colors.grey[300]),
                          const SizedBox(height: 12),
                          Text(
                            '${_selectedDay!.month}/${_selectedDay!.day} 没有分享记录',
                            style: const TextStyle(color: AppColors.textMuted, fontSize: 14),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 100),
                      itemCount: selectedMenus.length,
                      itemBuilder: (context, index) {
                        return _ShareHistoryCard(sharedMenu: selectedMenus[index]);
                      },
                    ),
        ),
      ],
    );
  }
}

// 排行榜卡片
class _RankingCard extends StatefulWidget {
  final int rank;
  final String recipeId;
  final int shareCount;

  const _RankingCard({
    required this.rank,
    required this.recipeId,
    required this.shareCount,
  });

  @override
  State<_RankingCard> createState() => _RankingCardState();
}

class _RankingCardState extends State<_RankingCard> {
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

  // 获取排名样式
  Widget _buildRankBadge() {
    Color bgColor;
    Color textColor;
    IconData? icon;

    if (widget.rank == 1) {
      bgColor = const Color(0xFFFFD700); // 金色
      textColor = Colors.white;
      icon = Icons.emoji_events;
    } else if (widget.rank == 2) {
      bgColor = const Color(0xFFC0C0C0); // 银色
      textColor = Colors.white;
      icon = Icons.emoji_events;
    } else if (widget.rank == 3) {
      bgColor = const Color(0xFFCD7F32); // 铜色
      textColor = Colors.white;
      icon = Icons.emoji_events;
    } else {
      bgColor = AppColors.primary.withValues(alpha: 0.1);
      textColor = AppColors.primary;
      icon = null;
    }

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: icon != null
            ? Icon(icon, color: textColor, size: 20)
            : Text(
                '${widget.rank}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final menuStore = context.watch<MenuStore>();

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
          child: Row(
            children: [
              // 排名徽章
              _buildRankBadge(),
              const SizedBox(width: 12),
              // 图片
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 60,
                  height: 60,
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
              // 名称和分享次数
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
                    Row(
                      children: [
                        Icon(Icons.share, size: 14, color: AppColors.textMuted),
                        const SizedBox(width: 4),
                        Text(
                          '分享 ${widget.shareCount} 次',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // 添加到菜单按钮
              IconButton(
                onPressed: () => menuStore.toggle(widget.recipeId),
                icon: Icon(
                  menuStore.isInMenu(widget.recipeId)
                      ? Icons.check_circle
                      : Icons.add_circle_outline,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 分享历史卡片
class _ShareHistoryCard extends StatefulWidget {
  final SharedMenu sharedMenu;

  const _ShareHistoryCard({required this.sharedMenu});

  @override
  State<_ShareHistoryCard> createState() => _ShareHistoryCardState();
}

class _ShareHistoryCardState extends State<_ShareHistoryCard> {
  List<Recipe?> _recipes = [];
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _loadRecipes();
  }

  Future<void> _loadRecipes() async {
    final service = context.read<RecipeService>();
    final recipes = <Recipe?>[];
    for (final id in widget.sharedMenu.recipeIds) {
      final recipe = await service.getRecipe(id);
      recipes.add(recipe);
    }
    if (mounted) {
      setState(() => _recipes = recipes);
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) return '刚刚';
    if (diff.inMinutes < 60) return '${diff.inMinutes}分钟前';
    if (diff.inHours < 24) return '${diff.inHours}小时前';
    if (diff.inDays < 7) return '${diff.inDays}天前';
    return '${time.year}/${time.month}/${time.day}';
  }

  void _importToMenu() {
    final menuStore = context.read<MenuStore>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('导入到今日菜单'),
        content: Text('将 ${widget.sharedMenu.recipeIds.length} 道菜导入到今日菜单？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              // 清空当前菜单并导入
              menuStore.clear();
              for (final id in widget.sharedMenu.recipeIds) {
                menuStore.add(id);
              }
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('已替换为 ${widget.sharedMenu.recipeIds.length} 道菜')),
              );
            },
            child: const Text('替换', style: TextStyle(color: Colors.orange)),
          ),
          TextButton(
            onPressed: () {
              // 合并导入
              for (final id in widget.sharedMenu.recipeIds) {
                menuStore.add(id);
              }
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('已添加 ${widget.sharedMenu.recipeIds.length} 道菜')),
              );
            },
            child: const Text('添加', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Dismissible(
        key: Key(widget.sharedMenu.id),
        direction: DismissDirection.endToStart,
        onDismissed: (_) => context.read<ShareHistoryStore>().removeSharedMenu(widget.sharedMenu.id),
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: Colors.red[400],
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.delete, color: Colors.white),
        ),
        child: GestureDetector(
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          child: Container(
            padding: const EdgeInsets.all(16),
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
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.restaurant_menu, color: AppColors.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${widget.sharedMenu.recipeIds.length} 道菜',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatTime(widget.sharedMenu.sharedAt),
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: _importToMenu,
                      icon: const Icon(Icons.playlist_add, color: AppColors.primary),
                      tooltip: '导入到菜单',
                    ),
                    Icon(
                      _isExpanded ? Icons.expand_less : Icons.expand_more,
                      color: AppColors.textMuted,
                    ),
                  ],
                ),

                // Expanded content
                if (_isExpanded) ...[
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 8),
                  ..._recipes.asMap().entries.map((entry) {
                    final index = entry.key;
                    final recipe = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: GestureDetector(
                        onTap: recipe != null
                            ? () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => RecipeDetailPage(recipeId: recipe.id),
                                  ),
                                )
                            : null,
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: SizedBox(
                                width: 40,
                                height: 40,
                                child: recipe?.coverUrl.isNotEmpty == true
                                    ? CachedNetworkImage(
                                        imageUrl: recipe!.coverUrl,
                                        fit: BoxFit.cover,
                                        placeholder: (_, __) => Container(color: Colors.grey[200]),
                                        errorWidget: (_, __, ___) => Container(
                                          color: Colors.grey[200],
                                          child: const Icon(Icons.restaurant, size: 16),
                                        ),
                                      )
                                    : Container(
                                        color: Colors.grey[200],
                                        child: const Icon(Icons.restaurant, size: 16),
                                      ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                recipe?.name ?? '加载中...',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
