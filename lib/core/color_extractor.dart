import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// 从图片中提取主色调
class ColorExtractor {
  /// 缓存已提取的颜色
  static final Map<String, ColorScheme> _cache = {};

  /// 从网络图片 URL 提取颜色方案
  static Future<ColorScheme> extractFromUrl(
    String imageUrl, {
    Brightness brightness = Brightness.dark,
  }) async {
    // 检查缓存
    final cacheKey = '$imageUrl-$brightness';
    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey]!;
    }

    try {
      final generator = await PaletteGenerator.fromImageProvider(
        CachedNetworkImageProvider(imageUrl),
        maximumColorCount: 20,
      );

      final scheme = _generateColorScheme(generator, brightness);
      _cache[cacheKey] = scheme;
      return scheme;
    } catch (e) {
      // 返回默认配色
      return _defaultColorScheme(brightness);
    }
  }

  /// 从本地图片提取颜色方案
  static Future<ColorScheme> extractFromProvider(
    ImageProvider provider, {
    Brightness brightness = Brightness.dark,
  }) async {
    try {
      final generator = await PaletteGenerator.fromImageProvider(
        provider,
        maximumColorCount: 20,
      );

      return _generateColorScheme(generator, brightness);
    } catch (e) {
      return _defaultColorScheme(brightness);
    }
  }

  /// 生成颜色方案
  static ColorScheme _generateColorScheme(
    PaletteGenerator generator,
    Brightness brightness,
  ) {
    final isDark = brightness == Brightness.dark;

    // 提取主色调
    final dominantColor = generator.dominantColor?.color ??
        generator.vibrantColor?.color ??
        (isDark ? const Color(0xFF6366F1) : const Color(0xFF3B82F6));

    // 提取次要色
    final secondaryColor = generator.vibrantColor?.color ??
        generator.mutedColor?.color ??
        dominantColor;

    // 提取强调色
    final tertiaryColor = generator.lightVibrantColor?.color ??
        generator.darkVibrantColor?.color ??
        dominantColor;

    if (isDark) {
      return ColorScheme.dark(
        primary: dominantColor,
        secondary: secondaryColor,
        tertiary: tertiaryColor,
        surface: _darken(dominantColor, 0.8),
        onSurface: Colors.white,
      );
    } else {
      return ColorScheme.light(
        primary: dominantColor,
        secondary: secondaryColor,
        tertiary: tertiaryColor,
        surface: _lighten(dominantColor, 0.9),
        onSurface: Colors.black,
      );
    }
  }

  /// 默认颜色方案
  static ColorScheme _defaultColorScheme(Brightness brightness) {
    if (brightness == Brightness.dark) {
      return const ColorScheme.dark(
        primary: Color(0xFF6366F1),
        secondary: Color(0xFF8B5CF6),
        tertiary: Color(0xFF06B6D4),
      );
    } else {
      return const ColorScheme.light(
        primary: Color(0xFF6366F1),
        secondary: Color(0xFF8B5CF6),
        tertiary: Color(0xFF06B6D4),
      );
    }
  }

  /// 加深颜色
  static Color _darken(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    return hsl.withLightness((hsl.lightness * (1 - amount)).clamp(0.0, 1.0)).toColor();
  }

  /// 变浅颜色
  static Color _lighten(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    return hsl.withLightness((hsl.lightness + (1 - hsl.lightness) * amount).clamp(0.0, 1.0)).toColor();
  }

  /// 获取渐变色
  static List<Color> getGradientColors(Color baseColor) {
    final hsl = HSLColor.fromColor(baseColor);

    return [
      hsl.withLightness((hsl.lightness * 0.3).clamp(0.0, 1.0)).toColor(),
      hsl.withLightness((hsl.lightness * 0.5).clamp(0.0, 1.0)).toColor(),
      hsl.withLightness((hsl.lightness * 0.7).clamp(0.0, 1.0)).toColor(),
    ];
  }

  /// 清除缓存
  static void clearCache() {
    _cache.clear();
  }
}

/// 动态背景组件
class DynamicBackground extends StatefulWidget {
  final String? imageUrl;
  final Widget child;
  final Duration animationDuration;

  const DynamicBackground({
    super.key,
    this.imageUrl,
    required this.child,
    this.animationDuration = const Duration(milliseconds: 800),
  });

  @override
  State<DynamicBackground> createState() => _DynamicBackgroundState();
}

class _DynamicBackgroundState extends State<DynamicBackground> {
  ColorScheme? _colorScheme;
  String? _currentImageUrl;

  @override
  void didUpdateWidget(DynamicBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.imageUrl != oldWidget.imageUrl) {
      _updateColors();
    }
  }

  @override
  void initState() {
    super.initState();
    _updateColors();
  }

  Future<void> _updateColors() async {
    if (widget.imageUrl == null || widget.imageUrl == _currentImageUrl) return;

    _currentImageUrl = widget.imageUrl;
    final scheme = await ColorExtractor.extractFromUrl(
      widget.imageUrl!,
      brightness: Theme.of(context).brightness,
    );

    if (mounted && _currentImageUrl == widget.imageUrl) {
      setState(() {
        _colorScheme = scheme;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = _colorScheme != null
        ? ColorExtractor.getGradientColors(_colorScheme!.primary)
        : [
            Theme.of(context).colorScheme.surface,
            Theme.of(context).colorScheme.surface,
          ];

    return AnimatedContainer(
      duration: widget.animationDuration,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.first.withOpacity(0.8),
            colors.last.withOpacity(0.6),
            Theme.of(context).colorScheme.surface,
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
      child: widget.child,
    );
  }
}
