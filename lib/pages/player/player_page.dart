import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import 'package:ether_music/state/player_state.dart';
import 'package:ether_music/core/audio_engine.dart';
import 'package:ether_music/core/color_extractor.dart';
import 'package:ether_music/core/local_storage_service.dart';
import 'package:ether_music/api/music_service.dart';
import 'package:ether_music/api/models/song.dart';
import 'package:ether_music/theme/app_theme.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

/// 桌面端分栏风格全屏播放器
class PlayerPage extends ConsumerStatefulWidget {
  const PlayerPage({super.key});

  @override
  ConsumerState<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends ConsumerState<PlayerPage>
    with SingleTickerProviderStateMixin {
  Color? _dominantColor;
  bool _isDragging = false;
  double _dragValue = 0.0;
  
  final ItemScrollController _lyricsController = ItemScrollController();
  final ItemPositionsListener _lyricsListener = ItemPositionsListener.create();
  List<LyricLine> _lyrics = [];
  int _currentLyricIndex = 0;
  bool _hasLyrics = false;
  bool _isLoadingLyrics = true;

  @override
  void initState() {
    super.initState();
    _updateColors();
    _loadLyrics();
  }

  Future<void> _updateColors() async {
    final song = ref.read(audioEngineProvider).currentSong;
    if (song?.coverUrl != null) {
      final scheme = await ColorExtractor.extractFromUrl(song!.coverUrl!);
      if (mounted && scheme != null) {
        setState(() => _dominantColor = scheme.primary);
      }
    }
  }

  Future<void> _loadLyrics() async {
    final song = ref.read(audioEngineProvider).currentSong;
    if (song == null) return;

    setState(() {
      _isLoadingLyrics = true;
      _lyrics = [];
    });

    try {
      final lyrics = await MusicService().getLyrics(song);
      if (mounted) {
        setState(() {
          _lyrics = lyrics;
          _hasLyrics = lyrics.isNotEmpty;
          _isLoadingLyrics = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingLyrics = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 监听歌曲变化
    // (Listeners kept here)
    final currentSong = ref.watch(currentSongProvider).valueOrNull;
    final playerState = ref.watch(playerStateProvider).valueOrNull;
    final isPlaying = playerState?.playing ?? false;

    ref.listen(currentSongProvider, (_, next) {
      final nextSong = next.valueOrNull;
      if (nextSong?.id != currentSong?.id) {
         _updateColors();
         _loadLyrics();
      }
    });

    // 歌词滚动逻辑
    if (_hasLyrics && _lyrics.isNotEmpty) {
      final position = ref.watch(positionProvider).valueOrNull ?? Duration.zero;
      int index = _lyrics.indexWhere((line) => line.time > position);
      if (index == -1) index = _lyrics.length;
      index -= 1;
      
      if (index < 0) index = 0;
      
      if (index != _currentLyricIndex) {
        _currentLyricIndex = index;
        if (_lyricsController.isAttached) {
             _lyricsController.scrollTo(
               index: index,
               duration: const Duration(milliseconds: 300),
               curve: Curves.easeInOut,
               alignment: 0.3, 
             );
        }
      }
    }

    final bgColor = _dominantColor ?? const Color(0xFF1a1a2e);
    final gradientColors = [
      bgColor.withValues(alpha: 0.8),
      Colors.black.withValues(alpha: 0.9),
    ];

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 背景
          AnimatedContainer(
            duration: const Duration(milliseconds: 800),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradientColors,
              ),
            ),
          ),
          // 模糊层
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: Container(color: Colors.transparent),
          ),

          // 主内容 - 响应式布局
          LayoutBuilder(
            builder: (context, constraints) {
              // 简单判断：宽度小于 800 或 是移动端平台则认为 Mobile 布局
              // PS: 实际上可以在 main.dart 注入 isDesktop 等全局变量，这里为了方便直接判断
              final bool isMobile = constraints.maxWidth < 800 || (Theme.of(context).platform == TargetPlatform.android || Theme.of(context).platform == TargetPlatform.iOS);
              
              if (isMobile) {
                return _buildMobileLayout(context);
              } else {
                return _buildDesktopLayout(context);
              }
            },
          ),
        ],
      ),
    );
  }

  // ==================== Desktop Layout ====================
  Widget _buildDesktopLayout(BuildContext context) {
    final currentSong = ref.watch(currentSongProvider).valueOrNull;
    final isPlaying = ref.watch(playerStateProvider).valueOrNull?.playing ?? false;
    final position = ref.watch(positionProvider).valueOrNull ?? Duration.zero;
    final duration = ref.watch(durationProvider).valueOrNull ?? Duration.zero;
    final playMode = ref.watch(playModeProvider).valueOrNull ?? PlayMode.sequence;

    return SafeArea(
      child: Column(
        children: [
          _buildTopBar(context),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  flex: 5,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                         const Spacer(),
                         Hero(
                           tag: 'album_cover_player_desktop',
                           child: Container(
                              constraints: const BoxConstraints(maxWidth: 400, maxHeight: 400),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.4),
                                    blurRadius: 40,
                                    offset: const Offset(0, 20),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: AspectRatio(
                                  aspectRatio: 1,
                                  child: currentSong?.coverUrl != null
                                     ? CachedNetworkImage(
                                         imageUrl: currentSong!.coverUrl!,
                                         fit: BoxFit.cover,
                                       )
                                     : Container(
                                        color: Colors.grey[800],
                                        child: const Icon(Icons.music_note, color: Colors.white, size: 80),
                                       ),
                                ),
                              ),
                           ),
                         ),
                         const SizedBox(height: 48),
                         Text(
                            currentSong?.name ?? '未知歌曲',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                         ),
                         const SizedBox(height: 8),
                         Text(
                            currentSong?.artist ?? '未知歌手',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                         ),
                         const SizedBox(height: 32),
                         _buildProgressBar(context, position, duration),
                         const SizedBox(height: 24),
                         _buildControls(context, isPlaying, playMode, iconSize: 36),
                         const Spacer(),
                         const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  flex: 6,
                  child: _buildLyricsView(isMobile: false),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== Mobile Layout ====================
  Widget _buildMobileLayout(BuildContext context) {
    final currentSong = ref.watch(currentSongProvider).valueOrNull;
    final isPlaying = ref.watch(playerStateProvider).valueOrNull?.playing ?? false;
    final position = ref.watch(positionProvider).valueOrNull ?? Duration.zero;
    final duration = ref.watch(durationProvider).valueOrNull ?? Duration.zero;
    final playMode = ref.watch(playModeProvider).valueOrNull ?? PlayMode.sequence;

    return SafeArea(
      child: Column(
        children: [
          // Mobile Top Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 32),
                ),
                Expanded(
                  child: Text(
                    '正在播放',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7), 
                      fontSize: 16, 
                      fontWeight: FontWeight.w600
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {}, // TODO: Menu or Share
                  icon: const Icon(Icons.more_horiz_rounded, color: Colors.white),
                ),
              ],
            ),
          ),
          
          // Content: Paged View (Cover/Controls vs Lyrics)
          Expanded(
            child: PageView(
              children: [
                // Page 1: Main Player
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Cover Art
                      Hero(
                         tag: 'album_cover_player_mobile',
                         child: Container(
                            constraints: const BoxConstraints(maxWidth: 320, maxHeight: 320),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  blurRadius: 30,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: AspectRatio(
                                aspectRatio: 1,
                                child: currentSong?.coverUrl != null
                                   ? CachedNetworkImage(
                                       imageUrl: currentSong!.coverUrl!,
                                       fit: BoxFit.cover,
                                     )
                                   : Container(
                                      color: Colors.grey[800],
                                      child: const Icon(Icons.music_note, color: Colors.white, size: 80),
                                     ),
                              ),
                            ),
                         ),
                      ),
                      
                      const SizedBox(height: 24),

                      // Info & Controls Area
                      Column(
                        children: [
                          // Song Info
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                 Text(
                                    currentSong?.name ?? '未知歌曲',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1, overflow: TextOverflow.ellipsis,
                                 ),
                                 const SizedBox(height: 4),
                                 Text(
                                    currentSong?.artist ?? '未知歌手',
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.7),
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1, overflow: TextOverflow.ellipsis,
                                 ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Seek Bar
                          _buildProgressBar(context, position, duration),
                          
                          const SizedBox(height: 20),
                          
                          // Controls
                          _buildControls(context, isPlaying, playMode, iconSize: 48),
                        ],
                      ),
                      
                      // Bottom Actions (Lyrics/List)
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                           IconButton(
                             onPressed: () {}, // Download/Favorite
                             icon: const Icon(Icons.favorite_border_rounded, color: Colors.white, size: 24),
                           ),
                           Text(
                             '左滑查看歌词',
                             style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 12),
                           ),
                           IconButton(
                             onPressed: () {}, // List
                             icon: const Icon(Icons.queue_music_rounded, color: Colors.white, size: 24),
                           ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
                
                // Page 2: Lyrics
                _buildLyricsView(isMobile: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
           IconButton(
             onPressed: () => context.pop(),
             icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 32),
           ),
           // 右侧工具如果需要的话
           Row(
             children: [
               IconButton(
                 onPressed: () {}, // TODO
                 icon: const Icon(Icons.more_horiz_rounded, color: Colors.white),
               ),
             ],
           ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(BuildContext context, Duration position, Duration duration) {
    final progress = duration.inMilliseconds > 0
        ? (_isDragging ? _dragValue : position.inMilliseconds / duration.inMilliseconds)
        : 0.0;

    return Column(
      children: [
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
            activeTrackColor: AppTheme.appleMusicRed,
            inactiveTrackColor: Colors.white.withValues(alpha: 0.2),
            thumbColor: Colors.white,
            overlayColor: AppTheme.appleMusicRed.withValues(alpha: 0.1),
          ),
          child: Slider(
            value: progress.clamp(0.0, 1.0),
            onChanged: (value) {
              setState(() {
                _isDragging = true;
                _dragValue = value;
              });
            },
            onChangeEnd: (value) {
              setState(() => _isDragging = false);
              final newPosition = Duration(
                milliseconds: (value * duration.inMilliseconds).round(),
              );
              ref.read(audioEngineProvider).seek(newPosition);
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDuration(position),
                style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
              ),
              Text(
                _formatDuration(duration),
                style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildControls(BuildContext context, bool isPlaying, PlayMode playMode, {double iconSize = 36}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: () => ref.read(audioEngineProvider).togglePlayMode(),
          icon: Icon(
             _getPlayModeIcon(playMode),
             color: playMode == PlayMode.sequence ? Colors.white54 : AppTheme.appleMusicRed,
             size: iconSize * 0.6
          ),
        ),
        const SizedBox(width: 24),
        IconButton(
          onPressed: () => ref.read(audioEngineProvider).playPrevious(),
          icon: Icon(Icons.skip_previous_rounded, color: Colors.white, size: iconSize),
        ),
        const SizedBox(width: 24),
        GestureDetector(
          onTap: () => ref.read(audioEngineProvider).togglePlay(),
          child: Container(
             width: iconSize * 2, height: iconSize * 2,
             decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.appleMusicRed,
             ),
             child: Icon(
                isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: Colors.white, size: iconSize * 1.2
             ),
          ),
        ),
        const SizedBox(width: 24),
        IconButton(
          onPressed: () => ref.read(audioEngineProvider).playNext(),
          icon: Icon(Icons.skip_next_rounded, color: Colors.white, size: iconSize),
        ),
        const SizedBox(width: 24),
         IconButton(
          onPressed: () {
             // Show queue
          },
          icon: Icon(Icons.queue_music_rounded, color: Colors.white54, size: iconSize * 0.6),
        ),
      ],
    );
  }

  Widget _buildLyricsView({bool isMobile = false}) {
    if (_isLoadingLyrics) {
      return const Center(child: CircularProgressIndicator(color: Colors.white30));
    }

    if (!_hasLyrics) {
      return Center(
        child: Text(
          '暂无歌词',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: isMobile ? 20 : 24, fontWeight: FontWeight.bold),
        ),
      );
    }

    // Mobile: Full screen padding. Desktop: Side padding.
    final padding = isMobile 
        ? const EdgeInsets.symmetric(horizontal: 24, vertical: 20)
        : const EdgeInsets.symmetric(horizontal: 60, vertical: 40);

    return Padding(
      padding: padding,
      child: ScrollablePositionedList.builder(
        itemScrollController: _lyricsController,
        itemPositionsListener: _lyricsListener,
        itemCount: _lyrics.length + 1, // End padding
        itemBuilder: (context, index) {
           if (index == _lyrics.length) {
             return const SizedBox(height: 200); // Bottom padding
           }

           final line = _lyrics[index];
           final isCurrent = index == _currentLyricIndex;

           return InkWell(
             onTap: () {
               ref.read(audioEngineProvider).seek(line.time);
             },
             child: Container(
               padding: const EdgeInsets.symmetric(vertical: 12),
               child: Text(
                 line.text,
                 style: TextStyle(
                   color: isCurrent ? Colors.white : Colors.white.withValues(alpha: 0.4),
                   fontSize: isCurrent ? (isMobile ? 28 : 32) : (isMobile ? 20 : 24),
                   fontWeight: FontWeight.bold,
                   height: 1.4,
                 ),
                 textAlign: isMobile ? TextAlign.center : TextAlign.left,
               ),
             ),
           );
        },
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  IconData _getPlayModeIcon(PlayMode mode) {
    switch (mode) {
      case PlayMode.sequence: return Icons.repeat_rounded;
      case PlayMode.loop: return Icons.repeat_rounded;
      case PlayMode.single: return Icons.repeat_one_rounded;
      case PlayMode.shuffle: return Icons.shuffle_rounded;
    }
  }
}
