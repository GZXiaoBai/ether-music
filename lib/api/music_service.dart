import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:ether_music/api/client.dart';
import 'package:ether_music/api/endpoints.dart';
import 'package:ether_music/api/models/song.dart';

/// 音乐 API 服务
class MusicService {
  final ApiClient _client = ApiClient();

  // ================ 搜索 ================

  /// 搜索歌曲
  Future<List<Song>> searchSongs(String keywords, {int limit = 30, int offset = 0}) async {
    final response = await _client.get(
      Endpoints.search,
      queryParameters: {
        'keywords': keywords,
        'type': 1, // 单曲
        'limit': limit,
        'offset': offset,
      },
    );

    final data = response.data;
    if (data['code'] != 200) {
      throw Exception('搜索失败: ${data['message']}');
    }

    final songs = data['result']?['songs'] as List? ?? [];
    return songs.map((s) => Song.fromJson(s as Map<String, dynamic>)).toList();
  }

  /// 获取热门搜索
  Future<List<String>> getHotSearch() async {
    final response = await _client.get(Endpoints.searchHot);

    final data = response.data;
    if (data['code'] != 200) {
      throw Exception('获取热搜失败');
    }

    final list = data['data'] as List? ?? [];
    return list.map((item) => item['searchWord'] as String).toList();
  }

  /// 获取搜索建议
  Future<List<String>> getSearchSuggestions(String keywords) async {
    final response = await _client.get(
      Endpoints.searchSuggest,
      queryParameters: {'keywords': keywords},
    );

    final data = response.data;
    if (data['code'] != 200) {
      return [];
    }

    final result = data['result'] as Map<String, dynamic>? ?? {};
    final albums = result['albums'] as List? ?? [];
    final artists = result['artists'] as List? ?? [];
    final songs = result['songs'] as List? ?? [];

    return [
      ...albums.map((a) => a['name'] as String),
      ...artists.map((a) => a['name'] as String),
      ...songs.map((s) => s['name'] as String),
    ].take(10).toList();
  }

  // ================ 歌曲 ================

  /// 获取歌曲详情
  Future<Song?> getSongDetail(int id) async {
    final response = await _client.get(
      Endpoints.songDetail,
      queryParameters: {'ids': id.toString()},
    );

    final data = response.data;
    if (data['code'] != 200) {
      throw Exception('获取歌曲详情失败');
    }

    final songs = data['songs'] as List? ?? [];
    if (songs.isEmpty) return null;

    return Song.fromJson(songs.first as Map<String, dynamic>);
  }

  /// 获取歌曲播放 URL
  /// 优先从网易云获取，失败时自动尝试 GDStudio 备用音源
  /// [songName] 和 [artistName] 用于在其他平台搜索匹配歌曲
  Future<String?> getSongUrl(
    int id, {
    String level = 'standard',
    String? songName,
    String? artistName,
  }) async {
    // 第一步：尝试从网易云获取
    final neteaseUrl = await _getNeteaseUrl(id, level: level);
    if (neteaseUrl != null && neteaseUrl.isNotEmpty) {
      return neteaseUrl;
    }
    
    // 第二步：网易云失败，尝试 GDStudio 备用音源
    debugPrint('⚠️ 网易云 URL 获取失败，尝试备用音源...');
    
    // 优先使用歌名搜索匹配（更准确）
    if (songName != null && songName.isNotEmpty) {
      final searchUrl = await _getBackupUrlBySearch(songName, artistName);
      if (searchUrl != null && searchUrl.isNotEmpty) {
        debugPrint('✅ 备用音源（搜索匹配）获取成功');
        return searchUrl;
      }
    }
    
    // 回退到 ID 直接请求
    final backupUrl = await _getBackupUrl(id);
    if (backupUrl != null && backupUrl.isNotEmpty) {
      debugPrint('✅ 备用音源获取成功');
      return backupUrl;
    }
    
    debugPrint('❌ 所有音源都无法获取');
    return null;
  }

  /// 从网易云 API 获取 URL
  /// 会检查返回的音频文件大小，过滤掉占位符音频
  Future<String?> _getNeteaseUrl(int id, {String level = 'standard'}) async {
    final levels = ['exhigh', 'higher', 'standard', 'lower'];
    
    for (final tryLevel in levels) {
      try {
        final response = await _client.get(
          Endpoints.songUrl,
          queryParameters: {
            'id': id,
            'level': tryLevel,
            // 启用多音源解锁（解灰功能）
            'unblock': 'true',
            // 使用随机中国 IP 绕过地区限制
            'randomCNIP': 'true',
            // 指定备用音源
            'source': 'qq,kuwo,kugou,migu',
          },
        );

        final data = response.data;
        if (data['code'] != 200) continue;

        final urls = data['data'] as List? ?? [];
        if (urls.isEmpty) continue;

        final urlData = urls.first;
        final url = urlData['url'] as String?;
        final size = urlData['size'] as int? ?? 0;
        
        // 过滤占位符音频：正常歌曲至少 50KB
        // 占位符音频通常只有 16KB 左右
        if (url != null && url.isNotEmpty && size > 50000) {
          debugPrint('✅ 网易云获取成功 (大小: ${(size / 1024).toStringAsFixed(1)}KB)');
          return url;
        } else if (url != null && size <= 50000) {
          debugPrint('⚠️ 网易云返回疑似占位符音频 (大小: ${(size / 1024).toStringAsFixed(1)}KB)，跳过');
        }
      } catch (e) {
        continue;
      }
    }
    return null;
  }

