import 'package:flutter_test/flutter_test.dart';
import 'package:device_restricted_auth/device_restricted_auth.dart';

void main() {
  // ============================================================
  // Package Import
  // ============================================================
  group('Package Import Tests', () {
    test('package can be imported successfully', () {
      expect(true, isTrue);
    });
  });

  // ============================================================
  // DeviceBinding
  // ============================================================
  group('DeviceBinding Tests', () {
    test('can be instantiated with required fields', () {
      final binding = DeviceBinding(
        deviceId: 'test-device-123',
        platform: 'android_debug',
        boundAt: DateTime.now(),
        lastActive: DateTime.now(),
        isPermanent: true,
      );

      expect(binding.deviceId, 'test-device-123');
      expect(binding.platform, 'android_debug');
      expect(binding.isPermanent, true);
      expect(binding.buildMode, isNull);
    });

    test('can be instantiated with buildMode', () {
      final binding = DeviceBinding(
        deviceId: 'test-device-123',
        platform: 'android_release',
        boundAt: DateTime.now(),
        lastActive: DateTime.now(),
        buildMode: BuildMode.release,
      );

      expect(binding.buildMode, BuildMode.release);
      expect(binding.platform, 'android_release');
    });

    test('toMap includes buildMode when set', () {
      final binding = DeviceBinding(
        deviceId: 'device-456',
        platform: 'android_debug',
        boundAt: DateTime.now(),
        lastActive: DateTime.now(),
        buildMode: BuildMode.debug,
      );

      final map = binding.toMap();
      expect(map['buildMode'], 'debug');
    });

    test('toMap omits buildMode when null', () {
      final binding = DeviceBinding(
        deviceId: 'device-desktop',
        platform: 'desktop',
        boundAt: DateTime.now(),
        lastActive: DateTime.now(),
      );

      final map = binding.toMap();
      expect(map.containsKey('buildMode'), false);
    });

    test('fromMap restores buildMode correctly', () {
      final now = DateTime.now();
      final map = {
        'deviceId': 'dev-789',
        'platform': 'android_release',
        'boundAt': now,
        'lastActive': now,
        'isPermanent': true,
        'buildMode': 'release',
      };

      final binding = DeviceBinding.fromMap(map);
      expect(binding.buildMode, BuildMode.release);
    });

    test('fromMap handles missing buildMode gracefully', () {
      final now = DateTime.now();
      final map = {
        'deviceId': 'dev-desktop',
        'platform': 'desktop',
        'boundAt': now,
        'lastActive': now,
        'isPermanent': true,
      };

      final binding = DeviceBinding.fromMap(map);
      expect(binding.buildMode, isNull);
    });

    test('toMap and fromMap round-trip correctly', () {
      final now = DateTime.now();
      final binding = DeviceBinding(
        deviceId: 'device-456',
        platform: 'desktop',
        boundAt: now,
        lastActive: now,
        isPermanent: true,
      );

      final map = binding.toMap();
      final restored = DeviceBinding.fromMap(map);
      expect(restored.deviceId, binding.deviceId);
      expect(restored.platform, binding.platform);
      expect(restored.isPermanent, binding.isPermanent);
    });

    test('copyWith creates modified copy preserving buildMode', () {
      final original = DeviceBinding(
        deviceId: 'original-id',
        platform: 'android_debug',
        boundAt: DateTime.now(),
        lastActive: DateTime.now(),
        isPermanent: true,
        buildMode: BuildMode.debug,
      );

      final modified = original.copyWith(deviceId: 'new-id');
      expect(modified.deviceId, 'new-id');
      expect(modified.platform, original.platform);
      expect(modified.buildMode, BuildMode.debug);
    });

    test('copyWith can override buildMode', () {
      final original = DeviceBinding(
        deviceId: 'id',
        platform: 'android_debug',
        boundAt: DateTime.now(),
        lastActive: DateTime.now(),
        buildMode: BuildMode.debug,
      );

      final modified = original.copyWith(buildMode: BuildMode.release);
      expect(modified.buildMode, BuildMode.release);
    });
  });

  // ============================================================
  // BuildMode
  // ============================================================
  group('BuildMode Tests', () {
    test('BuildMode enum has three values', () {
      expect(BuildMode.values.length, 3);
      expect(BuildMode.values, contains(BuildMode.debug));
      expect(BuildMode.values, contains(BuildMode.release));
      expect(BuildMode.values, contains(BuildMode.profile));
    });

    test('debug slotName is "debug"', () {
      expect(BuildMode.debug.slotName, 'debug');
    });

    test('release slotName is "release"', () {
      expect(BuildMode.release.slotName, 'release');
    });

    test('profile slotName is "debug" (shares debug slot)', () {
      expect(BuildMode.profile.slotName, 'debug');
    });

    test('BuildModeDetector.current() returns a valid BuildMode', () {
      final mode = BuildModeDetector.current();
      expect(BuildMode.values, contains(mode));
      // In test environment, kDebugMode == true → should be debug
      expect(mode, BuildMode.debug);
    });
  });

  // ============================================================
  // DeviceAuthUserInfo
  // ============================================================
  group('DeviceAuthUserInfo Tests', () {
    test('can be instantiated with all fields', () {
      const info = DeviceAuthUserInfo(
        userName: 'Rahul Sharma',
        email: 'rahul@example.com',
        customFields: {'plan': 'premium', 'role': 'user'},
      );

      expect(info.userName, 'Rahul Sharma');
      expect(info.email, 'rahul@example.com');
      expect(info.customFields['plan'], 'premium');
    });

    test('can be instantiated with only userName', () {
      const info = DeviceAuthUserInfo(userName: 'Rahul');
      expect(info.userName, 'Rahul');
      expect(info.email, isNull);
      expect(info.customFields, isEmpty);
    });

    test('defaults to empty customFields', () {
      const info = DeviceAuthUserInfo();
      expect(info.customFields, isEmpty);
    });

    test('toFirestoreMap includes non-null fields', () {
      const info = DeviceAuthUserInfo(
        userName: 'Rahul',
        email: 'rahul@example.com',
        customFields: {'plan': 'free'},
      );

      final map = info.toFirestoreMap();
      expect(map['userName'], 'Rahul');
      expect(map['email'], 'rahul@example.com');
      expect(map['plan'], 'free');
    });

    test('toFirestoreMap omits null fields', () {
      const info = DeviceAuthUserInfo(userName: 'Rahul');
      final map = info.toFirestoreMap();

      expect(map.containsKey('userName'), true);
      expect(map.containsKey('email'), false);
    });

    test('toFirestoreMap with empty info returns empty map', () {
      const info = DeviceAuthUserInfo();
      final map = info.toFirestoreMap();
      expect(map, isEmpty);
    });

    test('customFields are merged at top level in toFirestoreMap', () {
      const info = DeviceAuthUserInfo(
        customFields: {
          'subscriptionPlan': 'gold',
          'referralCode': 'ABC123',
        },
      );

      final map = info.toFirestoreMap();
      expect(map['subscriptionPlan'], 'gold');
      expect(map['referralCode'], 'ABC123');
      // customFields should NOT be a nested key
      expect(map.containsKey('customFields'), false);
    });
  });

  // ============================================================
  // DeviceMetadata
  // ============================================================
  group('DeviceMetadata Tests', () {
    test('can be instantiated', () {
      const metadata = DeviceMetadata(
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

    test('toMap and fromMap round-trip correctly', () {
      const metadata = DeviceMetadata(
        brand: 'Google',
        model: 'Pixel 6',
        osVersion: '13',
        additional: {'ram': '8GB'},
      );

      final map = metadata.toMap();
      final restored = DeviceMetadata.fromMap(map);
      expect(restored.brand, metadata.brand);
      expect(restored.model, metadata.model);
    });
  });

  // ============================================================
  // AuthResult
  // ============================================================
  group('AuthResult Tests', () {
    test('success factory creates valid result', () {
      final result = AuthResult.success(userId: 'user-123');
      expect(result.success, true);
      expect(result.userId, 'user-123');
      expect(result.type, AuthResultType.success);
    });

    test('failure factory creates invalid result', () {
      final result = AuthResult.failure(
        message: 'Device mismatch',
        type: AuthResultType.deviceMismatch,
      );
      expect(result.success, false);
      expect(result.message, 'Device mismatch');
      expect(result.type, AuthResultType.deviceMismatch);
    });
  });

  // ============================================================
  // ValidationResult
  // ============================================================
  group('ValidationResult Tests', () {
    test('valid factory creates valid result', () {
      final result = ValidationResult.valid();
      expect(result.isValid, true);
      expect(result.type, ValidationResultType.valid);
    });

    test('invalid factory creates invalid result', () {
      final result = ValidationResult.invalid(
        errorMessage: 'Device already bound',
        type: ValidationResultType.deviceAlreadyBound,
      );
      expect(result.isValid, false);
      expect(result.errorMessage, 'Device already bound');
      expect(result.type, ValidationResultType.deviceAlreadyBound);
    });
  });

  // ============================================================
  // Exceptions
  // ============================================================
  group('Exception Tests', () {
    test('DeviceAlreadyBoundException can be created', () {
      const exception = DeviceAlreadyBoundException(
        boundToEmail: 'test@example.com',
        message: 'Device is already bound',
      );
      expect(exception.boundToEmail, 'test@example.com');
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
      expect(exception.type, DeviceRestrictionErrorType.platformNotSupported);
    });
  });

  // ============================================================
  // DeviceBindingPolicy
  // ============================================================
  group('Policy Tests', () {
    test('allows binding when no existing binding', () {
      const policy = DeviceBindingPolicy();
      expect(policy.canBind(null, 'new-device-id'), true);
    });

    test('allows binding when existing binding is empty', () {
      const policy = DeviceBindingPolicy();
      final emptyBinding = DeviceBinding(
        deviceId: '',
        platform: 'android_debug',
        boundAt: DateTime.now(),
        lastActive: DateTime.now(),
      );
      expect(policy.canBind(emptyBinding, 'new-device-id'), true);
    });

    test('denies binding when device already bound', () {
      const policy = DeviceBindingPolicy();
      final existingBinding = DeviceBinding(
        deviceId: 'existing-device',
        platform: 'android_release',
        boundAt: DateTime.now(),
        lastActive: DateTime.now(),
      );
      expect(policy.canBind(existingBinding, 'new-device-id'), false);
    });

    test('allows login when no existing binding', () {
      const policy = DeviceBindingPolicy();
      expect(policy.canLogin(null, 'device-id'), true);
    });

    test('allows login when device matches', () {
      const policy = DeviceBindingPolicy();
      final binding = DeviceBinding(
        deviceId: 'device-123',
        platform: 'android_debug',
        boundAt: DateTime.now(),
        lastActive: DateTime.now(),
      );
      expect(policy.canLogin(binding, 'device-123'), true);
    });

    test('denies login when device does not match', () {
      const policy = DeviceBindingPolicy();
      final binding = DeviceBinding(
        deviceId: 'device-123',
        platform: 'android_debug',
        boundAt: DateTime.now(),
        lastActive: DateTime.now(),
      );
      expect(policy.canLogin(binding, 'different-device'), false);
    });

    test('marks all bindings as permanent', () {
      const policy = DeviceBindingPolicy();
      final binding = DeviceBinding(
        deviceId: 'device-123',
        platform: 'android_release',
        boundAt: DateTime.now(),
        lastActive: DateTime.now(),
        isPermanent: true,
      );
      expect(policy.isPermanentBinding(binding), true);
    });

    test('does not allow device replacement', () {
      const policy = DeviceBindingPolicy();
      final binding = DeviceBinding(
        deviceId: 'device-123',
        platform: 'android_release',
        boundAt: DateTime.now(),
        lastActive: DateTime.now(),
      );
      expect(policy.canReplaceDevice(binding), false);
    });
  });

  // ============================================================
  // DeviceBindingValidator
  // ============================================================
  group('Validator Tests', () {
    const validator = DeviceBindingValidator(policy: DeviceBindingPolicy());

    test('validates successful binding', () {
      final result = validator.validateBinding(
        existingBinding: null,
        newDeviceId: 'new-device',
        platform: 'android_debug',
      );
      expect(result.isValid, true);
      expect(result.type, ValidationResultType.valid);
    });

    test('rejects binding when device already bound', () {
      final existingBinding = DeviceBinding(
        deviceId: 'existing-device',
        platform: 'android_debug',
        boundAt: DateTime.now(),
        lastActive: DateTime.now(),
      );
      final result = validator.validateBinding(
        existingBinding: existingBinding,
        newDeviceId: 'new-device',
        platform: 'android_debug',
      );
      expect(result.isValid, false);
      expect(result.type, ValidationResultType.deviceAlreadyBound);
    });

    test('validates successful login', () {
      final binding = DeviceBinding(
        deviceId: 'device-123',
        platform: 'android_release',
        boundAt: DateTime.now(),
        lastActive: DateTime.now(),
      );
      final result = validator.validateLogin(
        existingBinding: binding,
        currentDeviceId: 'device-123',
        platform: 'android_release',
      );
      expect(result.isValid, true);
      expect(result.type, ValidationResultType.valid);
    });

    test('rejects login on device mismatch', () {
      final binding = DeviceBinding(
        deviceId: 'device-123',
        platform: 'android_debug',
        boundAt: DateTime.now(),
        lastActive: DateTime.now(),
      );
      final result = validator.validateLogin(
        existingBinding: binding,
        currentDeviceId: 'different-device',
        platform: 'android_debug',
      );
      expect(result.isValid, false);
      expect(result.type, ValidationResultType.deviceMismatch);
    });

    test('debug and release slots are independent — mismatch check uses correct slot', () {
      // Binding in android_debug slot
      final debugBinding = DeviceBinding(
        deviceId: 'debug-ssaid',
        platform: 'android_debug',
        boundAt: DateTime.now(),
        lastActive: DateTime.now(),
      );

      // Login attempt on android_release slot with release SSAID
      // (different SSAID, different slot — should be treated as first-time)
      final releaseBinding = DeviceBinding(
        deviceId: 'release-ssaid',
        platform: 'android_release',
        boundAt: DateTime.now(),
        lastActive: DateTime.now(),
      );

      // Validate debug slot — same SSAID should match
      final debugResult = validator.validateLogin(
        existingBinding: debugBinding,
        currentDeviceId: 'debug-ssaid',
        platform: 'android_debug',
      );
      expect(debugResult.isValid, true);

      // Validate release slot — same SSAID should match
      final releaseResult = validator.validateLogin(
        existingBinding: releaseBinding,
        currentDeviceId: 'release-ssaid',
        platform: 'android_release',
      );
      expect(releaseResult.isValid, true);
    });
  });
}
