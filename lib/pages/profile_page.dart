import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'family/family_page.dart';
import 'family/meal_plan_page.dart';
import 'family/shopping_list_page.dart';
import 'meal_record_page.dart';
import 'history_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final user = auth.user;
    return Scaffold(
      appBar: AppBar(title: const Text('我的')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 110),
        children: [
          const SizedBox(height: 16),
          Center(
            child: CircleAvatar(
              radius: 40,
              backgroundColor: const Color(0xFFFFD93D),
              backgroundImage: (user?.avatar.isNotEmpty ?? false)
                  ? NetworkImage(user!.avatar)
                  : null,
              child: (user?.avatar.isEmpty ?? true)
                  ? const Icon(Icons.person, size: 40, color: Color(0xFF5D4E37))
                  : null,
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(user?.nickname ?? '',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          Center(
            child: Text(user?.email ?? '',
                style: const TextStyle(color: Colors.black54)),
          ),
          const SizedBox(height: 24),
          _entry(context, Icons.home_rounded, '我的家庭', const FamilyPage()),
          _entry(context, Icons.restaurant_menu, '餐计划', const MealPlanPage()),
          _entry(context, Icons.shopping_cart, '购物清单', const ShoppingListPage()),
          _entry(context, Icons.event_note, '饮食记录', const MealRecordPage()),
          _entry(context, Icons.history_rounded, '历史记录', const HistoryPage()),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('退出登录', style: TextStyle(color: Colors.red)),
            onTap: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('退出登录'),
                  content: const Text('确定要退出当前账号吗？'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
                    TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('退出')),
                  ],
                ),
              );
              if (ok == true && context.mounted) {
                await context.read<AuthService>().logout();
                // 作为 tab 时无处可 pop;push 进来时才 pop。登出后 AuthGate 会自动切登录页
                if (context.mounted && Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _entry(BuildContext context, IconData icon, String title, Widget page) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF5D4E37)),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right, size: 20),
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
    );
  }
}
