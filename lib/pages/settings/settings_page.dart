import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ether_music/theme/app_theme.dart';

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

/// 设置页面 - 桌面端风格适配
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
      backgroundColor: Colors.transparent, // 由 DesktopLayout 提供背景
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(32, 40, 32, 24),
                  child: Text(
                    '设置',
                    style: theme.textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _SectionHeader(title: '音质体验', icon: Icons.equalizer_rounded),
                    _SettingsGroup(
                      children: [
                        _SettingsTile(
                          title: '在线播放音质',
                          subtitle: '${audioQuality.label} (${audioQuality.bitrate})',
                          icon: audioQuality.icon,
                          onTap: () => _showQualityPicker(context, ref, audioQualityProvider, '选择播放音质'),
                        ),
                        const _Divider(),
                        _SettingsTile(
                          title: '下载音质',
                          subtitle: '${downloadQuality.label} (${downloadQuality.bitrate})',
                          icon: Icons.download_rounded,
                          onTap: () => _showQualityPicker(context, ref, downloadQualityProvider, '选择下载音质'),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),
                    _SectionHeader(title: '播放习惯', icon: Icons.play_circle_outline_rounded),
                    _SettingsGroup(
                      children: [
                        _SettingsSwitchTile(
                          title: '自动播放',
                          subtitle: '打开应用时自动继续上次播放',
                          icon: Icons.play_arrow_rounded,
                          value: autoPlay,
                          onChanged: (v) => ref.read(autoPlayProvider.notifier).state = v,
                        ),
                        const _Divider(),
                        _SettingsSwitchTile(
                          title: '保存播放列表',
                          subtitle: '退出时保存当前播放队列',
                          icon: Icons.queue_music_rounded,
                          value: savePlaylist,
                          onChanged: (v) => ref.read(savePlaylistProvider.notifier).state = v,
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),
                    _SectionHeader(title: '存储与缓存', icon: Icons.folder_rounded),
                    _SettingsGroup(
                      children: [
                        _SettingsTile(
                          title: '下载位置',
                          subtitle: '~/Music/Ether',
                          icon: Icons.folder_open_rounded,
                          onTap: () {},
                        ),
                        const _Divider(),
                        _SettingsTile(
                          title: '清除缓存',
                          subtitle: '释放存储空间',
                          icon: Icons.cleaning_services_rounded,
                          onTap: () => _showClearCacheDialog(context),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),
                    _SectionHeader(title: '关于', icon: Icons.info_outline_rounded),
                    _SettingsGroup(
                      children: [
                        _SettingsTile(
                          title: 'Ether 以太音乐',
                          subtitle: 'Version 1.0.0 (Beta)',
                          icon: Icons.music_note_rounded,
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.appleMusicRed.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Open Source',
                              style: TextStyle(
                                color: AppTheme.appleMusicRed,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          onTap: () {},
                        ),
                         const _Divider(),
                        _SettingsTile(
                          title: '快捷键',
                          subtitle: '查看所有键盘快捷键',
                          icon: Icons.keyboard_rounded,
                          onTap: () => _showShortcutsDialog(context),
                        ),
                      ],
                    ),

                    const SizedBox(height: 60),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showQualityPicker(
    BuildContext context, 
    WidgetRef ref, 
    StateProvider<AudioQuality> provider,
    String title,
  ) {
    // ... Picker logic same as before but styled differently if needed ...
    // adapting to a simple dialog for desktop Feel
    final current = ref.read(provider);
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: AudioQuality.values.map((q) => RadioListTile<AudioQuality>(
            title: Text(q.label),
            subtitle: Text(q.bitrate),
            value: q,
            groupValue: current,
            onChanged: (v) {
              if (v != null) {
                ref.read(provider.notifier).state = v;
                Navigator.pop(context);
              }
            },
            activeColor: AppTheme.appleMusicRed,
          )).toList(),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
        ],
      ),
    );
  }

  void _showClearCacheDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清除缓存'),
        content: const Text('确定要清除所有图片和音频缓存吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('缓存已清除')));
            },
            child: const Text('确定', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
  
  void _showShortcutsDialog(BuildContext context) {
      final shortcuts = [
        ('Space', '播放 / 暂停'),
        ('← / →', '快退 / 快进'),
        ('↑ / ↓', '音量调节'),
        ('N / P', '下一首 / 上一首'),
      ];
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('快捷键'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: shortcuts.map((s) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   Container(
                     padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                     decoration: BoxDecoration(
                       color: Colors.grey.withValues(alpha: 0.2),
                       borderRadius: BorderRadius.circular(4),
                     ),
                     child: Text(s.$1, style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold)),
                   ),
                   const SizedBox(width: 20),
                   Text(s.$2),
                ],
              ),
            )).toList(),
          ),
           actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('关闭')),
          ],
        ),
      );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.appleMusicRed),
          const SizedBox(width: 8),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.appleMusicRed,
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  final List<Widget> children;

  const _SettingsGroup({required this.children});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(children: children),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget? trailing;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(icon, color: theme.colorScheme.onSurface),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
      trailing: trailing ?? const Icon(Icons.chevron_right_rounded, color: Colors.grey),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}

class _SettingsSwitchTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingsSwitchTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(icon, color: theme.colorScheme.onSurface),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
      trailing: Switch.adaptive(
        value: value, 
        onChanged: onChanged,
        activeColor: AppTheme.appleMusicRed,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1, 
      thickness: 1, 
      indent: 56, 
      endIndent: 16, 
      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05)
    );
  }
}
