import 'package:hive_flutter/hive_flutter.dart';

/// Hive-based local storage service for persisting user data,
/// tokens, and app preferences on-device.
class LocalStorageService {
  static const String _authBoxName = 'auth';
  static const String _settingsBoxName = 'settings';
  static const String _cacheBoxName = 'cache';

  late Box<dynamic> _authBox;
  late Box<dynamic> _settingsBox;
  late Box<dynamic> _cacheBox;

  /// Initializes Hive and opens all storage boxes.
  /// Must be called before any read/write operations.
  Future<void> init() async {
    await Hive.initFlutter();
    _authBox = await Hive.openBox(_authBoxName);
    _settingsBox = await Hive.openBox(_settingsBoxName);
    _cacheBox = await Hive.openBox(_cacheBoxName);
  }

  // ── Auth Tokens ─────────────────────────────────────────────────────

  Future<void> saveAccessToken(String token) async {
    await _authBox.put('access_token', token);
  }

  String? getAccessToken() {
    return _authBox.get('access_token') as String?;
  }

  Future<void> saveRefreshToken(String token) async {
    await _authBox.put('refresh_token', token);
  }

  String? getRefreshToken() {
    return _authBox.get('refresh_token') as String?;
  }

  Future<void> saveUserId(String userId) async {
    await _authBox.put('user_id', userId);
  }

  String? getUserId() {
    return _authBox.get('user_id') as String?;
  }

  Future<void> clearAuth() async {
    await _authBox.clear();
  }

  // ── Settings ────────────────────────────────────────────────────────

  Future<void> setThemeMode(String mode) async {
    await _settingsBox.put('theme_mode', mode);
  }

  String getThemeMode() {
    return _settingsBox.get('theme_mode', defaultValue: 'system') as String;
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    await _settingsBox.put('notifications_enabled', enabled);
  }

  bool getNotificationsEnabled() {
    return _settingsBox.get('notifications_enabled', defaultValue: true) as bool;
  }

  Future<void> setSoundEnabled(bool enabled) async {
    await _settingsBox.put('sound_enabled', enabled);
  }

  bool getSoundEnabled() {
    return _settingsBox.get('sound_enabled', defaultValue: true) as bool;
  }

  // ── Cache ───────────────────────────────────────────────────────────

  Future<void> cacheData(String key, dynamic value) async {
    await _cacheBox.put(key, value);
  }

  dynamic getCachedData(String key) {
    return _cacheBox.get(key);
  }

  Future<void> removeCachedData(String key) async {
    await _cacheBox.delete(key);
  }

  Future<void> clearCache() async {
    await _cacheBox.clear();
  }

  // ── Cleanup ─────────────────────────────────────────────────────────

  /// Clears all local data (used on logout).
  Future<void> clearAll() async {
    await _authBox.clear();
    await _settingsBox.clear();
    await _cacheBox.clear();
  }
}
