import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import 'package:ether_music/state/player_state.dart';
import 'package:ether_music/core/audio_engine.dart';
import 'package:ether_music/core/color_extractor.dart';
import 'package:ether_music/core/download_service.dart';
import 'package:ether_music/core/local_storage_service.dart';
import 'package:ether_music/api/music_service.dart';
import 'package:ether_music/pages/settings/settings_page.dart';
import 'package:ether_music/theme/glassmorphism.dart';

/// 全屏播放器页面
class PlayerPage extends ConsumerStatefulWidget {
  const PlayerPage({super.key});

  @override
  ConsumerState<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends ConsumerState<PlayerPage> {
  ColorScheme? _dynamicColorScheme;
  
  // 进度条拖动状态
  bool _isDragging = false;
  double _dragValue = 0.0;
  
  // 歌词显示状态
  bool _showLyrics = false;
  String? _lyrics;
  bool _loadingLyrics = false;
  
  // 当前播放音质
  String _currentQuality = 'exhigh';

  @override
  void initState() {
    super.initState();
    _updateColors();
  }

  Future<void> _updateColors() async {
    final song = ref.read(audioEngineProvider).currentSong;
    if (song?.coverUrl != null) {
      final scheme = await ColorExtractor.extractFromUrl(song!.coverUrl!);
      if (mounted) {
        setState(() {
          _dynamicColorScheme = scheme;
        });
      }
    }
  }
  
  Future<void> _loadLyrics(int songId) async {
    if (_loadingLyrics) return;
    setState(() => _loadingLyrics = true);
    
    try {
      final lyrics = await MusicService().getLyric(songId);
      if (mounted) {
        setState(() {
          _lyrics = lyrics;
          _loadingLyrics = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _lyrics = null;
          _loadingLyrics = false;
        });
      }
    }
  }
  
  void _showQualityPicker(BuildContext context) {
    final qualities = [
      ('standard', '标准', '128kbps'),
      ('higher', '较高', '192kbps'),
      ('exhigh', '极高', '320kbps'),
      ('lossless', '无损', 'FLAC'),
      ('hires', 'Hi-Res', '24bit'),
    ];
    
    final theme = Theme.of(context);
    
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '选择音质',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '更改音质后将应用于下一首歌曲',
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ...qualities.map((q) => ListTile(
              leading: Icon(
                _currentQuality == q.$1 ? Icons.check_circle_rounded : Icons.circle_outlined,
                color: _currentQuality == q.$1 ? theme.colorScheme.primary : Colors.grey,
              ),
              title: Text(q.$2),
              subtitle: Text(q.$3),
              onTap: () {
                setState(() => _currentQuality = q.$1);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('已切换到 ${q.$2} 音质'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            )),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final currentSong = ref.watch(currentSongProvider).valueOrNull;
    final playerState = ref.watch(playerStateProvider).valueOrNull;
    final position = ref.watch(positionProvider).valueOrNull ?? Duration.zero;
    final duration = ref.watch(durationProvider).valueOrNull ?? Duration.zero;
    final playMode = ref.watch(playModeProvider).valueOrNull ?? PlayMode.sequence;

    final isPlaying = playerState?.playing ?? false;

    // 监听歌曲变化更新颜色
    ref.listen(currentSongProvider, (_, next) {
      if (next.valueOrNull?.coverUrl != null) {
        _updateColors();
      }
    });

    final primaryColor = _dynamicColorScheme?.primary ?? theme.colorScheme.primary;
    final gradientColors = ColorExtractor.getGradientColors(primaryColor);

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 动态渐变背景
          AnimatedContainer(
            duration: const Duration(milliseconds: 800),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  gradientColors.first,
                  gradientColors.last.withOpacity(0.8),
                  theme.scaffoldBackgroundColor,
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),

          // 模糊背景图
          if (currentSong?.coverUrl != null)
            Positioned.fill(
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                child: Opacity(
                  opacity: 0.3,
                  child: CachedNetworkImage(
                    imageUrl: currentSong!.coverUrl!,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),

          // 主内容
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // 根据屏幕高度动态调整专辑封面大小
                final availableHeight = constraints.maxHeight;
                final coverSize = (availableHeight * 0.35).clamp(150.0, 350.0);
                final lyricsHeight = (availableHeight * 0.55).clamp(300.0, 500.0);
                
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: availableHeight),
                    child: IntrinsicHeight(
                      child: Column(
                        children: [
                          // 顶部栏
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 32),
                                  onPressed: () => context.pop(),
                                ),
                                Column(
                                  children: [
                                    Text(
                                      '正在播放',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: Colors.white70,
                                      ),
                                    ),
                                    Text(
                                      currentSong?.album?.name ?? '',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: Colors.white54,
                                      ),
                                    ),
                                  ],
                                ),
                                IconButton(
                                  icon: const Icon(Icons.more_vert_rounded),
                                  onPressed: () {
                                    // TODO: 更多选项
                                  },
                                ),
                              ],
                            ),
                          ).animate().fadeIn(duration: 300.ms),

                          const Spacer(),

                          // 专辑封面 / 歌词切换区域
                          GestureDetector(
                            onTap: () {
                              setState(() => _showLyrics = !_showLyrics);
                              if (_showLyrics && currentSong != null && _lyrics == null) {
                                _loadLyrics(currentSong.id);
                              }
                            },
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              child: _showLyrics
                                  ? Container(
                                      key: const ValueKey('lyrics'),
                                      width: constraints.maxWidth - 48,
                                      height: lyricsHeight,
                                      decoration: BoxDecoration(
                                        color: Colors.black26,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: _buildLyricsView(primaryColor),
                                    )
                                  : Hero(
                                      tag: 'album_cover',
                                      child: Container(
                                        key: const ValueKey('cover'),
                                        width: coverSize,
                                        height: coverSize,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(20),
                                          boxShadow: [
                                            BoxShadow(
                                              color: primaryColor.withOpacity(0.4),
                                              blurRadius: 40,
                                              offset: const Offset(0, 20),
                                            ),
                                          ],
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(20),
                                          child: currentSong?.coverUrl != null
                                              ? CachedNetworkImage(
                                                  imageUrl: currentSong!.coverUrl!,
                                                  fit: BoxFit.cover,
                                                  placeholder: (_, __) => _buildCoverPlaceholder(),
                                                  errorWidget: (_, __, ___) => _buildCoverPlaceholder(),
                                                )
                                              : _buildCoverPlaceholder(),
                                        ),
                                      ),
                                    ),
                            ),
                          ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.9, 0.9)),

                          const SizedBox(height: 24),

                          // 歌曲信息
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 40),
                            child: Column(
                              children: [
                                Text(
                                  currentSong?.name ?? '未在播放',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  currentSong?.artistNames ?? '',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: Colors.white70,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ).animate().fadeIn(duration: 400.ms, delay: 100.ms),

                          const Spacer(),

                          // 进度条
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: Column(
                              children: [
                                SliderTheme(
                                  data: SliderTheme.of(context).copyWith(
                                    trackHeight: 4,
                                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                                    activeTrackColor: Colors.white,
                                    inactiveTrackColor: Colors.white24,
                                    thumbColor: Colors.white,
                                    overlayColor: Colors.white24,
                                  ),
                                  child: Slider(
                                    value: _isDragging
                                        ? _dragValue
                                        : (duration.inMilliseconds > 0
                                            ? (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0)
                                            : 0.0),
                                    onChangeStart: (value) {
                                      setState(() {
                                        _isDragging = true;
                                        _dragValue = value;
                                      });
                                    },
                                    onChanged: (value) {
                                      setState(() {
                                        _dragValue = value;
                                      });
                                    },
                                    onChangeEnd: (value) {
                                      final newPosition = Duration(
                                        milliseconds: (value * duration.inMilliseconds).toInt(),
                                      );
                                      ref.read(audioEngineProvider).seek(newPosition);
                                      setState(() {
                                        _isDragging = false;
                                      });
                                    },
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        _formatDuration(position),
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: Colors.white54,
                                        ),
                                      ),
                                      Text(
                                        _formatDuration(duration),
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: Colors.white54,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ).animate().fadeIn(duration: 400.ms, delay: 200.ms),

                          const SizedBox(height: 16),

                          // 控制按钮
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                // 播放模式
                                IconButton(
                                  icon: Icon(_getPlayModeIcon(playMode), size: 24),
                                  color: Colors.white70,
                                  onPressed: () {
                                    ref.read(audioEngineProvider).togglePlayMode();
                                  },
                                ),
                                // 上一首
                                GlassmorphicIconButton(
                                  icon: Icons.skip_previous_rounded,
                                  size: 52,
                                  iconSize: 28,
                                  iconColor: Colors.white,
                                  onPressed: () {
                                    ref.read(audioEngineProvider).playPrevious();
                                  },
                                ),
                                // 播放/暂停
                                _buildPlayButton(isPlaying),
                                // 下一首
                                GlassmorphicIconButton(
                                  icon: Icons.skip_next_rounded,
                                  size: 52,
                                  iconSize: 28,
                                  iconColor: Colors.white,
                                  onPressed: () {
                                    ref.read(audioEngineProvider).playNext();
                                  },
                                ),
                                // 播放列表
                                IconButton(
                                  icon: const Icon(Icons.queue_music_rounded, size: 24),
                                  color: Colors.white70,
                                  onPressed: () {
                                    _showPlayQueue(context);
                                  },
                                ),
                              ],
                            ),
                          ).animate().fadeIn(duration: 400.ms, delay: 300.ms),

                          const SizedBox(height: 24),

                          // 底部功能按钮
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                // 音质选择
                                GestureDetector(
                                  onTap: () => _showQualityPicker(context),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.white30),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.graphic_eq_rounded, color: Colors.white70, size: 16),
                                        const SizedBox(width: 4),
                                        Text(
                                          _getQualityLabel(_currentQuality),
                                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                // 喜欢
                                IconButton(
                                  icon: Icon(
                                    LocalStorageService().isFavorite(currentSong?.id ?? 0)
                                        ? Icons.favorite_rounded
                                        : Icons.favorite_border_rounded,
                                    color: LocalStorageService().isFavorite(currentSong?.id ?? 0)
                                        ? Colors.red
                                        : Colors.white70,
                                  ),
                                  onPressed: () async {
                                    if (currentSong == null) return;
                                    final isFav = await LocalStorageService().toggleFavorite(currentSong);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(isFav ? '已收藏' : '已取消收藏'),
                                        behavior: SnackBarBehavior.floating,
                                        duration: const Duration(seconds: 1),
                                      ),
                                    );
                                    setState(() {});
                                  },
                                ),
                                // 歌词切换
                                IconButton(
                                  icon: Icon(
                                    _showLyrics ? Icons.album_rounded : Icons.lyrics_rounded,
                                    color: _showLyrics ? primaryColor : Colors.white70,
                                  ),
                                  onPressed: () {
                                    setState(() => _showLyrics = !_showLyrics);
                                    if (_showLyrics && currentSong != null && _lyrics == null) {
                                      _loadLyrics(currentSong.id);
                                    }
                                  },
                                ),
                                // 下载
                                IconButton(
                                  icon: const Icon(Icons.download_rounded),
                                  color: Colors.white70,
                                  onPressed: () {
                                    if (currentSong == null) return;
                                    DownloadService().download(currentSong, quality: _currentQuality);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('开始下载: ${currentSong.name}'),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  },
                                ),
                                // 分享
                                IconButton(
                                  icon: const Icon(Icons.share_rounded),
                                  color: Colors.white70,
                                  onPressed: () async {
                                    if (currentSong == null) return;
                                    await Share.share(
                                      '🎵 ${currentSong.name} - ${currentSong.artistNames}\n来自 Ether 以太音乐',
                                      subject: currentSong.name,
                                    );
                                  },
                                ),
                              ],
                            ),
                          ).animate().fadeIn(duration: 400.ms, delay: 400.ms),

                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoverPlaceholder() {
    return Container(
      color: Colors.grey[800],
      child: const Center(
        child: Icon(
          Icons.music_note_rounded,
          size: 80,
          color: Colors.grey,
        ),
      ),
    );
  }

  String _getQualityLabel(String quality) {
    switch (quality) {
      case 'standard':
        return '标准';
      case 'higher':
        return '较高';
      case 'exhigh':
        return '极高';
      case 'lossless':
        return '无损';
      case 'hires':
        return 'Hi-Res';
      default:
        return '极高';
    }
  }

  Widget _buildLyricsView(Color primaryColor) {
    if (_loadingLyrics) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white70),
      );
    }

    if (_lyrics == null || _lyrics!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lyrics_rounded, size: 48, color: Colors.white30),
            const SizedBox(height: 16),
            Text(
              '暂无歌词',
              style: TextStyle(color: Colors.white54, fontSize: 16),
            ),
          ],
        ),
      );
    }

    // 解析歌词
    final lines = _lyrics!.split('\n').where((l) => l.trim().isNotEmpty).toList();
    
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      itemCount: lines.length,
      itemBuilder: (context, index) {
        var line = lines[index];
        // 移除时间标签
        line = line.replaceAll(RegExp(r'\[\d{2}:\d{2}\.\d{2,3}\]'), '').trim();
        if (line.isEmpty) return const SizedBox.shrink();
        
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            line,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
        );
      },
    );
  }

  Widget _buildPlayButton(bool isPlaying) {
    return GestureDetector(
      onTap: () {
        ref.read(audioEngineProvider).togglePlay();
      },
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.white.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Icon(
              isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              key: ValueKey(isPlaying),
              color: Colors.black,
              size: 40,
            ),
          ),
        ),
      ),
    );
  }

  IconData _getPlayModeIcon(PlayMode mode) {
    switch (mode) {
      case PlayMode.sequence:
        return Icons.repeat_rounded;
      case PlayMode.loop:
        return Icons.repeat_rounded;
      case PlayMode.single:
        return Icons.repeat_one_rounded;
      case PlayMode.shuffle:
        return Icons.shuffle_rounded;
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  void _showPlayQueue(BuildContext context) {
    final queue = ref.read(audioEngineProvider).queue;
    final currentIndex = ref.read(audioEngineProvider).currentIndex;

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '播放队列 (${queue.length})',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      ref.read(audioEngineProvider).clearQueue();
                      Navigator.pop(context);
                    },
                    child: const Text('清空'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: queue.length,
                itemBuilder: (context, index) {
                  final song = queue[index];
                  final isCurrent = index == currentIndex;

                  return ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: song.coverUrl != null
                          ? CachedNetworkImage(
                              imageUrl: song.coverUrl!,
                              width: 44,
                              height: 44,
                              fit: BoxFit.cover,
                            )
                          : Container(
                              width: 44,
                              height: 44,
                              color: Colors.grey[800],
                              child: const Icon(Icons.music_note_rounded),
                            ),
                    ),
                    title: Text(
                      song.name,
                      style: TextStyle(
                        color: isCurrent
                            ? Theme.of(context).colorScheme.primary
                            : null,
                        fontWeight: isCurrent ? FontWeight.bold : null,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      song.artistNames,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: isCurrent
                        ? Icon(
                            Icons.equalizer_rounded,
                            color: Theme.of(context).colorScheme.primary,
                          )
                        : IconButton(
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () {
                              ref.read(audioEngineProvider).removeFromQueue(index);
                              setState(() {});
                            },
                          ),
                    onTap: () {
                      ref.read(audioEngineProvider).playAt(index);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
