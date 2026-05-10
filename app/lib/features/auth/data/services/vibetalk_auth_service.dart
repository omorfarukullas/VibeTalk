import 'package:dio/dio.dart';
import 'package:vibetalk/core/network/api_client.dart';

class VibeTalkAuthService {
  final ApiClient _apiClient;

  VibeTalkAuthService({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Sends the Firebase token to our backend to login/register the user.
  /// Returns the VibeTalk user data and tokens.
  Future<Map<String, dynamic>> loginWithFirebaseToken(String firebaseToken) async {
    try {
      final response = await _apiClient.post(
        'auth/register',
        data: {'firebaseToken': firebaseToken},
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to login: $e');
    }
  }

  /// Sends a request to refresh the VibeTalk access token.
  Future<Map<String, dynamic>> refreshToken(String refreshToken) async {
    try {
      final response = await _apiClient.post(
        'auth/refresh',
        data: {'refreshToken': refreshToken},
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to refresh token: $e');
    }
  }

  /// Updates the user's profile information.
  Future<Map<String, dynamic>> updateProfile({String? name, String? username, String? bio, String? avatarUrl}) async {
    try {
      final response = await _apiClient.put(
        'users/profile',
        data: {
          if (name != null) 'name': name,
          if (username != null) 'username': username,
          if (bio != null) 'bio': bio,
          if (avatarUrl != null) 'avatar_url': avatarUrl,
        },
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  /// Uploads an avatar image and returns the public URL.
  Future<String> uploadAvatar(String imagePath) async {
    try {
      final formData = FormData.fromMap({
        'avatar': await MultipartFile.fromFile(imagePath),
      });
      final response = await _apiClient.upload(
        'users/avatar',
        formData: formData,
      );
      return response.data['data']['avatar_url'];
    } catch (e) {
      throw Exception('Failed to upload avatar: $e');
    }
  }

  /// Fetches the current user's profile information.
  Future<Map<String, dynamic>> getCurrentUser() async {
    try {
      final response = await _apiClient.get('auth/me');
      // The backend returns the user object directly, not wrapped in data.user
      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to get current user: $e');
    }
  }

  /// Checks if a username is available.
  Future<bool> checkUsernameAvailability(String username) async {
    try {
      final response = await _apiClient.get(
        'users/check-username',
        queryParameters: {'u': username},
      );
      return response.data['data']['available'] as bool;
    } catch (e) {
      return false;
    }
  }
}


