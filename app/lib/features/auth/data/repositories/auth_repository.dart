import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
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
  })  : _firebaseService = firebaseService,
        _vibeTalkService = vibeTalkService,
        _secureStorage = secureStorage;

  Future<void> loginWithGoogle() async {
    final firebaseToken = await _firebaseService.signInWithGoogle();
    if (firebaseToken == null) {
      throw Exception('Google Sign-In canceled or failed.');
    }
    await _exchangeTokenAndSave(firebaseToken);
  }

  Future<void> loginWithEmail(String email, String password) async {
    final firebaseToken = await _firebaseService.signInWithEmailPassword(
      email: email,
      password: password,
    );
    if (firebaseToken == null) {
      throw Exception('Email login failed.');
    }
    await _exchangeTokenAndSave(firebaseToken);
  }

  Future<void> registerWithEmail(String email, String password) async {
    final firebaseToken = await _firebaseService.signUpWithEmailPassword(
      email: email,
      password: password,
    );
    if (firebaseToken == null) {
      throw Exception('Email registration failed.');
    }
    await _exchangeTokenAndSave(firebaseToken);
  }

  Future<void> _exchangeTokenAndSave(String firebaseToken) async {
    // Exchange Firebase token for VibeTalk JWT
    final response = await _vibeTalkService.loginWithFirebaseToken(firebaseToken);
    
    // Save VibeTalk tokens securely
    final tokens = response['tokens'];
    if (tokens != null) {
      await _secureStorage.write(key: 'access_token', value: tokens['accessToken']);
      await _secureStorage.write(key: 'refresh_token', value: tokens['refreshToken']);
    }
  }

  /// Logs the user out locally and from Firebase
  Future<void> logout() async {
    await _firebaseService.signOut();
    await _secureStorage.delete(key: 'access_token');
    await _secureStorage.delete(key: 'refresh_token');
  }

  /// Checks if the user is currently logged in by checking the secure storage
  Future<bool> isLoggedIn() async {
    final token = await _secureStorage.read(key: 'access_token');
    return token != null;
  }
}
