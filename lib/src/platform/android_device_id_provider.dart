// 🔐 Android Device ID Provider
// Retrieves Android hardware device ID

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:android_id/android_id.dart';
import 'device_id_provider.dart';
import '../core/models/device_metadata.dart';
import '../core/models/build_mode.dart';
import '../core/exceptions/device_restriction_exceptions.dart';

/// Retrieves Android device hardware ID using [android_id] (SSAID).
///
/// The SSAID (`Settings.Secure.ANDROID_ID`) is unique per device **and**
/// signing key on Android 8+. This means debug and release builds produce
/// different SSAIDs on the same physical device. This provider accounts for
/// this by returning a **build-mode-aware platform slot name**
/// (`android_debug` or `android_release`) so both IDs can coexist under the
/// same account in Firestore without conflict.
///
/// Example:
/// ```dart
/// final provider = AndroidDeviceIdProvider();
/// final deviceId = await provider.getDeviceId();  // SSAID string
/// final slot     = provider.getPlatformName();     // "android_debug" or "android_release"
/// ```
///
/// Throws [PlatformNotSupportedException] if used on non-Android platforms.
/// Throws [DeviceIdNotFoundException] if the device ID cannot be retrieved.
class AndroidDeviceIdProvider implements DeviceIdProvider {
  final DeviceInfoPlugin _deviceInfo;

  AndroidDeviceIdProvider({DeviceInfoPlugin? deviceInfo})
      : _deviceInfo = deviceInfo ?? DeviceInfoPlugin();

  @override
  Future<String> getDeviceId() async {
    if (!Platform.isAndroid) {
      throw const PlatformNotSupportedException(
        platform: 'android',
        message: 'This provider only works on Android platform',
      );
    }

    try {
      final androidInfo = await _deviceInfo.androidInfo;
      const androidIdPlugin = AndroidId();
      final deviceId = await androidIdPlugin.getId();

      if (deviceId == null || deviceId.isEmpty) {
        throw const DeviceIdNotFoundException(
          message: 'Failed to get Android secure device ID (SSAID)',
        );
      }

      final slot = getPlatformName();
      debugPrint('📱 Android Device Info:');
      debugPrint('   Device ID (SSAID): $deviceId');
      debugPrint('   Firestore Slot: $slot');
      debugPrint('   Brand: ${androidInfo.brand}');
      debugPrint('   Model: ${androidInfo.model}');
      debugPrint('   Manufacturer: ${androidInfo.manufacturer}');
      debugPrint('   Android Version: ${androidInfo.version.release}');

      return deviceId;
    } catch (e) {
      debugPrint('❌ Error getting Android device ID: $e');
      throw DeviceIdNotFoundException(
        message: 'Failed to retrieve Android device information: $e',
      );
    }
  }

  /// Returns the Firestore slot name for the current build mode.
  ///
  /// - Debug / Profile build → `"android_debug"`
  /// - Release build         → `"android_release"`
  ///
  /// This ensures both build variants can coexist under the same user account
  /// without forcing re-login when switching between them.
  @override
  String getPlatformName() {
    return 'android_${BuildModeDetector.current().slotName}';
  }

  @override
  Future<DeviceMetadata> getMetadata() async {
    final androidInfo = await _deviceInfo.androidInfo;
    return DeviceMetadata(
      brand: androidInfo.brand,
      model: androidInfo.model,
      osVersion: androidInfo.version.release,
      additional: {
        'manufacturer': androidInfo.manufacturer,
        'sdkInt': androidInfo.version.sdkInt,
        'buildSlot': getPlatformName(),
      },
    );
  }
}
