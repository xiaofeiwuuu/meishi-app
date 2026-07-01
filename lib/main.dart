import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'pages/home_page.dart';
import 'pages/fridge_page.dart';
import 'pages/menu_page.dart';
import 'pages/saved_page.dart';
import 'pages/profile_page.dart';
import 'services/recipe_service.dart';
import 'services/auth_service.dart';
import 'stores/menu_store.dart';
import 'stores/favorite_store.dart';
import 'stores/share_history_store.dart';
import 'pages/auth/login_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()..init()),
        ChangeNotifierProvider(create: (_) => RecipeService()),
        ChangeNotifierProvider(create: (_) => MenuStore()),
        ChangeNotifierProvider(create: (_) => FavoriteStore()),
        ChangeNotifierProvider(create: (_) => ShareHistoryStore()),
      ],
      child: MaterialApp(
        title: '美食天下',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFFFD93D),  // 奶黄主色
            brightness: Brightness.light,
          ),
          scaffoldBackgroundColor: const Color(0xFFFFF8E7),  // 温暖米白背景
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            foregroundColor: Color(0xFF5D4E37),  // 暖棕色文字
            elevation: 0,
          ),
          useMaterial3: true,
        ),
        home: const AuthGate(),
      ),
    );
  }
}

/// 启动鉴权门:根据登录态决定进主页还是登录页
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});
  @override
  Widget build(BuildContext context) {
    final status = context.watch<AuthService>().status;
    switch (status) {
      case AuthStatus.unknown:
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      case AuthStatus.authenticated:
        return const MainPage();
      case AuthStatus.unauthenticated:
        return const LoginPage();
    }
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;
  int _lastNonCenterIndex = 0; // 记录上一个非中间按钮的位置

  final List<Widget> _pages = [
    const HomePage(),
    const FridgePage(),
    const MenuPage(),
    const SavedPage(),
    const ProfilePage(),
  ];

  // Tab 配置
  static const _tabWidth = 56.0;
  static const _maxBarWidth = 380.0; // 最大宽度限制

  void _onTabTap(int index) {
    if (index != 2) {
      _lastNonCenterIndex = index;
    }
    setState(() => _currentIndex = index);
  }

  // 计算滑块位置(5 等分:槽位 i 中心 = barWidth*(2i+1)/10,滑块居中对齐)
  double _getSliderPosition(double barWidth) {
    final index = _currentIndex == 2 ? _lastNonCenterIndex : _currentIndex;
    return barWidth * (2 * index + 1) / 10 - _tabWidth / 2;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: _buildBottomNavBar()
    );
  }

  Widget _buildBottomNavBar() {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        height: 70,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _maxBarWidth),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final barWidth = constraints.maxWidth;
                final sliderLeft = _getSliderPosition(barWidth);

                return Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    // 底部胶囊条(填满整个可用宽度,配合 spaceAround 均分)
                    Container(
                      width: barWidth,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFFD93D).withValues(alpha: 0.25),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          // 滑动背景指示器
                          AnimatedPositioned(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOutCubic,
                            left: sliderLeft,
                            top: 6,
                            child: AnimatedOpacity(
                              duration: const Duration(milliseconds: 200),
                              opacity: _currentIndex == 2 ? 0.0 : 1.0,
                              child: Container(
                                width: _tabWidth,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFD93D),
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFFFD93D).withValues(alpha: 0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          // Tab items
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildNavItem(0, Icons.home_rounded, 'Home'),
                              _buildNavItem(1, Icons.kitchen_rounded, 'Fridge'),
                              const SizedBox(width: _tabWidth), // 中间按钮占位
                              _buildNavItem(3, Icons.favorite_rounded, 'Saved'),
                              _buildNavItem(4, Icons.person_rounded, '我的'),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // 中间突出的圆形按钮
                    Positioned(
                      top: -15,
                      child: GestureDetector(
                        onTap: () => _onTabTap(2),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOutBack,
                          width: _currentIndex == 2 ? 68 : 62,
                          height: _currentIndex == 2 ? 68 : 62,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: _currentIndex == 2
                                ? [const Color(0xFFFFD93D), const Color(0xFFFFD93D)]
                                : [const Color(0xFFFFF0C8), const Color(0xFFFFE4A0)],
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFFD93D).withValues(alpha: _currentIndex == 2 ? 0.5 : 0.3),
                                blurRadius: _currentIndex == 2 ? 16 : 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              AnimatedScale(
                                scale: _currentIndex == 2 ? 1.1 : 1.0,
                                duration: const Duration(milliseconds: 200),
                                child: Icon(
                                  Icons.restaurant_menu_rounded,
                                  color: _currentIndex == 2
                                    ? const Color(0xFF5D4E37)
                                    : const Color(0xFF9E8E7E),
                                  size: 28,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Menu',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                  color: _currentIndex == 2
                                    ? const Color(0xFF5D4E37)
                                    : const Color(0xFF9E8E7E),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () => _onTabTap(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: _tabWidth,
        height: 60,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedScale(
              scale: isSelected ? 1.1 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : const Color(0xFFCDBBAF),
                size: 20,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFFCDBBAF),
                fontSize: 9,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.clip,
            ),
          ],
        ),
      ),
    );
  }
}
