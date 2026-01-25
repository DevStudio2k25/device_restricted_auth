// 🔐 Device Binding Policy
// Defines rules for device binding (permanent binding policy)

import '../models/device_binding.dart';

class DeviceBindingPolicy {
  const DeviceBindingPolicy();

  /// Check if a new device can be bound
  /// Returns true only if no device is currently bound (deviceId is null)
  bool canBind(DeviceBinding? existingBinding, String newDeviceId) {
    // If no existing binding, allow binding
    if (existingBinding == null) {
      return true;
    }

    // If existing binding has no deviceId (null), allow binding
    if (existingBinding.deviceId.isEmpty) {
      return true;
    }

    // If device is already bound, do not allow re-binding
    return false;
  }

  /// Check if login is allowed for the current device
  /// Returns true if:
  /// 1. No device is bound yet (first-time login)
  /// 2. Current device matches the bound device
  bool canLogin(DeviceBinding? existingBinding, String currentDeviceId) {
    // If no existing binding, allow login (will bind on first login)
    if (existingBinding == null) {
      return true;
    }

    // If existing binding has no deviceId (null), allow login
    if (existingBinding.deviceId.isEmpty) {
      return true;
    }

    // If current device matches bound device, allow login
    if (existingBinding.deviceId == currentDeviceId) {
      return true;
    }

    // Device mismatch - deny login
    return false;
  }

  /// Check if device binding is permanent
  /// In this policy, all bindings are permanent
  bool isPermanentBinding(DeviceBinding binding) {
    return binding.isPermanent;
  }

  /// Check if device replacement is allowed
  /// In this policy, device replacement is NOT allowed
  bool canReplaceDevice(DeviceBinding existingBinding) {
    return false; // Permanent binding - no replacement
  }
}
