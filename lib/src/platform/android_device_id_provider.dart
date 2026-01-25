// 🔐 Android Device ID Provider
// Retrieves Android hardware device ID

import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'device_id_provider.dart';
import '../core/models/device_metadata.dart';
import '../core/exceptions/device_restriction_exceptions.dart';

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
      final deviceId = androidInfo.id;

      if (deviceId.isEmpty) {
        throw const DeviceIdNotFoundException(
          message: 'Failed to get Android device ID',
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
