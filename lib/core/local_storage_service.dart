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
    if (!isFavorite(song.id)) {
      _favorites.insert(0, song);
      await _saveFavorites();
      notifyListeners();
    }
  }

  /// 移除收藏
  Future<void> removeFavorite(int songId) async {
    _favorites.removeWhere((s) => s.id == songId);
    await _saveFavorites();
    notifyListeners();
  }

  /// 切换收藏状态
  Future<bool> toggleFavorite(Song song) async {
    if (isFavorite(song.id)) {
      await removeFavorite(song.id);
      return false;
    } else {
      await addFavorite(song);
      return true;
    }
  }

  /// 检查是否已收藏
  bool isFavorite(int songId) {
    return _favorites.any((s) => s.id == songId);
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
    _playHistory.removeWhere((s) => s.id == song.id);
    
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
}
