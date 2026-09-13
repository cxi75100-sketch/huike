import 'package:flutter/material.dart';

/// 外观偏好：跟随系统 / 日间 / 夜间。存 settings 表 `theme_mode`。
enum ThemePreference { system, light, dark }

ThemePreference themePreferenceFromString(String? value) =>
    switch (value) {
      'light' => ThemePreference.light,
      'dark' => ThemePreference.dark,
      _ => ThemePreference.system,
    };

String themePreferenceToString(ThemePreference preference) =>
    switch (preference) {
      ThemePreference.light => 'light',
      ThemePreference.dark => 'dark',
      ThemePreference.system => 'system',
    };

ThemeMode themeModeOf(ThemePreference preference) => switch (preference) {
  ThemePreference.light => ThemeMode.light,
  ThemePreference.dark => ThemeMode.dark,
  ThemePreference.system => ThemeMode.system,
};
