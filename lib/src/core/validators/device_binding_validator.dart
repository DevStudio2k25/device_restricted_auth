// 🔐 Device Binding Validator
// Validates device binding operations

import '../models/device_binding.dart';
import '../models/validation_result.dart';
import '../policies/device_binding_policy.dart';

class DeviceBindingValidator {
  final DeviceBindingPolicy policy;

  const DeviceBindingValidator({
    required this.policy,
  });

  /// Validate if a device can be bound
  ValidationResult validateBinding({
    required DeviceBinding? existingBinding,
    required String newDeviceId,
    required String platform,
  }) {
    // Check if binding is allowed by policy
    if (!policy.canBind(existingBinding, newDeviceId)) {
      return ValidationResult.invalid(
        errorMessage: '🚫 Device Already Bound!\n\n'
            'This account is permanently bound to another $platform device.\n'
            'Device binding cannot be changed.',
        type: ValidationResultType.deviceAlreadyBound,
      );
    }

    return ValidationResult.valid();
  }

  /// Validate if login is allowed for the current device
  ValidationResult validateLogin({
    required DeviceBinding? existingBinding,
    required String currentDeviceId,
    required String platform,
  }) {
    // Check if login is allowed by policy
    if (!policy.canLogin(existingBinding, currentDeviceId)) {
      return ValidationResult.invalid(
        errorMessage: '🚫 Device Not Matched!\n\n'
            'This account is permanently bound to another $platform device.\n'
            'You cannot login from a different device.\n\n'
            'Premium Plan: 1 Android + 1 Desktop (Permanent Binding)',
        type: ValidationResultType.deviceMismatch,
      );
    }

    // Check if this is first-time binding
    if (existingBinding == null || existingBinding.deviceId.isEmpty) {
      return ValidationResult.invalid(
        errorMessage: 'First-time binding required',
        type: ValidationResultType.firstTimeBinding,
      );
    }

    return ValidationResult.valid();
  }
}
