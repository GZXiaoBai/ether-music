import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ether_music/api/music_service.dart';
import 'package:ether_music/api/models/song.dart';
import 'package:ether_music/core/local_storage_service.dart';
import 'package:ether_music/theme/app_theme.dart';

/// 歌单导入对话框
class PlaylistImportDialog extends StatefulWidget {
  const PlaylistImportDialog({super.key});

  @override
  State<PlaylistImportDialog> createState() => _PlaylistImportDialogState();
}

class _PlaylistImportDialogState extends State<PlaylistImportDialog> {
  final TextEditingController _urlController = TextEditingController();
  final MusicService _musicService = MusicService();
  final LocalStorageService _storage = LocalStorageService();
  
  bool _isLoading = false;
  String? _errorMessage;
  List<Song>? _previewSongs;
  String? _playlistName;
  _ParsedPlaylist? _parsedInfo;

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  /// 解析歌单链接
  _ParsedPlaylist? _parsePlaylistUrl(String url) {
    // 网易云音乐
    // https://music.163.com/#/playlist?id=123456
    // https://music.163.com/playlist/123456
    // https://y.music.163.com/m/playlist?id=123456
    final neteaseRegexes = [
      RegExp(r'music\.163\.com.*[?&]id=(\d+)'),
      RegExp(r'music\.163\.com/playlist/(\d+)'),
      RegExp(r'163cn\.tv/.*?id=(\d+)'),
    ];
    for (final regex in neteaseRegexes) {
      final match = regex.firstMatch(url);
      if (match != null) {
        return _ParsedPlaylist(source: 'netease', id: match.group(1)!);
      }
    }

    // QQ 音乐
    // https://y.qq.com/n/ryqq/playlist/123456789
    // https://i.y.qq.com/n2/m/share/details/taoge.html?id=123456789
    final qqRegexes = [
      RegExp(r'y\.qq\.com.*playlist[/=](\d+)'),
      RegExp(r'y\.qq\.com.*taoge.*[?&]id=(\d+)'),
    ];
    for (final regex in qqRegexes) {
      final match = regex.firstMatch(url);
      if (match != null) {
        return _ParsedPlaylist(source: 'qq', id: match.group(1)!);
      }
    }

    // 酷我音乐
    // https://www.kuwo.cn/playlist_detail/123456789
    // https://kuwo.cn/playlist_detail/123456789
    final kuwoRegexes = [
      RegExp(r'kuwo\.cn/playlist_detail/(\d+)'),
    ];
    for (final regex in kuwoRegexes) {
      final match = regex.firstMatch(url);
      if (match != null) {
        return _ParsedPlaylist(source: 'kuwo', id: match.group(1)!);
      }
    }

    // 直接输入 ID (假设网易云)
    if (RegExp(r'^\d+$').hasMatch(url.trim())) {
      return _ParsedPlaylist(source: 'netease', id: url.trim());
    }

    return null;
  }

