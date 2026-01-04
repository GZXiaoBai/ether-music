import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:ether_music/api/music_service.dart';
import 'package:ether_music/api/models/song.dart';
import 'package:ether_music/theme/app_theme.dart';

class ToplistsPage extends StatefulWidget {
  const ToplistsPage({super.key});

  @override
  State<ToplistsPage> createState() => _ToplistsPageState();
}

class _ToplistsPageState extends State<ToplistsPage> {
  final MusicService _musicService = MusicService();
  List<Toplist> _toplists = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadToplists();
  }

  Future<void> _loadToplists() async {
    try {
      final toplists = await _musicService.getToplists();
      if (mounted) {
        setState(() {
          _toplists = toplists;
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(32, 24, 32, 16),
              child: Text(
                '排行榜',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            SliverFillRemaining(
              child: Center(child: Text('加载失败: $_error')),
            )
          else if (_toplists.isEmpty)
             const SliverFillRemaining(
              child: Center(child: Text('暂无榜单')),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                   maxCrossAxisExtent: 200,
                   childAspectRatio: 0.8,
                   crossAxisSpacing: 20,
                   mainAxisSpacing: 20,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final toplist = _toplists[index];
                    return _ToplistCard(toplist: toplist);
                  },
                  childCount: _toplists.length,
                ),
              ),
            ),
          
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }
}

class _ToplistCard extends StatefulWidget {
  final Toplist toplist;

  const _ToplistCard({required this.toplist});

  @override
  State<_ToplistCard> createState() => _ToplistCardState();
}

class _ToplistCardState extends State<_ToplistCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () {
         context.push('/playlist/${widget.toplist.id}?source=${widget.toplist.source}');
      },
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 封面
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                   Container(
                     decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                           if (_isHovered)
                             BoxShadow(
                               color: Colors.black.withValues(alpha: 0.2),
                               blurRadius: 12,
                               offset: const Offset(0, 4),
                             ),
                        ],
                     ),
                     child: ClipRRect(
                       borderRadius: BorderRadius.circular(12),
                       child: widget.toplist.coverUrl != null
                           ? CachedNetworkImage(
                              imageUrl: widget.toplist.coverUrl!,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => Container(color: theme.colorScheme.surfaceContainerHighest),
                             )
                           : Container(
                              color: theme.colorScheme.surfaceContainerHighest,
                              child: const Icon(Icons.music_note_rounded, size: 48, color: Colors.white24),
                             ),
                     ),
                   ),
                   // 播放图标 (Hover 时显示)
                   if (_isHovered)
                     Container(
                       decoration: BoxDecoration(
                         borderRadius: BorderRadius.circular(12),
                         color: Colors.black.withValues(alpha: 0.3),
                       ),
                       child: Center(
                          child: Container(
                             width: 48,
                             height: 48,
                             decoration: const BoxDecoration(
                               shape: BoxShape.circle,
                               color: AppTheme.appleMusicRed,
                             ),
                             child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 28),
                          ),
                       ),
                     ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // 标题
            Text(
              widget.toplist.name,
              style: theme.textTheme.titleMedium?.copyWith(
                 fontWeight: FontWeight.w600,
                 fontSize: 14,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (widget.toplist.updateFrequency != null) ...[
               const SizedBox(height: 4),
               Text(
                 widget.toplist.updateFrequency!,
                 style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    fontSize: 12,
                 ),
                 maxLines: 1,
               ),
            ],
          ],
        ),
      ),
    );
  }
}
