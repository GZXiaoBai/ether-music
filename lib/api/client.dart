import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

/// API 客户端封装
class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late final Dio _dio;
  final Logger _logger = Logger();

  // API 基础地址 - 使用部署在 Vercel 的 NeteaseCloudMusicApiEnhanced
  static const String defaultBaseUrl = 'https://api-enhanced-sandy-nu.vercel.app';
  String _baseUrl = defaultBaseUrl;

  String get baseUrl => _baseUrl;

  set baseUrl(String url) {
    _baseUrl = url;
    _dio.options.baseUrl = url;
  }

  ApiClient._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
        },
      ),
    );

    // 添加日志拦截器
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          _logger.d('REQUEST[${options.method}] => PATH: ${options.path}');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          _logger.d(
              'RESPONSE[${response.statusCode}] => PATH: ${response.requestOptions.path}');
          return handler.next(response);
        },
        onError: (error, handler) {
          _logger.e(
              'ERROR[${error.response?.statusCode}] => PATH: ${error.requestOptions.path}');
          return handler.next(error);
        },
      ),
    );
  }

  /// GET 请求
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
      );
    } catch (e) {
      _logger.e('GET request failed: $e');
      rethrow;
    }
  }

  /// POST 请求
  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } catch (e) {
      _logger.e('POST request failed: $e');
      rethrow;
    }
  }

  /// 设置 Cookie（用于登录状态）
  void setCookie(String cookie) {
    _dio.options.headers['Cookie'] = cookie;
  }

  /// 清除 Cookie
  void clearCookie() {
    _dio.options.headers.remove('Cookie');
  }
}
