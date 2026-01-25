# Device Restricted Auth - Example App

This example demonstrates how to use the `device_restricted_auth` package to implement device-based login restrictions in a Flutter app.

## What This Example Shows

- Firebase initialization
- Device restriction coordinator setup
- User signup with device verification
- User login with device binding validation
- Error handling for device restriction scenarios

## Setup Instructions

### 1. Firebase Configuration

Before running this example, you need to set up Firebase:

1. Create a Firebase project at [Firebase Console](https://console.firebase.google.com/)
2. Add Android and/or Windows app to your Firebase project
3. Download configuration files:
   - Android: `google-services.json` → place in `android/app/`
   - Windows: Follow FlutterFire CLI instructions

4. Run FlutterFire CLI to generate `firebase_options.dart`:
   ```bash
   flutterfire configure
   ```

### 2. Firestore Setup

Create these collections in Firestore:

**Collection: `users`**

- Used for user profile data

**Collection: `user_devices`**

- Used for device binding data

### 3. Firestore Security Rules

Add these rules in Firebase Console → Firestore → Rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    match /user_devices/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }

    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

### 4. Run the Example

```bash
cd example
flutter pub get
flutter run
```

## How to Test

### Test Scenario 1: New User Signup

1. Enter email and password
2. Click "Sign Up (Bind Device)"
3. ✅ Device is permanently bound to this account

### Test Scenario 2: Existing User Login (Same Device)

1. Enter same email and password
2. Click "Login (Verify Device)"
3. ✅ Login successful (device matches)

### Test Scenario 3: Login from Different Device

1. Run app on a different device
2. Try to login with same credentials
3. ❌ Error: "Device Not Matched" - access denied

### Test Scenario 4: Device Already Bound

1. Try to signup with a new email on already-bound device
2. ❌ Error: "Device Already Registered"

## Code Structure

```dart
// 1. Initialize coordinator
final coordinator = DeviceRestrictionCoordinator(
  deviceRepository: FirestoreDeviceRepository(),
  deviceIdProvider: Platform.isAndroid
      ? AndroidDeviceIdProvider()
      : WindowsDeviceIdProvider(),
);

// 2. During signup
await coordinator.verifyDeviceForSignup();
// ... create Firebase account ...
await coordinator.initializeDeviceDocument(userId);
await coordinator.verifyAndBindDevice(userId);

// 3. During login
// ... sign in with Firebase ...
await coordinator.verifyAndBindDevice(userId);
```

## Platform Support

- ✅ Android
- ✅ Windows Desktop
- ❌ iOS (not implemented)
- ❌ macOS (not implemented)
- ❌ Web (not supported)

## Notes

- Make sure Firebase is properly configured before running
- Device IDs are hardware-based and persist across app reinstalls
- Once bound, devices cannot be changed (by design)
- Each account can have 1 Android + 1 Desktop device
