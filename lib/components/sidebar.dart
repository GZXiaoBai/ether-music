import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:ui';
import 'package:ether_music/theme/app_theme.dart';

class Sidebar extends ConsumerWidget {
  const Sidebar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final state = GoRouterState.of(context);
    final route = state.uri.path;
    final query = state.uri.queryParameters;

    return Container(
      width: 240,
      color: Colors.transparent, // 依赖 DesktopLayout 的背景
      child: Column(
        children: [
          const SizedBox(height: 20),
          
          // 导航菜单
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _buildSectionTitle(theme, '发现'),
                _NavItem(
                  icon: Icons.home_rounded,
                  label: '今日推荐',
                  isSelected: route == '/' || route == '/home',
                  onTap: () => context.go('/home'),
                ),
                _NavItem(
                  icon: Icons.explore_rounded,
                  label: '排行榜',
                  isSelected: route == '/toplists',
                  onTap: () => context.go('/toplists'),
                ),
                
                const SizedBox(height: 20),
                _buildSectionTitle(theme, '我的音乐'),
                _NavItem(
                  icon: Icons.favorite_rounded,
                  label: '我喜欢的',
                  isSelected: route == '/library' && query['tab'] != '1',
                  onTap: () => context.go('/library'),
                ),
                _NavItem(
                  icon: Icons.history_rounded,
                  label: '最近播放',
                  isSelected: route == '/library' && query['tab'] == '1',
                  onTap: () => context.go('/library?tab=1'),
                ),
                _NavItem(
                  icon: Icons.download_rounded,
                  label: '本地与下载',
                  isSelected: route == '/downloads',
                  onTap: () => context.go('/downloads'),
                ),
                
                const SizedBox(height: 20),
                _buildSectionTitle(theme, '歌单'),
                _NavItem(
                  icon: Icons.playlist_play_rounded,
                  label: '我的歌单',
                  isSelected: route == '/playlists',
                  onTap: () => context.go('/playlists'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Text(
        title.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2, // 增加字间距
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isSelected ? AppTheme.appleMusicRed : theme.colorScheme.onSurface.withValues(alpha: 0.8);
    final bgColor = isSelected ? AppTheme.appleMusicRed.withValues(alpha: 0.1) : Colors.transparent;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          hoverColor: theme.colorScheme.onSurface.withValues(alpha: 0.05),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10), // 更圆润
            ),
            child: Row(
              children: [
                Icon(icon, size: 20, color: color),
                const SizedBox(width: 14),
                Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: color,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
