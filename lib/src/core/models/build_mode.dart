// 🔐 Build Mode Detection
// Detects whether the app is running in debug or release mode.
// Android SSAID differs per signing key, so debug and release builds
// get separate device slots in Firestore.

import 'package:flutter/foundation.dart';

/// Represents the current build mode of the application.
enum BuildMode {
  /// Debug build (signed with debug keystore).
  debug,

  /// Release build (signed with release keystore).
  release,

  /// Profile build — shares the debug slot since it is not a production build.
  profile,
}

/// Utility class that detects the current [BuildMode] at runtime.
///
/// Uses Flutter's [kDebugMode] and [kReleaseMode] compile-time constants.
///
/// Example:
/// ```dart
/// final mode = BuildModeDetector.current(); // BuildMode.debug or BuildMode.release
/// print(mode.slotName); // "debug" or "release"
/// ```
class BuildModeDetector {
  const BuildModeDetector._();

  /// Returns the current [BuildMode].
  ///
  /// - [kDebugMode] → [BuildMode.debug]
  /// - [kReleaseMode] → [BuildMode.release]
  /// - Otherwise (profile) → [BuildMode.profile]
  static BuildMode current() {
    if (kDebugMode) return BuildMode.debug;
    if (kReleaseMode) return BuildMode.release;
    return BuildMode.profile;
  }
}

/// Extension on [BuildMode] for convenient slot naming.
extension BuildModeExtension on BuildMode {
  /// Returns the Firestore slot suffix for this build mode.
  ///
  /// - [BuildMode.debug] → `"debug"`
  /// - [BuildMode.release] → `"release"`
  /// - [BuildMode.profile] → `"debug"` (shares debug slot, not a production build)
  String get slotName {
    switch (this) {
      case BuildMode.release:
        return 'release';
      case BuildMode.debug:
      case BuildMode.profile:
        return 'debug';
    }
  }
}
