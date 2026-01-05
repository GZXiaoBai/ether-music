import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ether_music/theme/app_theme.dart';
import 'package:ether_music/state/app_state.dart';
import 'dart:io';
import 'package:window_manager/window_manager.dart';

class TopBar extends ConsumerStatefulWidget {
  const TopBar({super.key});

  @override
  ConsumerState<TopBar> createState() => _TopBarState();
}

class _TopBarState extends ConsumerState<TopBar> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _handleSearch(String value) {
    if (value.trim().isNotEmpty) {
      ref.read(searchResultsProvider.notifier).search(value);
      context.go('/search');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isWindowsOrLinux = Platform.isWindows || Platform.isLinux;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onPanStart: isWindowsOrLinux ? (_) => windowManager.startDragging() : null,
      child: Container(
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          children: [
            // 导航按钮
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _NavButton(
                  icon: Icons.chevron_left_rounded,
                  onTap: () => context.canPop() ? context.pop() : null,
                ),
                const SizedBox(width: 8),
                _NavButton(
                  icon: Icons.chevron_right_rounded,
                  onTap: () {}, // TODO: Forward navigation
                ),
              ],
            ),
            
            const SizedBox(width: 24),
            
            // 搜索框
            Expanded(
              child: Container(
                height: 36,
                constraints: const BoxConstraints(maxWidth: 400),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(fontSize: 13),
                  textAlignVertical: TextAlignVertical.center,
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: '搜索音乐、歌手、歌词...',
                    hintStyle: TextStyle(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                      fontSize: 13,
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      size: 18,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  onSubmitted: _handleSearch,
                ),
              ),
            ),
            
            const Spacer(),
            
            // 工具栏
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.settings_outlined, size: 20),
                  onPressed: () => context.push('/settings'),
                  tooltip: '设置',
                ),
                // Windows/Linux 窗口控制
                if (isWindowsOrLinux) ...[
                  const SizedBox(width: 16),
                  _WindowButton(
                    icon: Icons.remove_rounded,
                    onTap: () => windowManager.minimize(),
                    tooltip: '最小化',
                  ),
                  _WindowButton(
                    icon: Icons.crop_square_rounded,
                    onTap: () async {
                      if (await windowManager.isMaximized()) {
                        windowManager.unmaximize();
                      } else {
                        windowManager.maximize();
                      }
                    },
                    tooltip: '最大化',
                  ),
                  _WindowButton(
                    icon: Icons.close_rounded,
                    onTap: () => windowManager.close(),
                    tooltip: '关闭',
                    isClose: true,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _NavButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          color: Colors.transparent,
        ),
        child: Icon(
          icon, 
          size: 22, 
          color: onTap != null ? null : Colors.grey.withValues(alpha: 0.3),
        ),
      ),
    );
  }
}

class _WindowButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;
  final bool isClose;

  const _WindowButton({
    required this.icon,
    required this.onTap,
    required this.tooltip,
    this.isClose = false,
  });

  @override
  State<_WindowButton> createState() => _WindowButtonState();
}

class _WindowButtonState extends State<_WindowButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Tooltip(
          message: widget.tooltip,
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _isHovered
                  ? (widget.isClose ? Colors.red : Colors.white.withValues(alpha: 0.1))
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(
              widget.icon,
              size: 16,
              color: _isHovered && widget.isClose ? Colors.white : null,
            ),
          ),
        ),
      ),
    );
  }
}
