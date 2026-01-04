import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ether_music/api/models/song.dart';

/// 本地存储服务 - 收藏、搜索记录等
class LocalStorageService extends ChangeNotifier {
  static final LocalStorageService _instance = LocalStorageService._internal();
  factory LocalStorageService() => _instance;
  LocalStorageService._internal();

  SharedPreferences? _prefs;
  
  // 收藏歌曲
  List<Song> _favorites = [];
  List<Song> get favorites => List.unmodifiable(_favorites);
  
  // 搜索记录
  List<String> _searchHistory = [];
  List<String> get searchHistory => List.unmodifiable(_searchHistory);
  
  // 最大搜索记录数
  static const int _maxSearchHistory = 20;

  /// 初始化
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadFavorites();
    await _loadSearchHistory();
    await _loadCustomPlaylists();
  }

  // ==================== 收藏功能 ====================

  /// 加载收藏
  Future<void> _loadFavorites() async {
    final json = _prefs?.getString('favorites');
    if (json != null) {
      try {
        final List<dynamic> list = jsonDecode(json);
        _favorites = list.map((e) => Song.fromJson(e)).toList();
      } catch (e) {
        _favorites = [];
      }
    }
  }

  /// 保存收藏
  Future<void> _saveFavorites() async {
    final json = jsonEncode(_favorites.map((s) => s.toJson()).toList());
    await _prefs?.setString('favorites', json);
  }

  /// 添加收藏
  Future<void> addFavorite(Song song) async {
    final key = '${song.platform}_${song.id}';
    if (!_favorites.any((s) => '${s.platform}_${s.id}' == key)) {
      _favorites.insert(0, song);
      await _saveFavorites();
      notifyListeners();
    }
  }

  /// 移除收藏
  Future<void> removeFavorite(String platform, String songId) async {
    final key = '${platform}_$songId';
    _favorites.removeWhere((s) => '${s.platform}_${s.id}' == key);
    await _saveFavorites();
    notifyListeners();
  }

  /// 切换收藏状态
  Future<bool> toggleFavorite(Song song) async {
    if (isFavorite(song)) {
      await removeFavorite(song.platform, song.id);
      return false;
    } else {
      await addFavorite(song);
      return true;
    }
  }

  /// 检查是否已收藏
  bool isFavorite(Song song) {
    final key = '${song.platform}_${song.id}';
    return _favorites.any((s) => '${s.platform}_${s.id}' == key);
  }

  // ==================== 搜索记录 ====================

  /// 加载搜索记录
  Future<void> _loadSearchHistory() async {
    final list = _prefs?.getStringList('searchHistory');
    if (list != null) {
      _searchHistory = list;
    }
  }

  /// 保存搜索记录
  Future<void> _saveSearchHistory() async {
    await _prefs?.setStringList('searchHistory', _searchHistory);
  }

  /// 添加搜索记录
  Future<void> addSearchHistory(String keyword) async {
    if (keyword.trim().isEmpty) return;
    
    // 移除重复项
    _searchHistory.remove(keyword);
    
    // 添加到开头
    _searchHistory.insert(0, keyword);
    
    // 限制数量
    if (_searchHistory.length > _maxSearchHistory) {
      _searchHistory = _searchHistory.sublist(0, _maxSearchHistory);
    }
    
    await _saveSearchHistory();
    notifyListeners();
  }

  /// 删除单条搜索记录
  Future<void> removeSearchHistory(String keyword) async {
    _searchHistory.remove(keyword);
    await _saveSearchHistory();
    notifyListeners();
  }

  /// 清空搜索记录
  Future<void> clearSearchHistory() async {
    _searchHistory.clear();
    await _saveSearchHistory();
    notifyListeners();
  }

  // ==================== 播放历史 ====================
  
  List<Song> _playHistory = [];
  List<Song> get playHistory => List.unmodifiable(_playHistory);
  
  /// 加载播放历史
  Future<void> _loadPlayHistory() async {
    final json = _prefs?.getString('playHistory');
    if (json != null) {
      try {
        final List<dynamic> list = jsonDecode(json);
        _playHistory = list.map((e) => Song.fromJson(e)).toList();
      } catch (e) {
        _playHistory = [];
      }
    }
  }

  /// 添加到播放历史
  Future<void> addToPlayHistory(Song song) async {
    // 移除重复项
    final key = '${song.platform}_${song.id}';
    _playHistory.removeWhere((s) => '${s.platform}_${s.id}' == key);
    
    // 添加到开头
    _playHistory.insert(0, song);
    
    // 限制数量
    if (_playHistory.length > 100) {
      _playHistory = _playHistory.sublist(0, 100);
    }
    
    final json = jsonEncode(_playHistory.map((s) => s.toJson()).toList());
    await _prefs?.setString('playHistory', json);
    notifyListeners();
  }

  /// 清空播放历史
  Future<void> clearPlayHistory() async {
    _playHistory.clear();
    await _prefs?.remove('playHistory');
    notifyListeners();
  }
  // ==================== 自建歌单 ====================

  List<Playlist> _customPlaylists = [];
  List<Playlist> get customPlaylists => List.unmodifiable(_customPlaylists);
  
  Map<String, List<Song>> _playlistSongs = {};

  /// 加载自建歌单
  Future<void> _loadCustomPlaylists() async {
    final json = _prefs?.getString('custom_playlists');
    if (json != null) {
      try {
        final List<dynamic> list = jsonDecode(json);
        _customPlaylists = list.map((e) => Playlist.fromJson(e)).toList();
      } catch (e) {
        _customPlaylists = [];
      }
    }
    
    // 加载每个歌单的歌曲
    for (final playlist in _customPlaylists) {
      final songJson = _prefs?.getString('playlist_songs_${playlist.id}');
      if (songJson != null) {
         try {
           final List<dynamic> list = jsonDecode(songJson);
           _playlistSongs[playlist.id] = list.map((e) => Song.fromJson(e)).toList();
         } catch(e) {
           _playlistSongs[playlist.id] = [];
         }
      } else {
        _playlistSongs[playlist.id] = [];
      }
    }
  }

  /// 保存歌单列表
  Future<void> _saveCustomPlaylists() async {
    final json = jsonEncode(_customPlaylists.map((p) => {
      'id': p.id,
      'name': p.name,
      'coverUrl': p.coverUrl,
      'description': p.description,
      'trackCount': p.trackCount,
      'source': 'local',
      'creator': {'nickname': '我'},
    }).toList());
    await _prefs?.setString('custom_playlists', json);
  }

  /// 保存特定歌单的歌曲
  Future<void> _savePlaylistSongs(String playlistId) async {
    final songs = _playlistSongs[playlistId] ?? [];
    final json = jsonEncode(songs.map((s) => s.toJson()).toList());
    await _prefs?.setString('playlist_songs_$playlistId', json);
  }

  /// 创建歌单
  Future<String> createPlaylist(String name) async {
    final id = 'local_${DateTime.now().millisecondsSinceEpoch}';
    final playlist = Playlist(
      id: id,
      name: name,
      source: 'local',
      creatorName: '我',
      trackCount: 0,
      coverUrl: null, // 可以后续添加封面
    );
    
    _customPlaylists.insert(0, playlist);
    _playlistSongs[id] = [];
    
    await _saveCustomPlaylists();
    notifyListeners();
    return id;
  }

  /// 删除歌单
  Future<void> deletePlaylist(String id) async {
    _customPlaylists.removeWhere((p) => p.id == id);
    _playlistSongs.remove(id);
    await _prefs?.remove('playlist_songs_$id');
    await _saveCustomPlaylists();
    notifyListeners();
  }
  
  /// 获取歌单歌曲
  List<Song> getPlaylistSongs(String playlistId) {
    return _playlistSongs[playlistId] ?? [];
  }

  /// 添加歌曲到歌单
  Future<void> addSongToPlaylist(String playlistId, Song song) async {
    if (!_playlistSongs.containsKey(playlistId)) return;
    
    final songs = _playlistSongs[playlistId]!;
    // 检查重复
    if (songs.any((s) => s.id == song.id && s.platform == song.platform)) return;
    
    songs.add(song);
    
    // 更新歌单 trackCount
    final index = _customPlaylists.indexWhere((p) => p.id == playlistId);
    if (index != -1) {
      final old = _customPlaylists[index];
      _customPlaylists[index] = Playlist(
        id: old.id, 
        name: old.name, 
        source: old.source, 
        coverUrl: song.coverUrl ?? old.coverUrl, // 使用第一首歌的封面
        trackCount: songs.length,
        creatorName: old.creatorName,
        description: old.description
      );
    }
    
    await _savePlaylistSongs(playlistId);
    await _saveCustomPlaylists();
    notifyListeners();
  }
}
