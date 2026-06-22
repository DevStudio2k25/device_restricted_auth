// 🔐 Windows Device ID Provider
// Retrieves Windows device identifier

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'device_id_provider.dart';
import '../core/models/device_metadata.dart';
import '../core/exceptions/device_restriction_exceptions.dart';

/// Retrieves Windows device identifier using device_info_plus.
///
/// This provider uses the Windows device ID which is unique to the device.
/// The ID is hardware-based and persists across app reinstalls.
///
/// Example:
/// ```dart
/// final provider = WindowsDeviceIdProvider();
/// final deviceId = await provider.getDeviceId();
/// ```
///
/// Throws [PlatformNotSupportedException] if used on non-Windows platforms.
/// Throws [DeviceIdNotFoundException] if the device ID cannot be retrieved.
class WindowsDeviceIdProvider implements DeviceIdProvider {
  final DeviceInfoPlugin _deviceInfo;

  WindowsDeviceIdProvider({DeviceInfoPlugin? deviceInfo})
      : _deviceInfo = deviceInfo ?? DeviceInfoPlugin();

  @override
  Future<String> getDeviceId() async {
    if (!Platform.isWindows) {
      throw const PlatformNotSupportedException(
        platform: 'windows',
        message: 'This provider only works on Windows platform',
      );
    }

    try {
      final windowsInfo = await _deviceInfo.windowsInfo;
      final deviceId = windowsInfo.deviceId;

      if (deviceId.isEmpty) {
        throw const DeviceIdNotFoundException(
          message: 'Failed to get Windows device ID',
        );
      }

      debugPrint('💻 Windows Device Info:');
      debugPrint('   Device ID: $deviceId');
      debugPrint('   Computer Name: ${windowsInfo.computerName}');

      return deviceId;
    } catch (e) {
      debugPrint('❌ Error getting Windows device ID: $e');
      throw DeviceIdNotFoundException(
        message: 'Failed to retrieve Windows device information: $e',
      );
    }
  }

  @override
  String getPlatformName() {
    return 'desktop';
  }

  @override
  Future<DeviceMetadata> getMetadata() async {
    final windowsInfo = await _deviceInfo.windowsInfo;
    return DeviceMetadata(
      brand: 'Windows',
      model: windowsInfo.computerName,
      osVersion: windowsInfo.buildNumber.toString(),
      additional: {
        'computerName': windowsInfo.computerName,
        'numberOfCores': windowsInfo.numberOfCores,
        'systemMemoryInMegabytes': windowsInfo.systemMemoryInMegabytes,
      },
    );
  }
}
