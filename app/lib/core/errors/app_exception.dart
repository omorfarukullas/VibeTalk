/// Base exception class for all VibeTalk application errors.
class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  const AppException(
    this.message, {
    this.code,
    this.originalError,
  });

  @override
  String toString() => 'AppException($code): $message';
}

/// Thrown when a network-level error occurs (no connectivity, timeout, DNS failure).
class NetworkException extends AppException {
  const NetworkException(super.message, {super.code = 'NETWORK_ERROR'});
}

/// Thrown when the API returns an error response (4xx, 5xx).
class ApiException extends AppException {
  final int statusCode;

  const ApiException({
    required this.statusCode,
    required String message,
  }) : super(message, code: 'API_ERROR_$statusCode');

  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;
  bool get isNotFound => statusCode == 404;
  bool get isServerError => statusCode >= 500;
}

/// Thrown when authentication fails (invalid token, expired session).
class AuthException extends AppException {
  const AuthException(super.message, {super.code = 'AUTH_ERROR'});
}

/// Thrown when local storage operations fail.
class StorageException extends AppException {
  const StorageException(super.message, {super.code = 'STORAGE_ERROR'});
}

/// Thrown when encryption or decryption fails.
class EncryptionException extends AppException {
  const EncryptionException(super.message, {super.code = 'ENCRYPTION_ERROR'});
}

/// Thrown when a WebRTC call operation fails.
class CallException extends AppException {
  const CallException(super.message, {super.code = 'CALL_ERROR'});
}

/// Thrown when file upload/download fails.
class MediaException extends AppException {
  const MediaException(super.message, {super.code = 'MEDIA_ERROR'});
}

/// Thrown when Socket.IO real-time operations fail.
class SocketException extends AppException {
  const SocketException(super.message, {super.code = 'SOCKET_ERROR'});
}

/// Thrown when required permissions are not granted.
class PermissionException extends AppException {
  const PermissionException(super.message, {super.code = 'PERMISSION_ERROR'});
}

/// Thrown when input validation fails.
class ValidationException extends AppException {
  final Map<String, String>? fieldErrors;

  const ValidationException(
    super.message, {
    this.fieldErrors,
    super.code = 'VALIDATION_ERROR',
  });
}
