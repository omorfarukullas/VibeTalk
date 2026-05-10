/// Application-wide constants for VibeTalk.
class AppConstants {
  AppConstants._();

  // ── App Info ────────────────────────────────────────────────────────
  static const String appName = 'VibeTalk';
  static const String appVersion = '1.0.0';
  static const String appBuildNumber = '1';
  static const String appDescription =
      'End-to-end encrypted messaging and calling';

  // ── API ─────────────────────────────────────────────────────────────
  static const String apiBaseUrl = 'http://192.168.0.103:3000/api/';
  // Socket.IO must connect to server root, not /api/
  static const String socketBaseUrl = 'http://192.168.0.103:3000';
  static const String apiVersion = '/api/v1';


  // ── WebSocket Events ────────────────────────────────────────────────
  static const String eventSendMessage = 'send_message';
  static const String eventReceiveMessage = 'receive_message';
  static const String eventTyping = 'typing';
  static const String eventJoinRoom = 'join_room';
  static const String eventLeaveRoom = 'leave_room';
  static const String eventCallOffer = 'call_offer';
  static const String eventCallAnswer = 'call_answer';
  static const String eventCallIceCandidate = 'call_ice_candidate';
  static const String eventCallEnd = 'call_end';
  static const String eventUserOnline = 'user_online';
  static const String eventUserOffline = 'user_offline';

  // ── Storage Keys ────────────────────────────────────────────────────
  static const String keyAccessToken = 'access_token';
  static const String keyRefreshToken = 'refresh_token';
  static const String keyUserId = 'user_id';
  static const String keyThemeMode = 'theme_mode';

  // ── Limits ──────────────────────────────────────────────────────────
  static const int maxMessageLength = 4096;
  static const int maxGroupMembers = 256;
  static const int maxFileSize = 50 * 1024 * 1024; // 50 MB
  static const int otpLength = 6;
  static const int otpTimeoutSeconds = 60;

  // ── Media ───────────────────────────────────────────────────────────
  static const List<String> supportedImageFormats = [
    'jpg',
    'jpeg',
    'png',
    'gif',
    'webp',
  ];
  static const List<String> supportedVideoFormats = [
    'mp4',
    'mov',
    'avi',
    'mkv',
  ];
  static const List<String> supportedAudioFormats = [
    'mp3',
    'wav',
    'aac',
    'm4a',
    'ogg',
  ];
  static const List<String> supportedDocumentFormats = [
    'pdf',
    'doc',
    'docx',
    'xls',
    'xlsx',
    'ppt',
    'pptx',
    'txt',
  ];
}
