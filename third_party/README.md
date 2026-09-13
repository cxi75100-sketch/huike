# Third-party source

## flutter_inappwebview_android 1.1.3

- Source package: `flutter_inappwebview_android` 1.1.3 from pub.dev.
- Upstream repository: <https://github.com/pichillilorenzo/flutter_inappwebview>
- License: Apache-2.0; the original `LICENSE`, package metadata and source are kept in `flutter_inappwebview_android/`.
- Local changes: in `android/build.gradle`, both build types use `proguard-android-optimize.txt` instead of the AGP 9-unsupported `proguard-android.txt`; the package-local analyzer configuration excludes vendored Dart source from the app repository's lint run.
- Reason for vendoring: keep Android builds reproducible after Pub cache cleanup and on a new machine while retaining the stable 1.1.3 package API.

Do not add unrelated edits to the vendored package. When upstream releases a compatible stable version, remove the override and re-run the full Android verification pipeline.
