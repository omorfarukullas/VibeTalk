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

  /// Starts the phone verification process via Firebase
  Future<void> sendOTP({
    required String phoneNumber,
    required Function(String verificationId, int? resendToken) codeSent,
    required Function(FirebaseAuthException e) verificationFailed,
    required Function(PhoneAuthCredential credential) verificationCompleted,
    required Function(String verificationId) codeAutoRetrievalTimeout,
  }) async {
    await _firebaseService.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      codeSent: codeSent,
      verificationFailed: verificationFailed,
      verificationCompleted: verificationCompleted,
      codeAutoRetrievalTimeout: codeAutoRetrievalTimeout,
    );
  }

  /// Verifies the OTP, gets the Firebase token, and logs into VibeTalk backend
  Future<void> verifyOTPAndLogin({
    required String verificationId,
    required String smsCode,
  }) async {
    // 1. Verify OTP with Firebase
    final firebaseToken = await _firebaseService.verifyOTP(
      verificationId: verificationId,
      smsCode: smsCode,
    );

    if (firebaseToken == null) {
      throw Exception('Failed to retrieve Firebase ID token.');
    }

    // 2. Exchange Firebase token for VibeTalk JWT
    final response = await _vibeTalkService.loginWithFirebaseToken(firebaseToken);
    
    // 3. Save VibeTalk tokens securely
    final tokens = response['tokens'];
    if (tokens != null) {
      await _secureStorage.write(key: 'access_token', value: tokens['accessToken']);
      await _secureStorage.write(key: 'refresh_token', value: tokens['refreshToken']);
    }

    // TODO: Also save user data locally (id, username, etc.) if needed here
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
