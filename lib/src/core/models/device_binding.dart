// 🔐 Device Binding Model
// Represents a device bound to a user account

import 'build_mode.dart';

class DeviceBinding {
  final String deviceId;

  /// The Firestore slot key for this binding.
  ///
  /// Android builds: `"android_debug"` or `"android_release"`.
  /// Desktop: `"desktop"`.
  final String platform;

  final DateTime boundAt;
  final DateTime lastActive;
  final bool isPermanent;

  /// The build mode that created this binding. Null for non-Android platforms.
  final BuildMode? buildMode;

  const DeviceBinding({
    required this.deviceId,
    required this.platform,
    required this.boundAt,
    required this.lastActive,
    this.isPermanent = true,
    this.buildMode,
  });

  factory DeviceBinding.fromMap(Map<String, dynamic> map) {
    BuildMode? buildMode;
    final buildModeStr = map['buildMode'] as String?;
    if (buildModeStr != null) {
      buildMode = BuildMode.values.firstWhere(
        (e) => e.name == buildModeStr,
        orElse: () => BuildMode.release,
      );
    }

    return DeviceBinding(
      deviceId: map['deviceId'] as String,
      platform: map['platform'] as String,
      boundAt: (map['boundAt'] as DateTime?) ?? DateTime.now(),
      lastActive: (map['lastActive'] as DateTime?) ?? DateTime.now(),
      isPermanent: map['isPermanent'] as bool? ?? true,
      buildMode: buildMode,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'deviceId': deviceId,
      'platform': platform,
      'boundAt': boundAt,
      'lastActive': lastActive,
      'isPermanent': isPermanent,
      if (buildMode != null) 'buildMode': buildMode!.name,
    };
  }

  DeviceBinding copyWith({
    String? deviceId,
    String? platform,
    DateTime? boundAt,
    DateTime? lastActive,
    bool? isPermanent,
    BuildMode? buildMode,
  }) {
    return DeviceBinding(
      deviceId: deviceId ?? this.deviceId,
      platform: platform ?? this.platform,
      boundAt: boundAt ?? this.boundAt,
      lastActive: lastActive ?? this.lastActive,
      isPermanent: isPermanent ?? this.isPermanent,
      buildMode: buildMode ?? this.buildMode,
    );
  }

  @override
  String toString() {
    return 'DeviceBinding(deviceId: $deviceId, platform: $platform, '
        'boundAt: $boundAt, lastActive: $lastActive, '
        'isPermanent: $isPermanent, buildMode: $buildMode)';
  }
}
