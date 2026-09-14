import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_palette.dart';

/// 「新历书」主题。
///
/// 圆角系统（全 App 唯一）：区块/弹层 12、按钮与输入 10、小签 4。
/// 结构分组优先用发丝线（hairline），卡片只用于真正需要抬升的表面。
class AppTheme {
  AppTheme._();

  static const _radiusBlock = 12.0;
  static const _radiusControl = 10.0;

  static ThemeData light() => _build(AppPalette.light, Brightness.light);

  static ThemeData dark() => _build(AppPalette.dark, Brightness.dark);

  static ThemeData _build(AppPalette p, Brightness brightness) {
    final scheme = ColorScheme(
      brightness: brightness,
      primary: p.accent,
      onPrimary: p.onAccent,
      secondary: p.accent,
      onSecondary: p.onAccent,
      error: p.danger,
      onError: p.onAccent,
      surface: p.surface,
      onSurface: p.ink,
      surfaceContainerHighest: p.surfaceAlt,
      onSurfaceVariant: p.inkSecondary,
      outline: p.hairlineStrong,
      outlineVariant: p.hairline,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: p.background,
      splashFactory: InkSparkle.splashFactory,
    );

    return base.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: p.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: p.ink,
          letterSpacing: 0.2,
        ),
        systemOverlayStyle: brightness == Brightness.light
            ? SystemUiOverlayStyle(
                statusBarColor: Colors.transparent,
                statusBarIconBrightness: Brightness.dark,
                statusBarBrightness: Brightness.light,
              )
            : SystemUiOverlayStyle(
                statusBarColor: Colors.transparent,
                statusBarIconBrightness: Brightness.light,
                statusBarBrightness: Brightness.dark,
              ),
      ),
      dividerTheme: DividerThemeData(color: p.hairline, thickness: 1, space: 1),
      textTheme: base.textTheme.apply(bodyColor: p.ink, displayColor: p.ink),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: p.accent,
        selectionColor: p.accent.withValues(alpha: 0.25),
        selectionHandleColor: p.accent,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radiusControl),
          borderSide: BorderSide(color: p.hairlineStrong),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radiusControl),
          borderSide: BorderSide(color: p.hairlineStrong),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radiusControl),
          borderSide: BorderSide(color: p.accent, width: 1.4),
        ),
        hintStyle: TextStyle(color: p.inkTertiary),
        labelStyle: TextStyle(color: p.inkSecondary),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: p.accent,
          foregroundColor: p.onAccent,
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_radiusControl),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: p.ink,
          minimumSize: const Size(48, 48),
          side: BorderSide(color: p.hairlineStrong),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_radiusControl),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: p.accent,
          minimumSize: const Size(48, 48),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radiusBlock),
        ),
        titleTextStyle: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: p.ink,
        ),
        contentTextStyle: TextStyle(fontSize: 14.5, color: p.inkSecondary),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: p.ink,
        contentTextStyle: TextStyle(color: p.background),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radiusControl),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: p.inkSecondary,
        titleTextStyle: TextStyle(fontSize: 15.5, color: p.ink),
        subtitleTextStyle: TextStyle(fontSize: 13, color: p.inkSecondary),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? p.onAccent : p.surface,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? p.accent
              : p.hairlineStrong,
        ),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radiusBlock),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: p.background,
        indicatorColor: p.accentSoft,
      ),
    );
  }

  /// 便捷取调色板。调色板不做 ThemeExtension，直接由明暗选择。
  static AppPalette paletteOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? AppPalette.dark
      : AppPalette.light;
}
