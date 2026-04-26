import 'dart:math';
import 'dart:typed_data';
import 'dart:convert';
import 'package:vibetalk/core/storage/secure_storage.dart';

/// Signal Protocol key generation — Sprint 1 preparation.
///
/// Generates cryptographically random key pairs using Dart's [Random.secure].
/// Private keys are stored in [SecureStorageService] (never in Hive).
/// Returns a public key bundle ready to POST to /api/users/keys.
///
/// Sprint 4 will replace the random byte generation with a proper
/// libsignal implementation using Curve25519 / X3DH.
class KeyGenerator {
  KeyGenerator._();

  static const int _keySize = 32; // 256-bit keys
  static const int _initialOneTimePrekeys = 10;

  // ── Internal helpers ─────────────────────────────────────────────────

  /// Generate a cryptographically secure random key as a base64 string.
  static String _generateRandomKey() {
    final random = Random.secure();
    final bytes = Uint8List.fromList(
      List.generate(_keySize, (_) => random.nextInt(256)),
    );
    return base64UrlEncode(bytes);
  }

  /// Generate a simple unique key ID based on current timestamp.
  static int _generateKeyId() {
    return DateTime.now().millisecondsSinceEpoch ~/ 1000;
  }

  // ── Public API ───────────────────────────────────────────────────────

  /// Generate all keys, store private keys securely, and return the
  /// public bundle to upload to the server.
  ///
  /// Returns a [KeyBundle] with public-only data.
  static Future<KeyBundle> generateAndStoreKeys() async {
    // 1. Identity key pair
    final identityPublic = _generateRandomKey();
    final identityPrivate = _generateRandomKey();
    await SecureStorageService.saveIdentityPrivateKey(identityPrivate);

    // 2. Signed pre-key
    final signedPrekeyId = _generateKeyId();
    final signedPrekeyPublic = _generateRandomKey();
    final signedPrekeyPrivate = _generateRandomKey();
    // Signature placeholder — Sprint 4 will sign with identity private key
    final signedPrekeySignature = _generateRandomKey();
    await SecureStorageService.saveSignedPrekeyPrivate(signedPrekeyPrivate);

    // 3. One-time pre-keys (10 initial)
    final List<Map<String, dynamic>> oneTimePrekeysPublic = [];
    for (int i = 0; i < _initialOneTimePrekeys; i++) {
      final id = signedPrekeyId + i + 1;
      final publicKey = _generateRandomKey();
      final privateKey = _generateRandomKey();
      await SecureStorageService.saveOneTimePrekey(id, privateKey);
      oneTimePrekeysPublic.add({'id': id, 'public_key': publicKey});
    }

    return KeyBundle(
      identityKey: identityPublic,
      signedPrekey: {
        'id': signedPrekeyId,
        'public_key': signedPrekeyPublic,
        'signature': signedPrekeySignature,
      },
      prekeyBundle: oneTimePrekeysPublic,
    );
  }

  /// Check whether the device already has identity keys stored.
  static Future<bool> hasKeys() async {
    final key = await SecureStorageService.getIdentityPrivateKey();
    return key != null && key.isNotEmpty;
  }

  /// Clear all stored keys (use on logout / account deletion).
  static Future<void> clearAllKeys() async {
    await SecureStorageService.clearAllKeys();
  }
}

/// Public key bundle ready to be serialised and sent to the server.
class KeyBundle {
  final String identityKey;
  final Map<String, dynamic> signedPrekey;
  final List<Map<String, dynamic>> prekeyBundle;

  const KeyBundle({
    required this.identityKey,
    required this.signedPrekey,
    required this.prekeyBundle,
  });

  Map<String, dynamic> toJson() => {
        'identity_key': identityKey,
        'signed_prekey': signedPrekey,
        'prekey_bundle': prekeyBundle,
      };
}
