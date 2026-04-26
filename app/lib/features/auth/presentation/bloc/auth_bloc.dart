import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vibetalk/core/encryption/key_generator.dart';
import 'package:vibetalk/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:vibetalk/features/auth/domain/usecases/login_usecase.dart';
import 'package:vibetalk/features/auth/domain/usecases/logout_usecase.dart';
import 'package:vibetalk/features/auth/domain/usecases/register_usecase.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final RegisterUseCase _register;
  final GetCurrentUserUseCase _getCurrentUser;
  final LogoutUseCase _logout;
  final UpdateProfileUseCase _updateProfile;
  final UploadAvatarUseCase _uploadAvatar;
  final UploadKeysUseCase _uploadKeys;

  final FirebaseAuth _firebaseAuth;

  AuthBloc({
    required RegisterUseCase register,
    required GetCurrentUserUseCase getCurrentUser,
    required LogoutUseCase logout,
    required UpdateProfileUseCase updateProfile,
    required UploadAvatarUseCase uploadAvatar,
    required UploadKeysUseCase uploadKeys,
    FirebaseAuth? firebaseAuth,
  })  : _register = register,
        _getCurrentUser = getCurrentUser,
        _logout = logout,
        _updateProfile = updateProfile,
        _uploadAvatar = uploadAvatar,
        _uploadKeys = uploadKeys,
        _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        super(const AuthInitial()) {
    on<CheckAuthStatusEvent>(_onCheckAuthStatus);
    on<SendOTPEvent>(_onSendOTP);
    on<VerifyOTPEvent>(_onVerifyOTP);
    on<ResendOTPEvent>(_onResendOTP);
    on<UpdateProfileEvent>(_onUpdateProfile);
    on<LogoutEvent>(_onLogout);
  }

  // ── Event Handlers ────────────────────────────────────────────────────

  Future<void> _onCheckAuthStatus(
    CheckAuthStatusEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final user = await _getCurrentUser();
      if (user == null) {
        emit(const AuthUnauthenticated());
        return;
      }

      if (!user.isProfileComplete) {
        emit(AuthNewUser(user));
      } else {
        emit(AuthAuthenticated(user));
      }
    } catch (_) {
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> _onSendOTP(SendOTPEvent event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    final fullPhone = '${event.countryCode}${event.phoneNumber}';

    try {
      await _firebaseAuth.verifyPhoneNumber(
        phoneNumber: fullPhone,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-verification on Android — treat like user submitted manually
          await _signInWithCredential(credential, emit);
        },
        verificationFailed: (FirebaseAuthException e) {
          emit(AuthError(_mapFirebaseError(e)));
        },
        codeSent: (String verificationId, int? resendToken) {
          emit(OTPSent(verificationId: verificationId, phoneNumber: fullPhone));
        },
        codeAutoRetrievalTimeout: (_) {
          // Timeout reached; user can still enter manually.
        },
      );
    } on FirebaseAuthException catch (e) {
      emit(AuthError(_mapFirebaseError(e)));
    } catch (e) {
      emit(AuthError(_humanReadable(e)));
    }
  }

  Future<void> _onResendOTP(ResendOTPEvent event, Emitter<AuthState> emit) async {
    // Delegate to SendOTP — same logic, new verificationId returned
    add(SendOTPEvent(phoneNumber: event.phoneNumber, countryCode: event.countryCode));
  }

  Future<void> _onVerifyOTP(VerifyOTPEvent event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: event.verificationId,
        smsCode: event.otpCode,
      );
      await _signInWithCredential(credential, emit);
    } on FirebaseAuthException catch (e) {
      emit(AuthError(_mapFirebaseError(e)));
    } catch (e) {
      emit(AuthError(_humanReadable(e)));
    }
  }

  Future<void> _signInWithCredential(
    PhoneAuthCredential credential,
    Emitter<AuthState> emit,
  ) async {
    final userCredential = await _firebaseAuth.signInWithCredential(credential);
    final firebaseToken = await userCredential.user?.getIdToken();

    if (firebaseToken == null) {
      emit(const AuthError('Failed to get Firebase ID token. Please try again.'));
      return;
    }

    final user = await _register(firebaseToken);

    if (!user.isProfileComplete) {
      emit(AuthNewUser(user));
    } else {
      emit(AuthAuthenticated(user));
    }
  }

  Future<void> _onUpdateProfile(
    UpdateProfileEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      String? avatarUrl;

      // Upload avatar if a file was provided
      if (event.imageFile != null) {
        avatarUrl = await _uploadAvatar(event.imageFile!);
      }

      final user = await _updateProfile(
        name: event.name,
        bio: event.bio,
        avatarUrl: avatarUrl,
      );

      // Generate and upload Signal Protocol keys (only for new users)
      final hasKeys = await KeyGenerator.hasKeys();
      if (!hasKeys) {
        final bundle = await KeyGenerator.generateAndStoreKeys();
        await _uploadKeys(
          identityKey: bundle.identityKey,
          signedPrekey: bundle.signedPrekey,
          prekeyBundle: bundle.prekeyBundle,
        );
      }

      emit(ProfileUpdated(user));
    } on FirebaseAuthException catch (e) {
      emit(AuthError(_mapFirebaseError(e)));
    } catch (e) {
      emit(AuthError(_humanReadable(e)));
    }
  }

  Future<void> _onLogout(LogoutEvent event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    try {
      await _firebaseAuth.signOut();
      await _logout();
      await KeyGenerator.clearAllKeys();
      emit(const AuthUnauthenticated());
    } catch (e) {
      // Even on error, clear local state and redirect
      emit(const AuthUnauthenticated());
    }
  }

  // ── Error helpers ─────────────────────────────────────────────────────

  String _mapFirebaseError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-phone-number':
        return 'The phone number you entered is invalid. Please check and try again.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a few minutes before trying again.';
      case 'invalid-verification-code':
        return 'The OTP you entered is incorrect. Please check and try again.';
      case 'session-expired':
        return 'Your OTP session has expired. Please request a new code.';
      case 'network-request-failed':
        return 'No internet connection. Please check your network and try again.';
      case 'quota-exceeded':
        return 'SMS quota exceeded. Please try again later.';
      case 'app-not-authorized':
        return 'This app is not authorized to use Firebase Authentication.';
      default:
        return e.message ?? 'Authentication failed. Please try again.';
    }
  }

  String _humanReadable(Object e) {
    final msg = e.toString();
    if (msg.contains('SocketException') || msg.contains('network')) {
      return 'No internet connection. Please check your network.';
    }
    if (msg.contains('timeout')) {
      return 'Request timed out. Please try again.';
    }
    return 'An unexpected error occurred. Please try again.';
  }
}
