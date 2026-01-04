import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:ether_music/api/client.dart';
import 'package:ether_music/api/models/song.dart';

/// 音乐服务 - 使用 TuneHub API
class MusicService {
  final ApiClient _client = ApiClient();

  // ================ 搜索 ================

  /// 聚合搜索歌曲（同时搜索网易云、QQ、酷我）
  Future<List<Song>> searchSongs(String keyword, {int limit = 20, int page = 1}) async {
    try {
      final response = await _client.aggregateSearch(
        keyword: keyword,
        limit: limit,
        page: page,
      );

      if (response['code'] != 200) {
        throw Exception('搜索失败: ${response['message']}');
      }

      final results = response['data']?['results'] as List? ?? [];
      return results.map((s) => Song.fromTuneHub(s as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('搜索失败: $e');
      rethrow;
    }
  }

  /// 单平台搜索
  Future<List<Song>> searchOnPlatform(
    String keyword, {
    String source = 'netease',
    int limit = 20,
    int page = 1,
  }) async {
    try {
      final response = await _client.search(
        source: source,
        keyword: keyword,
        limit: limit,
        page: page,
      );

      if (response['code'] != 200) {
        throw Exception('搜索失败: ${response['message']}');
      }

      final results = response['data']?['results'] as List? ?? [];
      return results.map((s) => Song.fromTuneHub(s as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('平台搜索失败: $e');
      rethrow;
    }
  }

  // ================ 歌曲 URL ================

  /// 获取歌曲播放 URL
  /// TuneHub 的 URL 接口直接重定向到真实地址
  String getSongUrl(Song song, {String br = '999k'}) {
    return _client.getSongUrl(
      source: song.platform,
      id: song.id,
      br: br,
    );
  }

  /// 异步获取歌曲播放 URL（跟随重定向）
  Future<String?> getSongUrlAsync(Song song, {String br = '999k'}) async {
    try {
      final url = getSongUrl(song, br: br);
      final response = await _client.dio.head(
        url,
        options: Options(
          followRedirects: true,
          validateStatus: (status) => status != null && status < 400,
        ),
      );
      
      // 返回最终重定向后的 URL
      final redirects = response.redirects;
      if (redirects.isNotEmpty) {
        return redirects.last.location.toString();
      }
      return url;
    } catch (e) {
      debugPrint('获取歌曲 URL 失败: $e');
      // 直接返回原始 URL，让播放器处理重定向
      return getSongUrl(song, br: br);
    }
  }

  // ================ 封面和歌词 ================

  /// 获取歌曲封面 URL
  String getCoverUrl(Song song) {
    // 如果已有封面 URL，直接使用
    if (song.coverUrl != null && song.coverUrl!.isNotEmpty) {
      return song.coverUrl!;
    }
    return _client.getCoverUrl(source: song.platform, id: song.id);
  }

  /// 获取歌词
  Future<List<LyricLine>> getLyrics(Song song) async {
    try {
      final content = await _client.getLyric(
        source: song.platform,
        id: song.id,
      );
      
      if (content == null || content.isEmpty) {
        return [];
      }
      
      return parseLrc(content);
    } catch (e) {
      debugPrint('获取歌词失败: $e');
      return [];
    }
  }

  /// 获取原始歌词文本
  Future<String?> getLyricText(Song song) async {
    return await _client.getLyric(
      source: song.platform,
      id: song.id,
    );
  }

  // ================ 排行榜 ================

  /// 获取所有排行榜
  Future<List<Toplist>> getToplists({String source = 'netease'}) async {
    try {
      final response = await _client.getToplists(source: source);

      if (response['code'] != 200) {
        throw Exception('获取排行榜失败: ${response['message']}');
      }

      final list = response['data']?['list'] as List? ?? [];
      return list.map((t) => Toplist.fromTuneHub(t as Map<String, dynamic>, source)).toList();
    } catch (e) {
      debugPrint('获取排行榜失败: $e');
      rethrow;
    }
  }

  /// 获取排行榜歌曲
  Future<List<Song>> getToplistSongs(Toplist toplist) async {
    try {
      final response = await _client.getToplist(
        source: toplist.source,
        id: toplist.id,
      );

      if (response['code'] != 200) {
        throw Exception('获取排行榜歌曲失败: ${response['message']}');
      }

      final songs = response['data']?['list'] as List? ?? [];
      return songs.map((s) => Song.fromTuneHub(s as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('获取排行榜歌曲失败: $e');
      rethrow;
    }
  }

  // ================ 歌单 ================

  /// 获取歌单歌曲
  Future<List<Song>> getPlaylistSongs(String playlistId, {String source = 'netease'}) async {
    try {
      final response = await _client.getPlaylist(
        source: source,
        id: playlistId,
      );

      if (response['code'] != 200) {
        throw Exception('获取歌单失败: ${response['message']}');
      }

      final songs = response['data']?['list'] as List? ?? [];
      return songs.map((s) => Song.fromTuneHub(s as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('获取歌单歌曲失败: $e');
      rethrow;
    }
  }

  // ================ 热门推荐 ================

  /// 获取热门排行榜（用于首页推荐）
  Future<List<Toplist>> getHotToplists() async {
    final toplists = await getToplists(source: 'netease');
    // 返回前 6 个排行榜
    return toplists.take(6).toList();
  }

  /// 获取热门歌曲（从飙升榜获取）
  Future<List<Song>> getHotSongs({int limit = 10}) async {
    try {
      final toplists = await getToplists(source: 'netease');
      if (toplists.isEmpty) return [];
      
      // 使用第一个排行榜（通常是飙升榜或热歌榜）
      final hotSongs = await getToplistSongs(toplists.first);
      return hotSongs.take(limit).toList();
    } catch (e) {
      debugPrint('获取热门歌曲失败: $e');
      return [];
    }
  }
}
