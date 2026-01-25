// 🔐 Device Restriction Exceptions
// Custom exceptions for device restriction logic

class DeviceRestrictionException implements Exception {
  final String message;
  final DeviceRestrictionErrorType type;

  const DeviceRestrictionException({
    required this.message,
    required this.type,
  });

  @override
  String toString() => message;
}

enum DeviceRestrictionErrorType {
  deviceAlreadyBound,
  deviceMismatch,
  deviceIdNotFound,
  platformNotSupported,
  firestoreError,
}

class DeviceAlreadyBoundException extends DeviceRestrictionException {
  final String boundToEmail;

  const DeviceAlreadyBoundException({
    required this.boundToEmail,
    required String message,
  }) : super(
          message: message,
          type: DeviceRestrictionErrorType.deviceAlreadyBound,
        );
}

class DeviceMismatchException extends DeviceRestrictionException {
  final String expectedDeviceId;
  final String actualDeviceId;

  const DeviceMismatchException({
    required this.expectedDeviceId,
    required this.actualDeviceId,
    required String message,
  }) : super(
          message: message,
          type: DeviceRestrictionErrorType.deviceMismatch,
        );
}

class DeviceIdNotFoundException extends DeviceRestrictionException {
  const DeviceIdNotFoundException({
    required String message,
  }) : super(
          message: message,
          type: DeviceRestrictionErrorType.deviceIdNotFound,
        );
}

class PlatformNotSupportedException extends DeviceRestrictionException {
  final String platform;

  const PlatformNotSupportedException({
    required this.platform,
    required String message,
  }) : super(
          message: message,
          type: DeviceRestrictionErrorType.platformNotSupported,
        );
}
