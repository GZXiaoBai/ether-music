import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:ether_music/api/models/song.dart';
import 'package:ether_music/api/music_service.dart';

/// 下载状态
enum DownloadStatus {
  pending,
  downloading,
  completed,
  failed,
}

/// 下载任务
class DownloadTask {
  final Song song;
  final String quality;
  DownloadStatus status;
  double progress;
  String? filePath;
  String? error;

  DownloadTask({
    required this.song,
    required this.quality,
    this.status = DownloadStatus.pending,
    this.progress = 0.0,
    this.filePath,
    this.error,
  });
}

/// 下载服务
class DownloadService extends ChangeNotifier {
  static final DownloadService _instance = DownloadService._internal();
  factory DownloadService() => _instance;
  DownloadService._internal();

  final MusicService _musicService = MusicService();
  final Dio _dio = Dio();
  final List<DownloadTask> _tasks = [];
  final Map<int, CancelToken> _cancelTokens = {};

  List<DownloadTask> get tasks => List.unmodifiable(_tasks);
  List<DownloadTask> get activeTasks => _tasks.where((t) => 
      t.status == DownloadStatus.pending || 
      t.status == DownloadStatus.downloading
  ).toList();

  /// 获取下载目录
  Future<Directory> get downloadDirectory async {
    // 使用应用文档目录，在沙盒环境下也能正常工作
    final appDir = await getApplicationDocumentsDirectory();
    final musicDir = Directory('${appDir.path}/Downloads');
    
    if (!await musicDir.exists()) {
      await musicDir.create(recursive: true);
    }
    return musicDir;
  }

  /// 添加下载任务
  Future<void> download(Song song, {String quality = 'exhigh'}) async {
    // 检查是否已在下载
    if (_tasks.any((t) => t.song.id == song.id && 
        (t.status == DownloadStatus.pending || t.status == DownloadStatus.downloading))) {
      return;
    }

    final task = DownloadTask(song: song, quality: quality);
    _tasks.insert(0, task);
    notifyListeners();

    await _startDownload(task);
  }

  Future<void> _startDownload(DownloadTask task) async {
    task.status = DownloadStatus.downloading;
    notifyListeners();

    try {
      // 获取歌曲 URL
      final url = await _musicService.getSongUrl(
        task.song.id,
        level: task.quality,
        songName: task.song.name,
        artistName: task.song.artistName,
      );
      if (url == null || url.isEmpty) {
        task.status = DownloadStatus.failed;
        task.error = '无法获取下载链接';
        notifyListeners();
        return;
      }

      // 确定文件扩展名
      String extension = 'mp3';
      if (url.contains('.flac')) {
        extension = 'flac';
      } else if (url.contains('.m4a')) {
        extension = 'm4a';
      }

      // 生成文件名
      final safeFileName = _sanitizeFileName('${task.song.artistNames} - ${task.song.name}');
      final dir = await downloadDirectory;
      final filePath = '${dir.path}/$safeFileName.$extension';

      // 创建取消令牌
      final cancelToken = CancelToken();
      _cancelTokens[task.song.id] = cancelToken;

      // 下载文件
      await _dio.download(
        url,
        filePath,
        cancelToken: cancelToken,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            task.progress = received / total;
            notifyListeners();
          }
        },
      );

      task.status = DownloadStatus.completed;
      task.filePath = filePath;
      task.progress = 1.0;
      _cancelTokens.remove(task.song.id);
      notifyListeners();

    } catch (e) {
      if (e is DioException && e.type == DioExceptionType.cancel) {
        _tasks.remove(task);
      } else {
        task.status = DownloadStatus.failed;
        task.error = e.toString();
      }
      _cancelTokens.remove(task.song.id);
      notifyListeners();
    }
  }

  /// 取消下载
  void cancel(DownloadTask task) {
    final cancelToken = _cancelTokens[task.song.id];
    if (cancelToken != null) {
      cancelToken.cancel();
    }
    _tasks.remove(task);
    notifyListeners();
  }

  /// 重试下载
  Future<void> retry(DownloadTask task) async {
    task.status = DownloadStatus.pending;
    task.progress = 0.0;
    task.error = null;
    notifyListeners();
    await _startDownload(task);
  }

  /// 清除已完成任务
  void clearCompleted() {
    _tasks.removeWhere((t) => t.status == DownloadStatus.completed);
    notifyListeners();
  }

  /// 检查歌曲是否已下载
  Future<bool> isDownloaded(Song song) async {
    final dir = await downloadDirectory;
    final files = await dir.list().toList();
    final songName = _sanitizeFileName('${song.artistNames} - ${song.name}');
    
    return files.any((f) => f.path.contains(songName));
  }

  /// 获取已下载歌曲路径
  Future<String?> getDownloadedPath(Song song) async {
    final dir = await downloadDirectory;
    final files = await dir.list().toList();
    final songName = _sanitizeFileName('${song.artistNames} - ${song.name}');
    
    for (final file in files) {
      if (file.path.contains(songName)) {
        return file.path;
      }
    }
    return null;
  }

  String _sanitizeFileName(String name) {
    return name
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}

/// 下载进度指示器
class DownloadProgressIndicator extends StatelessWidget {
  final DownloadTask task;

  const DownloadProgressIndicator({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    switch (task.status) {
      case DownloadStatus.pending:
        return Icon(
          Icons.hourglass_empty_rounded,
          color: theme.colorScheme.onSurface.withOpacity(0.5),
          size: 20,
        );
      case DownloadStatus.downloading:
        return SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            value: task.progress,
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
          ),
        );
      case DownloadStatus.completed:
        return Icon(
          Icons.check_circle_rounded,
          color: Colors.green,
          size: 20,
        );
      case DownloadStatus.failed:
        return Icon(
          Icons.error_rounded,
          color: theme.colorScheme.error,
          size: 20,
        );
    }
  }
}
