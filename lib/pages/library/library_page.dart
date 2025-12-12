import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:ether_music/pages/downloads/downloads_page.dart';

/// 音乐库页面
class LibraryPage extends ConsumerWidget {
  const LibraryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            backgroundColor: theme.scaffoldBackgroundColor.withOpacity(0.9),
            title: Text(
              '音乐库',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.add_rounded),
                onPressed: () {
                  // TODO: 新建歌单
                  _showCreatePlaylistDialog(context);
                },
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Column(
              children: [
                // 快捷入口
                _buildQuickAccess(context),
                const Divider(height: 32),
                // 我的歌单
                _buildMyPlaylists(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAccess(BuildContext context) {
    final theme = Theme.of(context);

    final items = [
      _QuickAccessItem(
        icon: Icons.favorite_rounded,
        label: '喜欢的音乐',
        subtitle: '0 首',
        color: Colors.red,
        onTap: () {},
      ),
      _QuickAccessItem(
        icon: Icons.history_rounded,
        label: '最近播放',
        subtitle: '查看历史记录',
        color: Colors.blue,
        onTap: () {},
      ),
      _QuickAccessItem(
        icon: Icons.download_rounded,
        label: '下载管理',
        subtitle: '查看下载任务',
        color: Colors.green,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const DownloadsPage()),
          );
        },
      ),
      _QuickAccessItem(
        icon: Icons.folder_rounded,
        label: '本地音乐',
        subtitle: '扫描本地歌曲',
        color: Colors.orange,
        onTap: () {},
      ),
    ];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      item.color.withOpacity(0.8),
                      item.color,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: item.color.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(item.icon, color: Colors.white, size: 24),
              ),
              title: Text(
                item.label,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                item.subtitle,
                style: theme.textTheme.bodySmall,
              ),
              trailing: Icon(
                Icons.chevron_right_rounded,
                color: theme.colorScheme.onSurface.withOpacity(0.3),
              ),
              onTap: item.onTap,
            ),
          ).animate().fadeIn(duration: 300.ms, delay: (index * 50).ms).slideX(begin: -0.1);
        }).toList(),
      ),
    );
  }

  Widget _buildMyPlaylists(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '我的歌单',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.sort_rounded),
                    onPressed: () {},
                    tooltip: '排序',
                  ),
                  IconButton(
                    icon: const Icon(Icons.grid_view_rounded),
                    onPressed: () {},
                    tooltip: '切换视图',
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 空状态
          Center(
            child: Column(
              children: [
                const SizedBox(height: 40),
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Icon(
                    Icons.library_music_rounded,
                    size: 48,
                    color: theme.colorScheme.primary.withOpacity(0.5),
                  ),
                ).animate().scale(duration: 400.ms).fadeIn(),
                const SizedBox(height: 20),
                Text(
                  '还没有创建歌单',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '点击右上角的 + 创建你的第一个歌单',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.4),
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => _showCreatePlaylistDialog(context),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('创建歌单'),
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showCreatePlaylistDialog(BuildContext context) {
    final controller = TextEditingController();
    final theme = Theme.of(context);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('新建歌单'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: '输入歌单名称',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('歌单 "$name" 创建成功')),
                );
              }
            },
            child: const Text('创建'),
          ),
        ],
      ),
    );
  }
}

class _QuickAccessItem {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  _QuickAccessItem({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });
}

