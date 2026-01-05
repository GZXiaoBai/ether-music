import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:ether_music/state/app_state.dart';
import 'package:ether_music/state/player_state.dart';
import 'package:ether_music/theme/app_theme.dart';
import 'package:ether_music/api/models/song.dart';
import 'package:ether_music/core/audio_engine.dart';
import 'package:ether_music/components/desktop_song_row.dart';

import 'package:ether_music/core/update_service.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      UpdateService().checkUpdate(context, silent: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        slivers: [
          // 欢迎 Banner
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: _buildWelcomeBanner(context, ref),
            ),
          ),

          // 推荐歌单网格
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            sliver: SliverToBoxAdapter(
              child: _SectionHeader(title: '今日推荐', onTapMore: () {}),
            ),
          ),
          
          const SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            sliver: _RecommendedGrid(),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 32)),

          // 热门歌曲列表
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            sliver: SliverToBoxAdapter(
              child: _SectionHeader(title: '热门单曲', onTapMore: () {
                // TODO: View all songs
              }),
            ),
          ),

          const _HotSongsList(),

          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  Widget _buildWelcomeBanner(BuildContext context, WidgetRef ref) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFE2B0FF).withValues(alpha: 0.2), // Lavender
            const Color(0xFF9F44D3).withValues(alpha: 0.2), // Purple
          ],
        ),
        boxShadow: [
          BoxShadow(
             color: Colors.black.withValues(alpha: 0.1),
             blurRadius: 10,
             offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            left: 24,
            top: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hi Music Lover',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '今日为你推荐',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () async {
                    final songs = await ref.read(hotSongsProvider.future);
                    if (context.mounted && songs.isNotEmpty) {
                      ref.read(audioEngineProvider).setQueue(songs);
                    }
                  },
                  icon: const Icon(Icons.play_arrow_rounded, color: Colors.black),
                  label: const Text('播放全部', style: TextStyle(color: Colors.black)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
          // 装饰性图片（模拟图中的二次元风格或其他）
          Positioned(
            right: 24,
            bottom: -20,
            child: Icon(
              Icons.music_note_rounded,
              size: 180,
              color: Colors.white.withValues(alpha: 0.05),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1, end: 0);
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback onTapMore;

  const _SectionHeader({required this.title, required this.onTapMore});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          InkWell(
            onTap: onTapMore,
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  Text(
                    '查看全部',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 16,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecommendedGrid extends ConsumerWidget {
  const _RecommendedGrid();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final toplistsAsync = ref.watch(hotToplistsProvider);

    return toplistsAsync.when(
      loading: () => SliverGrid.count(
        crossAxisCount: 5,
        mainAxisSpacing: 20,
        crossAxisSpacing: 20,
        childAspectRatio: 0.8,
        children: List.generate(5, (_) => _buildPlaceholder(context)),
      ),
      error: (_, __) => SliverToBoxAdapter(child: Container()),
      data: (toplists) => SliverGrid(
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 240, // 响应式网格
          mainAxisSpacing: 24,
          crossAxisSpacing: 24,
          childAspectRatio: 0.75,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final item = toplists[index];
            return _GridItemCard(
              title: item.name,
              coverUrl: item.coverUrl,
              subtitle: '每日更新', // 模拟副标题
              onTap: () {
                context.push(
                    '/playlist/${item.id}',
                    extra: {
                      'name': item.name,
                      'coverUrl': item.coverUrl,
                      'source': item.source,
                    },
                  );
              },
            ).animate().fadeIn(delay: (index * 50).ms);
          },
          childCount: toplists.length,
        ),
      ),
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}

class _GridItemCard extends StatefulWidget {
  final String title;
  final String? coverUrl;
  final String subtitle;
  final VoidCallback onTap;

  const _GridItemCard({
    required this.title,
    this.coverUrl,
    required this.subtitle,
    required this.onTap,
  });

  @override
  State<_GridItemCard> createState() => _GridItemCardState();
}

class _GridItemCardState extends State<_GridItemCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 封面区
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: _isHovered ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        )
                      ] : [],
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
                              child: const Icon(Icons.music_note_rounded, size: 40),
                            ),
                    ),
                  ),
                  
                  // 播放按钮 (Hover 显示)
                  AnimatedOpacity(
                    opacity: _isHovered ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: Center(
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.play_arrow_rounded,
                          color: AppTheme.appleMusicRed,
                          size: 32,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // 标题
            Text(
              widget.title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            // 副标题
            Text(
              widget.subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _HotSongsList extends ConsumerWidget {
  const _HotSongsList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final songsAsync = ref.watch(hotSongsProvider);
    final theme = Theme.of(context);
    final currentSong = ref.watch(currentSongProvider).valueOrNull;

    return songsAsync.when(
      loading: () => SliverToBoxAdapter(
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const SliverToBoxAdapter(child: SizedBox()),
      data: (songs) => SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            if (index >= 12 || index >= songs.length) return null; // 仅显示前 12 首且防止越界
            final song = songs[index];
            final isPlaying = currentSong?.id == song.id;
            
            return DesktopSongRow(
              index: index + 1,
              song: song,
              isPlaying: isPlaying,
              onTap: () {
                 ref.read(audioEngineProvider).setQueue(songs, startIndex: index);
              },
            );
          },
        ),
      ),
    );
  }
}

