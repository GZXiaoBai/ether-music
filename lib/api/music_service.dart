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
  /// 会尝试多种音质级别，并启用多音源解锁（QQ/酷狗/酷我/咪咕）
  Future<String?> getSongUrl(int id, {String level = 'standard'}) async {
    // 尝试的音质级别列表（从高到低）
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

        final url = urls.first['url'] as String?;
        if (url != null && url.isNotEmpty) {
          return url;
        }
      } catch (e) {
        // 继续尝试下一个音质级别
        continue;
      }
    }
    
    // 所有音质级别都失败，返回 null
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
