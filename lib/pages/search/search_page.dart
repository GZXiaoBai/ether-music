import 'dart:ui';
import 'dart:io';
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
import 'package:ether_music/core/local_storage_service.dart';
import 'package:ether_music/core/download_service.dart';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final LocalStorageService _storage = LocalStorageService();
  final TextEditingController _mobileSearchController = TextEditingController();

  @override
  void dispose() {
    _mobileSearchController.dispose();
    super.dispose();
  }

  void _handleMobileSearch(String value) {
    if (value.trim().isNotEmpty) {
      ref.read(searchResultsProvider.notifier).search(value);
      _storage.addSearchHistory(value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final searchResults = ref.watch(searchResultsProvider);
    final currentSong = ref.watch(currentSongProvider).valueOrNull;
    final isMobile = !Platform.isMacOS && !Platform.isWindows && !Platform.isLinux;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        slivers: [
          // 移动端搜索框
          if (isMobile)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: TextField(
                  controller: _mobileSearchController,
                  decoration: InputDecoration(
                    hintText: '搜索音乐、歌手...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerHighest,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  textInputAction: TextInputAction.search,
                  onSubmitted: _handleMobileSearch,
                ),
              ),
            ),
          
          // 搜索结果
          searchResults.when(
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, _) => SliverFillRemaining(
              child: Center(child: Text('搜索出错: $error')),
            ),
            data: (songs) {
              if (songs.isEmpty) {
                return SliverFillRemaining(
                   child: _buildSearchHistoryOrEmpty(context),
                );
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index == 0) {
                      return _buildResultHeader(context, songs.length);
                    }
                    if (index == 1) {
                      return _buildTableHeader(context);
                    }
                    
                    final songIndex = index - 2;
                    final song = songs[songIndex];
                    final isPlaying = currentSong?.id == song.id &&
                        currentSong?.platform == song.platform;

                    return _DesktopSearchResultRow(
                      index: songIndex + 1,
                      song: song,
                      isPlaying: isPlaying,
                      onTap: () {
                         ref.read(audioEngineProvider).setQueue(songs, startIndex: songIndex);
                      },
                    ).animate().fadeIn(duration: 200.ms, delay: ((songIndex % 10) * 20).ms);
                  },
                  childCount: songs.length + 2,
                ),
              );
            },
          ),
          
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  Widget _buildSearchHistoryOrEmpty(BuildContext context) {
    final history = _storage.searchHistory;
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (history.isNotEmpty) ...[
            Text(
              '搜索历史',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: history.map((e) => ActionChip(
                label: Text(e),
                onPressed: () {
                  ref.read(searchResultsProvider.notifier).search(e);
                },
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                side: BorderSide.none,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              )).toList(),
            ),
             const SizedBox(height: 40),
          ],
          
          Center(
            child: Column(
              children: [
                Icon(
                  Icons.search_rounded, 
                  size: 64, 
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                ),
                const SizedBox(height: 16),
                Text(
                  '搜索你喜欢的音乐',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultHeader(BuildContext context, int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 24, 32, 16),
      child: Row(
        children: [
          Text(
            '搜索结果',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.appleMusicRed.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count 首',
              style: TextStyle(
                color: AppTheme.appleMusicRed,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 8, 32, 8),
      child: Row(
        children: [
          const SizedBox(width: 50), // 序号
          const SizedBox(width: 56), // 封面
          Expanded(flex: 4, child: Text('标题', style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.5)))),
          Expanded(flex: 3, child: Text('歌手', style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.5)))),
          Expanded(flex: 2, child: Text('平台', style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.5)))),
          SizedBox(width: 60, child: Text('操作', style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.5)), textAlign: TextAlign.right)),
        ],
      ),
    );
  }
}

class _DesktopSearchResultRow extends ConsumerStatefulWidget {
  final int index;
  final Song song;
  final bool isPlaying;
  final VoidCallback onTap;

  const _DesktopSearchResultRow({
    required this.index,
    required this.song,
    required this.isPlaying,
    required this.onTap,
  });

  @override
  ConsumerState<_DesktopSearchResultRow> createState() => _DesktopSearchResultRowState();
}

class _DesktopSearchResultRowState extends ConsumerState<_DesktopSearchResultRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isActive = widget.isPlaying;
    final textColor = isActive ? AppTheme.appleMusicRed : theme.colorScheme.onSurface;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: InkWell(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 10),
          color: _isHovered 
              ? theme.colorScheme.onSurface.withValues(alpha: 0.05) 
              : Colors.transparent,
          child: Row(
            children: [
              // 序号
              SizedBox(
                width: 30,
                child: isActive 
                    ? Icon(Icons.equalizer_rounded, color: AppTheme.appleMusicRed, size: 18)
                    : Text(
                        '${widget.index}', 
                        style: TextStyle(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
              ),
              const SizedBox(width: 20),
              
              // 封面
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: widget.song.coverUrl != null
                 ? CachedNetworkImage(
                     imageUrl: widget.song.coverUrl!,
                     width: 36, height: 36,
                     fit: BoxFit.cover,
                   )
                 : Container(
                    width: 36, height: 36,
                    color: theme.colorScheme.surfaceContainerHighest,
                   ),
              ),
              const SizedBox(width: 20),

              // 标题
              Expanded(
                flex: 4,
                child: Text(
                  widget.song.name,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                  ),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                ),
              ),
              
              // 歌手 (可点击)
              Expanded(
                flex: 3,
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () {
                      context.push(
                        '/artist/${Uri.encodeComponent(widget.song.artist)}',
                        extra: {'coverUrl': widget.song.coverUrl},
                      );
                    },
                    child: Text(
                      widget.song.artist,
                      style: TextStyle(
                        color: isActive ? AppTheme.appleMusicRed.withValues(alpha: 0.8) : theme.colorScheme.onSurface.withValues(alpha: 0.7),
                        fontSize: 13,
                        decoration: TextDecoration.underline,
                        decorationColor: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                      ),
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
              
              // 平台
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getPlatformColor(widget.song.platform).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _getPlatformName(widget.song.platform),
                    style: TextStyle(
                      color: _getPlatformColor(widget.song.platform),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              
              // 按钮
              SizedBox(
                 width: 60,
                 child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (_isHovered) ...[
                      IconButton(
                        icon: const Icon(Icons.add_rounded, size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () {
                           ref.read(audioEngineProvider).addToQueue(widget.song);
                           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已添加到队列')));
                        },
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.download_rounded, size: 18),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () {
                          // TODO
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('开始下载')));
                           DownloadService().download(widget.song); 
                        },
                      ),
                    ]
                  ],
                 ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getPlatformName(String platform) {
    if (platform == 'netease') return '网易云';
    if (platform == 'qq') return 'QQ音乐';
    if (platform == 'kuwo') return '酷我';
    return platform;
  }

  Color _getPlatformColor(String platform) {
    if (platform == 'netease') return  const Color(0xFFE60026);
    if (platform == 'qq') return const Color(0xFF31C27C);
    if (platform == 'kuwo') return const Color(0xFFFF6600);
    return Colors.grey;
  }
}
