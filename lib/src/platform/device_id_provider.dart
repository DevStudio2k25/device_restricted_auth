// 🔐 Device ID Provider Interface
// Abstract interface for platform-specific device ID retrieval

import '../core/models/device_metadata.dart';

abstract class DeviceIdProvider {
  /// Get the unique device identifier for this platform
  Future<String> getDeviceId();

  /// Get the platform name ("android" or "desktop")
  String getPlatformName();

  /// Get additional device metadata
  Future<DeviceMetadata> getMetadata();
}
