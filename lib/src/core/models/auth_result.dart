// 🔐 Auth Result Model
// Result of authentication operations

class AuthResult {
  final bool success;
  final String? userId;
  final String? message;
  final AuthResultType type;

  const AuthResult({
    required this.success,
    this.userId,
    this.message,
    required this.type,
  });

  factory AuthResult.success({required String userId}) {
    return AuthResult(
      success: true,
      userId: userId,
      type: AuthResultType.success,
    );
  }

  factory AuthResult.failure(
      {required String message, required AuthResultType type}) {
    return AuthResult(
      success: false,
      message: message,
      type: type,
    );
  }

  @override
  String toString() {
    return 'AuthResult(success: $success, userId: $userId, message: $message, type: $type)';
  }
}

enum AuthResultType {
  success,
  deviceAlreadyBound,
  deviceMismatch,
  invalidCredentials,
  networkError,
  unknownError,
}
