import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  /// Signs in the user with Google.
  /// Returns the Firebase token (JWT) if successful.
  Future<String?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return null; // The user canceled the sign-in
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      if (userCredential.user != null) {
        return await userCredential.user!.getIdToken();
      }
      return null;
    } on FirebaseAuthException catch (e, stackTrace) {
      await Sentry.captureException(e, stackTrace: stackTrace);
      throw Exception('Google Sign-In failed: ${e.message}');
    } catch (e, stackTrace) {
      await Sentry.captureException(e, stackTrace: stackTrace);
      throw Exception('An unexpected error occurred during Google Sign-In.');
    }
  }

  /// Signs in the user with Email and Password.
  /// Returns the Firebase token (JWT) if successful.
  Future<String?> signInWithEmailPassword({required String email, required String password}) async {
    try {
      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (userCredential.user != null) {
        return await userCredential.user!.getIdToken();
      }
      return null;
    } on FirebaseAuthException catch (e, stackTrace) {
      await Sentry.captureException(e, stackTrace: stackTrace);
      throw Exception('Email Sign-In failed: ${e.message}');
    } catch (e, stackTrace) {
      await Sentry.captureException(e, stackTrace: stackTrace);
      throw Exception('An unexpected error occurred during Email Sign-In.');
    }
  }

  /// Registers a new user with Email and Password.
  /// Returns the Firebase token (JWT) if successful.
  Future<String?> signUpWithEmailPassword({required String email, required String password}) async {
    try {
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (userCredential.user != null) {
        return await userCredential.user!.getIdToken();
      }
      return null;
    } on FirebaseAuthException catch (e, stackTrace) {
      await Sentry.captureException(e, stackTrace: stackTrace);
      throw Exception('Email Sign-Up failed: ${e.message}');
    } catch (e, stackTrace) {
      await Sentry.captureException(e, stackTrace: stackTrace);
      throw Exception('An unexpected error occurred during Email Sign-Up.');
    }
  }

  /// Signs the user out of Firebase and Google
  Future<void> signOut() async {
    await Future.wait([
      _auth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }
}
