import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ether_music/pages/home/home_page.dart';
import 'package:ether_music/pages/search/search_page.dart';
import 'package:ether_music/pages/player/player_page.dart';
import 'package:ether_music/pages/library/library_page.dart';
import 'package:ether_music/pages/artist/artist_page.dart';
import 'package:ether_music/pages/playlist/playlist_page.dart';
import 'package:ether_music/pages/settings/settings_page.dart';
import 'package:ether_music/components/main_layout.dart';

/// 路由配置
final GoRouter appRouter = GoRouter(
  initialLocation: '/home',
  routes: [
    // 主布局（带底部导航栏和播放栏）
    ShellRoute(
      builder: (context, state, child) => MainLayout(child: child),
      routes: [
        GoRoute(
          path: '/home',
          name: 'home',
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const HomePage(),
            transitionsBuilder: _fadeTransition,
          ),
        ),
        GoRoute(
          path: '/search',
          name: 'search',
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const SearchPage(),
            transitionsBuilder: _fadeTransition,
          ),
        ),
        GoRoute(
          path: '/library',
          name: 'library',
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const LibraryPage(),
            transitionsBuilder: _fadeTransition,
          ),
        ),
      ],
    ),
    // 全屏播放器页面
    GoRoute(
      path: '/player',
      name: 'player',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const PlayerPage(),
        transitionsBuilder: _slideUpTransition,
      ),
    ),
    // 设置页面
    GoRoute(
      path: '/settings',
      name: 'settings',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const SettingsPage(),
        transitionsBuilder: _slideTransition,
      ),
    ),
    // 歌手详情页
    GoRoute(
      path: '/artist/:id',
      name: 'artist',
      pageBuilder: (context, state) {
        final id = int.parse(state.pathParameters['id']!);
        final extra = state.extra as Map<String, dynamic>?;
        return CustomTransitionPage(
          key: state.pageKey,
          child: ArtistPage(
            artistId: id,
            artistName: extra?['name'] as String?,
            coverUrl: extra?['coverUrl'] as String?,
          ),
          transitionsBuilder: _slideTransition,
        );
      },
    ),
    // 歌单详情页
    GoRoute(
      path: '/playlist/:id',
      name: 'playlist',
      pageBuilder: (context, state) {
        final id = int.parse(state.pathParameters['id']!);
        final extra = state.extra as Map<String, dynamic>?;
        return CustomTransitionPage(
          key: state.pageKey,
          child: PlaylistPage(
            playlistId: id,
            playlistName: extra?['name'] as String?,
            coverUrl: extra?['coverUrl'] as String?,
          ),
          transitionsBuilder: _slideTransition,
        );
      },
    ),
  ],
);

/// 淡入淡出过渡动画
Widget _fadeTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  return FadeTransition(opacity: animation, child: child);
}

/// 从下向上滑动过渡动画
Widget _slideUpTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  const begin = Offset(0.0, 1.0);
  const end = Offset.zero;
  const curve = Curves.easeOutCubic;

  final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
  final offsetAnimation = animation.drive(tween);

  return SlideTransition(
    position: offsetAnimation,
    child: child,
  );
}

/// 从右向左滑动过渡动画
Widget _slideTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  const begin = Offset(1.0, 0.0);
  const end = Offset.zero;
  const curve = Curves.easeOutCubic;

  final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
  final offsetAnimation = animation.drive(tween);

  return SlideTransition(
    position: offsetAnimation,
    child: child,
  );
}
