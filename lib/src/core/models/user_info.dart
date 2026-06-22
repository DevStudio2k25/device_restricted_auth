// 🔐 Device Auth User Info
// Carries user metadata to be stored at the document level in Firestore.
// Enables admin filtering by userName/email and supports arbitrary custom fields.

/// Holds user metadata to be stored alongside device bindings in Firestore.
///
/// Stored at the **document level** (not inside platform slots) so that admins
/// can query and filter users directly from the `user_devices` collection.
///
/// The [customFields] map is fully open-ended — pass any extra data your app
/// needs (e.g. subscription plan, role, referral code).
///
/// Example — basic:
/// ```dart
/// DeviceAuthUserInfo(userName: 'Rahul Sharma', email: 'rahul@example.com')
/// ```
///
/// Example — with custom fields:
/// ```dart
/// DeviceAuthUserInfo(
///   userName: 'Rahul Sharma',
///   email: 'rahul@example.com',
///   customFields: {
///     'subscriptionPlan': 'premium',
///     'role': 'user',
///     'referralCode': 'ABC123',
///   },
/// )
/// ```
class DeviceAuthUserInfo {
  /// Display name of the user (e.g. from Firebase Auth `displayName`).
  final String? userName;

  /// Email address of the user.
  final String? email;

  /// Any extra fields the app wants to store alongside device data.
  ///
  /// Values must be Firestore-compatible types (String, num, bool,
  /// DateTime, List, Map, or null).
  final Map<String, dynamic> customFields;

  const DeviceAuthUserInfo({
    this.userName,
    this.email,
    this.customFields = const {},
  });

  /// Returns a Firestore-ready map of only the non-null top-level fields,
  /// merged with [customFields].
  ///
  /// This is used with [SetOptions(merge: true)] so existing fields are
  /// preserved and only provided fields are overwritten.
  Map<String, dynamic> toFirestoreMap() {
    return {
      if (userName != null) 'userName': userName,
      if (email != null) 'email': email,
      ...customFields,
    };
  }

  @override
  String toString() =>
      'DeviceAuthUserInfo(userName: $userName, email: $email, customFields: $customFields)';
}
