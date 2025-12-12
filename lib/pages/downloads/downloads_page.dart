import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:ether_music/core/download_service.dart';
import 'package:ether_music/theme/glassmorphism.dart';

/// 下载管理页面
class DownloadsPage extends StatefulWidget {
  const DownloadsPage({super.key});

  @override
  State<DownloadsPage> createState() => _DownloadsPageState();
}

class _DownloadsPageState extends State<DownloadsPage> {
  final DownloadService _downloadService = DownloadService();

  @override
  void initState() {
    super.initState();
    _downloadService.addListener(_onDownloadUpdate);
  }

  @override
  void dispose() {
    _downloadService.removeListener(_onDownloadUpdate);
    super.dispose();
  }

  void _onDownloadUpdate() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tasks = _downloadService.tasks;

    return Scaffold(
      appBar: AppBar(
        title: const Text('下载管理'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (tasks.any((t) => t.status == DownloadStatus.completed))
            TextButton(
              onPressed: () {
                _downloadService.clearCompleted();
              },
              child: const Text('清除已完成'),
            ),
        ],
      ),
      body: tasks.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.download_for_offline_rounded,
                    size: 80,
                    color: theme.colorScheme.onSurface.withOpacity(0.2),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '暂无下载任务',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '点击歌曲的下载按钮开始下载',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.4),
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                final task = tasks[index];
                return _DownloadTaskCard(
                  task: task,
                  onCancel: () => _downloadService.cancel(task),
                  onRetry: () => _downloadService.retry(task),
                ).animate().fadeIn(duration: 200.ms, delay: (index * 30).ms);
              },
            ),
    );
  }
}

/// 下载任务卡片
class _DownloadTaskCard extends StatelessWidget {
  final DownloadTask task;
  final VoidCallback onCancel;
  final VoidCallback onRetry;

  const _DownloadTaskCard({
    required this.task,
    required this.onCancel,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final song = task.song;

    return GlassmorphicContainer(
      margin: const EdgeInsets.only(bottom: 12),
      borderRadius: 16,
      blur: 10,
      opacity: 0.1,
      child: Padding(
        padding: const EdgeInsets.all(12),
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
                    style: theme.textTheme.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    song.artistNames,
                    style: theme.textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  
                  // 进度条
                  if (task.status == DownloadStatus.downloading)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: task.progress,
                        minHeight: 4,
                        backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
                      ),
                    )
                  else
                    Row(
                      children: [
                        _buildStatusIcon(),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _getStatusText(),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: _getStatusColor(theme),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            
            // 操作按钮
            _buildActionButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIcon() {
    switch (task.status) {
      case DownloadStatus.pending:
        return const Icon(Icons.hourglass_empty_rounded, size: 14, color: Colors.grey);
      case DownloadStatus.downloading:
        return const Icon(Icons.downloading_rounded, size: 14, color: Colors.blue);
      case DownloadStatus.completed:
        return const Icon(Icons.check_circle_rounded, size: 14, color: Colors.green);
      case DownloadStatus.failed:
        return const Icon(Icons.error_rounded, size: 14, color: Colors.red);
    }
  }

  String _getStatusText() {
    switch (task.status) {
      case DownloadStatus.pending:
        return '等待中';
      case DownloadStatus.downloading:
        return '${(task.progress * 100).toStringAsFixed(0)}%';
      case DownloadStatus.completed:
        return '已完成';
      case DownloadStatus.failed:
        return task.error ?? '下载失败';
    }
  }

  Color _getStatusColor(ThemeData theme) {
    switch (task.status) {
      case DownloadStatus.pending:
        return Colors.grey;
      case DownloadStatus.downloading:
        return theme.colorScheme.primary;
      case DownloadStatus.completed:
        return Colors.green;
      case DownloadStatus.failed:
        return theme.colorScheme.error;
    }
  }

  Widget _buildActionButton(BuildContext context) {
    switch (task.status) {
      case DownloadStatus.pending:
      case DownloadStatus.downloading:
        return IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: onCancel,
          tooltip: '取消',
        );
      case DownloadStatus.failed:
        return IconButton(
          icon: const Icon(Icons.refresh_rounded),
          onPressed: onRetry,
          tooltip: '重试',
        );
      case DownloadStatus.completed:
        return IconButton(
          icon: const Icon(Icons.folder_open_rounded),
          onPressed: () async {
            if (task.filePath != null) {
              final file = File(task.filePath!);
              final dir = file.parent.path;
              
              if (Platform.isMacOS) {
                await Process.run('open', [dir]);
              } else if (Platform.isWindows) {
                await Process.run('explorer', [dir]);
              } else if (Platform.isLinux) {
                await Process.run('xdg-open', [dir]);
              }
            }
          },
          tooltip: '打开位置',
        );
    }
  }
}
