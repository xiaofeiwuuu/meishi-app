import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../theme/colors.dart';

class ShoppingListPage extends StatefulWidget {
  const ShoppingListPage({super.key});
  @override
  State<ShoppingListPage> createState() => _ShoppingListPageState();
}

class _ShoppingListPageState extends State<ShoppingListPage> {
  List<dynamic> _items = [];
  bool _loading = true;
  String? _blocked;

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
      final data = await ApiClient.instance.get('/app/shopping-list');
      setState(() {
        _items = (data as List?) ?? [];
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

  Future<void> _add() async {
    final name = await _prompt();
    if (name == null || name.trim().isEmpty) return;
    try {
      await ApiClient.instance.post('/app/shopping-list', data: {'name': name.trim()});
      _load();
    } catch (e) {
      _toast(e.toString());
    }
  }

  Future<void> _toggle(Map item) async {
    final newVal = !(item['checked'] == true);
    setState(() => item['checked'] = newVal); // 乐观更新
    try {
      await ApiClient.instance.put('/app/shopping-list/${item['id']}', data: {'checked': newVal});
    } catch (e) {
      setState(() => item['checked'] = !newVal);
      _toast(e.toString());
    }
  }

  Future<void> _remove(String id) async {
    try {
      await ApiClient.instance.delete('/app/shopping-list/$id');
      _load();
    } catch (e) {
      _toast(e.toString());
    }
  }

  Future<void> _clearChecked() async {
    try {
      await ApiClient.instance.delete('/app/shopping-list');
      _load();
    } catch (e) {
      _toast(e.toString());
    }
  }

  Future<void> _generate() async {
    final now = DateTime.now();
    final to = now.add(const Duration(days: 7));
    String f(DateTime d) =>
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    try {
      final r = await ApiClient.instance
          .post('/app/shopping-list/generate', data: {'from': f(now), 'to': f(to)});
      _toast('已从餐计划生成 ${r['added']} 项');
      _load();
    } catch (e) {
      _toast(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('购物清单'),
        actions: [
          if (_blocked == null)
            PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'gen') _generate();
                if (v == 'clear') _clearChecked();
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'gen', child: Text('从餐计划生成')),
                PopupMenuItem(value: 'clear', child: Text('清空已买')),
              ],
            ),
        ],
      ),
      floatingActionButton: _blocked == null
          ? FloatingActionButton(
              backgroundColor: AppColors.primary,
              onPressed: _add,
              child: const Icon(Icons.add, color: Color(0xFF5D4E37)),
            )
          : null,
      body: _body(),
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
              const Icon(Icons.shopping_cart_outlined, size: 64, color: AppColors.textMuted),
              const SizedBox(height: 16),
              Text(_blocked!, textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary)),
            ],
          ),
        ),
      );
    }
    if (_items.isEmpty) {
      return const Center(
        child: Text('清单是空的,点右下角添加,或从餐计划生成',
            style: TextStyle(color: AppColors.textMuted)),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(12),
      children: _items.map((i) {
        final checked = i['checked'] == true;
        return Card(
          color: Colors.white,
          child: ListTile(
            leading: Checkbox(
              value: checked,
              activeColor: AppColors.primary,
              onChanged: (_) => _toggle(i as Map),
            ),
            title: Text(
              i['name'] ?? '',
              style: TextStyle(
                decoration: checked ? TextDecoration.lineThrough : null,
                color: checked ? AppColors.textMuted : AppColors.textPrimary,
              ),
            ),
            subtitle: (i['amount'] != null && (i['amount'] as String).isNotEmpty)
                ? Text(i['amount'])
                : null,
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              onPressed: () => _remove(i['id'].toString()),
            ),
          ),
        );
      }).toList(),
    );
  }

  Future<String?> _prompt() {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('添加物品'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(labelText: '物品名', hintText: '如:鸡蛋'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          TextButton(onPressed: () => Navigator.pop(ctx, ctrl.text), child: const Text('添加')),
        ],
      ),
    );
  }
}
