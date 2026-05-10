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

class UpdateProfileEvent extends AuthEvent {
  final String name;
  final String username;
  final String? bio;
  final String? imagePath;
  UpdateProfileEvent({required this.name, required this.username, this.bio, this.imagePath});
}

class LogoutEvent extends AuthEvent {}

