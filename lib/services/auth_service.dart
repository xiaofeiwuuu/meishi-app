import 'package:flutter/foundation.dart';
import 'api_client.dart';
import 'token_store.dart';

class AppUser {
  final String id;
  final String email;
  final String nickname;
  final String avatar;
  AppUser({required this.id, required this.email, required this.nickname, required this.avatar});

  factory AppUser.fromJson(Map<String, dynamic> j) => AppUser(
        id: j['id']?.toString() ?? '',
        email: j['email'] ?? '',
        nickname: j['nickname'] ?? '',
        avatar: j['avatar'] ?? '',
      );
}

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthService extends ChangeNotifier {
  final _api = ApiClient.instance;

  AuthStatus status = AuthStatus.unknown;
  AppUser? user;

  AuthService() {
    // refresh 也失败时,统一登出
    ApiClient.onSessionExpired = _setLoggedOut;
  }

  bool get isAuthenticated => status == AuthStatus.authenticated;

  /// 启动:有 token 就拉 /app/me 验证
  Future<void> init() async {
    await TokenStore.load();
    if (!TokenStore.hasToken) {
      status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }
    try {
      final data = await _api.get('/app/me');
      user = AppUser.fromJson(Map<String, dynamic>.from(data));
      status = AuthStatus.authenticated;
    } catch (_) {
      await TokenStore.clear();
      status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<void> register(String email, String password, String nickname) =>
      _api.post('/app/auth/register',
          data: {'email': email, 'password': password, 'nickname': nickname});

  Future<void> resendCode(String email) =>
      _api.post('/app/auth/resend-code', data: {'email': email});

  Future<void> verifyEmail(String email, String code) async {
    final data = await _api.post('/app/auth/verify-email',
        data: {'email': email, 'code': code});
    await _applyAuth(Map<String, dynamic>.from(data));
  }

  Future<void> login(String email, String password) async {
    final data = await _api.post('/app/auth/login',
        data: {'email': email, 'password': password});
    await _applyAuth(Map<String, dynamic>.from(data));
  }

  Future<void> forgotPassword(String email) =>
      _api.post('/app/auth/forgot-password', data: {'email': email});

  Future<void> resetPassword(String email, String code, String password) =>
      _api.post('/app/auth/reset-password',
          data: {'email': email, 'code': code, 'password': password});

  Future<void> logout() async {
    await TokenStore.clear();
    _setLoggedOut();
  }

  Future<void> _applyAuth(Map<String, dynamic> data) async {
    await TokenStore.save(
      data['accessToken'] as String,
      data['refreshToken'] as String,
    );
    user = AppUser.fromJson(Map<String, dynamic>.from(data['user']));
    status = AuthStatus.authenticated;
    notifyListeners();
  }

  void _setLoggedOut() {
    user = null;
    status = AuthStatus.unauthenticated;
    notifyListeners();
  }
}
