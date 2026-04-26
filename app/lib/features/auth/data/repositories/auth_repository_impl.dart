import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:vibetalk/core/storage/local_storage.dart';
import 'package:vibetalk/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:vibetalk/features/auth/domain/entities/user_entity.dart';
import 'package:vibetalk/features/auth/domain/repositories/auth_repository.dart';

/// Concrete implementation of [AuthRepository].
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remote;
  final LocalStorageService _local;

  AuthRepositoryImpl({
    required AuthRemoteDataSource remote,
    required LocalStorageService local,
  })  : _remote = remote,
        _local = local;

  @override
  Future<UserEntity> register(String firebaseToken) async {
    final data = await _remote.register(firebaseToken);

    final user = UserEntity.fromMap(data['user'] as Map<String, dynamic>);
    await _local.saveTokens(
      accessToken: data['access_token'] as String,
      refreshToken: data['refresh_token'] as String,
    );
    await _local.saveUserId(user.id);
    await _local.saveUser(user.toMap());

    return user;
  }

  @override
  Future<void> refreshTokens() async {
    final storedRefresh = _local.getRefreshToken();
    if (storedRefresh == null) {
      throw Exception('No refresh token stored.');
    }

    final data = await _remote.refresh(storedRefresh);
    await _local.saveTokens(
      accessToken: data['access_token'] as String,
      refreshToken: data['refresh_token'] as String,
    );
  }

  @override
  Future<void> logout() async {
    try {
      await _remote.logout();
    } catch (_) {
      // Best-effort server logout; always clear local state.
    }
    await _local.clearAuth();
  }

  @override
  Future<UserEntity?> getCurrentUser() async {
    final userMap = _local.getUser();
    if (userMap == null) return null;
    return UserEntity.fromMap(userMap);
  }

  @override
  Future<UserEntity> updateProfile({
    required String name,
    String? bio,
    String? avatarUrl,
  }) async {
    final data = await _remote.updateProfile(
      name: name,
      bio: bio,
      avatarUrl: avatarUrl,
    );
    final user = UserEntity.fromMap(data['user'] as Map<String, dynamic>);
    await _local.saveUser(user.toMap());
    return user;
  }

  @override
  Future<String> uploadAvatar(File imageFile) async {
    // Compress before upload (max 800px wide, 80% quality)
    final compressed = await FlutterImageCompress.compressAndGetFile(
      imageFile.path,
      '${imageFile.path}_compressed.jpg',
      quality: 80,
      minWidth: 800,
      minHeight: 800,
    );

    final fileToUpload = compressed != null ? File(compressed.path) : imageFile;
    return _remote.uploadAvatar(fileToUpload);
  }

  @override
  Future<void> uploadKeys({
    required String identityKey,
    required Map<String, dynamic> signedPrekey,
    required List<Map<String, dynamic>> prekeyBundle,
  }) async {
    await _remote.uploadKeys(
      identityKey: identityKey,
      signedPrekey: signedPrekey,
      prekeyBundle: prekeyBundle,
    );
  }
}
