import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:ether_music/state/app_state.dart';
import 'package:ether_music/state/player_state.dart';
import 'package:ether_music/components/song_card.dart';
import 'package:ether_music/core/local_storage_service.dart';
import 'package:ether_music/theme/glassmorphism.dart';

/// 搜索页
class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final LocalStorageService _storage = LocalStorageService();

  @override
  void initState() {
    super.initState();
    _storage.addListener(_onStorageUpdate);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _storage.removeListener(_onStorageUpdate);
    super.dispose();
  }

  void _onStorageUpdate() {
    if (mounted) setState(() {});
  }

  void _onSearch(String keywords) {
    if (keywords.trim().isNotEmpty) {
      _storage.addSearchHistory(keywords);
      ref.read(searchResultsProvider.notifier).search(keywords);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final searchResults = ref.watch(searchResultsProvider);
    final hotSearchAsync = ref.watch(hotSearchProvider);
    final currentSong = ref.watch(currentSongProvider).valueOrNull;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        slivers: [
          // 搜索栏
          SliverAppBar(
            floating: true,
            backgroundColor: theme.scaffoldBackgroundColor.withOpacity(0.9),
            toolbarHeight: 80,
            title: GlassmorphicContainer(
              borderRadius: 16,
              blur: 10,
              opacity: 0.1,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchController,
                focusNode: _focusNode,
                decoration: InputDecoration(
                  hintText: '搜索歌曲、歌手、专辑',
                  hintStyle: TextStyle(
                    color: theme.colorScheme.onSurface.withOpacity(0.4),
                  ),
                  border: InputBorder.none,
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () {
                            _searchController.clear();
                            ref.read(searchResultsProvider.notifier).clear();
                            setState(() {});
                          },
                        )
                      : null,
                ),
                onSubmitted: _onSearch,
                onChanged: (value) => setState(() {}),
                textInputAction: TextInputAction.search,
              ),
            ),
          ),

          // 搜索结果或热门搜索
          searchResults.when(
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, _) => SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      size: 64,
                      color: theme.colorScheme.error,
                    ),
                    const SizedBox(height: 16),
                    Text('搜索出错: $error'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        _onSearch(_searchController.text);
                      },
                      child: const Text('重试'),
                    ),
                  ],
                ),
              ),
            ),
            data: (songs) {
              if (songs.isEmpty && _searchController.text.isEmpty) {
                // 显示热门搜索和搜索记录
                return _buildHotSearchAndHistory(hotSearchAsync);
              }

              if (songs.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off_rounded,
                          size: 64,
                          color: theme.colorScheme.onSurface.withOpacity(0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '未找到相关结果',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index == 0) {
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                        child: Text(
                          '找到 ${songs.length} 首歌曲',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      );
                    }

                    final song = songs[index - 1];
                    final isPlaying = currentSong?.id == song.id;

                    return SongCard(
                      song: song,
                      isPlaying: isPlaying,
                      onTap: () async {
                        final engine = ref.read(audioEngineProvider);
                        await engine.setQueue(songs, startIndex: index - 1);
                      },
                      onMoreTap: () {
                        _showSongOptions(context, song);
                      },
                    ).animate().fadeIn(
                      duration: 200.ms,
                      delay: (index * 20).ms,
                    );
                  },
                  childCount: songs.length + 1,
                ),
              );
            },
          ),

          // 底部间距
          const SliverToBoxAdapter(
            child: SizedBox(height: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildHotSearchAndHistory(AsyncValue<List<String>> hotSearchAsync) {
    final theme = Theme.of(context);
    final searchHistory = _storage.searchHistory;

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 搜索记录
            if (searchHistory.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.history_rounded, color: theme.colorScheme.primary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        '搜索记录',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () {
                      _storage.clearSearchHistory();
                    },
                    child: const Text('清空'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: searchHistory.map((keyword) {
                  return GestureDetector(
                    onTap: () {
                      _searchController.text = keyword;
                      _onSearch(keyword);
                    },
                    onLongPress: () {
                      _storage.removeSearchHistory(keyword);
                    },
                    child: GlassmorphicContainer(
                      borderRadius: 20,
                      blur: 5,
                      opacity: 0.1,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(keyword, style: theme.textTheme.bodyMedium),
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: () => _storage.removeSearchHistory(keyword),
                            child: Icon(Icons.close, size: 14, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
            ],
            
            // 热门搜索
            ...hotSearchAsync.when(
              loading: () => [const Center(child: CircularProgressIndicator())],
              error: (_, __) => [const SizedBox.shrink()],
              data: (hotSearches) => [
                Row(
                  children: [
                    Icon(Icons.local_fire_department_rounded, color: Colors.orange, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      '热门搜索',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: hotSearches.asMap().entries.map((entry) {
                    final index = entry.key;
                    final keyword = entry.value;

                    return GestureDetector(
                      onTap: () {
                        _searchController.text = keyword;
                        _onSearch(keyword);
                      },
                      child: GlassmorphicContainer(
                        borderRadius: 20,
                        blur: 5,
                        opacity: 0.1,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (index < 3)
                              Container(
                                margin: const EdgeInsets.only(right: 6),
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _getRankColor(index),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ),
                            Text(keyword, style: theme.textTheme.bodyMedium),
                          ],
                        ),
                      ),
                    ).animate().fadeIn(duration: 300.ms, delay: (index * 30).ms);
                  }).toList(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getRankColor(int index) {
    switch (index) {
      case 0:
        return Colors.red;
      case 1:
        return Colors.orange;
      case 2:
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  void _showSongOptions(BuildContext context, song) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.playlist_add_rounded),
              title: const Text('添加到播放队列'),
              onTap: () {
                ref.read(audioEngineProvider).addToQueue(song);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('已添加到播放队列')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.queue_music_rounded),
              title: const Text('下一首播放'),
              onTap: () {
                ref.read(audioEngineProvider).playNext_add(song);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('将在下一首播放')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_rounded),
              title: const Text('查看歌手'),
              onTap: () {
                Navigator.pop(context);
                // TODO: 跳转歌手详情
              },
            ),
            ListTile(
              leading: const Icon(Icons.album_rounded),
              title: const Text('查看专辑'),
              onTap: () {
                Navigator.pop(context);
                // TODO: 跳转专辑详情
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
