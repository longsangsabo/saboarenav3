import 'package:flutter/material.dart';
import 'app_theme.dart';

// Extension to provide access to theme colors as if they were appTheme instance
extension AppThemeExtension on BuildContext() {
  AppThemeData get appTheme => AppThemeData();
}

class AppThemeData() {
  // Primary colors
  Color get primaryLight => AppTheme.primaryLight;
  Color get primary => AppTheme.primaryLight;
  
  // Secondary colors  
  Color get secondaryLight => AppTheme.secondaryLight;
  Color get secondary => AppTheme.secondaryLight;
  
  // Background colors
  Color get backgroundLight => AppTheme.backgroundLight;
  Color get background => AppTheme.backgroundLight;
  Color get surfaceLight => AppTheme.surfaceLight;
  Color get surface => AppTheme.surfaceLight;
  
  // Status colors
  Color get errorLight => AppTheme.errorLight;
  Color get error => AppTheme.errorLight;
  Color get successLight => AppTheme.successLight;
  Color get success => AppTheme.successLight;
  Color get warningLight => AppTheme.warningLight;
  Color get warning => AppTheme.warningLight;
  
  // Common color variations needed by widgets
  Color get green50 => const Color(0xFFE8F5E8);
  Color get green200 => const Color(0xFFC8E6C9);
  Color get green600 => const Color(0xFF2E7D32);
  Color get green700 => const Color(0xFF388E3C);
  Color get green800 => const Color(0xFF1B5E20);
  Color get red50 => const Color(0xFFFFEBEE);  
  Color get red600 => const Color(0xFFD32F2F);
  Color get red700 => const Color(0xFFD32F2F);
  Color get blue50 => const Color(0xFFE3F2FD);
  Color get blue200 => const Color(0xFFBBDEFB);
  Color get blue600 => const Color(0xFF1976D2);
  Color get blue800 => const Color(0xFF1565C0);
  Color get orange50 => const Color(0xFFFFF3E0);
  Color get orange600 => const Color(0xFFFF6F00);
  
  // Purple variations
  Color get purple50 => const Color(0xFFF3E5F5);
  Color get purple100 => const Color(0xFFE1BEE7);
  Color get purple200 => const Color(0xFFCE93D8);
  Color get purple600 => const Color(0xFF8E24AA);
  
  // Gray variations
  Color get gray50 => const Color(0xFFFAFAFA);
  Color get gray100 => const Color(0xFFF5F5F5);
  Color get gray200 => const Color(0xFFEEEEEE);
  Color get gray300 => const Color(0xFFE0E0E0);
  Color get gray400 => const Color(0xFFBDBDBD);
  Color get gray500 => const Color(0xFF9E9E9E);
  Color get gray600 => const Color(0xFF757575);
  Color get gray700 => const Color(0xFF616161);
  Color get gray900 => const Color(0xFF212121);
  Color get black900 => const Color(0xFF000000);
  
  // Text colors
  Color get onPrimaryLight => AppTheme.onPrimaryLight;
  Color get onSecondaryLight => AppTheme.onSecondaryLight;
  Color get onBackgroundLight => AppTheme.onBackgroundLight;
  Color get onSurfaceLight => AppTheme.onSurfaceLight;
  Color get onErrorLight => AppTheme.onErrorLight;
}

// Global appTheme instance for backwards compatibility
final appTheme = AppThemeData();