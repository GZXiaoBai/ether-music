import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:ether_music/core/local_storage_service.dart';
import 'package:ether_music/pages/downloads/downloads_page.dart';
import 'package:ether_music/state/player_state.dart';
import 'package:ether_music/theme/app_theme.dart';
import 'package:ether_music/api/models/song.dart';
import 'package:ether_music/components/desktop_song_row.dart';
import 'package:ether_music/components/playlist_import_dialog.dart';

class LibraryPage extends ConsumerStatefulWidget {
  const LibraryPage({super.key});

  @override
  ConsumerState<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends ConsumerState<LibraryPage>
    with SingleTickerProviderStateMixin {
  final LocalStorageService _storage = LocalStorageService();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _storage.addListener(_onStorageUpdate);
    
    // 延迟一帧处理初始 tab，确保路由参数可用
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleTabSelection();
    });
  }

  @override
  void didUpdateWidget(LibraryPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    _handleTabSelection();
  }

  void _handleTabSelection() {
    final state = GoRouterState.of(context);
    final tab = state.uri.queryParameters['tab'];
    if (tab == '1' && _tabController.index != 1) {
      _tabController.animateTo(1);
    } else if (tab == null && _tabController.index != 0) {
      // 可选：如果没参数，切回默认？
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _storage.removeListener(_onStorageUpdate);
    super.dispose();
  }

  void _onStorageUpdate() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // DesktopLayout 透明背景
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(32, 24, 32, 16),
              child: Row(
                children: [
                  Text(
                    '我的音乐',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () async {
                      final result = await showDialog<bool>(
                        context: context,
                        builder: (context) => const PlaylistImportDialog(),
                      );
                      if (result == true && mounted) {
                        setState(() {}); // 刷新列表
                      }
                    },
                    icon: const Icon(Icons.playlist_add, size: 20),
                    label: const Text('导入歌单'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.appleMusicRed,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPersistentHeader(
            delegate: _StickyTabBarDelegate(
              tabBar: TabBar(
                controller: _tabController,
                isScrollable: true,
                labelColor: theme.colorScheme.onSurface,
                unselectedLabelColor: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                indicatorColor: AppTheme.appleMusicRed,
                indicatorWeight: 3,
                labelPadding: const EdgeInsets.symmetric(horizontal: 24),
                dividerColor: Colors.transparent,
                splashFactory: NoSplash.splashFactory,
                overlayColor: WidgetStateProperty.all(Colors.transparent),
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
                tabs: [
                  Tab(text: '我喜欢的 (${_storage.favorites.length})'),
                  Tab(text: '最近播放 (${_storage.playHistory.length})'),
                  const Tab(text: '下载管理'), // Downloads could be a separate page but tabs work fine
                ],
              ),
              color: theme.colorScheme.surface,
            ),
            pinned: true,
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildSongList(_storage.favorites, isFavoriteList: true),
            _buildSongList(_storage.playHistory),
            const DownloadsPage(), // Reuse DownloadsPage content directly
          ],
        ),
      ),
    );
  }

  Widget _buildSongList(List<Song> songs, {bool isFavoriteList = false}) {
    if (songs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
             Icon(Icons.music_off_rounded, size: 60, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2)),
             const SizedBox(height: 16),
             Text(
               '暂无音乐',
               style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
             ),
          ],
        ),
      );
    }

    final currentSong = ref.watch(currentSongProvider).valueOrNull;

    return CustomScrollView(
      slivers: [
        if (songs.isNotEmpty)
          SliverToBoxAdapter(
             child: Padding(
               padding: const EdgeInsets.fromLTRB(32, 16, 32, 8),
               child: Row(
                 children: [
                    ElevatedButton.icon(
                      onPressed: () {
                         ref.read(audioEngineProvider).setQueue(songs, startIndex: 0);
                      },
                      icon: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 18),
                      label: const Text('播放全部', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.appleMusicRed,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: () {
                         final shuffled = List<Song>.from(songs)..shuffle();
                         ref.read(audioEngineProvider).setQueue(shuffled, startIndex: 0);
                      },
                      icon: const Icon(Icons.shuffle_rounded, size: 18),
                      label: const Text('随机播放'),
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
                const SizedBox(width: 50), // 序号
                const SizedBox(width: 56), // 封面
                Expanded(flex: 4, child: Text('标题', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)))),
                Expanded(flex: 3, child: Text('歌手', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)))),
                Expanded(flex: 2, child: Text('平台', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)))),
                const SizedBox(width: 80), // 操作
              ],
            ),
          ),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final song = songs[index];
              final isPlaying = currentSong?.id == song.id &&
                  currentSong?.platform == song.platform;

              return DesktopSongRow(
                index: index + 1,
                song: song,
                isPlaying: isPlaying,
                onTap: () {
                  ref.read(audioEngineProvider).setQueue(songs, startIndex: index);
                },
                customTrailing: isFavoriteList ? [
                  IconButton(
                    icon: const Icon(Icons.favorite_rounded, color: AppTheme.appleMusicRed, size: 20),
                    tooltip: '取消收藏',
                    onPressed: () async {
                      _storage.toggleFavorite(song);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.play_circle_outline_rounded, size: 20),
                    onPressed: () {
                      ref.read(audioEngineProvider).setQueue(songs, startIndex: index);
                    },
                  ),
                ] : null, // keep default for history
              ).animate().fadeIn(duration: 200.ms, delay: (index * 20).ms);
            },
            childCount: songs.length,
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 40)),
      ],
    );
  }
}

class _StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  final Color color;

  _StickyTabBarDelegate({required this.tabBar, required this.color});

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          color: color.withValues(alpha: 0.2), // Much more transparent for Aurora effect
          child: tabBar,
        ),
      ),
    );
  }

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return true;
  }
}
