import 'dart:io';
import 'package:vibetalk/features/auth/domain/entities/user_entity.dart';
import 'package:vibetalk/features/auth/domain/repositories/auth_repository.dart';

/// Use case: Update the user's profile.
class UpdateProfileUseCase {
  final AuthRepository _repository;
  const UpdateProfileUseCase(this._repository);

  Future<UserEntity> call({
    required String name,
    String? bio,
    String? avatarUrl,
  }) =>
      _repository.updateProfile(name: name, bio: bio, avatarUrl: avatarUrl);
}

/// Use case: Upload avatar image.
class UploadAvatarUseCase {
  final AuthRepository _repository;
  const UploadAvatarUseCase(this._repository);

  Future<String> call(File imageFile) => _repository.uploadAvatar(imageFile);
}

/// Use case: Upload Signal Protocol public keys.
class UploadKeysUseCase {
  final AuthRepository _repository;
  const UploadKeysUseCase(this._repository);

  Future<void> call({
    required String identityKey,
    required Map<String, dynamic> signedPrekey,
    required List<Map<String, dynamic>> prekeyBundle,
  }) =>
      _repository.uploadKeys(
        identityKey: identityKey,
        signedPrekey: signedPrekey,
        prekeyBundle: prekeyBundle,
      );
}
