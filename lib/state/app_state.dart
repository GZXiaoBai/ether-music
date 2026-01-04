import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ether_music/api/music_service.dart';
import 'package:ether_music/api/models/song.dart';

/// 音乐服务 Provider
final musicServiceProvider = Provider<MusicService>((ref) {
  return MusicService();
});

/// 应用主题模式 Provider
final themeModeProvider = StateProvider<ThemeMode>((ref) {
  return ThemeMode.dark;
});

/// 搜索结果 Provider
final searchResultsProvider = StateNotifierProvider<SearchNotifier, AsyncValue<List<Song>>>((ref) {
  return SearchNotifier(ref);
});

class SearchNotifier extends StateNotifier<AsyncValue<List<Song>>> {
  final Ref _ref;

  SearchNotifier(this._ref) : super(const AsyncValue.data([]));

  Future<void> search(String keywords) async {
    if (keywords.trim().isEmpty) {
      state = const AsyncValue.data([]);
      return;
    }

    state = const AsyncValue.loading();

    try {
      final service = _ref.read(musicServiceProvider);
      final results = await service.searchSongs(keywords);
      state = AsyncValue.data(results);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void clear() {
    state = const AsyncValue.data([]);
  }
}

/// 热门排行榜 Provider
final hotToplistsProvider = FutureProvider<List<Toplist>>((ref) async {
  final service = ref.read(musicServiceProvider);
  return service.getHotToplists();
});

/// 热门歌曲 Provider
final hotSongsProvider = FutureProvider<List<Song>>((ref) async {
  final service = ref.read(musicServiceProvider);
  return service.getHotSongs(limit: 20);
});

/// Theme Mode 枚举
enum ThemeMode { light, dark, system }
