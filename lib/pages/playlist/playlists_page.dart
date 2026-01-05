import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ether_music/theme/app_theme.dart';
import 'package:ether_music/core/local_storage_service.dart';
import 'package:ether_music/api/models/song.dart';
import 'package:ether_music/components/playlist_import_dialog.dart';

class PlaylistsPage extends ConsumerStatefulWidget {
  const PlaylistsPage({super.key});

  @override
  ConsumerState<PlaylistsPage> createState() => _PlaylistsPageState();
}

class _PlaylistsPageState extends ConsumerState<PlaylistsPage> {
  final _storage = LocalStorageService();

  @override
  void initState() {
    super.initState();
    _storage.addListener(_onStorageUpdate);
  }

  @override
  void dispose() {
    _storage.removeListener(_onStorageUpdate);
    super.dispose();
  }

  void _onStorageUpdate() {
    if (mounted) setState(() {});
  }

  void _showCreatePlaylistDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('新建歌单'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: '请输入歌单名称',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (_) => _createPlaylist(controller.text),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => _createPlaylist(controller.text),
            child: const Text('创建'),
          ),
        ],
      ),
    );
  }

  void _createPlaylist(String name) async {
    if (name.trim().isEmpty) return;
    Navigator.pop(context);
    await _storage.createPlaylist(name);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final playlists = _storage.customPlaylists;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(32, 24, 32, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '我的歌单',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      TextButton.icon(
                        onPressed: () async {
                          final result = await showDialog<bool>(
                            context: context,
                            builder: (context) => const PlaylistImportDialog(),
                          );
                          if (result == true && mounted) {
                            setState(() {});
                          }
                        },
                        icon: const Icon(Icons.cloud_download_rounded, size: 18),
                        label: const Text('导入歌单'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.appleMusicRed,
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: _showCreatePlaylistDialog,
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('新建歌单'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.appleMusicRed,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          if (playlists.isEmpty)
             SliverFillRemaining(
               hasScrollBody: false,
               child: Center(
                 child: Column(
                   mainAxisSize: MainAxisSize.min,
                   children: [
                     Icon(Icons.playlist_add_rounded, size: 64, color: theme.colorScheme.onSurface.withValues(alpha: 0.2)),
                     const SizedBox(height: 16),
                     Text(
                       '还没有歌单',
                       style: theme.textTheme.titleMedium?.copyWith(
                         color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                       ),
                     ),
                     const SizedBox(height: 8),
                     TextButton(
                       onPressed: _showCreatePlaylistDialog,
                       child: const Text('创建第一个歌单'),
                     ),
                   ],
                 ),
               ),
             )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 220,
                  childAspectRatio: 0.8,
                  crossAxisSpacing: 24,
                  mainAxisSpacing: 24,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final playlist = playlists[index];
                    return _PlaylistCard(playlist: playlist);
                  },
                  childCount: playlists.length,
                ),
              ),
            ),
          
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }
}

class _PlaylistCard extends StatefulWidget {
  final Playlist playlist;

  const _PlaylistCard({required this.playlist});

  @override
  State<_PlaylistCard> createState() => _PlaylistCardState();
}

class _PlaylistCardState extends State<_PlaylistCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: () {
           context.push('/playlist/${widget.playlist.id}?source=local', extra: {
             'name': widget.playlist.name,
             'coverUrl': widget.playlist.coverUrl,
             'source': 'local',
           });
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: _isHovered ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        )
                      ] : null,
                      image: widget.playlist.coverUrl != null ? DecorationImage(
                        image: NetworkImage(widget.playlist.coverUrl!),
                        fit: BoxFit.cover,
                      ) : null,
                      color: theme.colorScheme.surfaceContainerHighest,
                    ),
                    child: widget.playlist.coverUrl == null 
                        ? const Center(child: Icon(Icons.music_note_rounded, size: 48, color: Colors.grey)) 
                        : null,
                  ),
                  if (_isHovered)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: const BoxDecoration(
                            color: AppTheme.appleMusicRed,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.play_arrow_rounded, color: Colors.white),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              widget.playlist.name,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              '${widget.playlist.trackCount} 首歌曲',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
