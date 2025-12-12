import 'dart:io';
import 'package:flutter/material.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';
import 'package:ether_music/core/audio_engine.dart';

/// 系统托盘管理器（仅桌面端）
class TrayService with TrayListener {
  static final TrayService _instance = TrayService._internal();
  factory TrayService() => _instance;
  TrayService._internal();

  final AudioEngine _audioEngine = AudioEngine();
  bool _isInitialized = false;

  /// 初始化系统托盘
  Future<void> init() async {
    if (_isInitialized) return;
    if (!Platform.isMacOS && !Platform.isWindows && !Platform.isLinux) return;

    await trayManager.setIcon(_getTrayIconPath());
    await trayManager.setToolTip('Ether 以太音乐');
    
    trayManager.addListener(this);
    _isInitialized = true;
    
    // 初始化窗口管理器
    await windowManager.ensureInitialized();
    
    // 设置窗口选项
    WindowOptions windowOptions = const WindowOptions(
      size: Size(1200, 800),
      minimumSize: Size(800, 600),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.hidden,
    );
    
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
    
    _updateTrayMenu();
  }

  String _getTrayIconPath() {
    if (Platform.isMacOS) {
      return 'assets/icons/tray_icon.png';
    } else if (Platform.isWindows) {
      return 'assets/icons/tray_icon.ico';
    }
    return 'assets/icons/tray_icon.png';
  }

  /// 更新托盘菜单
  Future<void> _updateTrayMenu() async {
    final isPlaying = _audioEngine.isPlaying;
    final currentSong = _audioEngine.currentSong;
    
    final menuItems = <MenuItem>[
      MenuItem(
        label: currentSong?.name ?? 'Ether 以太音乐',
        disabled: true,
      ),
      MenuItem.separator(),
      MenuItem(
        label: isPlaying ? '暂停' : '播放',
        onClick: (item) {
          _audioEngine.togglePlay();
          _updateTrayMenu();
        },
      ),
      MenuItem(
        label: '上一首',
        onClick: (item) {
          _audioEngine.playPrevious();
        },
      ),
      MenuItem(
        label: '下一首',
        onClick: (item) {
          _audioEngine.playNext();
        },
      ),
      MenuItem.separator(),
      MenuItem(
        label: '显示窗口',
        onClick: (item) async {
          await windowManager.show();
          await windowManager.focus();
        },
      ),
      MenuItem(
        label: '退出',
        onClick: (item) async {
          await trayManager.destroy();
          exit(0);
        },
      ),
    ];

    await trayManager.setContextMenu(Menu(items: menuItems));
  }

  @override
  void onTrayIconMouseDown() {
    // 点击托盘图标显示窗口
    windowManager.show();
    windowManager.focus();
  }

  @override
  void onTrayIconRightMouseDown() {
    // 右键点击显示菜单
    trayManager.popUpContextMenu();
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    // 菜单项点击回调已在 onClick 中处理
  }

  /// 销毁托盘
  Future<void> dispose() async {
    if (!_isInitialized) return;
    trayManager.removeListener(this);
    await trayManager.destroy();
    _isInitialized = false;
  }

  /// 监听播放状态变化，更新托盘菜单
  void listenToPlaybackChanges() {
    _audioEngine.playerStateStream.listen((_) {
      _updateTrayMenu();
    });
    
    _audioEngine.currentSongNotifier.addListener(() {
      _updateTrayMenu();
    });
  }
}
