import 'dart:io';
import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Check whether a valid session exists (called on splash screen init).
class CheckAuthStatusEvent extends AuthEvent {
  const CheckAuthStatusEvent();
}

/// Initiate Firebase phone OTP — triggers verifyPhoneNumber.
class SendOTPEvent extends AuthEvent {
  final String phoneNumber;
  final String countryCode;

  const SendOTPEvent({required this.phoneNumber, required this.countryCode});

  @override
  List<Object?> get props => [phoneNumber, countryCode];
}

/// Verify the 6-digit OTP code; registers/logs in on the server.
class VerifyOTPEvent extends AuthEvent {
  final String verificationId;
  final String otpCode;

  const VerifyOTPEvent({required this.verificationId, required this.otpCode});

  @override
  List<Object?> get props => [verificationId, otpCode];
}

/// Called when resend OTP button is tapped.
class ResendOTPEvent extends AuthEvent {
  final String phoneNumber;
  final String countryCode;

  const ResendOTPEvent({required this.phoneNumber, required this.countryCode});

  @override
  List<Object?> get props => [phoneNumber, countryCode];
}

/// Update display name, bio, and optionally upload a new avatar.
class UpdateProfileEvent extends AuthEvent {
  final String name;
  final String? bio;
  final File? imageFile;

  const UpdateProfileEvent({required this.name, this.bio, this.imageFile});

  @override
  List<Object?> get props => [name, bio, imageFile];
}

/// Log out the current user.
class LogoutEvent extends AuthEvent {
  const LogoutEvent();
}
