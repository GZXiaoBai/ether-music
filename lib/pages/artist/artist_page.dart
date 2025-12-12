import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:ether_music/api/models/song.dart';
import 'package:ether_music/api/music_service.dart';
import 'package:ether_music/state/player_state.dart';
import 'package:ether_music/components/song_card.dart';
import 'package:ether_music/theme/glassmorphism.dart';

/// 歌手详情页
class ArtistPage extends ConsumerStatefulWidget {
  final int artistId;
  final String? artistName;
  final String? coverUrl;

  const ArtistPage({
    super.key,
    required this.artistId,
    this.artistName,
    this.coverUrl,
  });

  @override
  ConsumerState<ArtistPage> createState() => _ArtistPageState();
}

class _ArtistPageState extends ConsumerState<ArtistPage> {
  final MusicService _musicService = MusicService();
  Artist? _artistDetail;
  List<Song> _topSongs = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadArtistData();
  }

  Future<void> _loadArtistData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final futures = await Future.wait([
        _musicService.getArtistDetail(widget.artistId),
        _musicService.getArtistTopSongs(widget.artistId),
      ]);

      if (mounted) {
        setState(() {
          _artistDetail = futures[0] as Artist?;
          _topSongs = futures[1] as List<Song>;
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
            expandedHeight: 300,
            pinned: true,
            stretch: true,
            backgroundColor: theme.scaffoldBackgroundColor,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                _artistDetail?.name ?? widget.artistName ?? '歌手',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(color: Colors.black54, blurRadius: 8),
                  ],
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // 背景图
                  if (_artistDetail?.avatarUrl != null || widget.coverUrl != null)
                    CachedNetworkImage(
                      imageUrl: _artistDetail?.avatarUrl ?? widget.coverUrl!,
                      fit: BoxFit.cover,
                    )
                  else
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            theme.colorScheme.primary,
                            theme.colorScheme.secondary,
                          ],
                        ),
                      ),
                      child: const Icon(
                        Icons.person_rounded,
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

          // 操作按钮
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: GlassmorphicButton(
                      onPressed: () {
                        if (_topSongs.isNotEmpty) {
                          ref.read(audioEngineProvider).setQueue(_topSongs);
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
                    icon: Icons.favorite_border_rounded,
                    onPressed: () {
                      // TODO: 收藏歌手
                    },
                  ),
                  const SizedBox(width: 8),
                  GlassmorphicIconButton(
                    icon: Icons.share_rounded,
                    onPressed: () {
                      // TODO: 分享
                    },
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 300.ms),
          ),

          // 热门歌曲标题
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
              child: Text(
                '热门歌曲',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
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
                      onPressed: _loadArtistData,
                      child: const Text('重试'),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final song = _topSongs[index];
                  final isPlaying = currentSong?.id == song.id;

                  return SongCard(
                    song: song,
                    index: index,
                    isPlaying: isPlaying,
                    onTap: () {
                      ref.read(audioEngineProvider).setQueue(_topSongs, startIndex: index);
                    },
                  ).animate().fadeIn(duration: 200.ms, delay: (index * 30).ms);
                },
                childCount: _topSongs.length,
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
