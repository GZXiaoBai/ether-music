import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ether_music/components/player_bar.dart';

/// 主布局组件（包含底部导航栏和迷你播放栏）
class MainLayout extends ConsumerStatefulWidget {
  final Widget child;

  const MainLayout({super.key, required this.child});

  @override
  ConsumerState<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends ConsumerState<MainLayout> {
  int _currentIndex = 0;

  final List<String> _routes = ['/home', '/search', '/library'];

  void _onDestinationSelected(int index) {
    if (_currentIndex != index) {
      setState(() {
        _currentIndex = index;
      });
      context.go(_routes[index]);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 根据当前路由更新选中状态
    final currentLocation = GoRouterState.of(context).matchedLocation;
    final newIndex = _routes.indexOf(currentLocation);
    if (newIndex != -1 && newIndex != _currentIndex) {
      _currentIndex = newIndex;
    }

    return Scaffold(
      body: Stack(
        children: [
          // 主内容区域（底部留出播放栏和导航栏的空间）
          Positioned.fill(
            bottom: 140, // 迷你播放栏 + 导航栏高度
            child: widget.child,
          ),
          // 迷你播放栏
          const Positioned(
            left: 0,
            right: 0,
            bottom: 80, // 导航栏高度
            child: MiniPlayerBar(),
          ),
          // 底部导航栏
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildBottomNavBar(context),
          ),
        ],
      ),
    );
  }

  /// 构建底部导航栏
  Widget _buildBottomNavBar(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withOpacity(0.95),
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.1),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavItem(
            icon: Icons.home_rounded,
            label: '首页',
            isSelected: _currentIndex == 0,
            onTap: () => _onDestinationSelected(0),
          ),
          _NavItem(
            icon: Icons.search_rounded,
            label: '搜索',
            isSelected: _currentIndex == 1,
            onTap: () => _onDestinationSelected(1),
          ),
          _NavItem(
            icon: Icons.library_music_rounded,
            label: '音乐库',
            isSelected: _currentIndex == 2,
            onTap: () => _onDestinationSelected(2),
          ),
        ],
      ),
    );
  }
}

/// 导航栏项
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
    final color = isSelected
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurface.withOpacity(0.5);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 80,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.colorScheme.primary.withOpacity(0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
