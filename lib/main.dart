import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'core/theme/theme_preference_provider.dart';

void main() {
  final binding = WidgetsFlutterBinding.ensureInitialized();
  binding.deferFirstFrame();
  final container = ProviderContainer();
  // Read the saved theme before submitting the first frame. This is actual
  // initialization, never a wait for motion, and other reads run concurrently.
  container
      .read(themePreferenceProvider.future)
      .then(
        (_) => binding.allowFirstFrame(),
        onError: (Object error, StackTrace stack) => binding.allowFirstFrame(),
      );
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  runApp(
    UncontrolledProviderScope(container: container, child: const HuikeApp()),
  );
}
