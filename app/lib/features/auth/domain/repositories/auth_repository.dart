import 'dart:io';
import 'package:vibetalk/features/auth/domain/entities/user_entity.dart';

/// Abstract auth repository — the domain layer's contract.
/// The data layer provides the concrete implementation.
abstract class AuthRepository {
  /// Verify OTP and register/log in the user.
  /// [firebaseToken] — Firebase ID token after phone OTP verification.
  /// Returns [UserEntity] and stores tokens internally.
  Future<UserEntity> register(String firebaseToken);

  /// Refresh the access token using stored refresh token.
  Future<void> refreshTokens();

  /// Log out: delete server-side refresh token and clear local storage.
  Future<void> logout();

  /// Return the currently cached user, or null if unauthenticated.
  Future<UserEntity?> getCurrentUser();

  /// Update the user's display name, bio, and optionally avatar.
  Future<UserEntity> updateProfile({
    required String name,
    String? bio,
    String? avatarUrl,
  });

  /// Upload an avatar image file and return the new URL.
  Future<String> uploadAvatar(File imageFile);

  /// Upload Signal Protocol public keys to the server.
  Future<void> uploadKeys({
    required String identityKey,
    required Map<String, dynamic> signedPrekey,
    required List<Map<String, dynamic>> prekeyBundle,
  });
}
