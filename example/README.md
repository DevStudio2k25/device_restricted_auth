# Device Restricted Auth - Example App

This example demonstrates how to use the `device_restricted_auth` package to implement device-based login restrictions in a Flutter app.

## ⚠️ Firebase Setup (Required)

**This example app does NOT include Firebase configuration files.**

You must set up your own Firebase project to run this example.

### Step-by-Step Firebase Setup

1. **Create a Firebase Project**
   - Go to [Firebase Console](https://console.firebase.google.com/)
   - Click "Add project" and follow the setup wizard

2. **Enable Email/Password Authentication**
   - In Firebase Console, go to **Authentication** → **Sign-in method**
   - Enable **Email/Password** provider
   - Click "Save"

3. **Create Firestore Database**
   - Go to **Firestore Database** → **Create database**
   - Start in **test mode** (for development)
   - Choose a location and click "Enable"

4. **Add Security Rules**
   - In Firestore, go to **Rules** tab
   - Replace with these rules:

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

   - Click "Publish"

5. **Add Android App to Firebase**
   - In Firebase Console, click the Android icon
   - Package name: `com.example.example` (or your custom package)
   - Download `google-services.json`
   - Place it in: `example/android/app/google-services.json`

6. **Add Windows App (Optional)**
   - Install FlutterFire CLI:
     ```bash
     dart pub global activate flutterfire_cli
     ```
   - Run in the example directory:
     ```bash
     cd example
     flutterfire configure
     ```
   - This will generate `lib/firebase_options.dart`

7. **Run the Example**
   ```bash
   cd example
   flutter pub get
   flutter run
   ```

## What This Example Shows

- ✅ Firebase initialization
- ✅ Device restriction coordinator setup
- ✅ User signup with device verification
- ✅ User login with device binding validation
- ✅ Error handling for device restriction scenarios
- ✅ Platform-specific device ID provider selection

## How to Test

### Test Scenario 1: New User Signup

1. Enter email: `test@example.com`
2. Enter password: `password123`
3. Click **"Sign Up (Bind Device)"**
4. ✅ Result: Device is permanently bound to this account

### Test Scenario 2: Existing User Login (Same Device)

1. Enter same email and password
2. Click **"Login (Verify Device)"**
3. ✅ Result: Login successful (device matches)

### Test Scenario 3: Login from Different Device

1. Run app on a different Android device or Windows PC
2. Try to login with same credentials
3. ❌ Result: Error - "Device Not Matched" (access denied)

### Test Scenario 4: Device Already Bound

1. Try to signup with a new email on already-bound device
2. ❌ Result: Error - "Device Already Registered"

## Code Structure

The example demonstrates the complete integration flow:

```dart
// 1. Initialize Firebase (you need to add firebase_options.dart)
await Firebase.initializeApp();

// 2. Create coordinator with platform-specific provider
final coordinator = DeviceRestrictionCoordinator(
  deviceRepository: FirestoreDeviceRepository(),
  deviceIdProvider: Platform.isAndroid
      ? AndroidDeviceIdProvider()
      : WindowsDeviceIdProvider(),
);

// 3. During signup
await coordinator.verifyDeviceForSignup();
final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(...);
await coordinator.initializeDeviceDocument(credential.user!.uid);
await coordinator.verifyAndBindDevice(credential.user!.uid);

// 4. During login
final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(...);
await coordinator.verifyAndBindDevice(credential.user!.uid);
```

## Platform Support

- ✅ Android
- ✅ Windows Desktop
- ❌ iOS (not implemented in package)
- ❌ macOS (not implemented in package)
- ❌ Web (not supported - no hardware ID)

## Troubleshooting

### "MissingPluginException"

- Make sure you've run `flutter pub get`
- Try `flutter clean` and rebuild

### "Firebase not initialized"

- Ensure `google-services.json` is in `android/app/`
- For Windows, run `flutterfire configure`

### "Permission denied" in Firestore

- Check that Firestore security rules are set correctly
- Ensure user is authenticated before accessing Firestore

### "Device ID not found"

- Android: Check that `device_info_plus` has proper permissions
- Windows: Ensure app has access to device information

## Important Notes

- **Firebase configuration is NOT included** - you must set it up yourself
- Device IDs are hardware-based and persist across app reinstalls
- Once bound, devices cannot be changed (by design)
- Each account can have 1 Android + 1 Desktop device
- This is a demo app - add proper error handling for production use

## Need Help?

- [Firebase Setup Guide](https://firebase.google.com/docs/flutter/setup)
- [FlutterFire Documentation](https://firebase.flutter.dev/)
- [Package Documentation](https://pub.dev/packages/device_restricted_auth)
