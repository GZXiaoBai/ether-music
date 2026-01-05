import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ether_music/theme/app_theme.dart';

class UpdateService {
  static final UpdateService _instance = UpdateService._internal();

  factory UpdateService() => _instance;

  UpdateService._internal();

  static const String _owner = 'GZXiaoBai';
  static const String _repo = 'ether-music';
  final Dio _dio = Dio();

  /// 检查更新
  Future<void> checkUpdate(BuildContext context, {bool silent = false}) async {
    try {
      final latestRelease = await _fetchLatestRelease();
      if (latestRelease == null) {
        if (!silent && context.mounted) {
          _showSnackBar(context, '检查更新失败');
        }
        return;
      }

      final currentVersion = await _getCurrentVersion();
      final latestVersion = latestRelease['tag_name'].toString().replaceAll('v', '');

      if (_isNewVersion(currentVersion, latestVersion)) {
        if (context.mounted) {
          _showUpdateDialog(context, latestRelease);
        }
      } else {
        if (!silent && context.mounted) {
          _showSnackBar(context, '当前已是最新版本');
        }
      }
    } catch (e) {
      if (!silent && context.mounted) {
        _showSnackBar(context, '检查更新出错: $e');
      }
    }
  }

  Future<Map<String, dynamic>?> _fetchLatestRelease() async {
    try {
      final response = await _dio.get(
        'https://api.github.com/repos/$_owner/$_repo/releases/latest',
      );

      if (response.statusCode == 200) {
        return response.data;
      }
    } catch (e) {
      debugPrint('Error fetching release: $e');
    }
    return null;
  }

  Future<String> _getCurrentVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.version;
  }

  bool _isNewVersion(String current, String latest) {
    try {
      // 简单处理：移除 build number
      final currentBase = current.split('+')[0];
      final latestBase = latest.split('+')[0];

      List<int> currentParts = currentBase.split('.').map((e) => int.tryParse(e) ?? 0).toList();
      List<int> latestParts = latestBase.split('.').map((e) => int.tryParse(e) ?? 0).toList();

      for (int i = 0; i < latestParts.length; i++) {
        int c = i < currentParts.length ? currentParts[i] : 0;
        int l = latestParts[i];
        if (l > c) return true;
        if (l < c) return false;
      }
    } catch (e) {
      return false;
    }
    return false;
  }

  void _showUpdateDialog(BuildContext context, Map<String, dynamic> release) {
    final tagName = release['tag_name'];
    final body = release['body'];
    final htmlUrl = release['html_url'];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('发现新版本 $tagName'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: SingleChildScrollView(
                    child: Text(body ?? '暂无更新日志'),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('稍后'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _launchUrl(htmlUrl);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.appleMusicRed,
                foregroundColor: Colors.white,
              ),
              child: const Text('立即更新'),
            ),
          ],
        );
      },
    );
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
