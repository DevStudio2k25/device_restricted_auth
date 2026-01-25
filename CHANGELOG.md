## 0.1.0

**Initial Release**

- Device-based login restriction with Firebase Authentication
- Permanent device binding (1 Android + 1 Desktop per account)
- Hardware-level device identification using `device_info_plus`
- Firebase Firestore integration for device management
- Support for Android and Windows Desktop platforms
- Policy-based device binding validation
- Custom exceptions for device restriction scenarios:
  - `DeviceAlreadyBoundException`
  - `DeviceMismatchException`
  - `DeviceIdNotFoundException`
  - `PlatformNotSupportedException`
- Complete example app demonstrating signup and login flows
- Comprehensive documentation and API reference
