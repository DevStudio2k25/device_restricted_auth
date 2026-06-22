// 🔐 Firestore Device Repository
// Firestore implementation of device repository

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'device_repository.dart';
import '../core/models/device_binding.dart';
import '../core/models/user_info.dart';

/// Firestore implementation of [DeviceRepository].
///
/// ## Collection: `user_devices`
/// Each document is keyed by Firebase Auth `userId` and has:
///
/// - **Top-level user info fields** (for admin queries):
///   `userName`, `email`, `createdAt`, `lastSeenAt`, plus any `customFields`.
///
/// - **Platform slots** (maps):
///   - `android_debug`   — SSAID from debug build
///   - `android_release` — SSAID from release build
///   - `desktop`         — Windows device ID
///
/// ### Legacy migration
/// If an existing document has the old `android` field (pre-dual-slot), it is
/// automatically migrated to `android_release` on the user's next login.
///
/// Example:
/// ```dart
/// final repo = FirestoreDeviceRepository();
/// final binding = await repo.getBinding(userId, 'android_debug');
/// ```
class FirestoreDeviceRepository implements DeviceRepository {
  final FirebaseFirestore _firestore;

  FirestoreDeviceRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // ---------------------------------------------------------------------------
  // Internal helpers
  // ---------------------------------------------------------------------------

  DocumentReference _userDoc(String userId) =>
      _firestore.collection('user_devices').doc(userId);

  // ---------------------------------------------------------------------------
  // getBinding
  // ---------------------------------------------------------------------------

