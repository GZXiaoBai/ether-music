import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:ether_music/api/models/song.dart';
import 'package:ether_music/theme/glassmorphism.dart';

/// 歌曲卡片组件
class SongCard extends StatelessWidget {
  final Song song;
  final VoidCallback? onTap;
  final VoidCallback? onMoreTap;
  final bool isPlaying;
  final int? index;

  const SongCard({
    super.key,
    required this.song,
    this.onTap,
    this.onMoreTap,
    this.isPlaying = false,
    this.index,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              // 序号或正在播放指示器
              if (index != null)
                SizedBox(
                  width: 32,
                  child: isPlaying
                      ? Icon(
                          Icons.equalizer_rounded,
                          color: theme.colorScheme.primary,
                          size: 20,
                        )
                      : Text(
                          '${index! + 1}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.5),
                          ),
                          textAlign: TextAlign.center,
                        ),
                ),
              // 专辑封面
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: song.coverUrl != null
                    ? CachedNetworkImage(
                        imageUrl: song.coverUrl!,
                        width: 52,
                        height: 52,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => _buildPlaceholder(),
                        errorWidget: (_, __, ___) => _buildPlaceholder(),
                      )
                    : _buildPlaceholder(),
              ),
              const SizedBox(width: 12),
              // 歌曲信息
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      song.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: isPlaying
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (song.isVip)
                          Container(
                            margin: const EdgeInsets.only(right: 6),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'VIP',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.amber,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        Expanded(
                          child: Text(
                            '${song.artistNames} · ${song.album?.name ?? '未知专辑'}',
                            style: theme.textTheme.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // 时长
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Text(
                  song.durationFormatted,
                  style: theme.textTheme.bodySmall,
                ),
              ),
              // 更多按钮
              if (onMoreTap != null)
                IconButton(
                  icon: Icon(
                    Icons.more_vert_rounded,
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                  onPressed: onMoreTap,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.music_note_rounded, color: Colors.grey, size: 24),
    );
  }
}

/// 歌单卡片组件
class PlaylistCard extends StatelessWidget {
  final Playlist playlist;
  final VoidCallback? onTap;
  final double width;

  const PlaylistCard({
    super.key,
    required this.playlist,
    this.onTap,
    this.width = 150,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 封面
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                children: [
                  playlist.coverUrl != null
                      ? CachedNetworkImage(
                          imageUrl: playlist.coverUrl!,
                          width: width,
                          height: width,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => _buildPlaceholder(),
                          errorWidget: (_, __, ___) => _buildPlaceholder(),
                        )
                      : _buildPlaceholder(),
                  // 播放次数
                  if (playlist.playCount != null)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.play_arrow_rounded,
                              size: 12,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              _formatPlayCount(playlist.playCount!),
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // 标题
            Text(
              playlist.name,
              style: theme.textTheme.titleSmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: width,
      height: width,
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.album_rounded, color: Colors.grey, size: 48),
    );
  }

  String _formatPlayCount(int count) {
    if (count >= 100000000) {
      return '${(count / 100000000).toStringAsFixed(1)}亿';
    } else if (count >= 10000) {
      return '${(count / 10000).toStringAsFixed(1)}万';
    }
    return count.toString();
  }
}
