import 'package:dio/dio.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:vibetalk/core/network/api_client.dart';

class VibeTalkAuthService {
  final ApiClient _apiClient;

  VibeTalkAuthService({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Sends the Firebase token to our backend to login/register the user.
  /// Returns the VibeTalk user data and tokens.
  Future<Map<String, dynamic>> loginWithFirebaseToken(String firebaseToken) async {
    try {
      final response = await _apiClient.dio.post(
        'auth/register',
        data: {'firebaseToken': firebaseToken},
      );
      
      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception('Failed to login: ${response.data}');
      }
    } on DioException catch (e, stackTrace) {
      await Sentry.captureException(e, stackTrace: stackTrace);
      throw Exception('Network error during login: ${e.message}');
    } catch (e, stackTrace) {
      await Sentry.captureException(e, stackTrace: stackTrace);
      throw Exception('An unexpected error occurred during login.');
    }
  }

  /// Sends a request to refresh the VibeTalk access token.
  Future<Map<String, dynamic>> refreshToken(String refreshToken) async {
    try {
      final response = await _apiClient.dio.post(
        'auth/refresh',
        data: {'refreshToken': refreshToken},
      );
      
      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception('Failed to refresh token: ${response.data}');
      }
    } catch (e, stackTrace) {
      await Sentry.captureException(e, stackTrace: stackTrace);
      rethrow;
    }
  }
}
