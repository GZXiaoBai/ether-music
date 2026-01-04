import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:ether_music/api/models/song.dart';
import 'package:ether_music/theme/app_theme.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ether_music/core/download_service.dart';
import 'package:ether_music/core/audio_engine.dart';
import 'package:ether_music/state/player_state.dart';

class DesktopSongRow extends ConsumerStatefulWidget {
  final int index;
  final Song song;
  final bool isPlaying;
  final VoidCallback onTap;
  /// 可选：覆盖默认的 trailing actions
  final List<Widget>? customTrailing;

  const DesktopSongRow({
    super.key,
    required this.index,
    required this.song,
    required this.isPlaying,
    required this.onTap,
    this.customTrailing,
  });

  @override
  ConsumerState<DesktopSongRow> createState() => _DesktopSongRowState();
}

class _DesktopSongRowState extends ConsumerState<DesktopSongRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isActive = widget.isPlaying;
    final textColor = isActive ? AppTheme.appleMusicRed : theme.colorScheme.onSurface;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        onSecondaryTapUp: (details) => _showContextMenu(context, details.globalPosition),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8), // 更紧凑
          decoration: BoxDecoration(
            color: _isHovered
                ? theme.colorScheme.onSurface.withValues(alpha: 0.05)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8), // 圆角列表项
          ),
          child: Row(
            children: [
              // 序号 / 均衡器
              SizedBox(
                width: 30,
                child: isActive
                    ? Icon(Icons.equalizer_rounded, color: AppTheme.appleMusicRed, size: 16)
                    : Text(
                        '${widget.index}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
              ),
              const SizedBox(width: 12),

              // 封面
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: widget.song.coverUrl != null
                    ? CachedNetworkImage(
                        imageUrl: widget.song.coverUrl!,
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        width: 40,
                        height: 40,
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: Icon(Icons.music_note_rounded, size: 20, color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
                      ),
              ),
              const SizedBox(width: 16),

              // 标题
              Expanded(
                flex: 4,
                child: Text(
                  widget.song.name,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: textColor,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // 歌手
              Expanded(
                flex: 3,
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () {
                      context.push('/artist/${Uri.encodeComponent(widget.song.artist)}');
                    },
                    child: Text(
                      widget.song.artist,
                      style: theme.textTheme.bodySmall?.copyWith(
                         color: isActive ? AppTheme.appleMusicRed.withValues(alpha: 0.8) : theme.colorScheme.onSurface.withValues(alpha: 0.7), // 略微增加对比度
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),

              // 专辑/平台
              Expanded(
                flex: 3,
                child: Text(
                  widget.song.platform, // 这里实际应该显示 Album，暂时用 Platform
                  style: theme.textTheme.bodySmall?.copyWith(
                     color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // 操作区
              SizedBox(
                width: 120, // 固定宽度防止溢出
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: _isHovered
                      ? (widget.customTrailing ?? _buildDefaultActions(context, theme))
                      : [
                          Text(
                            '03:45',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                        ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildDefaultActions(BuildContext context, ThemeData theme) {
    return [
       _ActionButton(
         icon: Icons.play_arrow_rounded,
         tooltip: '播放',
         onTap: widget.onTap,
       ),
       const SizedBox(width: 4),
       _ActionButton(
         icon: Icons.download_rounded,
         tooltip: '下载',
         onTap: () {
            DownloadService().download(widget.song);
            ScaffoldMessenger.of(context).showSnackBar(
               const SnackBar(content: Text('已加入下载队列'), duration: Duration(seconds: 1)),
            );
         },
       ),
       const SizedBox(width: 4),
       _ActionButton(
         icon: Icons.more_horiz_rounded,
         tooltip: '更多',
         onTap: () {
            final renderBox = context.findRenderObject() as RenderBox;
            final position = renderBox.localToGlobal(Offset.zero);
            _showContextMenu(context, position + const Offset(100, 20)); // Offset slightly
         },
       ),
    ];
  }

  void _showContextMenu(BuildContext context, Offset position) {
    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(position.dx, position.dy, position.dx + 200, position.dy + 200),
      elevation: 10,
      shadowColor: Colors.black.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      items: [
        PopupMenuItem(
          onTap: widget.onTap,
          child: _BuildMenuItem(icon: Icons.play_arrow_rounded, text: '播放'),
        ),
        PopupMenuItem(
          onTap: () => ref.read(audioEngineProvider).addNext(widget.song),
          child: _BuildMenuItem(icon: Icons.playlist_play_rounded, text: '下一首播放'),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          onTap: () {
             DownloadService().download(widget.song);
             ScaffoldMessenger.of(context).showSnackBar(
               const SnackBar(content: Text('已加入下载队列'), duration: Duration(seconds: 1)),
            );
          },
          child: _BuildMenuItem(icon: Icons.download_rounded, text: '下载'),
        ),
        PopupMenuItem(
          onTap: () {}, // TODO
          child: _BuildMenuItem(icon: Icons.favorite_border_rounded, text: '收藏'),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _ActionButton({required this.icon, required this.tooltip, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, size: 20),
      tooltip: tooltip,
      onPressed: onTap,
      style: IconButton.styleFrom(
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        padding: const EdgeInsets.all(8),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}

class _BuildMenuItem extends StatelessWidget {
  final IconData icon;
  final String text;
  const _BuildMenuItem({required this.icon, required this.text});
  
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Theme.of(context).colorScheme.onSurface),
        const SizedBox(width: 12),
        Text(text, style: TextStyle(fontSize: 14)),
      ],
    );
  }
}
