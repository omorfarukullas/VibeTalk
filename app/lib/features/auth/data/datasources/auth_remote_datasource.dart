import 'dart:io';
import 'package:dio/dio.dart';
import 'package:vibetalk/core/errors/app_exception.dart';

/// Remote datasource for auth — makes HTTP calls to the VibeTalk backend.
class AuthRemoteDataSource {
  final Dio _dio;

  AuthRemoteDataSource(this._dio);

  /// POST /api/auth/register
  /// [firebaseToken] — raw Firebase ID token from phone OTP.
  Future<Map<String, dynamic>> register(String firebaseToken) async {
    final response = await _dio.post(
      '/auth/register',
      options: Options(
        headers: {'Authorization': 'Bearer $firebaseToken'},
      ),
    );
    return _extractData(response);
  }

  /// POST /api/auth/refresh
  Future<Map<String, dynamic>> refresh(String refreshToken) async {
    final response = await _dio.post(
      '/auth/refresh',
      data: {'refresh_token': refreshToken},
    );
    return _extractData(response);
  }

  /// POST /api/auth/logout
  Future<void> logout() async {
    await _dio.post('/auth/logout');
  }

  /// GET /api/auth/me
  Future<Map<String, dynamic>> getMe() async {
    final response = await _dio.get('/auth/me');
    return _extractData(response);
  }

  /// PUT /api/users/profile
  Future<Map<String, dynamic>> updateProfile({
    required String name,
    String? bio,
    String? avatarUrl,
  }) async {
    final body = <String, dynamic>{'name': name};
    if (bio != null) body['bio'] = bio;
    if (avatarUrl != null) body['avatar_url'] = avatarUrl;

    final response = await _dio.put('/users/profile', data: body);
    return _extractData(response);
  }

  /// POST /api/users/avatar (multipart)
  Future<String> uploadAvatar(File imageFile) async {
    final fileName = imageFile.path.split('/').last;
    final formData = FormData.fromMap({
      'avatar': await MultipartFile.fromFile(
        imageFile.path,
        filename: fileName,
      ),
    });

    final response = await _dio.post(
      '/users/avatar',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );

    final data = _extractData(response);
    return data['avatar_url'] as String;
  }

  /// POST /api/users/keys
  Future<void> uploadKeys({
    required String identityKey,
    required Map<String, dynamic> signedPrekey,
    required List<Map<String, dynamic>> prekeyBundle,
  }) async {
    await _dio.post('/users/keys', data: {
      'identity_key': identityKey,
      'signed_prekey': signedPrekey,
      'prekey_bundle': prekeyBundle,
    });
  }

  // ── Helpers ───────────────────────────────────────────────────────────

  Map<String, dynamic> _extractData(Response response) {
    final body = response.data as Map<String, dynamic>?;
    if (body == null || body['success'] != true) {
      throw AppException(
        body?['error']?['message'] as String? ?? 'Unexpected server response.',
        code: body?['error']?['code'] as String?,
      );
    }
    return body['data'] as Map<String, dynamic>;
  }
}
