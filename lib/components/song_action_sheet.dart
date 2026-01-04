import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:ether_music/api/models/song.dart';
import 'package:ether_music/api/music_service.dart';
import 'package:ether_music/core/download_service.dart';
import 'package:ether_music/pages/settings/settings_page.dart';

/// 歌曲操作菜单
class SongActionSheet extends ConsumerWidget {
  final Song song;
  final VoidCallback? onPlayNext;
  final VoidCallback? onAddToQueue;

  const SongActionSheet({
    super.key,
    required this.song,
    this.onPlayNext,
    this.onAddToQueue,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final downloadQuality = ref.watch(downloadQualityProvider);

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 拖动指示器
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // 歌曲信息
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // 封面
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: song.coverUrl != null
                      ? Image.network(
                          song.coverUrl!,
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          width: 56,
                          height: 56,
                          color: theme.colorScheme.surfaceContainerHighest,
                          child: const Icon(Icons.music_note_rounded),
                        ),
                ),
                const SizedBox(width: 12),
                // 信息
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        song.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        song.artist,
                        style: theme.textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // 操作列表
          _ActionItem(
            icon: Icons.playlist_play_rounded,
            title: '下一首播放',
            onTap: () {
              onPlayNext?.call();
              Navigator.pop(context);
              _showSnackBar(context, '已添加到下一首播放');
            },
          ),

          _ActionItem(
            icon: Icons.queue_music_rounded,
            title: '添加到播放队列',
            onTap: () {
              onAddToQueue?.call();
              Navigator.pop(context);
              _showSnackBar(context, '已添加到播放队列');
            },
          ),

          _ActionItem(
            icon: Icons.download_rounded,
            title: '下载 (${downloadQuality.label})',
            onTap: () {
              DownloadService().download(song, quality: downloadQuality.value);
              Navigator.pop(context);
              _showSnackBar(context, '开始下载: ${song.name}');
            },
          ),

          _ActionItem(
            icon: Icons.favorite_border_rounded,
            title: '收藏到我喜欢',
            onTap: () {
              Navigator.pop(context);
              _showSnackBar(context, '已收藏');
            },
          ),

          _ActionItem(
            icon: Icons.playlist_add_rounded,
            title: '添加到歌单',
            onTap: () {
              Navigator.pop(context);
              _showAddToPlaylistDialog(context);
            },
          ),

          _ActionItem(
            icon: Icons.lyrics_rounded,
            title: '复制歌词',
            onTap: () async {
              Navigator.pop(context);
              await _copyLyrics(context, song);
            },
          ),

          _ActionItem(
            icon: Icons.share_rounded,
            title: '分享',
            onTap: () async {
              Navigator.pop(context);
              await Share.share(
                '🎵 ${song.name} - ${song.artist}\n来自 Ether 以太音乐',
                subject: song.name,
              );
            },
          ),

          _ActionItem(
            icon: Icons.person_rounded,
            title: '查看歌手',
            onTap: () {
              Navigator.pop(context);
              // TODO: 跳转到歌手页面
            },
          ),

          _ActionItem(
            icon: Icons.album_rounded,
            title: '查看专辑',
            onTap: () {
              Navigator.pop(context);
              // TODO: 跳转到专辑页面
            },
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showAddToPlaylistDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('添加到歌单'),
        content: const Text('此功能开发中...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  Future<void> _copyLyrics(BuildContext context, Song song) async {
    try {
      final musicService = MusicService();
      final lyrics = await musicService.getLyricText(song);
      
      if (lyrics == null || lyrics.isEmpty) {
        if (context.mounted) _showSnackBar(context, '暂无歌词');
        return;
      }

      await Clipboard.setData(ClipboardData(text: lyrics));
      if (context.mounted) _showSnackBar(context, '歌词已复制到剪贴板');
    } catch (e) {
      if (context.mounted) _showSnackBar(context, '获取歌词失败');
    }
  }
}

/// 操作项
class _ActionItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color? iconColor;

  const _ActionItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      leading: Icon(
        icon,
        color: iconColor ?? theme.colorScheme.onSurface.withOpacity(0.7),
      ),
      title: Text(title),
      onTap: onTap,
    );
  }
}

/// 显示歌曲操作菜单
void showSongActionSheet(
  BuildContext context, 
  Song song, {
  VoidCallback? onPlayNext,
  VoidCallback? onAddToQueue,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => SongActionSheet(
      song: song,
      onPlayNext: onPlayNext,
      onAddToQueue: onAddToQueue,
    ),
  );
}
