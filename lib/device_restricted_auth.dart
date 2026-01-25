// 🔐 Device Restricted Auth - Public API
// This is the main entry point for the package

library device_restricted_auth;

// Core Models
export 'src/core/models/device_binding.dart';
export 'src/core/models/device_metadata.dart';
export 'src/core/models/auth_result.dart';
export 'src/core/models/validation_result.dart';

// Core Exceptions
export 'src/core/exceptions/device_restriction_exceptions.dart';

// Core Policies
export 'src/core/policies/device_binding_policy.dart';

// Core Validators
export 'src/core/validators/device_binding_validator.dart';

// Platform Adapters (Android + Windows only)
export 'src/platform/device_id_provider.dart';
export 'src/platform/android_device_id_provider.dart';
export 'src/platform/windows_device_id_provider.dart';

// Firebase Adapter
export 'src/firebase/device_repository.dart';
export 'src/firebase/firestore_device_repository.dart';

// Coordinator
export 'src/coordinator/device_restriction_coordinator.dart';
