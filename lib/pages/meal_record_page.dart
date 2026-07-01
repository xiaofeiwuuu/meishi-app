import 'package:flutter/material.dart';
import '../services/api_client.dart';
import '../config.dart';
import '../theme/colors.dart';

const _slots = {'breakfast': '早餐', 'lunch': '午餐', 'dinner': '晚餐', 'snack': '加餐'};

class MealRecordPage extends StatefulWidget {
  const MealRecordPage({super.key});
  @override
  State<MealRecordPage> createState() => _MealRecordPageState();
}

class _MealRecordPageState extends State<MealRecordPage> {
  DateTime _date = DateTime.now();
  List<dynamic> _records = [];
  bool _loading = true;

  String get _dateStr =>
      '${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await ApiClient.instance.get('/app/meal-records', query: {'date': _dateStr});
      setState(() {
        _records = (data as List?) ?? [];
        _loading = false;
      });
    } catch (e) {
      _toast(e.toString());
      setState(() => _loading = false);
    }
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _add(String slot) async {
    final result = await _promptRecord();
    if (result == null) return;
    try {
      await ApiClient.instance.post('/app/meal-records', data: {
        'recordDate': _dateStr,
        'mealSlot': slot,
        'customName': result['name'],
        if (result['note'] != null && result['note']!.isNotEmpty) 'note': result['note'],
      });
      _load();
    } catch (e) {
      _toast(e.toString());
    }
  }

  Future<void> _remove(String id) async {
    try {
      await ApiClient.instance.delete('/app/meal-records/$id');
      _load();
    } catch (e) {
      _toast(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('饮食记录')),
      body: Column(
        children: [
          Container(
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
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: _slots.entries.map((slot) {
                      final items =
                          _records.where((e) => e['mealSlot'] == slot.key).toList();
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
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary)),
                                TextButton.icon(
                                  icon: const Icon(Icons.add, size: 18),
                                  label: const Text('记一笔'),
                                  onPressed: () => _add(slot.key),
                                ),
                              ],
                            ),
                          ),
                          ...items.map((e) => Card(
                                color: Colors.white,
                                child: ListTile(
                                  leading: (e['cover'] != null &&
                                          (e['cover'] as String).isNotEmpty)
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(6),
                                          child: Image.network(
                                              AppConfig.coverUrl(e['cover']),
                                              width: 44,
                                              height: 44,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) =>
                                                  const Icon(Icons.fastfood)),
                                        )
                                      : const Icon(Icons.fastfood, color: AppColors.primary),
                                  title: Text(e['name'] ?? ''),
                                  subtitle: (e['note'] != null &&
                                          (e['note'] as String).isNotEmpty)
                                      ? Text(e['note'])
                                      : null,
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
                  ),
          ),
        ],
      ),
    );
  }

  Future<Map<String, String>?> _promptRecord() {
    final name = TextEditingController();
    final note = TextEditingController();
    return showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('记录吃了什么'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              autofocus: true,
              decoration: const InputDecoration(labelText: '吃了什么', hintText: '如:楼下麻辣烫'),
            ),
            TextField(
              controller: note,
              decoration: const InputDecoration(labelText: '备注(可选)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          TextButton(
            onPressed: () {
              if (name.text.trim().isEmpty) return;
              Navigator.pop(ctx, {'name': name.text.trim(), 'note': note.text.trim()});
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }
}
