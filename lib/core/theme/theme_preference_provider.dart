import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/database_provider.dart';
import 'theme_preference.dart';

const _themeModeKey = 'theme_mode';

class ThemeController extends AsyncNotifier<ThemePreference> {
  @override
  Future<ThemePreference> build() async {
    final db = ref.watch(databaseProvider);
    final value = await db.settingValue(_themeModeKey);
    return themePreferenceFromString(value);
  }

  Future<void> set(ThemePreference preference) async {
    final db = ref.watch(databaseProvider);
    await db.setSetting(_themeModeKey, themePreferenceToString(preference));
    state = AsyncData(preference);
  }
}

final themePreferenceProvider =
    AsyncNotifierProvider<ThemeController, ThemePreference>(
      ThemeController.new,
    );
