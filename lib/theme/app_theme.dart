import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Apple Music 风格主题配置
/// 设计原则：简洁、优雅、高对比度
class AppTheme {
  // ==================== Apple Music 配色 ====================
  
  // 主色调
  static const Color appleMusicRed = Color(0xFFFA233B); // 更鲜艳的红
  static const Color appleMusicPink = Color(0xFFFB5C74);
  
  // 深色主题色板 (Premium Dark)
  static const Color darkBackground = Color(0xFF191919); // 稍微提亮一点纯黑，更有质感
  static const Color darkSurface = Color(0xFF242424);
  static const Color darkSurfaceElevated = Color(0xFF333333);
  static const Color darkSeparator = Color(0xFF38383A);
  
  // 浅色主题色板
  static const Color lightBackground = Color(0xFFF9F9F9);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceElevated = Color(0xFFFFFFFF);
  static const Color lightSeparator = Color(0xFFE5E5E5);
  
  // 文字颜色
  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color.fromRGBO(235, 235, 245, 0.6);
  static const Color darkTextTertiary = Color.fromRGBO(235, 235, 245, 0.3);
  
  static const Color lightTextPrimary = Color(0xFF000000);
  static const Color lightTextSecondary = Color.fromRGBO(60, 60, 67, 0.6);
  static const Color lightTextTertiary = Color.fromRGBO(60, 60, 67, 0.3);
  
  // ==================== 设计 Tokens ====================
  
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXLarge = 24.0;
  
  // 间距
  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 16.0;
  static const double spacingL = 24.0;
  static const double spacingXL = 32.0;
  
