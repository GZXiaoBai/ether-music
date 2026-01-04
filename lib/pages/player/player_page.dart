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
    final currentSong = ref.watch(currentSongProvider).valueOrNull;
    final playerState = ref.watch(playerStateProvider).valueOrNull;
    final position = ref.watch(positionProvider).valueOrNull ?? Duration.zero;
    final duration = ref.watch(durationProvider).valueOrNull ?? Duration.zero;
    final playMode = ref.watch(playModeProvider).valueOrNull ?? PlayMode.sequence;

    final isPlaying = playerState?.playing ?? false;

    // 监听歌曲变化
    ref.listen(currentSongProvider, (_, next) {
      final nextSong = next.valueOrNull;
      if (nextSong?.id != currentSong?.id) {
         _updateColors();
         _loadLyrics();
      }
    });

    // 歌词滚动逻辑
    if (_hasLyrics && _lyrics.isNotEmpty) {
      // 查找当前歌词行
      int index = _lyrics.indexWhere((line) => line.time > position);
      if (index == -1) index = _lyrics.length;
      index -= 1;
      
      if (index < 0) index = 0;
      
      if (index != _currentLyricIndex) {
        _currentLyricIndex = index;
        // 自动滚动到当前行
        if (_lyricsController.isAttached) {
             _lyricsController.scrollTo(
               index: index,
               duration: const Duration(milliseconds: 300),
               curve: Curves.easeInOut,
               alignment: 0.3, // 垂直居中偏上
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

          // 主内容
          SafeArea(
            child: Column(
              children: [
                // 顶部栏
                _buildTopBar(context),
                
                Expanded(
                  child: Row(
                    children: [
                      // 左侧：封面与控制
                      Expanded(
                        flex: 5,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                               Spacer(),
                               // 封面
                               Hero(
                                 tag: 'album_cover_player',
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
                               
                               // 歌曲信息
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
                               
                               // 进度条
                               _buildProgressBar(context, position, duration),
                                
                               const SizedBox(height: 24),

                               // 播放控制
                               _buildControls(context, isPlaying, playMode),
                               
                               const Spacer(),
                               const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ),
                      
                      // 右侧：歌词
                      Expanded(
                        flex: 6,
                        child: _buildLyricsView(),
                      ),
                    ],
                  ),
                ),
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

  Widget _buildControls(BuildContext context, bool isPlaying, PlayMode playMode) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: () => ref.read(audioEngineProvider).togglePlayMode(),
          icon: Icon(
             _getPlayModeIcon(playMode),
             color: playMode == PlayMode.sequence ? Colors.white54 : AppTheme.appleMusicRed,
             size: 20
          ),
        ),
        const SizedBox(width: 24),
        IconButton(
          onPressed: () => ref.read(audioEngineProvider).playPrevious(),
          icon: const Icon(Icons.skip_previous_rounded, color: Colors.white, size: 36),
        ),
        const SizedBox(width: 24),
        GestureDetector(
          onTap: () => ref.read(audioEngineProvider).togglePlay(),
          child: Container(
             width: 64, height: 64,
             decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.appleMusicRed,
             ),
             child: Icon(
                isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: Colors.white, size: 36
             ),
          ),
        ),
        const SizedBox(width: 24),
        IconButton(
          onPressed: () => ref.read(audioEngineProvider).playNext(),
          icon: const Icon(Icons.skip_next_rounded, color: Colors.white, size: 36),
        ),
        const SizedBox(width: 24),
         IconButton(
          onPressed: () {
             // Show queue
          },
          icon: const Icon(Icons.queue_music_rounded, color: Colors.white54, size: 20),
        ),
      ],
    );
  }

  Widget _buildLyricsView() {
    if (_isLoadingLyrics) {
      return const Center(child: CircularProgressIndicator(color: Colors.white30));
    }

    if (!_hasLyrics) {
      return Center(
        child: Text(
          '暂无歌词',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 24, fontWeight: FontWeight.bold),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 40),
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
                   fontSize: isCurrent ? 32 : 24,
                   fontWeight: FontWeight.bold,
                   height: 1.4,
                 ),
                 textAlign: TextAlign.left,
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
