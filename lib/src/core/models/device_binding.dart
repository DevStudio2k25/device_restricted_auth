// 🔐 Device Binding Model
// Represents a device bound to a user account

class DeviceBinding {
  final String deviceId;
  final String platform; // "android" or "desktop"
  final DateTime boundAt;
  final DateTime lastActive;
  final bool isPermanent;

  const DeviceBinding({
    required this.deviceId,
    required this.platform,
    required this.boundAt,
    required this.lastActive,
    this.isPermanent = true,
  });

  factory DeviceBinding.fromMap(Map<String, dynamic> map) {
    return DeviceBinding(
      deviceId: map['deviceId'] as String,
      platform: map['platform'] as String,
      boundAt: (map['boundAt'] as DateTime?) ?? DateTime.now(),
      lastActive: (map['lastActive'] as DateTime?) ?? DateTime.now(),
      isPermanent: map['isPermanent'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'deviceId': deviceId,
      'platform': platform,
      'boundAt': boundAt,
      'lastActive': lastActive,
      'isPermanent': isPermanent,
    };
  }

  DeviceBinding copyWith({
    String? deviceId,
    String? platform,
    DateTime? boundAt,
    DateTime? lastActive,
    bool? isPermanent,
  }) {
    return DeviceBinding(
      deviceId: deviceId ?? this.deviceId,
      platform: platform ?? this.platform,
      boundAt: boundAt ?? this.boundAt,
      lastActive: lastActive ?? this.lastActive,
      isPermanent: isPermanent ?? this.isPermanent,
    );
  }

  @override
  String toString() {
    return 'DeviceBinding(deviceId: $deviceId, platform: $platform, boundAt: $boundAt, lastActive: $lastActive, isPermanent: $isPermanent)';
  }
}