  // 动画时长
  static const Duration animationFast = Duration(milliseconds: 150);
  static const Duration animationNormal = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);
  
  // ==================== 字体样式 (SF Pro Style) ====================
  static const TextTheme darkTextTheme = TextTheme(
    displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, letterSpacing: -0.5, color: darkTextPrimary),
    displayMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: -0.4, color: darkTextPrimary),
    displaySmall: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, letterSpacing: -0.3, color: darkTextPrimary),
    headlineLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, letterSpacing: -0.3, color: darkTextPrimary),
    headlineMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: -0.2, color: darkTextPrimary),
    titleLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: -0.2, color: darkTextPrimary),
    titleMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: -0.1, color: darkTextPrimary),
    titleSmall: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, letterSpacing: -0.1, color: darkTextPrimary),
    bodyLarge: TextStyle(fontSize: 15, fontWeight: FontWeight.w400, letterSpacing: -0.1, color: darkTextPrimary, height: 1.4),
    bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, letterSpacing: 0, color: darkTextSecondary, height: 1.4),
    bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, letterSpacing: 0, color: darkTextSecondary),
    labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: -0.1, color: appleMusicRed),
    labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0, color: darkTextSecondary),
    labelSmall: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.2, color: darkTextTertiary),
  );

  static const TextTheme lightTextTheme = TextTheme(
    displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, letterSpacing: -0.5, color: lightTextPrimary),
    displayMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: -0.4, color: lightTextPrimary),
    displaySmall: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, letterSpacing: -0.3, color: lightTextPrimary),
    headlineLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, letterSpacing: -0.3, color: lightTextPrimary),
    headlineMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: -0.2, color: lightTextPrimary),
    titleLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: -0.2, color: lightTextPrimary),
    titleMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: -0.1, color: lightTextPrimary),
    titleSmall: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, letterSpacing: -0.1, color: lightTextPrimary),
    bodyLarge: TextStyle(fontSize: 15, fontWeight: FontWeight.w400, letterSpacing: -0.1, color: lightTextPrimary, height: 1.4),
    bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, letterSpacing: 0, color: lightTextSecondary, height: 1.4),
    bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, letterSpacing: 0, color: lightTextSecondary),
    labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: -0.1, color: appleMusicRed),
    labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0, color: lightTextSecondary),
    labelSmall: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.2, color: lightTextTertiary),
  );
    
  // ==================== 深色主题 ====================
  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    
    // 配色方案
    colorScheme: const ColorScheme.dark(
      primary: appleMusicRed,
      onPrimary: Colors.white,
      secondary: appleMusicPink,
      onSecondary: Colors.white,
      surface: darkSurface,
      onSurface: darkTextPrimary,
      surfaceContainerHighest: darkSurfaceElevated,
      outline: darkSeparator,
      error: Color(0xFFFF453A),
    ),
    
    // 背景色
    scaffoldBackgroundColor: darkBackground,
    cardColor: darkSurface,
    dividerColor: darkSeparator,
    
    // AppBar 主题
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      titleTextStyle: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: darkTextPrimary,
        letterSpacing: -0.4,
      ),
      iconTheme: IconThemeData(color: appleMusicRed),
    ),
    
    // 文字主题
    textTheme: darkTextTheme,
    iconTheme: const IconThemeData(
      color: darkTextPrimary,
      size: 24,
    ),
    
    // 按钮主题
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: appleMusicRed,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
        textStyle: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.4,
        ),
      ),
    ),
    
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: appleMusicRed,
        textStyle: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w400,
          letterSpacing: -0.4,
        ),
      ),
    ),
    
    // 滑块主题
    sliderTheme: SliderThemeData(
      activeTrackColor: appleMusicRed,
      inactiveTrackColor: darkSeparator,
      thumbColor: Colors.white,
      overlayColor: appleMusicRed.withValues(alpha: 0.2),
      trackHeight: 4,
      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
    ),
    
    // 底部导航栏主题
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: darkSurface,
      selectedItemColor: appleMusicRed,
      unselectedItemColor: darkTextSecondary,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
      selectedLabelStyle: TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
      unselectedLabelStyle: TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
    ),
    
    // 底部 Sheet 主题
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: darkSurfaceElevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(radiusXLarge)),
      ),
    ),
    
    // 对话框主题
    dialogTheme: DialogThemeData(
      backgroundColor: darkSurfaceElevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusLarge),
      ),
    ),
    
    // 列表磁贴主题
    listTileTheme: const ListTileThemeData(
      contentPadding: EdgeInsets.symmetric(horizontal: spacingM),
      minLeadingWidth: 0,
    ),
    
    // SnackBar 主题
    snackBarTheme: SnackBarThemeData(
      backgroundColor: darkSurfaceElevated,
      contentTextStyle: const TextStyle(color: darkTextPrimary),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
      ),
      behavior: SnackBarBehavior.floating,
    ),
  );

  // ==================== 浅色主题 ====================
  
  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    
    // 配色方案
    colorScheme: const ColorScheme.light(
      primary: appleMusicRed,
      onPrimary: Colors.white,
      secondary: appleMusicPink,
      onSecondary: Colors.white,
      surface: lightSurface,
      onSurface: lightTextPrimary,
      surfaceContainerHighest: lightSurfaceElevated,
      outline: lightSeparator,
      error: Color(0xFFFF3B30),
    ),
    
    // 背景色
    scaffoldBackgroundColor: lightBackground,
    cardColor: lightSurfaceElevated,
    dividerColor: lightSeparator,
    
    // AppBar 主题
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      titleTextStyle: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: lightTextPrimary,
        letterSpacing: -0.4,
      ),
      iconTheme: IconThemeData(color: appleMusicRed),
    ),
    
    // 文字主题 - SF Pro 风格
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 34,
        fontWeight: FontWeight.w700,
        color: lightTextPrimary,
        letterSpacing: 0.4,
        height: 1.2,
      ),
      displayMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: lightTextPrimary,
        letterSpacing: 0.4,
        height: 1.2,
      ),
      displaySmall: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: lightTextPrimary,
        letterSpacing: 0.35,
        height: 1.3,
      ),
      headlineLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: lightTextPrimary,
        letterSpacing: 0.35,
      ),
      headlineMedium: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: lightTextPrimary,
        letterSpacing: 0.38,
      ),
      headlineSmall: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: lightTextPrimary,
        letterSpacing: -0.4,
      ),
      titleLarge: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: lightTextPrimary,
        letterSpacing: -0.4,
      ),
      titleMedium: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: lightTextPrimary,
        letterSpacing: -0.2,
      ),
      titleSmall: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: lightTextPrimary,
        letterSpacing: -0.1,
      ),
      bodyLarge: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w400,
        color: lightTextPrimary,
        letterSpacing: -0.4,
        height: 1.4,
      ),
      bodyMedium: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: lightTextSecondary,
        letterSpacing: -0.2,
        height: 1.4,
      ),
      bodySmall: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: lightTextSecondary,
        letterSpacing: -0.1,
        height: 1.4,
      ),
      labelLarge: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: appleMusicRed,
        letterSpacing: -0.2,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: lightTextSecondary,
        letterSpacing: 0,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: lightTextTertiary,
        letterSpacing: 0.5,
      ),
    ),
    
    // 图标主题
    iconTheme: const IconThemeData(
      color: lightTextPrimary,
      size: 24,
    ),
    
    // 按钮主题
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: appleMusicRed,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
        textStyle: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.4,
        ),
      ),
    ),
    
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: appleMusicRed,
        textStyle: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w400,
          letterSpacing: -0.4,
        ),
      ),
    ),
    
    // 滑块主题
    sliderTheme: SliderThemeData(
      activeTrackColor: appleMusicRed,
      inactiveTrackColor: lightSeparator,
      thumbColor: Colors.white,
      overlayColor: appleMusicRed.withValues(alpha: 0.2),
      trackHeight: 4,
      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
    ),
    
    // 底部导航栏主题
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: lightSurfaceElevated,
      selectedItemColor: appleMusicRed,
      unselectedItemColor: lightTextSecondary,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
      selectedLabelStyle: TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
      unselectedLabelStyle: TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
    ),
    
    // 底部 Sheet 主题
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: lightSurfaceElevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(radiusXLarge)),
      ),
    ),
    
    // 对话框主题
    dialogTheme: DialogThemeData(
      backgroundColor: lightSurfaceElevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusLarge),
      ),
    ),
    
    // 列表磁贴主题
    listTileTheme: const ListTileThemeData(
      contentPadding: EdgeInsets.symmetric(horizontal: spacingM),
      minLeadingWidth: 0,
    ),
    
    // SnackBar 主题
    snackBarTheme: SnackBarThemeData(
      backgroundColor: lightTextPrimary,
      contentTextStyle: const TextStyle(color: lightBackground),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
      ),
      behavior: SnackBarBehavior.floating,
    ),
  );
}

/// Apple Music 风格扩展
extension AppleMusicColors on ColorScheme {
  /// 获取 Apple Music 红色
  Color get appleMusicRed => AppTheme.appleMusicRed;
  
  /// 获取分隔线颜色
  Color get separator => brightness == Brightness.dark 
      ? AppTheme.darkSeparator 
      : AppTheme.lightSeparator;
  
  /// 获取次级文字颜色
  Color get textSecondary => brightness == Brightness.dark
      ? AppTheme.darkTextSecondary
      : AppTheme.lightTextSecondary;
      
  /// 获取三级文字颜色  
  Color get textTertiary => brightness == Brightness.dark
      ? AppTheme.darkTextTertiary
      : AppTheme.lightTextTertiary;
}
