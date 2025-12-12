import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:just_audio/just_audio.dart';
import 'package:ether_music/state/player_state.dart';
import 'package:ether_music/theme/glassmorphism.dart';

/// 迷你播放栏组件
class MiniPlayerBar extends ConsumerWidget {
  const MiniPlayerBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentSong = ref.watch(currentSongProvider).valueOrNull;
    final playerState = ref.watch(playerStateProvider).valueOrNull;
    final position = ref.watch(positionProvider).valueOrNull ?? Duration.zero;
    final duration = ref.watch(durationProvider).valueOrNull ?? Duration.zero;

    if (currentSong == null) {
      return const SizedBox.shrink();
    }

    final isPlaying = playerState?.playing ?? false;
    final progress = duration.inMilliseconds > 0
        ? (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;

    return GestureDetector(
      onTap: () => context.push('/player'),
      child: GlassmorphicContainer(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.all(8),
        borderRadius: 16,
        blur: 20,
        opacity: 0.15,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                // 专辑封面
                Hero(
                  tag: 'album_cover',
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: currentSong.coverUrl != null
                        ? CachedNetworkImage(
                            imageUrl: currentSong.coverUrl!,
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => _buildPlaceholder(),
                            errorWidget: (_, __, ___) => _buildPlaceholder(),
                          )
                        : _buildPlaceholder(),
                  ),
                ),
                const SizedBox(width: 12),
                // 歌曲信息
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        currentSong.name,
                        style: Theme.of(context).textTheme.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        currentSong.artistNames,
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // 控制按钮
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 上一首
                    IconButton(
                      icon: const Icon(Icons.skip_previous_rounded),
                      iconSize: 28,
                      onPressed: () {
                        ref.read(audioEngineProvider).playPrevious();
                      },
                    ),
                    // 播放/暂停
                    _PlayPauseButton(
                      isPlaying: isPlaying,
                      onPressed: () {
                        ref.read(audioEngineProvider).togglePlay();
                      },
                    ),
                    // 下一首
                    IconButton(
                      icon: const Icon(Icons.skip_next_rounded),
                      iconSize: 28,
                      onPressed: () {
                        ref.read(audioEngineProvider).playNext();
                      },
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 4),
            // 进度条
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 3,
                backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                valueColor: AlwaysStoppedAnimation(
                  Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(Icons.music_note_rounded, color: Colors.grey),
    );
  }
}

/// 播放/暂停按钮（带动画）
class _PlayPauseButton extends StatelessWidget {
  final bool isPlaying;
  final VoidCallback onPressed;

  const _PlayPauseButton({
    required this.isPlaying,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.secondary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                key: ValueKey(isPlaying),
                color: Colors.white,
                size: 26,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
