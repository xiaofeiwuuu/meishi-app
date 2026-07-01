import 'dart:io';

/// 全局配置
class AppConfig {
  static const int port = 5320;

  /// 后端 API 地址。
  /// - iOS 模拟器:localhost
  /// - Android 模拟器:10.0.2.2(模拟器访问宿主机的特殊地址)
  /// - 真机调试:改成你 Mac 的局域网 IP,如 http://192.168.1.x:5320/api
  static String get apiBaseUrl {
    if (Platform.isAndroid) return 'http://10.0.2.2:$port/api';
    return 'http://localhost:$port/api';
  }

  /// 菜谱图片 CDN 前缀(后端返回相对路径时拼接)
  static const String imageBase =
      'https://cdn.jsdelivr.net/gh/xiaofeiwuuu/recipe@main';

  /// 拼完整图片 URL(已是 http 直接用)
  static String coverUrl(String? cover) {
    if (cover == null || cover.isEmpty) return '';
    if (cover.startsWith('http')) return cover;
    return '$imageBase/$cover';
  }
}
