import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ether_music/theme/app_theme.dart';
import 'sidebar.dart';
import 'top_bar.dart';
import 'dart:ui';
import 'desktop_player_bar.dart';

class DesktopLayout extends ConsumerWidget {
  final Widget child;

  const DesktopLayout({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    // 使用 Scaffold 确保 Material 特性
    return Scaffold(
      backgroundColor: Colors.transparent, // 背景由 Container 控制
      body: Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          image: const DecorationImage(
             image: NetworkImage('https://picsum.photos/seed/music_bg/1920/1080'), // 临时使用风景或抽象图作为底层，实际可用本地资源
             fit: BoxFit.cover,
             opacity: 0.2, // 低不透明度混入背景
          ),
        ),
        child: Stack(
          children: [
            // 1. 动态极光背景 (Aurora)
            Positioned.fill(
              child: Container(
                color: theme.brightness == Brightness.dark 
                    ? const Color(0xFF0F0F1A) // 极深蓝黑底
                    : const Color(0xFFF5F5FA),
              ),
            ),
            // 左上角 - 紫色光晕
            Positioned(
              top: -100,
              left: -100,
              width: 600,
              height: 600,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: theme.brightness == Brightness.dark
                        ? [const Color(0xFF4A00E0).withValues(alpha: 0.5), Colors.transparent]
                        : [const Color(0xFFE0C3FC).withValues(alpha: 0.8), Colors.transparent],
                    stops: const [0.0, 0.7],
                  ),
                ),
              ),
            ),
            // 右下角 - 红色光晕
            Positioned(
              bottom: -200,
              right: -100,
              width: 800,
              height: 800,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: theme.brightness == Brightness.dark
                        ? [const Color(0xFFFA233B).withValues(alpha: 0.3), Colors.transparent]
                        : [const Color(0xFFFFDEE9).withValues(alpha: 0.8), Colors.transparent],
                    stops: const [0, 0.6],
                  ),
                ),
              ),
            ),
             // 顶部中间 - 蓝色点缀
            Positioned(
              top: -150,
              right: 200,
              width: 500,
              height: 500,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: theme.brightness == Brightness.dark
                        ? [const Color(0xFF007AFF).withValues(alpha: 0.2), Colors.transparent]
                        : [const Color(0xFFBDE0FE).withValues(alpha: 0.6), Colors.transparent],
                    stops: const [0, 0.7],
                  ),
                ),
              ),
            ),
            // 全局模糊 - 融合所有光晕
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60), // 略微减少模糊，保留颜色层次
                child: Container(color: Colors.transparent),
              ),
            ),
            
            // 2. 主体布局 (叠加在背景之上)
            Column(
          children: [
            // 主体区域 (Sidebar + Content)
            Expanded(
              child: Row(
                children: [
                  // 左侧边栏
                  const SizedBox(
                    width: 240,
                    child: Sidebar(),
                  ),
                  
                  // 分割线
                  Container(
                    width: 1,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
                  ),
                  
                  // 右侧内容区
                  Expanded(
                    child: Column(
                      children: [
                        // 顶部导航栏
                        const TopBar(),
                        
                        // 页面内容
                        Expanded(
                          child: ClipRRect(
                            child: child, // 页面内容
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // 底部播放栏
            const SizedBox(
              height: 120, // 增加高度以容纳悬浮播放栏 (84 + 24 padding)
              child: DesktopPlayerBar(),
            ),

            ],
          ),
        ],
      ),
    ),
    );
  }
}
