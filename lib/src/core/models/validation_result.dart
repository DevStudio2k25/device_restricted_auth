// 🔐 Validation Result Model
// Result of device binding validation

class ValidationResult {
  final bool isValid;
  final String? errorMessage;
  final ValidationResultType type;

  const ValidationResult({
    required this.isValid,
    this.errorMessage,
    required this.type,
  });

  factory ValidationResult.valid() {
    return const ValidationResult(
      isValid: true,
      type: ValidationResultType.valid,
    );
  }

  factory ValidationResult.invalid({
    required String errorMessage,
    required ValidationResultType type,
  }) {
    return ValidationResult(
      isValid: false,
      errorMessage: errorMessage,
      type: type,
    );
  }

  @override
  String toString() {
    return 'ValidationResult(isValid: $isValid, errorMessage: $errorMessage, type: $type)';
  }
}

enum ValidationResultType {
  valid,
  deviceAlreadyBound,
  deviceMismatch,
  firstTimeBinding,
  deviceNotFound,
}
