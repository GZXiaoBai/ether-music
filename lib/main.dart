import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ether_music/theme/app_theme.dart';
import 'package:ether_music/utils/router.dart';
import 'package:ether_music/core/keyboard_shortcuts.dart';
import 'package:ether_music/core/tray_service.dart';
import 'package:ether_music/core/local_storage_service.dart';

import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 初始化本地存储服务
  await LocalStorageService().init();
  
  // 桌面端配置
  final isDesktop = Platform.isMacOS || Platform.isWindows || Platform.isLinux;
  if (isDesktop) {
    // 1. 系统托盘
    try {
      final trayService = TrayService();
      await trayService.init();
      trayService.listenToPlaybackChanges();
    } catch (e) {
      debugPrint('Error initializing tray service: $e');
    }

    // 2. 窗口管理 (特别是 Windows/Linux)
    try {
      await windowManager.ensureInitialized();
      
      const windowOptions = WindowOptions(
        size: Size(1200, 800),
        minimumSize: Size(800, 600),
        center: true,
        backgroundColor: Colors.transparent,
        skipTaskbar: false,
        titleBarStyle: TitleBarStyle.hidden, // 隐藏原生标题栏
        title: 'Ether 以太音乐',
      );
      
      await windowManager.waitUntilReadyToShow(windowOptions, () async {
        await windowManager.show();
        await windowManager.focus();
      });
    } catch (e) {
      debugPrint('Error initializing window manager: $e');
    }
  }
  
  runApp(const ProviderScope(child: EtherApp()));
}

/// Ether 音乐播放器主应用
class EtherApp extends ConsumerWidget {
  const EtherApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 判断是否为桌面平台
    final isDesktop = Platform.isMacOS || Platform.isWindows || Platform.isLinux;
    
    Widget app = MaterialApp.router(
      title: 'Ether 以太音乐',
      debugShowCheckedModeBanner: false,

      // 使用深色主题
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,

      // 路由配置
      routerConfig: appRouter,
    );

    // 桌面端添加键盘快捷键支持
    if (isDesktop) {
      app = KeyboardShortcuts(child: app);
    }

    return app;
  }
}
