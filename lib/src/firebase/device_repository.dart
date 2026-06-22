// 🔐 Device Repository Interface
// Abstract interface for device binding data access

import '../core/models/device_binding.dart';
import '../core/models/user_info.dart';

abstract class DeviceRepository {
  /// Get device binding for a user and platform slot (e.g. "android_debug").
  Future<DeviceBinding?> getBinding(String userId, String platform);

  /// Create a new device binding, optionally storing user metadata.
  Future<void> createBinding(
    String userId,
    DeviceBinding binding, {
    DeviceAuthUserInfo? userInfo,
  });

  /// Update device activity timestamp and optionally refresh user info.
  Future<void> updateActivity(
    String userId,
    String platform, {
    DeviceAuthUserInfo? userInfo,
  });

  /// Find users by device ID within a specific slot.
  Future<List<String>> findUsersByDevice(String deviceId, String platform);

  /// Find users by device ID across ALL Android slots (debug + release).
  ///
  /// Used during signup to prevent the same physical device from being
  /// registered to more than one account, regardless of build flavor.
  Future<List<String>> findUsersByDeviceAnySlot(
    String deviceId,
    String basePlatform,
  );

  /// Initialize device document with null values for all slots.
  Future<void> initializeDeviceDocument(
    String userId, {
    DeviceAuthUserInfo? userInfo,
  });

  /// Update only the user info fields on an existing document.
  Future<void> updateUserInfo(String userId, DeviceAuthUserInfo userInfo);
}
