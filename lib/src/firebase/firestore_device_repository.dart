// 🔐 Firestore Device Repository
// Firestore implementation of device repository

import 'package:cloud_firestore/cloud_firestore.dart';
import 'device_repository.dart';
import '../core/models/device_binding.dart';

/// Firestore implementation of [DeviceRepository].
///
/// Stores device bindings in the `user_devices` collection in Firestore.
/// Each document is keyed by user ID and contains platform-specific device data.
///
/// Example:
/// ```dart
/// final repository = FirestoreDeviceRepository();
/// final binding = await repository.getBinding(userId, 'android');
/// ```
class FirestoreDeviceRepository implements DeviceRepository {
  final FirebaseFirestore _firestore;

  FirestoreDeviceRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<DeviceBinding?> getBinding(String userId, String platform) async {
    try {
      final doc = await _firestore.collection('user_devices').doc(userId).get();

      if (!doc.exists || doc.data() == null) {
        return null;
      }

      final data = doc.data()!;
      final platformData = data[platform] as Map<String, dynamic>?;

      if (platformData == null) {
        return null;
      }

      final deviceId = platformData['deviceId'] as String?;
      if (deviceId == null || deviceId.isEmpty) {
        return null;
      }

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
      print('❌ Error getting device binding: $e');
      return null;
    }
  }

  @override
  Future<void> createBinding(String userId, DeviceBinding binding) async {
    try {
      await _firestore.collection('user_devices').doc(userId).set({
        binding.platform: {
          'deviceId': binding.deviceId,
          'boundAt': FieldValue.serverTimestamp(),
          'lastActive': FieldValue.serverTimestamp(),
          'isPermanent': binding.isPermanent,
        }
      }, SetOptions(merge: true));

      print('✅ Device Permanently Bound!');
      print('⚠️  This device is now permanently linked to your account.');
      print('⚠️  You cannot login from another ${binding.platform} device.');
    } catch (e) {
      print('❌ Error creating device binding: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateActivity(String userId, String platform) async {
    try {
      await _firestore.collection('user_devices').doc(userId).update({
        '$platform.lastActive': FieldValue.serverTimestamp(),
      });
      print('✅ Device activity updated');
    } catch (e) {
      print('❌ Error updating device activity: $e');
      rethrow;
    }
  }

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
      print('❌ Error finding users by device: $e');
      return [];
    }
  }

  @override
  Future<void> initializeDeviceDocument(String userId) async {
    try {
      await _firestore.collection('user_devices').doc(userId).set({
        'android': {
          'deviceId': null,
          'boundAt': null,
          'lastActive': null,
          'lastReplacedAt': null,
        },
        'desktop': {
          'deviceId': null,
          'boundAt': null,
          'lastActive': null,
          'lastReplacedAt': null,
        },
      });
      print('✅ Device document initialized');
    } catch (e) {
      print('❌ Error initializing device document: $e');
      rethrow;
    }
  }
}
