import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:ether_music/api/models/song.dart';
import 'package:ether_music/api/music_service.dart';
import 'package:ether_music/state/player_state.dart';
import 'package:ether_music/theme/app_theme.dart';
import 'package:ether_music/core/local_storage_service.dart';
import 'package:ether_music/core/download_service.dart';
import 'package:ether_music/components/desktop_song_row.dart';

/// 桌面端风格歌单详情页
class PlaylistPage extends ConsumerStatefulWidget {
  final String playlistId;
  final String? playlistName;
  final String? coverUrl;
  final String source;

  const PlaylistPage({
    super.key,
    required this.playlistId,
    this.playlistName,
    this.coverUrl,
    this.source = 'netease',
  });

  @override
  ConsumerState<PlaylistPage> createState() => _PlaylistPageState();
}

class _PlaylistPageState extends ConsumerState<PlaylistPage> {
  final MusicService _musicService = MusicService();
  List<Song> _songs = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPlaylistData();
  }

  Future<void> _loadPlaylistData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      List<Song> songs;
      if (widget.source == 'local') {
        songs = LocalStorageService().getPlaylistSongs(widget.playlistId);
        // 模拟一点延迟，体验更统一？或者不用
        await Future.delayed(const Duration(milliseconds: 200)); 
      } else {
        songs = await _musicService.getPlaylistSongs(
          widget.playlistId,
          source: widget.source,
        );
      }
      
      if (mounted) {
        setState(() {
          _songs = songs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _handleMenuAction(BuildContext context, String action) {
    switch (action) {
      case 'shuffle':
        if (_songs.isNotEmpty) {
          final shuffled = List<Song>.from(_songs)..shuffle();
          ref.read(audioEngineProvider).setQueue(shuffled, startIndex: 0);
        }
        break;
      case 'download':
        for (final song in _songs) {
          DownloadService().download(song);
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('开始下载 ${_songs.length} 首歌曲')),
        );
        break;
      case 'delete':
        _showDeleteConfirmDialog(context);
        break;
    }
  }

  void _showDeleteConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除歌单'),
        content: Text('确定要删除歌单「${widget.playlistName ?? ''}」吗？此操作不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              LocalStorageService().deletePlaylist(widget.playlistId);
              context.pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('歌单已删除')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentSong = ref.watch(currentSongProvider).valueOrNull;

    return Scaffold(
      backgroundColor: Colors.transparent, // 由 DesktopLayout 控制背景
      body: CustomScrollView(
        slivers: [
          // 头部信息区
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 封面
                  Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: widget.coverUrl != null
                          ? CachedNetworkImage(
                              imageUrl: widget.coverUrl!,
                              fit: BoxFit.cover,
                            )
                          : Container(
                              color: theme.colorScheme.surfaceContainerHighest,
                              child: const Icon(Icons.music_note_rounded, size: 64),
                            ),
                    ),
                  ),
                  const SizedBox(width: 32),
                  
                  // 信息
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppTheme.appleMusicRed),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '歌单',
                            style: TextStyle(
                              color: AppTheme.appleMusicRed,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          widget.playlistName ?? '歌单详情',
                          style: theme.textTheme.displaySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 12),
                        // 创建人信息等 (暂无数据，模拟)
                        Row(
                          children: [
                            const CircleAvatar(
                              radius: 12,
                              backgroundImage: NetworkImage('https://github.com/shadcn.png'),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Music Admin',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: AppTheme.appleMusicRed,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '创建 · ${_songs.length} 首歌曲',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        // 操作按钮
                        Row(
                          children: [
                            ElevatedButton.icon(
                              onPressed: _songs.isEmpty ? null : () {
                                ref.read(audioEngineProvider).setQueue(_songs, startIndex: 0);
                              },
                              icon: const Icon(Icons.play_arrow_rounded, color: Colors.white),
                              label: const Text('播放全部', style: TextStyle(color: Colors.white)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.appleMusicRed,
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                              ),
                            ),
                            const SizedBox(width: 16),
                            OutlinedButton.icon(
                              onPressed: () {}, // TODO: Favorite
                              icon: const Icon(Icons.favorite_border_rounded),
                              label: const Text('收藏'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                              ),
                            ),
                            const SizedBox(width: 16),
                            PopupMenuButton<String>(
                              icon: Icon(Icons.more_horiz_rounded, color: theme.colorScheme.onSurface),
                              onSelected: (value) => _handleMenuAction(context, value),
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'shuffle',
                                  child: Row(
                                    children: [
                                      Icon(Icons.shuffle_rounded, size: 20),
                                      SizedBox(width: 12),
                                      Text('随机播放'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'download',
                                  child: Row(
                                    children: [
                                      Icon(Icons.download_rounded, size: 20),
                                      SizedBox(width: 12),
                                      Text('下载全部'),
                                    ],
                                  ),
                                ),
                                if (widget.source == 'local') ...[
                                  const PopupMenuDivider(),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete_rounded, size: 20, color: Colors.red),
                                        SizedBox(width: 12),
                                        Text('删除歌单', style: TextStyle(color: Colors.red)),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 表格头
          if (_songs.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
                child: Row(
                  children: [
                    const SizedBox(width: 50), // 序号宽
                    const SizedBox(width: 56), // 封面宽 + 间距
                    Expanded(flex: 4, child: Text('标题', style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.5)))),
                    Expanded(flex: 3, child: Text('歌手', style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.5)))),
                    Expanded(flex: 3, child: Text('专辑', style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.5)))),
                    SizedBox(width: 60, child: Text('时长', style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.5)), textAlign: TextAlign.right)),
                  ],
                ),
              ),
            ),
             SliverToBoxAdapter(
               child: Padding(
                 padding: const EdgeInsets.symmetric(horizontal: 32),
                 child: Divider(color: theme.colorScheme.onSurface.withValues(alpha: 0.1)),
               ),
             ),

          // 歌曲列表
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            SliverFillRemaining(
              child: Center(child: Text('加载失败: $_error')),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final song = _songs[index];
                  final isPlaying = currentSong?.id == song.id;
                  
                  return DesktopSongRow(
                    index: index + 1,
                    song: song,
                    isPlaying: isPlaying,
                    onTap: () {
                      ref.read(audioEngineProvider).setQueue(_songs, startIndex: index);
                    },
                  );
                },
                childCount: _songs.length,
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }
}


