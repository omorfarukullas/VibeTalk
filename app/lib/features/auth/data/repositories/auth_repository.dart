import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:vibetalk/config/service_locator.dart';
import 'package:vibetalk/core/storage/local_storage.dart';
import '../services/firebase_auth_service.dart';
import '../services/vibetalk_auth_service.dart';


class AuthRepository {
  final FirebaseAuthService _firebaseService;
  final VibeTalkAuthService _vibeTalkService;
  final FlutterSecureStorage _secureStorage;

  AuthRepository({
    required FirebaseAuthService firebaseService,
    required VibeTalkAuthService vibeTalkService,
    required FlutterSecureStorage secureStorage,
  }) : _firebaseService = firebaseService,
       _vibeTalkService = vibeTalkService,
       _secureStorage = secureStorage;

  Future<bool> loginWithGoogle() async {
    final firebaseToken = await _firebaseService.signInWithGoogle();
    if (firebaseToken == null) {
      throw Exception('Google Sign-In canceled or failed.');
    }
    return await _exchangeTokenAndSave(firebaseToken);
  }

  Future<bool> loginWithEmail(String email, String password) async {
    final firebaseToken = await _firebaseService.signInWithEmailPassword(
      email: email,
      password: password,
    );
    if (firebaseToken == null) {
      throw Exception('Email login failed.');
    }
    return await _exchangeTokenAndSave(firebaseToken);
  }

  Future<bool> registerWithEmail(String email, String password) async {
    final firebaseToken = await _firebaseService.signUpWithEmailPassword(
      email: email,
      password: password,
    );
    if (firebaseToken == null) {
      throw Exception('Email registration failed.');
    }
    return await _exchangeTokenAndSave(firebaseToken);
  }

  Future<bool> _exchangeTokenAndSave(String firebaseToken) async {
    final response = await _vibeTalkService.loginWithFirebaseToken(firebaseToken);

    final tokens = response['tokens'];
    if (tokens != null) {
      final accessToken = tokens['accessToken'] as String?;
      final refreshToken = tokens['refreshToken'] as String?;

      if (accessToken != null) {
        // Save to FlutterSecureStorage (long-term secure)
        await _secureStorage.write(key: 'access_token', value: accessToken);
        // Save to Hive (synchronous reads for ApiClient interceptor)
        await sl<LocalStorageService>().saveAccessToken(accessToken);
      }
      if (refreshToken != null) {
        await _secureStorage.write(key: 'refresh_token', value: refreshToken);
      }
    }

    final user = response['user'];
    final isProfileComplete = user != null && user['isProfileComplete'] == true;

    if (user?['id'] != null) {
      await sl<LocalStorageService>().saveUserId(user['id'].toString());
    }

    await _secureStorage.write(
      key: 'is_profile_complete',
      value: isProfileComplete.toString(),
    );

    return isProfileComplete;
  }


  /// Logs the user out locally and from Firebase
  Future<void> logout() async {
    await _firebaseService.signOut();
    await _secureStorage.delete(key: 'access_token');
    await _secureStorage.delete(key: 'refresh_token');
    await sl<LocalStorageService>().clearAll();
  }

  /// Checks if the user is currently logged in by checking the secure storage
  Future<bool> isLoggedIn() async {
    final token = await _secureStorage.read(key: 'access_token');
    return token != null;
  }

  /// Checks if the user's profile is complete
  Future<bool> isProfileComplete() async {
    final status = await _secureStorage.read(key: 'is_profile_complete');
    return status == 'true';
  }

  /// Updates the user's profile and saves the status to secure storage
  Future<void> updateProfile({required String name, String? bio, String? imagePath}) async {
    String? avatarUrl;
    if (imagePath != null) {
      try {
        avatarUrl = await _vibeTalkService.uploadAvatar(imagePath);
      } catch (e) {
        // Avatar upload failed (e.g. R2 not configured) — continue without avatar
        print('Avatar upload skipped: $e');
      }
    }

    final response = await _vibeTalkService.updateProfile(
      name: name,
      bio: bio,
      avatarUrl: avatarUrl,
    );

    final user = response['data']['user'];
    if (user != null) {
      await _secureStorage.write(
        key: 'is_profile_complete',
        value: 'true',
      );
    }
  }

}

