import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Sends an SMS code to the provided phone number.
  /// Uses callbacks to handle the different stages of phone verification.
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(String verificationId, int? resendToken) codeSent,
    required Function(FirebaseAuthException e) verificationFailed,
    required Function(PhoneAuthCredential credential) verificationCompleted,
    required Function(String verificationId) codeAutoRetrievalTimeout,
  }) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: verificationCompleted,
        verificationFailed: verificationFailed,
        codeSent: codeSent,
        codeAutoRetrievalTimeout: codeAutoRetrievalTimeout,
        timeout: const Duration(seconds: 60),
      );
    } catch (e, stackTrace) {
      await Sentry.captureException(e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Verifies the SMS code entered by the user.
  /// Returns the Firebase token (JWT) if successful.
  Future<String?> verifyOTP({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      // Create a PhoneAuthCredential with the code
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      // Sign the user in (or link) with the credential
      UserCredential userCredential = await _auth.signInWithCredential(credential);
      
      // Get the Firebase ID token to send to our Node.js backend
      if (userCredential.user != null) {
        return await userCredential.user!.getIdToken();
      }
      return null;
    } on FirebaseAuthException catch (e, stackTrace) {
      await Sentry.captureException(e, stackTrace: stackTrace);
      throw Exception('Invalid OTP or verification failed: ${e.message}');
    } catch (e, stackTrace) {
      await Sentry.captureException(e, stackTrace: stackTrace);
      throw Exception('An unexpected error occurred during OTP verification.');
    }
  }

  /// Signs the user out of Firebase
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
