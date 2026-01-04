import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:ether_music/api/models/song.dart';
import 'package:ether_music/api/music_service.dart';
import 'package:ether_music/state/player_state.dart';
import 'package:ether_music/theme/app_theme.dart';
import 'package:ether_music/core/local_storage_service.dart';
import 'package:ether_music/core/audio_engine.dart';
import 'package:ether_music/components/desktop_song_row.dart';

/// 歌手详情页 (Desktop Layout Style)
class ArtistPage extends ConsumerStatefulWidget {
  final String artistName;
  final String? coverUrl;

  const ArtistPage({
    super.key,
    required this.artistName,
    this.coverUrl,
  });

  @override
  ConsumerState<ArtistPage> createState() => _ArtistPageState();
}

class _ArtistPageState extends ConsumerState<ArtistPage> {
  final MusicService _musicService = MusicService();
  List<Song> _songs = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadArtistSongs();
  }

  Future<void> _loadArtistSongs() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final songs = await _musicService.searchSongs(widget.artistName, limit: 50);
      
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
      backgroundColor: Colors.transparent, // 透出 Aurora 背景
      body: CustomScrollView(
        slivers: [
          // 头部信息区 (保持与 PlaylistPage 一致的视觉风格)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   // 歌手头像 (圆形或圆角矩形，这里选圆角矩形以保持一致，但歌手通常是圆形? 不，Apple Music 桌面版歌手页头图是圆形的)
                   // 我们用圆形来区分歌手和歌单。
                  Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: widget.coverUrl != null
                          ? CachedNetworkImage(
                              imageUrl: widget.coverUrl!,
                              fit: BoxFit.cover,
                            )
                          : Container(
                              color: theme.colorScheme.surfaceContainerHighest,
                              child: const Icon(Icons.person_rounded, size: 80),
                            ),
                    ),
                  ),
                  const SizedBox(width: 32),
                  
                  // 信息
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.appleMusicRed.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '歌手 Artist',
                            style: TextStyle(
                              color: AppTheme.appleMusicRed,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          widget.artistName,
                          style: theme.textTheme.displaySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '热门歌曲 · ${_songs.length} 首',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(height: 24),
                        // 操作按钮
                        Row(
                          children: [
                            ElevatedButton.icon(
                              onPressed: _songs.isEmpty ? null : () {
                                ref.read(audioEngineProvider).setQueue(_songs);
                              },
                              icon: const Icon(Icons.play_arrow_rounded, color: Colors.white),
                              label: const Text('播放热门歌曲', style: TextStyle(color: Colors.white)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.appleMusicRed,
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                              ),
                            ),
                            const SizedBox(width: 16),
                            OutlinedButton.icon(
                              onPressed: () {}, 
                              icon: const Icon(Icons.favorite_border_rounded),
                              label: const Text('关注'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 表格头
          if (_songs.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
                child: Row(
                  children: [
                    const SizedBox(width: 50),
                    const SizedBox(width: 56),
                    Expanded(flex: 4, child: Text('标题', style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.5)))),
                    Expanded(flex: 3, child: Text('专辑', style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.5)))), // 歌手页不需要显示歌手列
                    SizedBox(width: 60, child: Text('时长', style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.5)), textAlign: TextAlign.right)),
                  ],
                ),
              ),
            ),
             SliverToBoxAdapter(
               child: Padding(
                 padding: const EdgeInsets.symmetric(horizontal: 32),
                 child: Divider(color: theme.colorScheme.onSurface.withValues(alpha: 0.1)),
               ),
             ),

          // 歌曲列表
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            SliverFillRemaining(
              child: Center(child: Text('加载失败: $_error')),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final song = _songs[index];
                  final isPlaying = currentSong?.id == song.id;
                  
                  return DesktopSongRow(
                    index: index + 1,
                    song: song,
                    isPlaying: isPlaying,
                    onTap: () {
                      ref.read(audioEngineProvider).setQueue(_songs, startIndex: index);
                    },
                    // 歌手页不需要显示歌手名列，我们可以自定义 trailing 或者只是不管它
                    // DesktopSongRow 默认显示歌手。
                    // 我们可以不用 customTrailing，默认显示就好，虽然有点冗余但也无伤大雅。
                  );
                },
                childCount: _songs.length,
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }
}
