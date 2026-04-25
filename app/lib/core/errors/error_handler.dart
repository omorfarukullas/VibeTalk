import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:vibetalk/core/errors/app_exception.dart';

/// Centralised error handler that logs errors locally and reports
/// critical errors to Sentry for production monitoring.
class ErrorHandler {
  ErrorHandler._();

  /// Handles an error with optional stack trace and context.
  /// Non-critical errors are logged locally; critical errors go to Sentry.
  static Future<void> handleError(
    dynamic error, {
    StackTrace? stackTrace,
    String? context,
    bool fatal = false,
  }) async {
    // Always log locally
    _logError(error, stackTrace: stackTrace, context: context);

    // Report to Sentry in production
    if (!kDebugMode) {
      await Sentry.captureException(
        error,
        stackTrace: stackTrace,
        withScope: (scope) {
          if (context != null) {
            scope.setContexts('error_context', {'description': context});
          }
          scope.level = fatal ? SentryLevel.fatal : SentryLevel.error;
        },
      );
    }
  }

  /// Returns a user-friendly error message for display in the UI.
  static String getUserMessage(dynamic error) {
    if (error is NetworkException) {
      return error.message;
    }
    if (error is ApiException) {
      if (error.isUnauthorized) {
        return 'Your session has expired. Please sign in again.';
      }
      if (error.isServerError) {
        return 'Something went wrong on our end. Please try again later.';
      }
      return error.message;
    }
    if (error is AuthException) {
      return error.message;
    }
    if (error is PermissionException) {
      return error.message;
    }
    if (error is ValidationException) {
      return error.message;
    }
    if (error is EncryptionException) {
      return 'Unable to process encrypted data. Please try again.';
    }
    if (error is CallException) {
      return error.message;
    }
    if (error is MediaException) {
      return error.message;
    }
    if (error is AppException) {
      return error.message;
    }
    return 'An unexpected error occurred. Please try again.';
  }

  /// Logs the error to the debug console with formatting.
  static void _logError(
    dynamic error, {
    StackTrace? stackTrace,
    String? context,
  }) {
    debugPrint('══════════════════════════════════════════════════════════');
    debugPrint('ERROR${context != null ? ' [$context]' : ''}');
    debugPrint('Type: ${error.runtimeType}');
    debugPrint('Message: $error');
    if (stackTrace != null) {
      debugPrint('Stack trace:\n$stackTrace');
    }
    debugPrint('══════════════════════════════════════════════════════════');
  }
}
