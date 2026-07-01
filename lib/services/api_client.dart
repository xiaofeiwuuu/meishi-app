import 'package:dio/dio.dart';
import '../config.dart';
import 'token_store.dart';

/// 业务异常(携带后端 message)
class ApiException implements Exception {
  final String message;
  final int? status;
  ApiException(this.message, [this.status]);
  @override
  String toString() => message;
}

/// 统一 API 客户端:自动带 token、解包 {code,data,message}、401 自动刷新
class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  /// 刷新也失败 → session 失效回调(App 跳登录)
  static void Function()? onSessionExpired;

  late final Dio _dio = _build();

  Dio _build() {
    final dio = Dio(BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
    ));
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        if (TokenStore.hasToken) {
          options.headers['Authorization'] = 'Bearer ${TokenStore.accessToken}';
        }
        handler.next(options);
      },
      onResponse: (response, handler) {
        final body = response.data;
        if (body is Map && body['code'] == 0) {
          response.data = body['data'];
          handler.next(response);
        } else {
          final msg = (body is Map ? body['message'] : null) ?? '请求失败';
          handler.reject(DioException(
            requestOptions: response.requestOptions,
            response: response,
            error: ApiException(msg.toString()),
          ));
        }
      },
      onError: (e, handler) async {
        final is401 = e.response?.statusCode == 401;
        final isRefresh = e.requestOptions.path.contains('/auth/refresh');
        if (is401 &&
            !isRefresh &&
            TokenStore.refreshToken != null &&
            e.requestOptions.extra['retried'] != true) {
          if (await _refresh()) {
            try {
              final opts = e.requestOptions;
              opts.extra['retried'] = true;
              opts.headers['Authorization'] = 'Bearer ${TokenStore.accessToken}';
              return handler.resolve(await _dio.fetch(opts));
            } catch (_) {/* 落到下面 */}
          }
          await TokenStore.clear();
          onSessionExpired?.call();
        }
        if (e.error is ApiException) return handler.reject(e);
        final body = e.response?.data;
        final msg = (body is Map ? body['message'] : null) ?? e.message ?? '网络错误';
        handler.reject(DioException(
          requestOptions: e.requestOptions,
          response: e.response,
          error: ApiException(msg.toString(), e.response?.statusCode),
        ));
      },
    ));
    return dio;
  }

  Future<bool> _refresh() async {
    try {
      final plain = Dio(BaseOptions(baseUrl: AppConfig.apiBaseUrl));
      final r = await plain.post('/app/auth/refresh',
          data: {'refreshToken': TokenStore.refreshToken});
      final data = r.data is Map ? r.data['data'] : null;
      if (data is Map && data['accessToken'] != null) {
        await TokenStore.save(
          data['accessToken'] as String,
          (data['refreshToken'] ?? TokenStore.refreshToken) as String,
        );
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) async =>
      (await _dio.get(path, queryParameters: query)).data;

  Future<dynamic> post(String path, {Object? data}) async =>
      (await _dio.post(path, data: data)).data;

  Future<dynamic> put(String path, {Object? data}) async =>
      (await _dio.put(path, data: data)).data;

  Future<dynamic> delete(String path,
          {Object? data, Map<String, dynamic>? query}) async =>
      (await _dio.delete(path, data: data, queryParameters: query)).data;
}
