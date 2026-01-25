import 'package:flutter_test/flutter_test.dart';
import 'package:device_restricted_auth/device_restricted_auth.dart';

void main() {
  group('Package Import Tests', () {
    test('package can be imported successfully', () {
      // Verify package loads without errors
      expect(true, isTrue);
    });
  });

  group('Core Model Tests', () {
    test('DeviceBinding can be instantiated', () {
      final binding = DeviceBinding(
        deviceId: 'test-device-123',
        platform: 'android',
        boundAt: DateTime.now(),
        lastActive: DateTime.now(),
        isPermanent: true,
      );

      expect(binding.deviceId, 'test-device-123');
      expect(binding.platform, 'android');
      expect(binding.isPermanent, true);
    });

    test('DeviceBinding toMap and fromMap work correctly', () {
      final now = DateTime.now();
      final binding = DeviceBinding(
        deviceId: 'device-456',
        platform: 'desktop',
        boundAt: now,
        lastActive: now,
        isPermanent: true,
      );

      final map = binding.toMap();
      expect(map['deviceId'], 'device-456');
      expect(map['platform'], 'desktop');
      expect(map['isPermanent'], true);

      final restored = DeviceBinding.fromMap(map);
      expect(restored.deviceId, binding.deviceId);
      expect(restored.platform, binding.platform);
      expect(restored.isPermanent, binding.isPermanent);
    });

    test('DeviceBinding copyWith creates modified copy', () {
      final original = DeviceBinding(
        deviceId: 'original-id',
        platform: 'android',
        boundAt: DateTime.now(),
        lastActive: DateTime.now(),
        isPermanent: true,
      );

      final modified = original.copyWith(deviceId: 'new-id');

      expect(modified.deviceId, 'new-id');
      expect(modified.platform, original.platform);
      expect(modified.isPermanent, original.isPermanent);
    });

    test('DeviceMetadata can be instantiated', () {
      final metadata = DeviceMetadata(
        brand: 'Samsung',
        model: 'Galaxy S21',
        osVersion: '12',
        additional: {'manufacturer': 'Samsung'},
      );

      expect(metadata.brand, 'Samsung');
      expect(metadata.model, 'Galaxy S21');
      expect(metadata.osVersion, '12');
      expect(metadata.additional['manufacturer'], 'Samsung');
    });

    test('DeviceMetadata toMap and fromMap work correctly', () {
      final metadata = DeviceMetadata(
        brand: 'Google',
        model: 'Pixel 6',
        osVersion: '13',
        additional: {'ram': '8GB'},
      );

      final map = metadata.toMap();
      expect(map['brand'], 'Google');
      expect(map['model'], 'Pixel 6');

      final restored = DeviceMetadata.fromMap(map);
      expect(restored.brand, metadata.brand);
      expect(restored.model, metadata.model);
    });

    test('AuthResult success factory creates valid result', () {
      final result = AuthResult.success(userId: 'user-123');

      expect(result.success, true);
      expect(result.userId, 'user-123');
      expect(result.type, AuthResultType.success);
    });

    test('AuthResult failure factory creates valid result', () {
      final result = AuthResult.failure(
        message: 'Device mismatch',
        type: AuthResultType.deviceMismatch,
      );

      expect(result.success, false);
      expect(result.message, 'Device mismatch');
      expect(result.type, AuthResultType.deviceMismatch);
    });

    test('ValidationResult valid factory creates valid result', () {
      final result = ValidationResult.valid();

      expect(result.isValid, true);
      expect(result.type, ValidationResultType.valid);
    });

    test('ValidationResult invalid factory creates invalid result', () {
      final result = ValidationResult.invalid(
        errorMessage: 'Device already bound',
        type: ValidationResultType.deviceAlreadyBound,
      );

      expect(result.isValid, false);
      expect(result.errorMessage, 'Device already bound');
      expect(result.type, ValidationResultType.deviceAlreadyBound);
    });
  });

  group('Exception Tests', () {
    test('DeviceAlreadyBoundException can be created', () {
      const exception = DeviceAlreadyBoundException(
        boundToEmail: 'test@example.com',
        message: 'Device is already bound',
      );

      expect(exception.boundToEmail, 'test@example.com');
      expect(exception.message, 'Device is already bound');
      expect(exception.type, DeviceRestrictionErrorType.deviceAlreadyBound);
    });

    test('DeviceMismatchException can be created', () {
      const exception = DeviceMismatchException(
        expectedDeviceId: 'device-1',
        actualDeviceId: 'device-2',
        message: 'Device mismatch detected',
      );

      expect(exception.expectedDeviceId, 'device-1');
      expect(exception.actualDeviceId, 'device-2');
      expect(exception.message, 'Device mismatch detected');
      expect(exception.type, DeviceRestrictionErrorType.deviceMismatch);
    });

    test('DeviceIdNotFoundException can be created', () {
      const exception = DeviceIdNotFoundException(
        message: 'Device ID not found',
      );

      expect(exception.message, 'Device ID not found');
      expect(exception.type, DeviceRestrictionErrorType.deviceIdNotFound);
    });

    test('PlatformNotSupportedException can be created', () {
      const exception = PlatformNotSupportedException(
        platform: 'ios',
        message: 'iOS not supported',
      );

      expect(exception.platform, 'ios');
      expect(exception.message, 'iOS not supported');
      expect(exception.type, DeviceRestrictionErrorType.platformNotSupported);
    });
  });

  group('Policy Tests', () {
    test('DeviceBindingPolicy allows binding when no existing binding', () {
      const policy = DeviceBindingPolicy();

      final canBind = policy.canBind(null, 'new-device-id');

      expect(canBind, true);
    });

    test('DeviceBindingPolicy allows binding when existing binding is empty',
        () {
      const policy = DeviceBindingPolicy();
      final emptyBinding = DeviceBinding(
        deviceId: '',
        platform: 'android',
        boundAt: DateTime.now(),
        lastActive: DateTime.now(),
      );

      final canBind = policy.canBind(emptyBinding, 'new-device-id');

      expect(canBind, true);
    });

    test('DeviceBindingPolicy denies binding when device already bound', () {
      const policy = DeviceBindingPolicy();
      final existingBinding = DeviceBinding(
        deviceId: 'existing-device',
        platform: 'android',
        boundAt: DateTime.now(),
        lastActive: DateTime.now(),
      );

      final canBind = policy.canBind(existingBinding, 'new-device-id');

      expect(canBind, false);
    });

    test('DeviceBindingPolicy allows login when no existing binding', () {
      const policy = DeviceBindingPolicy();

      final canLogin = policy.canLogin(null, 'device-id');

      expect(canLogin, true);
    });

    test('DeviceBindingPolicy allows login when device matches', () {
      const policy = DeviceBindingPolicy();
      final binding = DeviceBinding(
        deviceId: 'device-123',
        platform: 'android',
        boundAt: DateTime.now(),
        lastActive: DateTime.now(),
      );

      final canLogin = policy.canLogin(binding, 'device-123');

      expect(canLogin, true);
    });

    test('DeviceBindingPolicy denies login when device does not match', () {
      const policy = DeviceBindingPolicy();
      final binding = DeviceBinding(
        deviceId: 'device-123',
        platform: 'android',
        boundAt: DateTime.now(),
        lastActive: DateTime.now(),
      );

      final canLogin = policy.canLogin(binding, 'different-device');

      expect(canLogin, false);
    });

    test('DeviceBindingPolicy marks all bindings as permanent', () {
      const policy = DeviceBindingPolicy();
      final binding = DeviceBinding(
        deviceId: 'device-123',
        platform: 'android',
        boundAt: DateTime.now(),
        lastActive: DateTime.now(),
        isPermanent: true,
      );

      expect(policy.isPermanentBinding(binding), true);
    });

    test('DeviceBindingPolicy does not allow device replacement', () {
      const policy = DeviceBindingPolicy();
      final binding = DeviceBinding(
        deviceId: 'device-123',
        platform: 'android',
        boundAt: DateTime.now(),
        lastActive: DateTime.now(),
      );

      expect(policy.canReplaceDevice(binding), false);
    });
  });

  group('Validator Tests', () {
    test('DeviceBindingValidator validates successful binding', () {
      const validator = DeviceBindingValidator(
        policy: DeviceBindingPolicy(),
      );

      final result = validator.validateBinding(
        existingBinding: null,
        newDeviceId: 'new-device',
        platform: 'android',
      );

      expect(result.isValid, true);
      expect(result.type, ValidationResultType.valid);
    });

    test('DeviceBindingValidator rejects binding when device already bound',
        () {
      const validator = DeviceBindingValidator(
        policy: DeviceBindingPolicy(),
      );
      final existingBinding = DeviceBinding(
        deviceId: 'existing-device',
        platform: 'android',
        boundAt: DateTime.now(),
        lastActive: DateTime.now(),
      );

      final result = validator.validateBinding(
        existingBinding: existingBinding,
        newDeviceId: 'new-device',
        platform: 'android',
      );

      expect(result.isValid, false);
      expect(result.type, ValidationResultType.deviceAlreadyBound);
    });

    test('DeviceBindingValidator validates successful login', () {
      const validator = DeviceBindingValidator(
        policy: DeviceBindingPolicy(),
      );
      final binding = DeviceBinding(
        deviceId: 'device-123',
        platform: 'android',
        boundAt: DateTime.now(),
        lastActive: DateTime.now(),
      );

      final result = validator.validateLogin(
        existingBinding: binding,
        currentDeviceId: 'device-123',
        platform: 'android',
      );

      expect(result.isValid, true);
      expect(result.type, ValidationResultType.valid);
    });

    test('DeviceBindingValidator rejects login on device mismatch', () {
      const validator = DeviceBindingValidator(
        policy: DeviceBindingPolicy(),
      );
      final binding = DeviceBinding(
        deviceId: 'device-123',
        platform: 'android',
        boundAt: DateTime.now(),
        lastActive: DateTime.now(),
      );

      final result = validator.validateLogin(
        existingBinding: binding,
        currentDeviceId: 'different-device',
        platform: 'android',
      );

      expect(result.isValid, false);
      expect(result.type, ValidationResultType.deviceMismatch);
    });
  });
}
