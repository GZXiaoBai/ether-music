import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:ether_music/api/models/song.dart';
import 'package:ether_music/theme/app_theme.dart';

/// Apple Music 风格歌曲行组件
/// 支持三种显示模式：紧凑、标准、大号
class AMSongRow extends StatelessWidget {
  final Song song;
  final int? index;
  final bool isPlaying;
  final bool showCover;
  final bool showMoreButton;
  final VoidCallback? onTap;
  final VoidCallback? onMoreTap;
  final AMSongRowStyle style;

  const AMSongRow({
    super.key,
    required this.song,
    this.index,
    this.isPlaying = false,
    this.showCover = true,
    this.showMoreButton = true,
    this.onTap,
    this.onMoreTap,
    this.style = AMSongRowStyle.standard,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: AppTheme.spacingM,
            vertical: style == AMSongRowStyle.compact 
                ? AppTheme.spacingS 
                : AppTheme.spacingM - 4,
          ),
          child: Row(
            children: [
              // 序号或播放指示器
              if (index != null) ...[
                SizedBox(
                  width: 28,
                  child: isPlaying
                      ? Icon(
                          Icons.equalizer_rounded,
                          color: AppTheme.appleMusicRed,
                          size: 20,
                        )
                      : Text(
                          '${index! + 1}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                ),
                const SizedBox(width: AppTheme.spacingS),
              ],
              
              // 封面
              if (showCover) ...[
                _buildCover(context),
                const SizedBox(width: AppTheme.spacingM),
              ],
              
              // 歌曲信息
              Expanded(child: _buildInfo(context)),
              
              // 更多按钮
              if (showMoreButton)
                IconButton(
                  icon: Icon(
                    Icons.more_horiz_rounded,
                    color: colorScheme.textSecondary,
                  ),
                  onPressed: onMoreTap,
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCover(BuildContext context) {
    final size = style == AMSongRowStyle.compact ? 40.0 : 48.0;
    final radius = style == AMSongRowStyle.compact ? 6.0 : 8.0;
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: song.coverUrl != null
          ? CachedNetworkImage(
              imageUrl: song.coverUrl!,
              width: size,
              height: size,
              fit: BoxFit.cover,
              placeholder: (_, __) => _buildCoverPlaceholder(size),
              errorWidget: (_, __, ___) => _buildCoverPlaceholder(size),
            )
          : _buildCoverPlaceholder(size),
    );
  }

  Widget _buildCoverPlaceholder(double size) {
    return Container(
      width: size,
      height: size,
      color: AppTheme.darkSurfaceElevated,
      child: Icon(
        Icons.music_note_rounded,
        size: size * 0.5,
        color: AppTheme.darkTextTertiary,
      ),
    );
  }

  Widget _buildInfo(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          song.name,
          style: theme.textTheme.titleMedium?.copyWith(
            color: isPlaying ? AppTheme.appleMusicRed : colorScheme.onSurface,
            fontWeight: isPlaying ? FontWeight.w600 : FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          song.artist,
          style: theme.textTheme.bodySmall?.copyWith(
            color: isPlaying 
                ? AppTheme.appleMusicRed.withValues(alpha: 0.8) 
                : colorScheme.textSecondary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

/// 歌曲行显示样式
enum AMSongRowStyle {
  /// 紧凑模式：小封面，更紧凑的间距
  compact,
  /// 标准模式：正常大小
  standard,
}

/// Apple Music 风格专辑/歌单卡片
class AMAlbumCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? imageUrl;
  final double size;
  final VoidCallback? onTap;

  const AMAlbumCard({
    super.key,
    required this.title,
    this.subtitle,
    this.imageUrl,
    this.size = 160,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: size,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 封面
            ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              child: imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: imageUrl!,
                      width: size,
                      height: size,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => _buildPlaceholder(),
                      errorWidget: (_, __, ___) => _buildPlaceholder(),
                    )
                  : _buildPlaceholder(),
            ),
            const SizedBox(height: AppTheme.spacingS),
            // 标题
            Text(
              title,
              style: theme.textTheme.titleSmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(
                subtitle!,
                style: theme.textTheme.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppTheme.darkSurfaceElevated,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Icon(
        Icons.album_rounded,
        size: size * 0.4,
        color: AppTheme.darkTextTertiary,
      ),
    );
  }
}

/// Apple Music 风格排行榜行
class AMToplistRow extends StatelessWidget {
  final int rank;
  final Song song;
  final bool isPlaying;
  final VoidCallback? onTap;

  const AMToplistRow({
    super.key,
    required this.rank,
    required this.song,
    this.isPlaying = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingM,
            vertical: AppTheme.spacingM - 4,
          ),
          child: Row(
            children: [
              // 排名
              SizedBox(
                width: 32,
                child: Text(
                  '$rank',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: rank <= 3 
                        ? AppTheme.appleMusicRed 
                        : colorScheme.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: AppTheme.spacingM),
              
              // 封面
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: song.coverUrl != null
                    ? CachedNetworkImage(
                        imageUrl: song.coverUrl!,
                        width: 52,
                        height: 52,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        width: 52,
                        height: 52,
                        color: AppTheme.darkSurfaceElevated,
                        child: const Icon(Icons.music_note_rounded),
                      ),
              ),
              const SizedBox(width: AppTheme.spacingM),
              
              // 歌曲信息
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      song.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: isPlaying 
                            ? AppTheme.appleMusicRed 
                            : colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      song.artist,
                      style: theme.textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              
              // 播放指示器
              if (isPlaying)
                Icon(
                  Icons.equalizer_rounded,
                  color: AppTheme.appleMusicRed,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
