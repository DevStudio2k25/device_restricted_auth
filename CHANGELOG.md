## 0.2.0

**Debug + Release Dual Slot Support & User Metadata**

### New Features

- **Android dual device slots**: `android_debug` and `android_release` slots now coexist under the same account, eliminating re-login when switching between debug and release builds.
- **User metadata storage**: `DeviceAuthUserInfo` model stores `userName`, `email`, and open-ended `customFields` at the Firestore document level for easy admin querying and filtering.
- **Extensible custom fields**: Apps can store any Firestore-compatible extra data (e.g. `subscriptionPlan`, `role`, `referralCode`) alongside device bindings.
- **`BuildMode` enum + `BuildModeDetector`**: Auto-detects current build flavor (`debug`/`release`/`profile`) using Flutter foundation constants.
- **Legacy migration**: Automatically migrates existing `android` field (v0.1.x format) to the new `android_release` slot on the user's next login — no manual steps.
- **Cross-slot signup check**: `verifyDeviceForSignup()` now checks all Android slots to prevent the same physical device from being registered to multiple accounts.
- `lastSeenAt` document-level timestamp updated on every login.

### Breaking Changes

- `initializeDeviceDocument(userId)` and `verifyAndBindDevice(userId)` now accept an optional named parameter `userInfo: DeviceAuthUserInfo?`.
- `DeviceRepository.createBinding()` and `updateActivity()` now accept an optional `userInfo` parameter.
- New Firestore document structure uses `android_debug` and `android_release` slots instead of a single `android` slot. Existing users are migrated automatically on next login.
- `DeviceRepository` interface has two new methods: `findUsersByDeviceAnySlot()` and `updateUserInfo()`. Custom implementations must implement these.

---

## 0.1.1

- Migrated Android Device ID from system Build ID to Secure Android ID (SSAID) to prevent collisions on devices with the same OS build.
- Added `android_id` dependency.

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
