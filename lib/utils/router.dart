import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ether_music/pages/home/home_page.dart';
import 'package:ether_music/pages/search/search_page.dart';
import 'package:ether_music/pages/player/player_page.dart';
import 'package:ether_music/pages/library/library_page.dart';
import 'package:ether_music/pages/artist/artist_page.dart';
import 'package:ether_music/pages/playlist/playlist_page.dart';
import 'package:ether_music/pages/settings/settings_page.dart';
import 'package:ether_music/pages/downloads/downloads_page.dart';
import 'package:ether_music/components/desktop_layout.dart';
import 'package:ether_music/pages/playlist/playlists_page.dart';
import 'package:ether_music/pages/toplists/toplists_page.dart';
import 'package:ether_music/components/mobile_layout.dart';
import 'dart:io';

/// 路由配置
final GoRouter appRouter = GoRouter(
  initialLocation: '/home',
  routes: [
    // 桌面端主布局（侧边栏 + 顶部栏 + 底部播放栏）
    ShellRoute(
      builder: (context, state, child) {
        final isDesktop = Platform.isMacOS || Platform.isWindows || Platform.isLinux;
        if (isDesktop) {
          return DesktopLayout(child: child);
        } else {
          return MobileLayout(child: child);
        }
      },
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
          path: '/playlists',
          name: 'playlists',
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const PlaylistsPage(),
            transitionsBuilder: _fadeTransition,
          ),
        ),
        GoRoute(
          path: '/toplists',
          name: 'toplists',
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const ToplistsPage(),
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
        GoRoute(
          path: '/downloads',
          name: 'downloads',
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const DownloadsPage(),
            transitionsBuilder: _fadeTransition,
          ),
        ),
         GoRoute(
          path: '/settings',
          name: 'settings', // Settings now inside shell for desktop preference usually? 
                           // Or modal? Let's keep it in shell for now or make it a dialog.
                           // User plan said "PageContent", so likely in shell.
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const SettingsPage(),
            transitionsBuilder: _fadeTransition,
          ),
        ),
         // 歌手详情页 (In Shell)
        GoRoute(
          path: '/artist/:name',
          name: 'artist',
          pageBuilder: (context, state) {
            final name = state.pathParameters['name'] ?? '';
            final extra = state.extra as Map<String, dynamic>?;
            return CustomTransitionPage(
              key: state.pageKey,
              child: ArtistPage(
                artistName: name, // GoRouter already decodes path parameters
                coverUrl: extra?['coverUrl'] as String?,
              ),
              transitionsBuilder: _fadeTransition,
            );
          },
        ),
        // 歌单详情页 (In Shell)
        GoRoute(
          path: '/playlist/:id',
          name: 'playlist',
          pageBuilder: (context, state) {
            final id = state.pathParameters['id'] ?? '';
            final extra = state.extra as Map<String, dynamic>?;
            return CustomTransitionPage(
              key: state.pageKey,
              child: PlaylistPage(
                playlistId: id,
                playlistName: extra?['name'] as String?,
                coverUrl: extra?['coverUrl'] as String?,
                source: extra?['source'] as String? ?? 'netease',
              ),
              transitionsBuilder: _fadeTransition,
            );
          },
        ),
      ],
    ),
    // 全屏播放器页面 (Modal style or separate window, keeping as route for now, maybe not used in desktop flow as much)
    GoRoute(
      path: '/player',
      name: 'player',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const PlayerPage(),
        transitionsBuilder: _slideUpTransition,
      ),
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
