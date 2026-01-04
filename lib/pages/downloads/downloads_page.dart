import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:ether_music/core/download_service.dart';
import 'package:ether_music/theme/app_theme.dart';

class DownloadsPage extends ConsumerStatefulWidget {
  const DownloadsPage({super.key});

  @override
  ConsumerState<DownloadsPage> createState() => _DownloadsPageState();
}

class _DownloadsPageState extends ConsumerState<DownloadsPage> {
  final DownloadService _downloadService = DownloadService();

  @override
  void initState() {
    super.initState();
    _downloadService.addListener(_update);
  }

  @override
  void dispose() {
    _downloadService.removeListener(_update);
    super.dispose();
  }

  void _update() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // tasks is a List<DownloadTask>
    final tasks = _downloadService.tasks.reversed.toList();

    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.download_done_rounded, size: 60, color: theme.colorScheme.onSurface.withValues(alpha: 0.2)),
            const SizedBox(height: 16),
            Text('暂无下载任务', style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
          ],
        ),
      );
    }

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(32, 24, 32, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                 Text(
                  '下载管理', 
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)
                 ),
                 TextButton.icon(
                   onPressed: () {
                     _downloadService.clearCompleted();
                   },
                   icon: const Icon(Icons.delete_sweep_rounded, size: 18),
                   label: const Text('清理已完成'),
                 ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(32, 8, 32, 8),
            child: Row(
              children: [
                const SizedBox(width: 56), // 封面
                Expanded(flex: 4, child: Text('标题', style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.5)))),
                Expanded(flex: 3, child: Text('进度/状态', style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.5)))),
                SizedBox(width: 100, child: Text('操作', style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.5)), textAlign: TextAlign.right)),
              ],
            ),
          ),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final task = tasks[index];
              return _DesktopDownloadRow(task: task);
            },
            childCount: tasks.length,
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 40)),
      ],
    );
  }
}

class _DesktopDownloadRow extends StatefulWidget {
  final DownloadTask task;

  const _DesktopDownloadRow({required this.task});

  @override
  State<_DesktopDownloadRow> createState() => _DesktopDownloadRowState();
}

class _DesktopDownloadRowState extends State<_DesktopDownloadRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final task = widget.task;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
        color: _isHovered 
              ? theme.colorScheme.onSurface.withValues(alpha: 0.05) 
              : Colors.transparent,
        child: Row(
          children: [
            // 封面
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: task.song.coverUrl != null
                 ? CachedNetworkImage(
                     imageUrl: task.song.coverUrl!,
                     width: 40, height: 40,
                     fit: BoxFit.cover,
                   )
                 : Container(
                    width: 40, height: 40,
                    color: theme.colorScheme.surfaceContainerHighest,
                   ),
            ),
            const SizedBox(width: 16),
            
            // 标题 & 歌手
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.song.name,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    task.song.artist,
                    style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            
            // 进度条
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (task.status == DownloadStatus.downloading) ...[
                     LinearProgressIndicator(
                       value: task.progress, 
                       backgroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                       color: AppTheme.appleMusicRed,
                       minHeight: 4,
                       borderRadius: BorderRadius.circular(2),
                     ),
                     const SizedBox(height: 4),
                     Text(
                       '${(task.progress * 100).toStringAsFixed(1)}%',
                       style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                     ),
                  ] else ...[
                     _buildStatusBadge(task.status),
                  ]
                ],
              ),
            ),

            // 操作按钮
            SizedBox(
              width: 100,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (task.status == DownloadStatus.failed)
                    IconButton(
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      tooltip: '重试',
                      onPressed: () => DownloadService().retry(task),
                    ),
                  if (task.status == DownloadStatus.completed)
                     IconButton(
                       icon: const Icon(Icons.folder_open_rounded, size: 18),
                       tooltip: '打开文件',
                       onPressed: () {
                         // TODO: Open folder
                       },
                     ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, size: 18, color: theme.colorScheme.error),
                    tooltip: '删除',
                    onPressed: () => DownloadService().cancel(task),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(DownloadStatus status) {
    String text = '';
    Color color = Colors.grey;
    IconData? icon;

    switch (status) {
      case DownloadStatus.pending:
        text = '等待中';
        icon = Icons.hourglass_empty_rounded;
        break;
      case DownloadStatus.downloading:
        text = '下载中';
        break;
      case DownloadStatus.completed:
        text = '已完成';
        color = Colors.green;
        icon = Icons.check_circle_rounded;
        break;
      case DownloadStatus.failed:
        text = '失败';
        color = Colors.red;
        icon = Icons.error_outline_rounded;
        break;
      case DownloadStatus.canceled:
        text = '已取消';
        color = Colors.orange;
        icon = Icons.cancel_outlined;
        break;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[Icon(icon, size: 14, color: color), const SizedBox(width: 4)],
        Text(text, style: TextStyle(color: color, fontSize: 12)),
      ],
    );
  }
}