  /// GDStudio 备用音源 API
  static const String _gdStudioApi = 'https://music.gdstudio.xyz/api.php';
  static const String _gdStudioHostname = 'music.gdstudio.xyz';
  static const String _gdStudioVersion = '20251104'; // 版本号需定期更新
  
  // 缓存的时间戳（避免频繁请求）
  static int? _cachedTimestamp;
  static DateTime? _timestampFetchTime;

  /// 获取服务器时间戳（从 Ximalaya）
  Future<String> _getServerTimePrefix() async {
    // 如果缓存有效（5分钟内），直接使用
    if (_cachedTimestamp != null && _timestampFetchTime != null) {
      final elapsed = DateTime.now().difference(_timestampFetchTime!);
      if (elapsed.inMinutes < 5) {
        // 计算当前时间戳
        final currentTs = _cachedTimestamp! + elapsed.inMilliseconds;
        return currentTs.toString().substring(0, 9);
      }
    }
    
    try {
      final response = await Dio().get('https://www.ximalaya.com/revision/time');
      if (response.data is int) {
        _cachedTimestamp = response.data as int;
        _timestampFetchTime = DateTime.now();
        return _cachedTimestamp.toString().substring(0, 9);
      }
    } catch (e) {
      debugPrint('获取服务器时间失败: $e');
    }
    
    // 回退：使用本地时间
    return DateTime.now().millisecondsSinceEpoch.toString().substring(0, 9);
  }

  /// 计算 GDStudio API 签名（MD5 最后 8 位大写）
  Future<String> _calculateSignature(String value) async {
    final timePrefix = await _getServerTimePrefix();
    final encodedValue = _gdStudioUrlEncode(value);
    final combined = '$_gdStudioHostname|$_gdStudioVersion|$timePrefix|$encodedValue';
    final hash = md5.convert(utf8.encode(combined)).toString();
    return hash.substring(hash.length - 8).toUpperCase();
  }
  
  /// URL 编码（GDStudio 特殊编码规则）
  String _gdStudioUrlEncode(String str) {
    return Uri.encodeComponent(str)
        .replaceAll('(', '%28')
        .replaceAll(')', '%29')
        .replaceAll('*', '%2A')
        .replaceAll("'", '%27')
        .replaceAll('!', '%21');
  }

  /// 从 GDStudio API 获取备用音源 URL
  Future<String?> _getBackupUrl(int id) async {
    // 尝试多个音源平台
    final sources = ['tencent', 'kugou', 'kuwo', 'migu'];
    
    for (final source in sources) {
      try {
        final s = await _calculateSignature(id.toString());
        
        final response = await Dio().post(
          _gdStudioApi,
          options: Options(
            contentType: 'application/x-www-form-urlencoded',
          ),
          data: 'types=url&id=$id&source=$source&br=320&s=$s',
        );

        final data = response.data;
        if (data is Map && data['url'] != null) {
          final url = data['url'] as String;
          if (url.isNotEmpty && url.startsWith('http')) {
            debugPrint('✅ 从备用源 $source 获取成功');
            return url;
          }
        }
      } catch (e) {
        debugPrint('备用音源 $source 获取失败: $e');
        continue;
      }
    }
    return null;
  }

  /// 通过歌名搜索获取备用音源 URL
  Future<String?> _getBackupUrlBySearch(String songName, String? artistName) async {
    final sources = ['tencent', 'kugou', 'kuwo', 'migu'];
    final searchQuery = artistName != null ? '$songName $artistName' : songName;
    
    for (final source in sources) {
      try {
        // 1. 搜索歌曲
        final searchResult = await _searchOnPlatform(searchQuery, source);
        if (searchResult == null) continue;
        
        final songId = searchResult['id']?.toString();
        if (songId == null || songId.isEmpty) continue;
        
        // 2. 获取歌曲 URL
        final s = await _calculateSignature(songId);
        final response = await Dio().post(
          _gdStudioApi,
          options: Options(
            contentType: 'application/x-www-form-urlencoded',
          ),
          data: 'types=url&id=$songId&source=$source&br=320&s=$s',
        );

        final data = response.data;
        if (data is Map && data['url'] != null) {
          final url = data['url'] as String;
          if (url.isNotEmpty && url.startsWith('http')) {
            debugPrint('✅ 从 $source 搜索匹配成功');
            return url;
          }
        }
      } catch (e) {
        debugPrint('搜索匹配 $source 失败: $e');
        continue;
      }
    }
    return null;
  }

