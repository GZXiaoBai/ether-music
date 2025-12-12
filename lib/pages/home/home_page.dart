import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:ether_music/state/app_state.dart';
import 'package:ether_music/state/player_state.dart';
import 'package:ether_music/components/song_card.dart';
import 'package:ether_music/api/models/song.dart';

/// 首页
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        slivers: [
          // AppBar
          SliverAppBar(
            floating: true,
            backgroundColor: theme.scaffoldBackgroundColor.withOpacity(0.9),
            title: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primary,
                        theme.colorScheme.secondary,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.music_note_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Ether',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings_rounded),
                onPressed: () {
                  context.push('/settings');
                },
              ),
            ],
          ),

          // 欢迎语
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getGreeting(),
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ).animate().fadeIn(duration: 500.ms).slideX(begin: -0.1),
                  const SizedBox(height: 4),
                  Text(
                    '今天想听点什么？',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ).animate().fadeIn(duration: 500.ms, delay: 100.ms),
                ],
              ),
            ),
          ),

          // 推荐歌单
          SliverToBoxAdapter(
            child: _buildSection(
              context,
              title: '推荐歌单',
              child: _RecommendPlaylists(),
            ),
          ),

          // 推荐新歌
          SliverToBoxAdapter(
            child: _buildSection(
              context,
              title: '新歌推荐',
              child: const _NewSongs(),
            ),
          ),

          // 底部间距
          const SliverToBoxAdapter(
            child: SizedBox(height: 20),
          ),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 6) return '夜深了';
    if (hour < 12) return '早上好';
    if (hour < 18) return '下午好';
    return '晚上好';
  }

  Widget _buildSection(BuildContext context, {required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  // TODO: 查看更多
                },
                child: Text(
                  '更多',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        child,
      ],
    );
  }
}

/// 推荐歌单列表
class _RecommendPlaylists extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlistsAsync = ref.watch(recommendPlaylistsProvider);

    return playlistsAsync.when(
      loading: () => SizedBox(
        height: 200,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: 4,
          itemBuilder: (_, __) => _buildPlaceholder(),
        ),
      ),
      error: (error, _) => _buildError(context, error.toString()),
      data: (playlists) => SizedBox(
        height: 200,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: playlists.length,
          itemBuilder: (context, index) {
            final playlist = playlists[index];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: PlaylistCard(
                playlist: playlist,
                onTap: () {
                  context.push(
                    '/playlist/${playlist.id}',
                    extra: {
                      'name': playlist.name,
                      'coverUrl': playlist.coverUrl,
                    },
                  );
                },
              ),
            ).animate().fadeIn(
              duration: 400.ms,
              delay: (index * 50).ms,
            ).slideY(begin: 0.2);
          },
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 150,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: 100,
            height: 14,
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context, String message) {
    return Container(
      height: 200,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: Theme.of(context).colorScheme.error,
            size: 48,
          ),
          const SizedBox(height: 8),
          Text(
            '加载失败',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 4),
          Text(
            message,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// 新歌推荐列表
class _NewSongs extends ConsumerWidget {
  const _NewSongs();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final songsAsync = ref.watch(newSongsProvider);
    final currentSong = ref.watch(currentSongProvider).valueOrNull;

    return songsAsync.when(
      loading: () => Column(
        children: List.generate(
          5,
          (_) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: _buildSongPlaceholder(),
          ),
        ),
      ),
      error: (error, _) => Padding(
        padding: const EdgeInsets.all(20),
        child: Text('加载失败: $error'),
      ),
      data: (songs) => Column(
        children: songs.asMap().entries.map((entry) {
          final index = entry.key;
          final song = entry.value;
          final isPlaying = currentSong?.id == song.id;

          return SongCard(
            song: song,
            index: index,
            isPlaying: isPlaying,
            onTap: () async {
              final engine = ref.read(audioEngineProvider);
              await engine.setQueue(songs, startIndex: index);
            },
          ).animate().fadeIn(
            duration: 300.ms,
            delay: (index * 30).ms,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSongPlaceholder() {
    return Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: Colors.grey[800],
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                height: 14,
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: 150,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