  @override
  Future<DeviceBinding?> getBinding(String userId, String platform) async {
    try {
      final doc = await _userDoc(userId).get();

      if (!doc.exists || doc.data() == null) return null;

      // Cast to Map<String, dynamic> for safe key access
      final data = Map<String, dynamic>.from(doc.data()! as Map<dynamic, dynamic>);

      // ── Legacy migration: old "android" key → android_release ──────────────
      if (platform.startsWith('android') && data.containsKey('android')) {
        final legacyRaw = data['android'];
        final legacyData = legacyRaw is Map
            ? Map<String, dynamic>.from(legacyRaw)
            : null;
        final legacyId = legacyData?['deviceId'] as String?;
        if (legacyId != null && legacyId.isNotEmpty) {
          // Check whether the target slot is already set
          final targetRaw = data[platform];
          final targetSlotData = targetRaw is Map
              ? Map<String, dynamic>.from(targetRaw)
              : null;
          final targetId = targetSlotData?['deviceId'] as String?;
          if (targetId == null || targetId.isEmpty) {
            // Migrate: copy legacy ID to the current slot
            debugPrint('🔄 Migrating legacy "android" slot → "$platform"');
            await _userDoc(userId).set({
              platform: {
                'deviceId': legacyId,
                'buildMode': platform == 'android_release' ? 'release' : 'debug',
                'boundAt': legacyData!['boundAt'],
                'lastActive': FieldValue.serverTimestamp(),
                'isPermanent': legacyData['isPermanent'] ?? true,
                'migratedFromLegacy': true,
              },
            }, SetOptions(merge: true));
            debugPrint('✅ Migration complete — "$platform" slot populated');
          }
        }
      }
      // ── Re-fetch after potential migration ─────────────────────────────────

      final freshDoc = await _userDoc(userId).get();
      final freshData = freshDoc.data() != null
          ? Map<String, dynamic>.from(freshDoc.data()! as Map<dynamic, dynamic>)
          : <String, dynamic>{};
      final platformRaw = freshData[platform];
      final platformData = platformRaw is Map
          ? Map<String, dynamic>.from(platformRaw)
          : null;

      if (platformData == null) return null;

      final deviceId = platformData['deviceId'] as String?;
      if (deviceId == null || deviceId.isEmpty) return null;

      return DeviceBinding(
        deviceId: deviceId,
        platform: platform,
        boundAt:
            (platformData['boundAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        lastActive: (platformData['lastActive'] as Timestamp?)?.toDate() ??
            DateTime.now(),
        isPermanent: platformData['isPermanent'] as bool? ?? true,
      );
    } catch (e) {
      debugPrint('❌ Error getting device binding: $e');
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // createBinding
  // ---------------------------------------------------------------------------

  @override
  Future<void> createBinding(
    String userId,
    DeviceBinding binding, {
    DeviceAuthUserInfo? userInfo,
  }) async {
    try {
      final Map<String, dynamic> payload = {
        binding.platform: {
          'deviceId': binding.deviceId,
          'buildMode': binding.buildMode?.name,
          'boundAt': FieldValue.serverTimestamp(),
          'lastActive': FieldValue.serverTimestamp(),
          'isPermanent': binding.isPermanent,
        },
        'lastSeenAt': FieldValue.serverTimestamp(),
      };

      // Merge user info at document level
      if (userInfo != null) {
        payload.addAll(userInfo.toFirestoreMap());
      }

      await _userDoc(userId).set(payload, SetOptions(merge: true));

      debugPrint('✅ Device Permanently Bound!');
      debugPrint('   Slot: ${binding.platform}');
      debugPrint('⚠️  This device is now permanently linked to your account.');
    } catch (e) {
      debugPrint('❌ Error creating device binding: $e');
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // updateActivity
  // ---------------------------------------------------------------------------

  @override
  Future<void> updateActivity(
    String userId,
    String platform, {
    DeviceAuthUserInfo? userInfo,
  }) async {
    try {
      final Map<String, dynamic> payload = {
        '$platform.lastActive': FieldValue.serverTimestamp(),
        'lastSeenAt': FieldValue.serverTimestamp(),
      };

      // Refresh user info on every login so it stays up to date
      if (userInfo != null) {
        payload.addAll(userInfo.toFirestoreMap());
      }

      await _userDoc(userId).update(payload);
      debugPrint('✅ Device activity updated (slot: $platform)');
    } catch (e) {
      debugPrint('❌ Error updating device activity: $e');
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // findUsersByDevice
  // ---------------------------------------------------------------------------

  @override
  Future<List<String>> findUsersByDevice(
      String deviceId, String platform) async {
    try {
      final querySnapshot = await _firestore
          .collection('user_devices')
          .where('$platform.deviceId', isEqualTo: deviceId)
          .limit(1)
          .get();

      return querySnapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      debugPrint('❌ Error finding users by device: $e');
      return [];
    }
  }

  // ---------------------------------------------------------------------------
  // findUsersByDeviceAnySlot
  // ---------------------------------------------------------------------------

  /// Checks both `android_debug` and `android_release` slots (plus legacy
  /// `android`) for the given [deviceId]. Used during signup to ensure the
  /// same physical device isn't registered to multiple accounts.
  @override
  Future<List<String>> findUsersByDeviceAnySlot(
    String deviceId,
    String basePlatform,
  ) async {
    try {
      final slots = <String>[];

      if (basePlatform == 'android') {
        slots.addAll(['android_debug', 'android_release', 'android']);
      } else {
        slots.add(basePlatform);
      }

      for (final slot in slots) {
        final querySnapshot = await _firestore
            .collection('user_devices')
            .where('$slot.deviceId', isEqualTo: deviceId)
            .limit(1)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          return querySnapshot.docs.map((doc) => doc.id).toList();
        }
      }

      return [];
    } catch (e) {
      debugPrint('❌ Error finding users by device (any slot): $e');
      return [];
    }
  }

  // ---------------------------------------------------------------------------
  // initializeDeviceDocument
  // ---------------------------------------------------------------------------

  @override
  Future<void> initializeDeviceDocument(
    String userId, {
    DeviceAuthUserInfo? userInfo,
  }) async {
    try {
      final Map<String, dynamic> payload = {
        'android_debug': {
          'deviceId': null,
          'buildMode': 'debug',
          'boundAt': null,
          'lastActive': null,
        },
        'android_release': {
          'deviceId': null,
          'buildMode': 'release',
          'boundAt': null,
          'lastActive': null,
        },
        'desktop': {
          'deviceId': null,
          'boundAt': null,
          'lastActive': null,
        },
        'createdAt': FieldValue.serverTimestamp(),
        'lastSeenAt': FieldValue.serverTimestamp(),
      };

      if (userInfo != null) {
        payload.addAll(userInfo.toFirestoreMap());
      }

      await _userDoc(userId).set(payload);
      debugPrint('✅ Device document initialized with dual Android slots');
    } catch (e) {
      debugPrint('❌ Error initializing device document: $e');
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // updateUserInfo
  // ---------------------------------------------------------------------------

  @override
  Future<void> updateUserInfo(
    String userId,
    DeviceAuthUserInfo userInfo,
  ) async {
    try {
      await _userDoc(userId).set(
        userInfo.toFirestoreMap(),
        SetOptions(merge: true),
      );
      debugPrint('✅ User info updated');
    } catch (e) {
      debugPrint('❌ Error updating user info: $e');
      rethrow;
    }
  }
}
