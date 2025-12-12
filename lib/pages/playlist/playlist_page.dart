import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:ether_music/api/models/song.dart';
import 'package:ether_music/api/music_service.dart';
import 'package:ether_music/state/player_state.dart';
import 'package:ether_music/components/song_card.dart';
import 'package:ether_music/theme/glassmorphism.dart';

/// 歌单详情页
class PlaylistPage extends ConsumerStatefulWidget {
  final int playlistId;
  final String? playlistName;
  final String? coverUrl;

  const PlaylistPage({
    super.key,
    required this.playlistId,
    this.playlistName,
    this.coverUrl,
  });

  @override
  ConsumerState<PlaylistPage> createState() => _PlaylistPageState();
}

class _PlaylistPageState extends ConsumerState<PlaylistPage> {
  final MusicService _musicService = MusicService();
  List<Song> _songs = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPlaylistData();
  }

  Future<void> _loadPlaylistData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final songs = await _musicService.getPlaylistSongs(widget.playlistId);
      if (mounted) {
        setState(() {
          _songs = songs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentSong = ref.watch(currentSongProvider).valueOrNull;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // 头部
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            stretch: true,
            backgroundColor: theme.scaffoldBackgroundColor,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.playlistName ?? '歌单',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  shadows: [
                    Shadow(color: Colors.black54, blurRadius: 8),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // 封面图
                  if (widget.coverUrl != null)
                    CachedNetworkImage(
                      imageUrl: widget.coverUrl!,
                      fit: BoxFit.cover,
                    )
                  else
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            theme.colorScheme.primary,
                            theme.colorScheme.secondary,
                          ],
                        ),
                      ),
                      child: const Icon(
                        Icons.queue_music_rounded,
                        size: 100,
                        color: Colors.white54,
                      ),
                    ),
                  // 渐变遮罩
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          theme.scaffoldBackgroundColor.withOpacity(0.8),
                          theme.scaffoldBackgroundColor,
                        ],
                        stops: const [0.0, 0.7, 1.0],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 歌曲数量和操作按钮
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!_isLoading)
                    Text(
                      '${_songs.length} 首歌曲',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: GlassmorphicButton(
                          onPressed: () {
                            if (_songs.isNotEmpty) {
                              ref.read(audioEngineProvider).setQueue(_songs);
                            }
                          },
                          borderRadius: 12,
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.play_arrow_rounded, color: Colors.white),
                              SizedBox(width: 8),
                              Text('播放全部', style: TextStyle(color: Colors.white)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      GlassmorphicIconButton(
                        icon: Icons.shuffle_rounded,
                        onPressed: () {
                          if (_songs.isNotEmpty) {
                            final shuffled = List<Song>.from(_songs)..shuffle();
                            ref.read(audioEngineProvider).setQueue(shuffled);
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                      GlassmorphicIconButton(
                        icon: Icons.favorite_border_rounded,
                        onPressed: () {
                          // TODO: 收藏歌单
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 300.ms),
          ),

          // 歌曲列表
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
                    const SizedBox(height: 16),
                    Text('加载失败: $_error'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadPlaylistData,
                      child: const Text('重试'),
                    ),
                  ],
                ),
              ),
            )
          else if (_songs.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.music_off_rounded,
                      size: 64,
                      color: theme.colorScheme.onSurface.withOpacity(0.3),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '歌单是空的',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final song = _songs[index];
                  final isPlaying = currentSong?.id == song.id;

                  return SongCard(
                    song: song,
                    index: index,
                    isPlaying: isPlaying,
                    onTap: () {
                      ref.read(audioEngineProvider).setQueue(_songs, startIndex: index);
                    },
                  ).animate().fadeIn(duration: 200.ms, delay: (index * 20).ms);
                },
                childCount: _songs.length,
              ),
            ),

          // 底部间距
          const SliverToBoxAdapter(
            child: SizedBox(height: 100),
          ),
        ],
      ),
    );
  }
}
