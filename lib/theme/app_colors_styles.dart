// AppColors class for color constants
class AppColors {
  static const Color primaryColor = AppTheme.primaryLight;
  static const Color secondaryColor = AppTheme.secondaryLight;
  static const Color backgroundColor = AppTheme.backgroundLight;
  static const Color surfaceColor = AppTheme.surfaceLight;
  static const Color errorColor = AppTheme.errorLight;
  static const Color successColor = AppTheme.successLight;
  static const Color warningColor = AppTheme.warningLight;

  // Additional colors for widgets
  static const Color green = Color(0xFF2E7D32);
  static const Color red = Color(0xFFD32F2F);
  static const Color blue = Color(0xFF1976D2);
  static const Color purple = Color(0xFF9C27B0);
  static const Color orange = Color(0xFFFF6F00);
  static const Color grey = Color(0xFF9E9E9E);
  static const Color lightGrey = Color(0xFFE0E0E0);

  // Primary color alias
  static const Color primary = primaryColor;
}

// CustomTextStyles class for text styling
class CustomTextStyles {
  static TextStyle get bodyMedium => TextStyle(
        fontSize: 14.sp,
        fontWeight: FontWeight.w400,
        color: AppTheme.onBackgroundLight,
      );

  static TextStyle get titleMedium => TextStyle(
        fontSize: 16.sp,
        fontWeight: FontWeight.w500,
        color: AppTheme.onBackgroundLight,
      );

  static TextStyle get titleLarge => TextStyle(
        fontSize: 20.sp,
        fontWeight: FontWeight.w600,
        color: AppTheme.onBackgroundLight,
      );

  static TextStyle get headlineSmall => TextStyle(
        fontSize: 24.sp,
        fontWeight: FontWeight.w700,
        color: AppTheme.onBackgroundLight,
      );
}
