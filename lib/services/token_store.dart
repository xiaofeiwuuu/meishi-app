import 'package:shared_preferences/shared_preferences.dart';

/// 本地 token 存储(开发期用 SharedPreferences;上线可换 flutter_secure_storage 更安全)
class TokenStore {
  static const _kAccess = 'access_token';
  static const _kRefresh = 'refresh_token';

  static String? _access;
  static String? _refresh;

  static String? get accessToken => _access;
  static String? get refreshToken => _refresh;
  static bool get hasToken => _access != null && _access!.isNotEmpty;

  /// 启动时载入
  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _access = prefs.getString(_kAccess);
    _refresh = prefs.getString(_kRefresh);
  }

  static Future<void> save(String access, String refresh) async {
    _access = access;
    _refresh = refresh;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kAccess, access);
    await prefs.setString(_kRefresh, refresh);
  }

  static Future<void> setAccess(String access) async {
    _access = access;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kAccess, access);
  }

  static Future<void> clear() async {
    _access = null;
    _refresh = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kAccess);
    await prefs.remove(_kRefresh);
  }
}