  /// 在指定平台搜索歌曲
  Future<Map<String, dynamic>?> _searchOnPlatform(String query, String source) async {
    try {
      final s = await _calculateSignature(query);
      final response = await Dio().post(
        _gdStudioApi,
        options: Options(
          contentType: 'application/x-www-form-urlencoded',
        ),
        data: 'types=search&count=5&source=$source&pages=1&name=${_gdStudioUrlEncode(query)}&s=$s',
      );

      final data = response.data;
      if (data is List && data.isNotEmpty) {
        return data.first as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('搜索 $source 失败: $e');
    }
    return null;
  }

  /// 检查歌曲是否可播放
  Future<bool> checkSongPlayable(int id) async {
    try {
      final response = await _client.get(
        '/check/music',
        queryParameters: {'id': id},
      );
      final data = response.data;
      return data['success'] == true;
    } catch (e) {
      return false;
    }
  }

  /// 获取歌词
  Future<String?> getLyric(int id) async {
    final response = await _client.get(
      Endpoints.lyric,
      queryParameters: {'id': id},
    );

    final data = response.data;
    if (data['code'] != 200) {
      throw Exception('获取歌词失败');
    }

    return data['lrc']?['lyric'] as String?;
  }

  /// 获取翻译歌词
  Future<String?> getTranslatedLyric(int id) async {
    final response = await _client.get(
      Endpoints.lyric,
      queryParameters: {'id': id},
    );

    final data = response.data;
    if (data['code'] != 200) {
      return null;
    }

    return data['tlyric']?['lyric'] as String?;
  }

  // ================ 推荐 ================

  /// 获取推荐歌单
  Future<List<Playlist>> getRecommendPlaylists({int limit = 10}) async {
    final response = await _client.get(
      Endpoints.recommendPlaylists,
      queryParameters: {'limit': limit},
    );

    final data = response.data;
    if (data['code'] != 200) {
      throw Exception('获取推荐歌单失败');
    }

    final playlists = data['result'] as List? ?? [];
    return playlists.map((p) => Playlist.fromJson(p as Map<String, dynamic>)).toList();
  }

  /// 获取推荐新歌
  Future<List<Song>> getNewSongs({int limit = 10}) async {
    final response = await _client.get(
      Endpoints.personalizedNewSongs,
      queryParameters: {'limit': limit},
    );

    final data = response.data;
    if (data['code'] != 200) {
      throw Exception('获取新歌推荐失败');
    }

    final songs = data['result'] as List? ?? [];
    return songs.map((s) => Song.fromJson(s['song'] as Map<String, dynamic>)).toList();
  }

  // ================ 排行榜 ================

  /// 获取所有排行榜
  Future<List<Playlist>> getToplist() async {
    final response = await _client.get(Endpoints.toplist);

    final data = response.data;
    if (data['code'] != 200) {
      throw Exception('获取排行榜失败');
    }

    final list = data['list'] as List? ?? [];
    return list.map((p) => Playlist.fromJson(p as Map<String, dynamic>)).toList();
  }

  // ================ 歌单 ================

  /// 获取歌单详情
  Future<List<Song>> getPlaylistSongs(int playlistId) async {
    final response = await _client.get(
      Endpoints.playlistDetail,
      queryParameters: {'id': playlistId},
    );

    final data = response.data;
    if (data['code'] != 200) {
      throw Exception('获取歌单详情失败');
    }

    final tracks = data['playlist']?['tracks'] as List? ?? [];
    return tracks.map((s) => Song.fromJson(s as Map<String, dynamic>)).toList();
  }

  // ================ 歌手 ================

  /// 获取歌手热门歌曲
  Future<List<Song>> getArtistTopSongs(int artistId) async {
    final response = await _client.get(
      Endpoints.artistTopSongs,
      queryParameters: {'id': artistId},
    );

    final data = response.data;
    if (data['code'] != 200) {
      throw Exception('获取歌手热门歌曲失败');
    }

    final songs = data['songs'] as List? ?? [];
    return songs.map((s) => Song.fromJson(s as Map<String, dynamic>)).toList();
  }

  /// 获取歌手详情
  Future<Artist?> getArtistDetail(int artistId) async {
    final response = await _client.get(
      Endpoints.artistDetail,
      queryParameters: {'id': artistId},
    );

    final data = response.data;
    if (data['code'] != 200) {
      throw Exception('获取歌手详情失败');
    }

    final artistData = data['data']?['artist'] as Map<String, dynamic>?;
    if (artistData == null) return null;

    return Artist.fromJson(artistData);
  }
}
