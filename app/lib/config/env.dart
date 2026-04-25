import 'package:envied/envied.dart';

part 'env.g.dart';

/// Environment configuration loaded from .env file at build time.
/// Run `dart run build_runner build` to generate env.g.dart after
/// populating the .env file with your credentials.
@Envied(path: '.env', obfuscate: true)
abstract class Env {
  // ── Firebase ──────────────────────────────────────────────────────────
  @EnviedField(varName: 'FIREBASE_API_KEY')
  static const String firebaseApiKey = _Env.firebaseApiKey;

  @EnviedField(varName: 'FIREBASE_APP_ID')
  static const String firebaseAppId = _Env.firebaseAppId;

  @EnviedField(varName: 'FIREBASE_MESSAGING_SENDER_ID')
  static const String firebaseMessagingSenderId = _Env.firebaseMessagingSenderId;

  @EnviedField(varName: 'FIREBASE_PROJECT_ID')
  static const String firebaseProjectId = _Env.firebaseProjectId;

  // ── API ───────────────────────────────────────────────────────────────
  @EnviedField(varName: 'API_BASE_URL')
  static const String apiBaseUrl = _Env.apiBaseUrl;

  // ── Cloudflare R2 ────────────────────────────────────────────────────
  @EnviedField(varName: 'CLOUDFLARE_R2_BUCKET')
  static const String r2Bucket = _Env.r2Bucket;

  @EnviedField(varName: 'CLOUDFLARE_R2_ACCESS_KEY')
  static const String r2AccessKey = _Env.r2AccessKey;

  @EnviedField(varName: 'CLOUDFLARE_R2_SECRET_KEY')
  static const String r2SecretKey = _Env.r2SecretKey;

  @EnviedField(varName: 'CLOUDFLARE_R2_ENDPOINT')
  static const String r2Endpoint = _Env.r2Endpoint;

  // ── Sentry ────────────────────────────────────────────────────────────
  @EnviedField(varName: 'SENTRY_DSN')
  static const String sentryDsn = _Env.sentryDsn;
}
