import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ether_music/components/player_bar.dart';
import 'package:ether_music/theme/app_theme.dart';

/// Apple Music 风格主布局（包含底部导航栏和迷你播放栏）
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
            bottom: 130, // 迷你播放栏 + 导航栏高度
            child: widget.child,
          ),
          // 迷你播放栏
          const Positioned(
            left: 0,
            right: 0,
            bottom: 58, // 导航栏高度
            child: MiniPlayerBar(),
          ),
          // 底部导航栏
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: AMBottomNavBar(
              currentIndex: _currentIndex,
              onTap: _onDestinationSelected,
            ),
          ),
        ],
      ),
    );
  }
}
