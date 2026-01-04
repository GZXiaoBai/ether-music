import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ether_music/theme/app_theme.dart';
import 'package:ether_music/components/player_bar.dart'; // Using the original player bar which is more mobile-friendly or we might need to adjust

class MobileLayout extends StatelessWidget {
  final Widget child;

  const MobileLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final route = GoRouterState.of(context).uri.path;

    return Scaffold(
      body: Stack(
        children: [
          child,
          // Mobile usually has player bar above bottom nav or integrated.
          // For now, let's put content, then player bar at bottom above nav bar
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _getSelectedIndex(route),
        onDestinationSelected: (index) => _onItemTapped(context, index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded, color: AppTheme.appleMusicRed),
            label: '首页',
          ),
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore_rounded, color: AppTheme.appleMusicRed),
            label: '发现',
          ),
          NavigationDestination(
            icon: Icon(Icons.library_music_outlined),
            selectedIcon: Icon(Icons.library_music_rounded, color: AppTheme.appleMusicRed),
            label: '资料库',
          ),
        ],
      ),
      // Add a persistent player bar above the navigation bar? 
      // Or use the scaffold's persistentFooterButtons / bottomSheet?
      // A common pattern is putting the player bar just above the nav bar.
      // Let's modify to use a Column if possible, but NavigationBar is usually at the bottom of Scaffold.
      // We can use `bottomSheet` for the PlayerBar if it's persistent.
      bottomSheet: SizedBox(
        height: 64, 
        child: const MiniPlayerBar(), 
      ),
    );
  }

  int _getSelectedIndex(String route) {
    if (route.startsWith('/home')) return 0;
    if (route.startsWith('/search') || route.startsWith('/toplists')) return 1;
    if (route.startsWith('/library') || route.startsWith('/playlist')) return 2;
    return 0;
  }

  void _onItemTapped(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/search'); // Or toplists as discovery
        break;
      case 2:
        context.go('/library');
        break;
    }
  }
}
