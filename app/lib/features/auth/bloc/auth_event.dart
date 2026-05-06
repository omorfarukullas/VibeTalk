abstract class AuthEvent {
  const AuthEvent();
}

/// Dispatched on app start to check if a valid token exists in storage.
class CheckAuthStatusEvent extends AuthEvent {
  const CheckAuthStatusEvent();
}

/// Trigger Google OAuth sign-in flow.
class LoginWithGoogleEvent extends AuthEvent {
  const LoginWithGoogleEvent();
}

/// Trigger email + password sign-in.
class LoginWithEmailEvent extends AuthEvent {
  final String email;
  final String password;
  const LoginWithEmailEvent(this.email, this.password);
}

/// Trigger email + password registration.
class RegisterWithEmailEvent extends AuthEvent {
  final String email;
  final String password;
  const RegisterWithEmailEvent(this.email, this.password);
}

/// Sign the user out and clear all stored tokens.
class LogoutEvent extends AuthEvent {
  const LogoutEvent();
}
