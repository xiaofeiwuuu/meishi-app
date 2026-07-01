import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../services/api_client.dart';
import '../../services/auth_service.dart';
import '../../theme/colors.dart';

class FamilyPage extends StatefulWidget {
  const FamilyPage({super.key});
  @override
  State<FamilyPage> createState() => _FamilyPageState();
}

class _FamilyPageState extends State<FamilyPage> {
  Map<String, dynamic>? _family; // null = 无家庭
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await ApiClient.instance.get('/app/family');
      setState(() {
        _family = data == null ? null : Map<String, dynamic>.from(data);
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

  Future<void> _create() async {
    final name = await _prompt('创建家庭', '家庭名称', hint: '如:温馨小家');
    if (name == null || name.trim().isEmpty) return;
    try {
      final data = await ApiClient.instance.post('/app/family', data: {'name': name.trim()});
      setState(() => _family = Map<String, dynamic>.from(data));
    } catch (e) {
      _toast(e.toString());
    }
  }

  Future<void> _join() async {
    final code = await _prompt('加入家庭', '邀请码', hint: '6 位邀请码');
    if (code == null || code.trim().isEmpty) return;
    try {
      final data = await ApiClient.instance
          .post('/app/family/join', data: {'inviteCode': code.trim().toUpperCase()});
      setState(() => _family = Map<String, dynamic>.from(data));
    } catch (e) {
      _toast(e.toString());
    }
  }

  Future<void> _refreshCode() async {
    try {
      final data = await ApiClient.instance.post('/app/family/refresh-code');
      setState(() => _family!['inviteCode'] = data['inviteCode']);
      _toast('邀请码已刷新');
    } catch (e) {
      _toast(e.toString());
    }
  }

  Future<void> _leave() async {
    if (!await _confirm('退出家庭', '确定退出这个家庭吗？')) return;
    try {
      await ApiClient.instance.post('/app/family/leave');
      setState(() => _family = null);
    } catch (e) {
      _toast(e.toString());
    }
  }

  Future<void> _disband() async {
    if (!await _confirm('解散家庭', '确定解散？所有成员都会被移出。')) return;
    try {
      await ApiClient.instance.delete('/app/family');
      setState(() => _family = null);
    } catch (e) {
      _toast(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('我的家庭')),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _family == null
              ? _buildEmpty()
              : _buildFamily(),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.home_rounded, size: 72, color: AppColors.textMuted),
            const SizedBox(height: 16),
            const Text('你还没有家庭', style: TextStyle(fontSize: 16, color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            const Text('创建一个家庭,和家人共享菜单、购物清单',
                textAlign: TextAlign.center, style: TextStyle(color: AppColors.textMuted)),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: _btnStyle,
                onPressed: _create,
                child: const Text('创建家庭'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _join,
                child: const Text('凭邀请码加入'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFamily() {
    final f = _family!;
    final members = (f['members'] as List?) ?? [];
    final myId = context.read<AuthService>().user?.id;
    final isOwner = f['ownerId']?.toString() == myId;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(f['name'] ?? '',
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('邀请码:', style: TextStyle(color: AppColors.textMuted)),
                    const SizedBox(width: 8),
                    SelectableText(f['inviteCode'] ?? '',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 2)),
                    IconButton(
                      icon: const Icon(Icons.copy, size: 18),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: f['inviteCode'] ?? ''));
                        _toast('邀请码已复制');
                      },
                    ),
                    if (isOwner)
                      TextButton(onPressed: _refreshCode, child: const Text('刷新')),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Padding(
          padding: EdgeInsets.fromLTRB(4, 8, 4, 8),
          child: Text('成员', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
        ),
        ...members.map((m) => Card(
              color: Colors.white,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.primary,
                  backgroundImage: (m['avatar'] != null && (m['avatar'] as String).isNotEmpty)
                      ? NetworkImage(m['avatar'])
                      : null,
                  child: (m['avatar'] == null || (m['avatar'] as String).isEmpty)
                      ? const Icon(Icons.person, color: Color(0xFF5D4E37))
                      : null,
                ),
                title: Text(m['nickname'] ?? ''),
                trailing: m['role'] == 'owner'
                    ? const Chip(label: Text('群主'), visualDensity: VisualDensity.compact)
                    : null,
              ),
            )),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
            onPressed: isOwner ? _disband : _leave,
            child: Text(isOwner ? '解散家庭' : '退出家庭'),
          ),
        ),
      ],
    );
  }

  final _btnStyle = FilledButton.styleFrom(
    backgroundColor: AppColors.primary,
    foregroundColor: const Color(0xFF5D4E37),
    padding: const EdgeInsets.symmetric(vertical: 14),
  );

  Future<String?> _prompt(String title, String label, {String? hint}) {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: InputDecoration(labelText: label, hintText: hint),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          TextButton(onPressed: () => Navigator.pop(ctx, ctrl.text), child: const Text('确定')),
        ],
      ),
    );
  }

  Future<bool> _confirm(String title, String content) async {
    final r = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('确定')),
        ],
      ),
    );
    return r == true;
  }
}
