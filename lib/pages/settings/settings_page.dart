import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:ether_music/theme/glassmorphism.dart';

/// 音质选项
enum AudioQuality {
  standard('standard', '标准', '128kbps', Icons.music_note_rounded),
  higher('higher', '较高', '192kbps', Icons.music_note_rounded),
  exhigh('exhigh', '极高', '320kbps', Icons.high_quality_rounded),
  lossless('lossless', '无损', 'FLAC', Icons.hd_rounded),
  hires('hires', 'Hi-Res', '24bit', Icons.surround_sound_rounded);

  final String value;
  final String label;
  final String bitrate;
  final IconData icon;

  const AudioQuality(this.value, this.label, this.bitrate, this.icon);
}

/// 设置状态
final audioQualityProvider = StateProvider<AudioQuality>((ref) => AudioQuality.exhigh);
final downloadQualityProvider = StateProvider<AudioQuality>((ref) => AudioQuality.lossless);
final autoPlayProvider = StateProvider<bool>((ref) => true);
final savePlaylistProvider = StateProvider<bool>((ref) => true);

/// 设置页面
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final audioQuality = ref.watch(audioQualityProvider);
    final downloadQuality = ref.watch(downloadQualityProvider);
    final autoPlay = ref.watch(autoPlayProvider);
    final savePlaylist = ref.watch(savePlaylistProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 音质设置
          _buildSectionTitle(context, '音质设置', Icons.equalizer_rounded),
          const SizedBox(height: 12),
          
          _SettingsCard(
            title: '在线播放音质',
            subtitle: '${audioQuality.label} (${audioQuality.bitrate})',
            icon: audioQuality.icon,
            onTap: () => _showQualityPicker(
              context, 
              ref, 
              audioQualityProvider, 
              '选择播放音质',
            ),
          ).animate().fadeIn(duration: 300.ms).slideX(begin: -0.1),
          
          const SizedBox(height: 8),
          
          _SettingsCard(
            title: '下载音质',
            subtitle: '${downloadQuality.label} (${downloadQuality.bitrate})',
            icon: Icons.download_rounded,
            onTap: () => _showQualityPicker(
              context, 
              ref, 
              downloadQualityProvider, 
              '选择下载音质',
            ),
          ).animate().fadeIn(duration: 300.ms, delay: 50.ms).slideX(begin: -0.1),

          const SizedBox(height: 24),

          // 播放设置
          _buildSectionTitle(context, '播放设置', Icons.play_circle_outline_rounded),
          const SizedBox(height: 12),

          _SettingsSwitch(
            title: '自动播放',
            subtitle: '打开应用时自动继续上次播放',
            icon: Icons.play_arrow_rounded,
            value: autoPlay,
            onChanged: (v) => ref.read(autoPlayProvider.notifier).state = v,
          ).animate().fadeIn(duration: 300.ms, delay: 100.ms).slideX(begin: -0.1),

          const SizedBox(height: 8),

          _SettingsSwitch(
            title: '保存播放列表',
            subtitle: '退出时保存当前播放队列',
            icon: Icons.queue_music_rounded,
            value: savePlaylist,
            onChanged: (v) => ref.read(savePlaylistProvider.notifier).state = v,
          ).animate().fadeIn(duration: 300.ms, delay: 150.ms).slideX(begin: -0.1),

          const SizedBox(height: 24),

          // 存储设置
          _buildSectionTitle(context, '存储', Icons.folder_rounded),
          const SizedBox(height: 12),

          _SettingsCard(
            title: '下载位置',
            subtitle: '~/Music/Ether',
            icon: Icons.folder_open_rounded,
            onTap: () {
              // TODO: 选择下载目录
            },
          ).animate().fadeIn(duration: 300.ms, delay: 200.ms).slideX(begin: -0.1),

          const SizedBox(height: 8),

          _SettingsCard(
            title: '清除缓存',
            subtitle: '清除图片和音频缓存',
            icon: Icons.cleaning_services_rounded,
            onTap: () => _showClearCacheDialog(context),
          ).animate().fadeIn(duration: 300.ms, delay: 250.ms).slideX(begin: -0.1),

          const SizedBox(height: 24),

          // 关于
          _buildSectionTitle(context, '关于', Icons.info_outline_rounded),
          const SizedBox(height: 12),

          _SettingsCard(
            title: 'Ether 以太音乐',
            subtitle: 'Version 1.0.0',
            icon: Icons.music_note_rounded,
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.secondary,
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Open Source',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            onTap: () {
              // TODO: 打开关于页面
            },
          ).animate().fadeIn(duration: 300.ms, delay: 300.ms).slideX(begin: -0.1),

          const SizedBox(height: 8),

          _SettingsCard(
            title: '快捷键说明',
            subtitle: '查看键盘快捷键',
            icon: Icons.keyboard_rounded,
            onTap: () => _showShortcutsDialog(context),
          ).animate().fadeIn(duration: 300.ms, delay: 350.ms).slideX(begin: -0.1),

          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title, IconData icon) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }

  void _showQualityPicker(
    BuildContext context, 
    WidgetRef ref, 
    StateProvider<AudioQuality> provider,
    String title,
  ) {
    final theme = Theme.of(context);
    final current = ref.read(provider);

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...AudioQuality.values.map((quality) => ListTile(
              leading: Icon(
                quality.icon,
                color: current == quality 
                    ? theme.colorScheme.primary 
                    : theme.colorScheme.onSurface.withOpacity(0.6),
              ),
              title: Text(quality.label),
              subtitle: Text(quality.bitrate),
              trailing: current == quality 
                  ? Icon(Icons.check_circle_rounded, color: theme.colorScheme.primary)
                  : null,
              onTap: () {
                ref.read(provider.notifier).state = quality;
                Navigator.pop(context);
              },
            )),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showClearCacheDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清除缓存'),
        content: const Text('确定要清除所有缓存吗？这将删除已缓存的图片和音频文件。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              // TODO: 清除缓存
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('缓存已清除')),
              );
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showShortcutsDialog(BuildContext context) {
    final shortcuts = [
      ('Space', '播放 / 暂停'),
      ('←', '快退 5 秒'),
      ('→', '快进 5 秒'),
      ('↑', '增加音量'),
      ('↓', '减少音量'),
      ('N', '下一首'),
      ('P', '上一首'),
      ('M', '静音'),
      ('L', '切换循环模式'),
      ('1-9', '跳转到对应进度'),
    ];

    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Container(
                    width: 60,
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
                      textAlign: TextAlign.center,
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
      ),
    );
  }
}

/// 设置卡片
class _SettingsCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GlassmorphicContainer(
      borderRadius: 16,
      blur: 10,
      opacity: 0.1,
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: theme.colorScheme.primary, size: 20),
        ),
        title: Text(title),
        subtitle: Text(
          subtitle,
          style: theme.textTheme.bodySmall,
        ),
        trailing: trailing ?? Icon(
          Icons.chevron_right_rounded,
          color: theme.colorScheme.onSurface.withOpacity(0.5),
        ),
        onTap: onTap,
      ),
    );
  }
}

/// 设置开关
class _SettingsSwitch extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingsSwitch({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GlassmorphicContainer(
      borderRadius: 16,
      blur: 10,
      opacity: 0.1,
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: theme.colorScheme.primary, size: 20),
        ),
        title: Text(title),
        subtitle: Text(
          subtitle,
          style: theme.textTheme.bodySmall,
        ),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeColor: theme.colorScheme.primary,
        ),
      ),
    );
  }
}
