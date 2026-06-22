// 🔐 Device Restriction Coordinator
// Orchestrates device restriction logic during auth operations

import 'package:flutter/foundation.dart';
import '../core/models/device_binding.dart';
import '../core/models/validation_result.dart';
import '../core/models/build_mode.dart';
import '../core/models/user_info.dart';
import '../core/validators/device_binding_validator.dart';
import '../core/policies/device_binding_policy.dart';
import '../firebase/device_repository.dart';
import '../platform/device_id_provider.dart';
import '../core/exceptions/device_restriction_exceptions.dart';

/// Orchestrates device restriction logic during authentication operations.
///
/// This is the main entry point for implementing device-based login restrictions.
/// It coordinates between device ID providers, the Firestore repository, and
/// validation policies.
///
/// ## Android dual-slot support
/// On Android, debug and release builds receive separate Firestore slots
/// (`android_debug` / `android_release`) so both can coexist under the same
/// account without forcing re-login when switching build flavors.
///
/// ## User metadata
/// Pass a [DeviceAuthUserInfo] to [verifyAndBindDevice] and
/// [initializeDeviceDocument] to store `userName`, `email`, and any custom
/// fields at the document level for easy admin queries.
///
/// Example:
/// ```dart
/// final coordinator = DeviceRestrictionCoordinator(
///   deviceRepository: FirestoreDeviceRepository(),
///   deviceIdProvider: AndroidDeviceIdProvider(),
/// );
///
/// // On signup
/// await coordinator.initializeDeviceDocument(
///   user.uid,
///   userInfo: DeviceAuthUserInfo(
///     userName: 'Rahul',
///     email: user.email,
///     customFields: {'plan': 'free'},
///   ),
/// );
///
/// // On every login
/// await coordinator.verifyAndBindDevice(
///   user.uid,
///   userInfo: DeviceAuthUserInfo(userName: 'Rahul', email: user.email),
/// );
/// ```
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

  // ---------------------------------------------------------------------------
  // verifyDeviceForSignup
  // ---------------------------------------------------------------------------

  /// Verifies that the current device is available for a new account signup.
  ///
  /// Checks **all** Android slots (debug + release + legacy) to prevent the
  /// same physical device from being registered to multiple accounts.
  ///
  /// Call this **before** creating a new Firebase Auth user account.
  ///
  /// Throws [DeviceAlreadyBoundException] if the device is already bound.
  ///
  /// Example:
  /// ```dart
  /// try {
  ///   await coordinator.verifyDeviceForSignup();
  ///   // Proceed with Firebase account creation
  /// } on DeviceAlreadyBoundException catch (e) {
  ///   // Show error
  /// }
  /// ```
  Future<void> verifyDeviceForSignup() async {
    final deviceId = await deviceIdProvider.getDeviceId();
    final platform = deviceIdProvider.getPlatformName();

    // Derive base platform for cross-slot search
    // e.g. "android_debug" → "android", "desktop" → "desktop"
    final basePlatform = platform.contains('_')
        ? platform.substring(0, platform.indexOf('_'))
        : platform;

    debugPrint('🔍 Checking if device is already bound...');
    debugPrint('   Device ID: $deviceId');
    debugPrint('   Slot: $platform');
    debugPrint('   Base Platform: $basePlatform');

    final boundUsers = await deviceRepository.findUsersByDeviceAnySlot(
      deviceId,
      basePlatform,
    );

    if (boundUsers.isNotEmpty) {
      throw const DeviceAlreadyBoundException(
        boundToEmail: 'another account',
        message: '🚫 Device Already Registered!\n\n'
            'This device is already linked to another account.\n\n'
            'Each device can only be used with one account.\n'
            'Please sign in with your existing account.',
      );
    }

    debugPrint('✅ Device is available for new account');
  }

  // ---------------------------------------------------------------------------
  // verifyAndBindDevice
  // ---------------------------------------------------------------------------

  /// Verifies and binds the current device to the user account.
  ///
  /// - **First login on this slot**: permanently binds device + stores user info.
  /// - **Subsequent logins**: validates device ID matches, updates activity +
  ///   refreshes user info.
  ///
  /// The [userInfo] parameter is optional but recommended — it keeps
  /// `userName`, `email`, and any custom fields up to date on every login.
  ///
  /// Throws [DeviceMismatchException] if a different device tries to use this slot.
  ///
  /// Example:
  /// ```dart
  /// try {
  ///   await coordinator.verifyAndBindDevice(
  ///     user.uid,
  ///     userInfo: DeviceAuthUserInfo(
  ///       userName: 'Rahul',
  ///       email: user.email,
  ///       customFields: {'plan': 'premium'},
  ///     ),
  ///   );
  /// } on DeviceMismatchException catch (e) {
  ///   await FirebaseAuth.instance.signOut();
  /// }
  /// ```
  Future<void> verifyAndBindDevice(
    String userId, {
    DeviceAuthUserInfo? userInfo,
  }) async {
    final deviceId = await deviceIdProvider.getDeviceId();
    final platform = deviceIdProvider.getPlatformName();

    // Determine current build mode for binding metadata
    final buildMode = BuildModeDetector.current();

    debugPrint('🔐 Verifying Device Binding...');
    debugPrint('   User ID: $userId');
    debugPrint('   Device ID: $deviceId');
    debugPrint('   Slot: $platform');
    debugPrint('   Build Mode: ${buildMode.name}');

    // Get existing binding for this specific slot
    final existingBinding = await deviceRepository.getBinding(userId, platform);

    // First-time login on this slot → bind permanently
    if (existingBinding == null || existingBinding.deviceId.isEmpty) {
      debugPrint('🆕 First time login on slot "$platform" — binding device...');

      final newBinding = DeviceBinding(
        deviceId: deviceId,
        platform: platform,
        boundAt: DateTime.now(),
        lastActive: DateTime.now(),
        isPermanent: true,
        buildMode: buildMode,
      );

      await deviceRepository.createBinding(
        userId,
        newBinding,
        userInfo: userInfo,
      );
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

    // Device matches — update last active + refresh user info
    debugPrint('✅ Device Matched! Updating activity...');
    await deviceRepository.updateActivity(
      userId,
      platform,
      userInfo: userInfo,
    );
    debugPrint('✅ Device Binding Verified Successfully!');
  }

  // ---------------------------------------------------------------------------
  // initializeDeviceDocument
  // ---------------------------------------------------------------------------

  /// Initializes the device document in Firestore for a new user.
  ///
  /// Creates a document with empty `android_debug`, `android_release`, and
  /// `desktop` slots, plus user metadata if provided.
  ///
  /// Call this immediately after creating a new Firebase Auth account.
  ///
  /// Example:
  /// ```dart
  /// final credential = await FirebaseAuth.instance
  ///     .createUserWithEmailAndPassword(...);
  ///
  /// await coordinator.initializeDeviceDocument(
  ///   credential.user!.uid,
  ///   userInfo: DeviceAuthUserInfo(
  ///     userName: displayName,
  ///     email: credential.user!.email,
  ///     customFields: {'plan': 'free', 'role': 'user'},
  ///   ),
  /// );
  /// ```
  Future<void> initializeDeviceDocument(
    String userId, {
    DeviceAuthUserInfo? userInfo,
  }) async {
    await deviceRepository.initializeDeviceDocument(
      userId,
      userInfo: userInfo,
    );
  }
}
