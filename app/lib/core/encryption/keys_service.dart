import 'package:dio/dio.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:vibetalk/core/network/api_client.dart';
import 'package:vibetalk/core/encryption/key_generator.dart';

class KeysService {
  final ApiClient _apiClient;

  KeysService({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Uploads the public key bundle to the backend.
  Future<void> uploadKeys(KeyBundle bundle) async {
    try {
      final response = await _apiClient.dio.post(
        'users/keys',
        data: bundle.toJson(),
      );
      
      if (response.statusCode != 201 && response.statusCode != 200) {
        throw Exception('Failed to upload keys: ${response.data}');
      }
    } on DioException catch (e, stackTrace) {
      await Sentry.captureException(e, stackTrace: stackTrace);
      throw Exception('Network error during key upload: ${e.message}');
    } catch (e, stackTrace) {
      await Sentry.captureException(e, stackTrace: stackTrace);
      throw Exception('An unexpected error occurred during key upload.');
    }
  }

  /// Fetches a user's public key bundle from the backend.
  Future<Map<String, dynamic>> fetchUserKeys(String userId) async {
    try {
      final response = await _apiClient.dio.get('users/keys/$userId');
      
      if (response.statusCode == 200) {
        return response.data['data'] as Map<String, dynamic>;
      } else {
        throw Exception('Failed to fetch keys: ${response.data}');
      }
    } on DioException catch (e, stackTrace) {
      await Sentry.captureException(e, stackTrace: stackTrace);
      throw Exception('Network error during key fetch: ${e.message}');
    } catch (e, stackTrace) {
      await Sentry.captureException(e, stackTrace: stackTrace);
      throw Exception('An unexpected error occurred during key fetch.');
    }
  }
}
