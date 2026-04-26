import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secure storage wrapper using flutter_secure_storage.
///
/// ONLY used for private encryption keys (Signal Protocol).
/// Regular app data (tokens, user info) lives in Hive [LocalStorageService].
class SecureStorageService {
  SecureStorageService._();

  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  // ── Key names ────────────────────────────────────────────────────────

  static const String _identityPrivateKey = 'identity_private_key';
  static const String _signedPrekeyPrivate = 'signed_prekey_private';

  // ── Generic Operations ───────────────────────────────────────────────

  static Future<void> saveString(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  static Future<String?> getString(String key) async {
    return _storage.read(key: key);
  }

  static Future<void> deleteKey(String key) async {
    await _storage.delete(key: key);
  }

  static Future<void> clearAll() async {
    await _storage.deleteAll();
  }

  // ── Encryption Key Helpers ───────────────────────────────────────────

  static Future<void> saveIdentityPrivateKey(String key) async {
    await saveString(_identityPrivateKey, key);
  }

  static Future<String?> getIdentityPrivateKey() async {
    return getString(_identityPrivateKey);
  }

  static Future<void> saveSignedPrekeyPrivate(String key) async {
    await saveString(_signedPrekeyPrivate, key);
  }

  static Future<String?> getSignedPrekeyPrivate() async {
    return getString(_signedPrekeyPrivate);
  }

  static Future<void> saveOneTimePrekey(int id, String key) async {
    await saveString('prekey_$id', key);
  }

  static Future<String?> getOneTimePrekey(int id) async {
    return getString('prekey_$id');
  }

  static Future<void> deleteOneTimePrekey(int id) async {
    await deleteKey('prekey_$id');
  }

  static Future<void> clearAllKeys() async {
    await clearAll();
  }
}
