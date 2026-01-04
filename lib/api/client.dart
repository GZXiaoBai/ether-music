import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// TuneHub API 客户端
/// API 文档: https://music-dl.sayqz.com
class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late final Dio _dio;

  // TuneHub API 基础地址
  static const String baseUrl = 'https://music-dl.sayqz.com/api/';

  ApiClient._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
        // 允许重定向，TuneHub 的 url/pic 接口会重定向
        followRedirects: false,
        validateStatus: (status) => status != null && status < 400,
      ),
    );

    // 调试模式下启用日志
    if (kDebugMode) {
      _dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            debugPrint('🌐 REQUEST: ${options.uri}');
            return handler.next(options);
          },
          onResponse: (response, handler) {
            debugPrint('✅ RESPONSE [${response.statusCode}]: ${response.requestOptions.uri}');
            return handler.next(response);
          },
          onError: (error, handler) {
            debugPrint('❌ ERROR [${error.response?.statusCode}]: ${error.requestOptions.uri}');
            return handler.next(error);
          },
        ),
      );
    }
  }

  /// 获取 Dio 实例（用于直接访问）
  Dio get dio => _dio;

  /// 通用 GET 请求
  Future<Response> get({
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.get(
      '',
      queryParameters: queryParameters,
      options: options,
    );
  }

  /// 聚合搜索 - 同时搜索多个平台
  Future<Map<String, dynamic>> aggregateSearch({
    required String keyword,
    int limit = 20,
    int page = 1,
  }) async {
    final response = await get(
      queryParameters: {
        'type': 'aggregateSearch',
        'keyword': keyword,
        'limit': limit,
        'page': page,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  /// 单平台搜索
  Future<Map<String, dynamic>> search({
    required String source,
    required String keyword,
    int limit = 20,
    int page = 1,
  }) async {
    final response = await get(
      queryParameters: {
        'source': source,
        'type': 'search',
        'keyword': keyword,
        'limit': limit,
        'page': page,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  /// 获取歌曲信息
  Future<Map<String, dynamic>> getSongInfo({
    required String source,
    required String id,
  }) async {
    final response = await get(
      queryParameters: {
        'source': source,
        'id': id,
        'type': 'info',
      },
    );
    return response.data as Map<String, dynamic>;
  }

  /// 获取歌曲播放 URL（直接返回重定向地址）
  String getSongUrl({
    required String source,
    required String id,
    String br = '999k', // 尝试请求最高音质
  }) {
    return '$baseUrl?source=$source&id=$id&type=url&br=$br';
  }

  /// 获取歌曲封面 URL
  String getCoverUrl({
    required String source,
    required String id,
  }) {
    return '$baseUrl?source=$source&id=$id&type=pic';
  }

  /// 获取歌词 URL
  String getLyricUrl({
    required String source,
    required String id,
  }) {
    return '$baseUrl?source=$source&id=$id&type=lrc';
  }

  /// 获取歌词内容
  Future<String?> getLyric({
    required String source,
    required String id,
  }) async {
    try {
      final response = await _dio.get(
        '',
        queryParameters: {
          'source': source,
          'id': id,
          'type': 'lrc',
        },
        options: Options(
          responseType: ResponseType.plain,
        ),
      );
      return response.data as String?;
    } catch (e) {
      debugPrint('获取歌词失败: $e');
      return null;
    }
  }

  /// 获取排行榜列表
  Future<Map<String, dynamic>> getToplists({
    required String source,
  }) async {
    final response = await get(
      queryParameters: {
        'source': source,
        'type': 'toplists',
      },
    );
    return response.data as Map<String, dynamic>;
  }

  /// 获取排行榜详情
  Future<Map<String, dynamic>> getToplist({
    required String source,
    required String id,
  }) async {
    final response = await get(
      queryParameters: {
        'source': source,
        'id': id,
        'type': 'toplist',
      },
    );
    return response.data as Map<String, dynamic>;
  }

  /// 获取歌单详情
  Future<Map<String, dynamic>> getPlaylist({
    required String source,
    required String id,
  }) async {
    final response = await get(
      queryParameters: {
        'source': source,
        'id': id,
        'type': 'playlist',
      },
    );
    return response.data as Map<String, dynamic>;
  }
}
