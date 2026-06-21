// 🔐 Android Device ID Provider
// Retrieves Android hardware device ID

import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:android_id/android_id.dart';
import 'device_id_provider.dart';
import '../core/models/device_metadata.dart';
import '../core/exceptions/device_restriction_exceptions.dart';

/// Retrieves Android device hardware ID using device_info_plus.
///
/// This provider uses the Android ID (`androidId`) which is unique per device
/// and app installation. The ID persists across app reinstalls but may change
/// if the device is factory reset.
///
/// Example:
/// ```dart
/// final provider = AndroidDeviceIdProvider();
/// final deviceId = await provider.getDeviceId();
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

      print('📱 Android Device Info:');
      print('   Device ID (androidId): $deviceId');
      print('   Brand: ${androidInfo.brand}');
      print('   Model: ${androidInfo.model}');
      print('   Manufacturer: ${androidInfo.manufacturer}');
      print('   Android Version: ${androidInfo.version.release}');

      return deviceId;
    } catch (e) {
      print('❌ Error getting Android device ID: $e');
      throw DeviceIdNotFoundException(
        message: 'Failed to retrieve Android device information: $e',
      );
    }
  }

  @override
  String getPlatformName() {
    return 'android';
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
      },
    );
  }
}