  Future<void> _fetchPlaylist() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      setState(() => _errorMessage = '请输入歌单链接或 ID');
      return;
    }

    final parsed = _parsePlaylistUrl(url);
    if (parsed == null) {
      setState(() => _errorMessage = '无法识别的链接格式，请检查输入');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _previewSongs = null;
      _parsedInfo = parsed;
    });

    try {
      final songs = await _musicService.getPlaylistSongs(parsed.id, source: parsed.source);
      if (songs.isEmpty) {
        setState(() {
          _errorMessage = '歌单为空或无法获取';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _previewSongs = songs;
        _playlistName = '导入的歌单 (${_getPlatformName(parsed.source)})';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = '获取歌单失败: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _importPlaylist() async {
    if (_previewSongs == null || _previewSongs!.isEmpty || _parsedInfo == null) return;

    setState(() => _isLoading = true);

    try {
      // 创建新歌单
      final playlistId = await _storage.createPlaylist(_playlistName ?? '导入的歌单');
      
      // 添加歌曲
      for (final song in _previewSongs!) {
        await _storage.addSongToPlaylist(playlistId, song);
      }

      if (mounted) {
        Navigator.of(context).pop(true); // 返回 true 表示成功
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('成功导入 ${_previewSongs!.length} 首歌曲'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = '导入失败: $e';
        _isLoading = false;
      });
    }
  }

  String _getPlatformName(String source) {
    switch (source) {
      case 'netease': return '网易云音乐';
      case 'qq': return 'QQ 音乐';
      case 'kuwo': return '酷我音乐';
      default: return source;
    }
  }

  void _showTutorial(BuildContext context) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.school_rounded, size: 28, color: AppTheme.appleMusicRed),
                    const SizedBox(width: 12),
                    Text('如何获取歌单链接', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    const Spacer(),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                  ],
                ),
                const SizedBox(height: 20),
                
                // 网易云音乐
                _TutorialSection(
                  icon: Icons.cloud_outlined,
                  color: const Color(0xFFE60026),
                  title: '网易云音乐',
                  steps: const [
                    '1. 打开网易云音乐 App 或网页版',
                    '2. 进入想要导入的歌单',
                    '3. 点击「分享」按钮 → 复制链接',
                    '4. 将链接粘贴到输入框中',
                  ],
                  example: 'music.163.com/playlist?id=123456',
                ),
                const SizedBox(height: 16),
                
                // QQ 音乐
                _TutorialSection(
                  icon: Icons.music_note_rounded,
                  color: const Color(0xFF31C27C),
                  title: 'QQ 音乐',
                  steps: const [
                    '1. 打开 QQ 音乐 App',
                    '2. 进入歌单详情页',
                    '3. 点击右上角「...」→「分享」→ 复制链接',
                    '4. 将链接粘贴到输入框中',
                  ],
                  example: 'y.qq.com/n/ryqq/playlist/123456',
                ),
                const SizedBox(height: 16),
                
                // 酷我音乐
                _TutorialSection(
                  icon: Icons.library_music_rounded,
                  color: const Color(0xFFFF6600),
                  title: '酷我音乐',
                  steps: const [
                    '1. 打开酷我音乐网页版',
                    '2. 找到歌单并进入',
                    '3. 复制浏览器地址栏中的链接',
                    '4. 将链接粘贴到输入框中',
                  ],
                  example: 'kuwo.cn/playlist_detail/123456',
                ),
                
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.lightbulb_outline, color: Colors.blue, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '💡 提示：也可以直接输入歌单 ID（纯数字），默认解析为网易云音乐歌单',
                          style: TextStyle(color: Colors.blue.shade700, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Dialog(
      backgroundColor: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题
              Row(
                children: [
                  const Icon(Icons.playlist_add, size: 28),
                  const SizedBox(width: 12),
                  Text('导入歌单', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    '支持导入网易云音乐、QQ 音乐、酷我音乐的歌单',
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => _showTutorial(context),
                    icon: const Icon(Icons.help_outline, size: 16),
                    label: const Text('如何获取链接?'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.appleMusicRed,
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // 输入框
              TextField(
                controller: _urlController,
                decoration: InputDecoration(
                  hintText: '粘贴歌单链接或输入歌单 ID',
                  prefixIcon: const Icon(Icons.link),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.content_paste),
                    tooltip: '粘贴',
                    onPressed: () async {
                      final data = await Clipboard.getData(Clipboard.kTextPlain);
                      if (data?.text != null) {
                        _urlController.text = data!.text!;
                      }
                    },
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest,
                ),
                onSubmitted: (_) => _fetchPlaylist(),
              ),
              const SizedBox(height: 16),
              
              // 获取按钮
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _fetchPlaylist,
                  icon: _isLoading 
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.search),
                  label: Text(_isLoading ? '获取中...' : '获取歌单'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.appleMusicRed,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              
              // 错误信息
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 20),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red))),
                    ],
                  ),
                ),
              ],
              
              // 预览
              if (_previewSongs != null && _previewSongs!.isNotEmpty) ...[
                const SizedBox(height: 20),
                Row(
                  children: [
                    Text('预览 (${_previewSongs!.length} 首)', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                    const Spacer(),
                    if (_parsedInfo != null)
                      Chip(
                        label: Text(_getPlatformName(_parsedInfo!.source)),
                        backgroundColor: AppTheme.appleMusicRed.withValues(alpha: 0.2),
                        labelStyle: TextStyle(color: AppTheme.appleMusicRed, fontSize: 12),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: _previewSongs!.length.clamp(0, 20), // 最多显示 20 首
                      itemBuilder: (context, index) {
                        final song = _previewSongs![index];
                        return ListTile(
                          dense: true,
                          leading: Text('${index + 1}', style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
                          title: Text(song.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                          subtitle: Text(song.artist, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
                        );
                      },
                    ),
                  ),
                ),
                if (_previewSongs!.length > 20)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text('还有 ${_previewSongs!.length - 20} 首歌曲...', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
                  ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _importPlaylist,
                    icon: const Icon(Icons.playlist_add_check),
                    label: Text('导入到我的歌单 (${_previewSongs!.length} 首)'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ParsedPlaylist {
  final String source;
  final String id;
  
  _ParsedPlaylist({required this.source, required this.id});
}

class _TutorialSection extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final List<String> steps;
  final String example;

  const _TutorialSection({
    required this.icon,
    required this.color,
    required this.title,
    required this.steps,
    required this.example,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
            ],
          ),
          const SizedBox(height: 8),
          ...steps.map((step) => Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 4),
            child: Text(step, style: theme.textTheme.bodySmall),
          )),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              example,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
