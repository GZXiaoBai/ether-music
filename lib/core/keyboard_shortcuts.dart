import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ether_music/state/player_state.dart';

/// 键盘快捷键配置
/// 支持的快捷键:
/// - Space: 播放/暂停
/// - Left/Right: 快进/快退 5 秒
/// - Up/Down: 音量增减
/// - N: 下一首
/// - P: 上一首
/// - M: 静音/取消静音
/// - L: 循环模式切换
/// - 1-9: 跳转到歌曲对应比例位置
class KeyboardShortcuts extends ConsumerStatefulWidget {
  final Widget child;

  const KeyboardShortcuts({
    super.key,
    required this.child,
  });

  @override
  ConsumerState<KeyboardShortcuts> createState() => _KeyboardShortcutsState();
}

class _KeyboardShortcutsState extends ConsumerState<KeyboardShortcuts> {
  final FocusNode _focusNode = FocusNode();
  double _previousVolume = 1.0;

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    final engine = ref.read(audioEngineProvider);
    final key = event.logicalKey;

    // Space: 播放/暂停
    if (key == LogicalKeyboardKey.space) {
      engine.togglePlay();
      return;
    }

    // Left: 快退 5 秒
    if (key == LogicalKeyboardKey.arrowLeft) {
      final newPosition = engine.position - const Duration(seconds: 5);
      engine.seek(newPosition.isNegative ? Duration.zero : newPosition);
      return;
    }

    // Right: 快进 5 秒
    if (key == LogicalKeyboardKey.arrowRight) {
      final duration = engine.duration;
      if (duration != null) {
        final newPosition = engine.position + const Duration(seconds: 5);
        engine.seek(newPosition > duration ? duration : newPosition);
      }
      return;
    }

    // Up: 增加音量
    if (key == LogicalKeyboardKey.arrowUp) {
      final newVolume = (engine.volume + 0.1).clamp(0.0, 1.0);
      engine.setVolume(newVolume);
      return;
    }

    // Down: 减少音量
    if (key == LogicalKeyboardKey.arrowDown) {
      final newVolume = (engine.volume - 0.1).clamp(0.0, 1.0);
      engine.setVolume(newVolume);
      return;
    }

    // N: 下一首
    if (key == LogicalKeyboardKey.keyN) {
      engine.playNext();
      return;
    }

    // P: 上一首
    if (key == LogicalKeyboardKey.keyP) {
      engine.playPrevious();
      return;
    }

    // M: 静音/取消静音
    if (key == LogicalKeyboardKey.keyM) {
      if (engine.volume > 0) {
        _previousVolume = engine.volume;
        engine.setVolume(0);
      } else {
        engine.setVolume(_previousVolume);
      }
      return;
    }

    // L: 循环模式切换
    if (key == LogicalKeyboardKey.keyL) {
      engine.togglePlayMode();
      return;
    }

    // 1-9: 跳转到歌曲对应比例位置
    final numKeys = {
      LogicalKeyboardKey.digit1: 0.1,
      LogicalKeyboardKey.digit2: 0.2,
      LogicalKeyboardKey.digit3: 0.3,
      LogicalKeyboardKey.digit4: 0.4,
      LogicalKeyboardKey.digit5: 0.5,
      LogicalKeyboardKey.digit6: 0.6,
      LogicalKeyboardKey.digit7: 0.7,
      LogicalKeyboardKey.digit8: 0.8,
      LogicalKeyboardKey.digit9: 0.9,
    };

    if (numKeys.containsKey(key)) {
      final duration = engine.duration;
      if (duration != null) {
        final newPosition = Duration(
          milliseconds: (duration.inMilliseconds * numKeys[key]!).toInt(),
        );
        engine.seek(newPosition);
      }
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: widget.child,
    );
  }
}

/// 快捷键帮助对话框
class ShortcutsHelpDialog extends StatelessWidget {
  const ShortcutsHelpDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    final shortcuts = [
      ('Space', '播放 / 暂停'),
      ('←', '快退 5 秒'),
      ('→', '快进 5 秒'),
      ('↑', '增加音量'),
      ('↓', '减少音量'),
      ('N', '下一首'),
      ('P', '上一首'),
      ('M', '静音 / 取消静音'),
      ('L', '切换循环模式'),
      ('1-9', '跳转到对应进度'),
    ];

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.keyboard_rounded, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          const Text('键盘快捷键'),
        ],
      ),
      content: SizedBox(
        width: 300,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: shortcuts.map((s) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    s.$1,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(child: Text(s.$2)),
              ],
            ),
          )).toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('关闭'),
        ),
      ],
    );
  }
}
