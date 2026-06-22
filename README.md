# Device Restricted Auth

A Flutter package that enforces **device-based login restrictions** using Firebase Authentication and Firestore. Permanently binds user accounts to specific devices — supports both **debug and release builds** on the same device.

## What is Device Restricted Auth?

This package permanently binds user accounts to specific devices, preventing account sharing across multiple devices. Once a user signs up or logs in from a device, that account becomes permanently linked to that device's hardware ID (SSAID on Android).

**Android debug and release builds get separate Firestore slots** (`android_debug` / `android_release`) so developers don't have to re-login when switching builds — while still enforcing the 1-physical-device-per-account rule.

## Why Use This Package?

**Use Cases:**

- **Streaming Apps**: Prevent password sharing (like Netflix's device limits)
- **Premium Apps**: Enforce "1 device per license" policies
- **Enterprise Apps**: Restrict corporate accounts to company-owned devices
- **Educational Apps**: Ensure students use their own devices for exams
- **Private Tools**: Limit access to authorized devices only

**Key Benefits:**

- Hardware-level device identification (SSAID — not spoofable by users)
- Debug + release builds coexist under the same account (no re-login when switching)
- User metadata (`userName`, `email`, custom fields) stored for easy admin queries
- Server-side enforcement via Firestore security rules
- Automatic device binding on first login
- Automatic legacy data migration from older `android` slot format

## Features

- ✅ **Permanent Device Binding**: Each account supports 1 Android (debug) + 1 Android (release) + 1 Desktop
- ✅ **Debug/Release Dual Slots**: No re-login needed when switching build flavors
- ✅ **User Metadata Storage**: `userName`, `email`, and custom fields stored at document level
- ✅ **Admin-Friendly Queries**: Filter `user_devices` by `userName`, `email`, or any custom field
- ✅ **Extensible Custom Fields**: Apps can add any extra metadata (plan, role, referralCode, etc.)
- ✅ **Legacy Migration**: Automatically migrates old `android` key to new dual-slot format
- ✅ **Hardware-Level Security**: Uses platform-specific hardware identifiers (SSAID)
- ✅ **Firebase Integration**: Works seamlessly with Firebase Auth and Firestore
- ✅ **Cross-Platform**: Android and Windows Desktop support
- ✅ **Policy-Based**: Configurable device binding policies
- ✅ **Type-Safe**: Full Dart type safety with custom exceptions

## Supported Platforms

| Platform | Support | Device ID Source                        |
| -------- | ------- | --------------------------------------- |
| Android  | ✅ Yes  | SSAID via `android_id` package          |
| Windows  | ✅ Yes  | Windows device ID from device_info_plus |
| iOS      | ❌ No   | Not implemented                         |
| macOS    | ❌ No   | Not implemented                         |
| Linux    | ❌ No   | Not implemented                         |
| Web      | ❌ No   | Not supported (no hardware ID)          |

## Installation

Add this to your `pubspec.yaml`:

```yaml
dependencies:
  device_restricted_auth: ^0.2.0
  firebase_core: ^3.8.0
  firebase_auth: ^5.3.3
  cloud_firestore: ^5.5.0
```

Then run:

```bash
flutter pub get
```

## Firebase Setup

### 1. Initialize Firebase

```dart
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}
```

### 2. Firestore Structure

This package uses the `user_devices` collection. Each document is keyed by Firebase Auth `userId`:

```
user_devices/{userId}
├── userName: "Rahul Sharma"          ← for admin filtering
├── email: "rahul@example.com"        ← for admin filtering
├── createdAt: Timestamp
├── lastSeenAt: Timestamp
├── [customFields...]                 ← any extra app-defined fields
│
├── android_debug:                    ← debug build SSAID
│   ├── deviceId: "ssaid_debug_value"
│   ├── buildMode: "debug"
│   ├── boundAt: Timestamp
│   ├── lastActive: Timestamp
│   └── isPermanent: true
│
├── android_release:                  ← release build SSAID
│   ├── deviceId: "ssaid_release_value"
│   ├── buildMode: "release"
│   ├── boundAt: Timestamp
│   ├── lastActive: Timestamp
│   └── isPermanent: true
│
└── desktop:
    ├── deviceId: "windows_id"
    ├── boundAt: Timestamp
    ├── lastActive: Timestamp
    └── isPermanent: true
```

> **Admin query example** — filter by `userName` in Firestore:
> ```dart
> firestore.collection('user_devices')
>   .where('userName', isEqualTo: 'Rahul Sharma')
>   .get();
> ```

### 3. Firestore Security Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // User devices collection — users can only read/write their own document
    match /user_devices/{userId} {
      allow read: if request.auth != null && request.auth.uid == userId;
      allow write: if request.auth != null && request.auth.uid == userId;
    }

    // Users collection
    match /users/{userId} {
      allow read: if request.auth != null && request.auth.uid == userId;
      allow create: if request.auth != null && request.auth.uid == userId;
      allow update: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

## Usage

### Step 1: Initialize the Coordinator

```dart
import 'dart:io';
import 'package:device_restricted_auth/device_restricted_auth.dart';

final deviceIdProvider = Platform.isAndroid
    ? AndroidDeviceIdProvider()
    : WindowsDeviceIdProvider();

final coordinator = DeviceRestrictionCoordinator(
  deviceRepository: FirestoreDeviceRepository(),
  deviceIdProvider: deviceIdProvider,
);
```

### Step 2: During User Signup

```dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:device_restricted_auth/device_restricted_auth.dart';

Future<void> signUp(String email, String password, String displayName) async {
  try {
    // 1. Check if device is available for new account
    await coordinator.verifyDeviceForSignup();

    // 2. Create Firebase account
    final credential = await FirebaseAuth.instance
        .createUserWithEmailAndPassword(email: email, password: password);

    // 3. Initialize device document with user info
    await coordinator.initializeDeviceDocument(
      credential.user!.uid,
      userInfo: DeviceAuthUserInfo(
        userName: displayName,
        email: email,
        customFields: {
          'plan': 'free',
          'role': 'user',
          // Add any extra fields your app needs
        },
      ),
    );

    // 4. Bind current device to this account
    await coordinator.verifyAndBindDevice(
      credential.user!.uid,
      userInfo: DeviceAuthUserInfo(userName: displayName, email: email),
    );

  } on DeviceAlreadyBoundException catch (e) {
    // Device is already registered to another account
    print('Error: ${e.message}');
  } catch (e) {
    print('Signup failed: $e');
  }
}
```

### Step 3: During User Login

```dart
Future<void> login(String email, String password, String displayName) async {
  try {
    // 1. Sign in with Firebase
    final credential = await FirebaseAuth.instance
        .signInWithEmailAndPassword(email: email, password: password);

    // 2. Verify device binding — also refreshes user info on every login
    await coordinator.verifyAndBindDevice(
      credential.user!.uid,
      userInfo: DeviceAuthUserInfo(
        userName: displayName,
        email: email,
        customFields: {'plan': 'premium'}, // optional
      ),
    );

  } on DeviceMismatchException catch (e) {
    print('Error: ${e.message}');
    await FirebaseAuth.instance.signOut();
  } catch (e) {
    print('Login failed: $e');
  }
}
```

## How Debug + Release Dual Slots Work

| Build Flavor | Firestore Slot | SSAID |
|---|---|---|
| `flutter run` (debug) | `android_debug` | Debug keystore SSAID |
| `flutter run --release` | `android_release` | Release keystore SSAID |
| Windows | `desktop` | Windows device ID |

Both slots belong to the same account. On first login from each build flavor, the device is automatically bound to that slot. Subsequent logins from that same flavor require no re-login.

> **Physical device uniqueness is still enforced.** `verifyDeviceForSignup()` checks **all** Android slots — a device cannot be registered to two different accounts regardless of build flavor.

## Legacy Migration (from v0.1.x)

If you have existing users with the old `android` field, the package **automatically migrates** it to `android_release` on the user's next login. No manual steps required.

## DeviceAuthUserInfo — Custom Fields

The `DeviceAuthUserInfo` model accepts any extra fields your app needs:

```dart
DeviceAuthUserInfo(
  userName: 'Rahul',
  email: 'rahul@example.com',
  customFields: {
    'subscriptionPlan': 'premium',
    'role': 'admin',
    'referralCode': 'ABC123',
    'onboardingComplete': true,
    // anything Firestore-compatible
  },
)
```

These fields are stored at the **document level** in `user_devices/{userId}`, so they are queryable directly without going into sub-maps.

## Error Handling

### DeviceAlreadyBoundException

Thrown during signup when the device is already registered to another account.

```dart
try {
  await coordinator.verifyDeviceForSignup();
} on DeviceAlreadyBoundException catch (e) {
  // Show: "This device is already linked to another account"
}
```

### DeviceMismatchException

Thrown during login when a different physical device tries to use an account slot.

```dart
try {
  await coordinator.verifyAndBindDevice(userId);
} on DeviceMismatchException catch (e) {
  await FirebaseAuth.instance.signOut();
}
```

### DeviceIdNotFoundException

Thrown when the SSAID cannot be retrieved.

```dart
try {
  final deviceId = await deviceIdProvider.getDeviceId();
} on DeviceIdNotFoundException catch (e) {
  // Check device permissions
}
```

### PlatformNotSupportedException

Thrown when using a provider on an unsupported platform.

```dart
try {
  final provider = AndroidDeviceIdProvider();
  await provider.getDeviceId(); // On iOS/Windows
} on PlatformNotSupportedException catch (e) {
  // Platform not supported
}
```

## How Device Binding Works

1. **Signup**: Device checked across all slots → Account created → Document initialized with user info
2. **First Login (debug build)**: `android_debug` slot bound permanently
3. **First Login (release build)**: `android_release` slot bound permanently (no re-login needed if debug was already bound)
4. **Subsequent Logins**: Device ID validated against slot → `lastSeenAt` + user info updated
5. **Legacy users**: Old `android` field auto-migrated to `android_release` on next login

## API Reference

### Core Classes

- **`DeviceRestrictionCoordinator`**: Main orchestrator — `verifyDeviceForSignup()`, `verifyAndBindDevice(userId, {userInfo})`, `initializeDeviceDocument(userId, {userInfo})`
- **`AndroidDeviceIdProvider`**: Returns SSAID + build-mode-aware slot name
- **`WindowsDeviceIdProvider`**: Returns Windows device ID
- **`FirestoreDeviceRepository`**: Firestore storage with dual-slot support

### Models

- **`DeviceBinding`**: A device bound to a user (includes `buildMode`)
- **`DeviceAuthUserInfo`**: User metadata with open-ended `customFields`
- **`BuildMode`**: `debug` / `release` / `profile` enum
- **`BuildModeDetector`**: `BuildModeDetector.current()` — detects current build mode
- **`DeviceMetadata`**: Additional device hardware info
- **`AuthResult`**: Result of authentication operations
- **`ValidationResult`**: Result of device validation

### Exceptions

- **`DeviceAlreadyBoundException`**: Device is registered to another account
- **`DeviceMismatchException`**: User trying to login from wrong device
- **`DeviceIdNotFoundException`**: Cannot retrieve device ID
- **`PlatformNotSupportedException`**: Platform not supported

## Limitations

- **No Device Replacement**: Once bound, devices cannot be changed (by design for security)
- **Platform-Specific**: Only Android and Windows Desktop are supported
- **Requires Firebase**: Tightly coupled with Firebase Auth + Firestore
- **No Web Support**: Web browsers don't have reliable hardware IDs
- **Privacy**: Device IDs and user metadata stored in Firestore — ensure compliance with local privacy laws (GDPR, etc.)

## Example App

See the [example](example/) directory for a complete working app demonstrating:

- Firebase initialization
- Signup with device verification and user info
- Login with device binding
- Error handling for all scenarios

## Contributing

1. Fork the repository
2. Create a feature branch
3. Submit a pull request with clear documentation

## License

MIT License — see [LICENSE](LICENSE) file for details.

## Support

For issues, questions, or feature requests, please visit the [GitHub repository](https://github.com/DevStudio2k25/device_restricted_auth).
