// 🔐 Device Repository Interface
// Abstract interface for device binding data access

import '../core/models/device_binding.dart';

abstract class DeviceRepository {
  /// Get device binding for a user and platform
  Future<DeviceBinding?> getBinding(String userId, String platform);

  /// Create a new device binding
  Future<void> createBinding(String userId, DeviceBinding binding);

  /// Update device activity timestamp
  Future<void> updateActivity(String userId, String platform);

  /// Find users by device ID (for checking if device is already bound)
  Future<List<String>> findUsersByDevice(String deviceId, String platform);

  /// Initialize device document with null values
  Future<void> initializeDeviceDocument(String userId);
}
