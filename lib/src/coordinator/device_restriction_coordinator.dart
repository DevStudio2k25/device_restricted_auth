// 🔐 Device Restriction Coordinator
// Orchestrates device restriction logic during auth operations

import '../core/models/device_binding.dart';
import '../core/models/validation_result.dart';
import '../core/validators/device_binding_validator.dart';
import '../core/policies/device_binding_policy.dart';
import '../firebase/device_repository.dart';
import '../platform/device_id_provider.dart';
import '../core/exceptions/device_restriction_exceptions.dart';

class DeviceRestrictionCoordinator {
  final DeviceRepository deviceRepository;
  final DeviceIdProvider deviceIdProvider;
  final DeviceBindingValidator validator;

  DeviceRestrictionCoordinator({
    required this.deviceRepository,
    required this.deviceIdProvider,
    DeviceBindingValidator? validator,
  }) : validator = validator ??
            const DeviceBindingValidator(
              policy: DeviceBindingPolicy(),
            );

  /// Verify and bind device during signup
  /// Throws exception if device is already bound to another account
  Future<void> verifyDeviceForSignup() async {
    final deviceId = await deviceIdProvider.getDeviceId();
    final platform = deviceIdProvider.getPlatformName();

    print('🔍 Checking if device is already bound...');
    print('   Device ID: $deviceId');
    print('   Platform: $platform');

    // Check if device is already bound to another account
    final boundUsers =
        await deviceRepository.findUsersByDevice(deviceId, platform);

    if (boundUsers.isNotEmpty) {
      throw DeviceAlreadyBoundException(
        boundToEmail: 'another account',
        message: '🚫 Device Already Registered!\n\n'
            'This device is already linked to another account.\n\n'
            'Each device can only be used with one account.\n'
            'Please sign in with your existing account.',
      );
    }

    print('✅ Device is available for new account');
  }

  /// Verify and bind device during login
  /// Binds device on first login, validates on subsequent logins
  Future<void> verifyAndBindDevice(String userId) async {
    final deviceId = await deviceIdProvider.getDeviceId();
    final platform = deviceIdProvider.getPlatformName();

    print('🔐 Verifying Device Binding...');
    print('   User ID: $userId');
    print('   Device ID: $deviceId');
    print('   Platform: $platform');

    // Get existing binding
    final existingBinding = await deviceRepository.getBinding(userId, platform);

    // If no binding exists, create one (first-time login)
    if (existingBinding == null || existingBinding.deviceId.isEmpty) {
      print('🆕 First time login on $platform - Binding device permanently...');

      final newBinding = DeviceBinding(
        deviceId: deviceId,
        platform: platform,
        boundAt: DateTime.now(),
        lastActive: DateTime.now(),
        isPermanent: true,
      );

      await deviceRepository.createBinding(userId, newBinding);
      return;
    }

    // Validate existing binding
    final validationResult = validator.validateLogin(
      existingBinding: existingBinding,
      currentDeviceId: deviceId,
      platform: platform,
    );

    if (!validationResult.isValid) {
      if (validationResult.type == ValidationResultType.deviceMismatch) {
        throw DeviceMismatchException(
          expectedDeviceId: existingBinding.deviceId,
          actualDeviceId: deviceId,
          message: validationResult.errorMessage ?? 'Device mismatch',
        );
      }
    }

    // Device matches - update last active
    print('✅ Device Matched! Updating last active...');
    await deviceRepository.updateActivity(userId, platform);
    print('✅ Device Binding Verified Successfully!');
  }

  /// Initialize device document for new user
  Future<void> initializeDeviceDocument(String userId) async {
    await deviceRepository.initializeDeviceDocument(userId);
  }
}
