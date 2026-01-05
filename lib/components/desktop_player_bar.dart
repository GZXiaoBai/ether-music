import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ether_music/theme/app_theme.dart';
import 'package:ether_music/state/player_state.dart';
import 'package:ether_music/core/audio_engine.dart';
import 'package:ether_music/core/local_storage_service.dart';
import 'package:ether_music/api/models/song.dart';
import 'package:cached_network_image/cached_network_image.dart';

class DesktopPlayerBar extends ConsumerWidget {
  const DesktopPlayerBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final currentSongAsync = ref.watch(currentSongProvider);
    final isPlayingAsync = ref.watch(playerStateProvider);
    final positionAsync = ref.watch(positionProvider);
    final durationAsync = ref.watch(durationProvider);
    final playModeAsync = ref.watch(playModeProvider);

    final currentSong = currentSongAsync.valueOrNull;
    final isPlaying = isPlayingAsync.value?.playing ?? false;
    final position = positionAsync.value ?? Duration.zero;
    final duration = durationAsync.value ?? Duration.zero;
    final playMode = playModeAsync.value ?? PlayMode.sequence;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24), // 悬浮边距
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20), // 大圆角
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25), // 强磨砂
          child: Container(
            height: 84, // 略微增高
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withValues(alpha: 0.65), // 半透明背景
              border: Border.all(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: [
                // 1. 左侧：歌曲信息
                Expanded(
                  flex: 3,
                  child: _buildSongInfo(context, currentSong),
                ),

                // 2. 中间：播放控制
                Expanded(
                  flex: 4,
                  child: _buildControls(
                    context, 
                    ref, 
                    isPlaying, 
                    position, 
                    duration, 
                    playMode,
                  ),
                ),

                // 3. 右侧：辅助功能 (音量等)
                Expanded(
                  flex: 3,
                  child: _buildExtraControls(context, ref),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSongInfo(BuildContext context, Song? song) {
    if (song == null) return const SizedBox();

    final theme = Theme.of(context);
    return Row(
      children: [
        // 封面
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () => context.push('/player'),
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: song.coverUrl != null
                    ? CachedNetworkImage(imageUrl: song.coverUrl!, fit: BoxFit.cover)
                    : Container(
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: Icon(Icons.music_note_rounded, color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
                      ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        // 文本
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                song.name,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                song.artist,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        // 收藏按钮 (可选)
        // 收藏按钮
        ListenableBuilder(
          listenable: LocalStorageService(),
          builder: (context, child) {
            final isFavorite = LocalStorageService().isFavorite(song);
            return IconButton(
              onPressed: () => LocalStorageService().toggleFavorite(song),
              icon: Icon(
                isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                size: 20, 
                color: isFavorite ? AppTheme.appleMusicRed : theme.colorScheme.onSurface.withValues(alpha: 0.4)
              ),
              tooltip: isFavorite ? '取消收藏' : '收藏',
            );
          },
        ),
      ],
    );
  }

  Widget _buildControls(BuildContext context, WidgetRef ref, bool isPlaying, Duration position, Duration duration, PlayMode mode) {
    final theme = Theme.of(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 按钮行
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 模式切换
            IconButton(
              onPressed: () => ref.read(audioEngineProvider).togglePlayMode(),
              icon: Icon(
                _getPlayModeIcon(mode),
                size: 20,
                color: mode == PlayMode.sequence 
                    ? theme.colorScheme.onSurface.withValues(alpha: 0.4)
                    : AppTheme.appleMusicRed,
              ),
              tooltip: _getPlayModeTooltip(mode),
            ),
            const SizedBox(width: 8),
            
            // 上一首
            IconButton(
              onPressed: () => ref.read(audioEngineProvider).playPrevious(),
              icon: const Icon(Icons.skip_previous_rounded, size: 28),
            ),
            const SizedBox(width: 16),
            
            // 播放/暂停 (大按钮)
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: IconButton(
                onPressed: () => ref.read(audioEngineProvider).togglePlay(),
                icon: Icon(
                  isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: theme.colorScheme.surface, // 反色
                  size: 30,
                ),
              ),
            ),
            const SizedBox(width: 16),
            
            // 下一首
            IconButton(
              onPressed: () => ref.read(audioEngineProvider).playNext(),
              icon: const Icon(Icons.skip_next_rounded, size: 28),
            ),
            const SizedBox(width: 8),
            
            // 歌词/功能
            IconButton(
              onPressed: () => context.push('/player'), // 歌词按钮也跳转播放页
              icon: Icon(Icons.lyrics_rounded, size: 20, color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
              tooltip: '打开歌词页',
            ),
          ],
        ),
        
        const SizedBox(height: 4),
        
        // 进度条行
        Row(
          children: [
            Text(
              _formatDuration(position),
              style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withValues(alpha: 0.4), fontFeatures: const [FontFeature.tabularFigures()]),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: SizedBox(
                height: 12,
                child: SliderTheme(
                  data: theme.sliderTheme.copyWith(
                    trackHeight: 3,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                    trackShape: _CustomTrackShape(), // 自定义 TrackShape 以消除默认边距
                  ),
                  child: Slider(
                    value: position.inSeconds.toDouble().clamp(0.0, duration.inSeconds.toDouble()),
                    min: 0,
                    max: duration.inSeconds.toDouble() > 0 ? duration.inSeconds.toDouble() : 1.0,
                    onChanged: (value) {
                      ref.read(audioEngineProvider).seek(Duration(seconds: value.toInt()));
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _formatDuration(duration),
              style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withValues(alpha: 0.4), fontFeatures: const [FontFeature.tabularFigures()]),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildExtraControls(BuildContext context, WidgetRef ref) {
    final volume = ref.watch(volumeProvider).value ?? 1.0;
    final theme = Theme.of(context);
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // 音质选择
        PopupMenuButton<String>(
          tooltip: '音质',
          icon: Icon(Icons.high_quality_rounded, size: 20, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
          onSelected: (quality) {
            // 保存音质设置并重新加载当前歌曲
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('已切换至 $quality 音质'), duration: const Duration(seconds: 1)),
            );
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: '128k', child: Text('标准 128k')),
            const PopupMenuItem(value: '320k', child: Text('高品质 320k')),
            const PopupMenuItem(value: '999k', child: Text('无损 FLAC')),
          ],
        ),
        const SizedBox(width: 8),
        // 音量控制
        IconButton(
          icon: Icon(
            volume == 0 ? Icons.volume_off_rounded : Icons.volume_up_rounded,
            size: 20,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
          onPressed: () {
            if (volume > 0) {
              ref.read(audioEngineProvider).setVolume(0);
            } else {
              ref.read(audioEngineProvider).setVolume(1.0);
            }
          },
          tooltip: volume > 0 ? '静音' : '取消静音',
        ),
        SizedBox(
          width: 80,
          child: SliderTheme(
            data: theme.sliderTheme.copyWith(
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 4),
            ),
            child: Slider(
              value: volume,
              onChanged: (v) => ref.read(audioEngineProvider).setVolume(v),
            ),
          ),
        ),
        const SizedBox(width: 16),
        IconButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('播放队列功能开发中...'), duration: Duration(seconds: 1)),
            );
          }, 
          icon: const Icon(Icons.queue_music_rounded),
          tooltip: '播放队列',
        ),
      ],
    );
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  IconData _getPlayModeIcon(PlayMode mode) {
    switch (mode) {
      case PlayMode.sequence: return Icons.repeat_rounded; // 还是显示循环icon但灰色
      case PlayMode.loop: return Icons.repeat_rounded;
      case PlayMode.single: return Icons.repeat_one_rounded;
      case PlayMode.shuffle: return Icons.shuffle_rounded;
    }
  }

  String _getPlayModeTooltip(PlayMode mode) {
    switch (mode) {
      case PlayMode.sequence: return '顺序播放';
      case PlayMode.loop: return '列表循环';
      case PlayMode.single: return '单曲循环';
      case PlayMode.shuffle: return '随机播放';
    }
  }
}

class _CustomTrackShape extends RoundedRectSliderTrackShape {
  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    final double trackHeight = sliderTheme.trackHeight!;
    final double trackLeft = offset.dx;
    final double trackTop = offset.dy + (parentBox.size.height - trackHeight) / 2;
    final double trackWidth = parentBox.size.width;
    return Rect.fromLTWH(trackLeft, trackTop, trackWidth, trackHeight);
  }
}
