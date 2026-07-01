import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../config.dart';
import '../../theme/colors.dart';

const _slots = {'breakfast': '早餐', 'lunch': '午餐', 'dinner': '晚餐'};

class MealPlanPage extends StatefulWidget {
  const MealPlanPage({super.key});
  @override
  State<MealPlanPage> createState() => _MealPlanPageState();
}

class _MealPlanPageState extends State<MealPlanPage> {
  DateTime _date = DateTime.now();
  List<dynamic> _entries = [];
  bool _loading = true;
  String? _blocked; // 无家庭等提示

  String get _dateStr =>
      '${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _blocked = null;
    });
    try {
      final data = await ApiClient.instance.get('/app/meal-plan', query: {'date': _dateStr});
      setState(() {
        _entries = (data as List?) ?? [];
        _loading = false;
      });
    } on ApiException catch (e) {
      setState(() {
        _blocked = e.toString();
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _blocked = e.toString();
        _loading = false;
      });
    }
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _add(String slot) async {
    final name = await _promptDish('加一道菜');
    if (name == null || name.trim().isEmpty) return;
    try {
      await ApiClient.instance.post('/app/meal-plan',
          data: {'planDate': _dateStr, 'mealSlot': slot, 'customName': name.trim()});
      _load();
    } catch (e) {
      _toast(e.toString());
    }
  }

  Future<void> _remove(String id) async {
    try {
      await ApiClient.instance.delete('/app/meal-plan/$id');
      _load();
    } catch (e) {
      _toast(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('餐计划')),
      body: Column(
        children: [
          _dateBar(),
          Expanded(child: _body()),
        ],
      ),
    );
  }

  Widget _dateBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              setState(() => _date = _date.subtract(const Duration(days: 1)));
              _load();
            },
          ),
          Text(_dateStr, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () {
              setState(() => _date = _date.add(const Duration(days: 1)));
              _load();
            },
          ),
        ],
      ),
    );
  }

  Widget _body() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (_blocked != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.groups_outlined, size: 64, color: AppColors.textMuted),
              const SizedBox(height: 16),
              Text(_blocked!, textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              const Text('去"我的 → 我的家庭"创建或加入家庭',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
            ],
          ),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: _slots.entries.map((slot) {
        final items = _entries.where((e) => e['mealSlot'] == slot.key).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(slot.value,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  TextButton.icon(
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('加菜'),
                    onPressed: () => _add(slot.key),
                  ),
                ],
              ),
            ),
            if (items.isEmpty)
              const Padding(
                padding: EdgeInsets.only(bottom: 8, left: 4),
                child: Text('还没安排', style: TextStyle(color: AppColors.textMuted)),
              ),
            ...items.map((e) => Card(
                  color: Colors.white,
                  child: ListTile(
                    leading: (e['cover'] != null && (e['cover'] as String).isNotEmpty)
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Image.network(AppConfig.coverUrl(e['cover']),
                                width: 44, height: 44, fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(Icons.restaurant)),
                          )
                        : const Icon(Icons.restaurant, color: AppColors.primary),
                    title: Text(e['name'] ?? ''),
                    trailing: IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => _remove(e['id'].toString()),
                    ),
                  ),
                )),
            const SizedBox(height: 8),
          ],
        );
      }).toList(),
    );
  }

  Future<String?> _promptDish(String title) {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(labelText: '菜名', hintText: '如:红烧肉'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          TextButton(onPressed: () => Navigator.pop(ctx, ctrl.text), child: const Text('添加')),
        ],
      ),
    );
  }
}
