import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:ether_music/state/player_state.dart';
import 'package:ether_music/theme/app_theme.dart';

/// Apple Music 风格迷你播放栏
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
    
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => context.push('/player'),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          color: isDark 
              ? AppTheme.darkSurfaceElevated.withValues(alpha: 0.95)
              : AppTheme.lightSurfaceElevated.withValues(alpha: 0.95),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    children: [
                      // 专辑封面
                      Hero(
                        tag: 'album_cover',
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: currentSong.coverUrl != null
                              ? CachedNetworkImage(
                                  imageUrl: currentSong.coverUrl!,
                                  width: 44,
                                  height: 44,
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
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 1),
                            Text(
                              currentSong.artist,
                              style: theme.textTheme.bodySmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      
                      // 播放/暂停按钮
                      _AMPlayButton(
                        isPlaying: isPlaying,
                        onPressed: () {
                          ref.read(audioEngineProvider).togglePlay();
                        },
                      ),
                      const SizedBox(width: 4),
                      
                      // 下一首
                      IconButton(
                        icon: const Icon(Icons.skip_next_rounded),
                        iconSize: 28,
                        color: theme.colorScheme.onSurface,
                        onPressed: () {
                          ref.read(audioEngineProvider).playNext();
                        },
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                ),
                
                // 进度条 - Apple Music 细线风格
                Container(
                  height: 2,
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(1),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: theme.colorScheme.separator,
                      valueColor: const AlwaysStoppedAnimation(
                        AppTheme.appleMusicRed,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppTheme.darkSurfaceElevated,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(
        Icons.music_note_rounded, 
        color: AppTheme.darkTextTertiary,
        size: 20,
      ),
    );
  }
}

/// Apple Music 风格播放按钮
class _AMPlayButton extends StatelessWidget {
  final bool isPlaying;
  final VoidCallback onPressed;

  const _AMPlayButton({
    required this.isPlaying,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 36,
        height: 36,
        decoration: const BoxDecoration(
          color: AppTheme.appleMusicRed,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: AnimatedSwitcher(
            duration: AppTheme.animationFast,
            child: Icon(
              isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              key: ValueKey(isPlaying),
              color: Colors.white,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }
}

/// Apple Music 风格底部导航栏
class AMBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AMBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: isDark 
            ? AppTheme.darkSurface.withValues(alpha: 0.9)
            : AppTheme.lightSurfaceElevated.withValues(alpha: 0.9),
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.separator,
            width: 0.5,
          ),
        ),
      ),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 50,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _AMNavItem(
                    icon: Icons.home_rounded,
                    label: '首页',
                    isSelected: currentIndex == 0,
                    onTap: () => onTap(0),
                  ),
                  _AMNavItem(
                    icon: Icons.search_rounded,
                    label: '搜索',
                    isSelected: currentIndex == 1,
                    onTap: () => onTap(1),
                  ),
                  _AMNavItem(
                    icon: Icons.library_music_rounded,
                    label: '资料库',
                    isSelected: currentIndex == 2,
                    onTap: () => onTap(2),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AMNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _AMNavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected 
        ? AppTheme.appleMusicRed 
        : Theme.of(context).colorScheme.textSecondary;
    
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 80,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
