abstract class AuthEvent {}

class SendOtpEvent extends AuthEvent {
  final String phoneNumber;
  SendOtpEvent(this.phoneNumber);
}

class VerifyOtpEvent extends AuthEvent {
  final String verificationId;
  final String smsCode;
  VerifyOtpEvent({required this.verificationId, required this.smsCode});
}

class CheckAuthStatusEvent extends AuthEvent {}

class LogoutEvent extends AuthEvent {}

/// Internal events triggered by Firebase callbacks
class CodeSentInternalEvent extends AuthEvent {
  final String verificationId;
  CodeSentInternalEvent(this.verificationId);
}

class AuthErrorInternalEvent extends AuthEvent {
  final String message;
  AuthErrorInternalEvent(this.message);
}
