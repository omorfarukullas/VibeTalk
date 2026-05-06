abstract class AuthEvent {}

class LoginWithGoogleEvent extends AuthEvent {}

class LoginWithEmailEvent extends AuthEvent {
  final String email;
  final String password;
  LoginWithEmailEvent({required this.email, required this.password});
}

class RegisterWithEmailEvent extends AuthEvent {
  final String email;
  final String password;
  RegisterWithEmailEvent({required this.email, required this.password});
}

class CheckAuthStatusEvent extends AuthEvent {}

class LogoutEvent extends AuthEvent {}
