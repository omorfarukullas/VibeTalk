import 'package:equatable/equatable.dart';
import 'package:vibetalk/features/auth/domain/entities/user_entity.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// Initial state before any auth check.
class AuthInitial extends AuthState {
  const AuthInitial();
}

/// Any async operation in progress.
class AuthLoading extends AuthState {
  const AuthLoading();
}

/// Firebase OTP has been sent successfully; verificationId is ready.
class OTPSent extends AuthState {
  final String verificationId;
  final String phoneNumber;

  const OTPSent({required this.verificationId, required this.phoneNumber});

  @override
  List<Object?> get props => [verificationId, phoneNumber];
}

/// User is authenticated and has a complete profile.
class AuthAuthenticated extends AuthState {
  final UserEntity user;

  const AuthAuthenticated(this.user);

  @override
  List<Object?> get props => [user];
}

/// User is authenticated but needs to complete their profile (new user).
class AuthNewUser extends AuthState {
  final UserEntity user;

  const AuthNewUser(this.user);

  @override
  List<Object?> get props => [user];
}

/// No valid session found.
class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

/// Profile updated successfully.
class ProfileUpdated extends AuthState {
  final UserEntity user;

  const ProfileUpdated(this.user);

  @override
  List<Object?> get props => [user];
}

/// An error occurred during any auth operation.
class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}
