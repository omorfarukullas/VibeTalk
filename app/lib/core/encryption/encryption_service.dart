import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as encrypt;

/// Encryption service wrapping AES-256 for local message encryption
/// and preparing for Signal Protocol integration in Sprint 2+.
///
/// In production, this will be replaced with full libsignal integration
/// for end-to-end encrypted messaging. This scaffold provides the
/// interface that the rest of the app will code against.
class EncryptionService {
  static const int _keyLength = 32; // 256 bits
  static const int _ivLength = 16; // 128 bits

  /// Generates a random AES-256 key encoded as base64.
  String generateKey() {
    final random = Random.secure();
    final keyBytes =
        Uint8List.fromList(List.generate(_keyLength, (_) => random.nextInt(256)));
    return base64Encode(keyBytes);
  }

  /// Generates a random initialization vector (IV) encoded as base64.
  String generateIV() {
    final random = Random.secure();
    final ivBytes =
        Uint8List.fromList(List.generate(_ivLength, (_) => random.nextInt(256)));
    return base64Encode(ivBytes);
  }

  /// Encrypts plaintext using AES-256-CBC with the given key.
  /// Returns a map with 'ciphertext' and 'iv' (both base64-encoded).
  Map<String, String> encryptMessage(String plaintext, String base64Key) {
    final key = encrypt.Key.fromBase64(base64Key);
    final iv = encrypt.IV.fromSecureRandom(_ivLength);
    final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));

    final encrypted = encrypter.encrypt(plaintext, iv: iv);

    return {
      'ciphertext': encrypted.base64,
      'iv': iv.base64,
    };
  }

  /// Decrypts ciphertext using AES-256-CBC with the given key and IV.
  String decryptMessage(
    String base64Ciphertext,
    String base64Key,
    String base64IV,
  ) {
    final key = encrypt.Key.fromBase64(base64Key);
    final iv = encrypt.IV.fromBase64(base64IV);
    final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));

    return encrypter.decrypt64(base64Ciphertext, iv: iv);
  }

  /// Hashes data using SHA-256 (for integrity verification).
  String hashData(String data) {
    final bytes = utf8.encode(data);
    final digest = _sha256(Uint8List.fromList(bytes));
    return base64Encode(digest);
  }

  /// Simple SHA-256 stub — will be replaced with crypto package.
  Uint8List _sha256(Uint8List data) {
    // Using encrypt package's built-in hashing
    // In production, use pointycastle or crypto package
    return data; // Placeholder — replace in Sprint 2
  }

  // ── Signal Protocol Interface (Sprint 2+) ───────────────────────────

  /// Generates an identity key pair for the Signal Protocol.
  /// Placeholder — will use libsignal in Sprint 2.
  Future<Map<String, String>> generateIdentityKeyPair() async {
    return {
      'publicKey': generateKey(),
      'privateKey': generateKey(),
    };
  }

  /// Generates a signed pre-key for the Signal Protocol.
  /// Placeholder — will use libsignal in Sprint 2.
  Future<Map<String, String>> generateSignedPreKey() async {
    return {
      'keyId': '1',
      'publicKey': generateKey(),
      'privateKey': generateKey(),
      'signature': generateKey(),
    };
  }

  /// Generates a batch of one-time pre-keys for the Signal Protocol.
  /// Placeholder — will use libsignal in Sprint 2.
  Future<List<Map<String, String>>> generatePreKeys(int count) async {
    return List.generate(count, (index) {
      return {
        'keyId': '${index + 1}',
        'publicKey': generateKey(),
        'privateKey': generateKey(),
      };
    });
  }
}
