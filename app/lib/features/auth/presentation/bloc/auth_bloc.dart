import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;

  AuthBloc(this._authRepository) : super(AuthInitial()) {
    on<SendOtpEvent>(_onSendOtp);
    on<VerifyOtpEvent>(_onVerifyOtp);
    on<CheckAuthStatusEvent>(_onCheckAuthStatus);
    on<LogoutEvent>(_onLogout);
    
    // Internal events from Firebase callbacks
    on<CodeSentInternalEvent>((event, emit) => emit(AuthCodeSent(event.verificationId)));
    on<AuthErrorInternalEvent>((event, emit) => emit(AuthError(event.message)));
  }

  Future<void> _onSendOtp(SendOtpEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      await _authRepository.sendOTP(
        phoneNumber: event.phoneNumber,
        codeSent: (verificationId, resendToken) {
          // Dispatch internal event so the state can update
          add(CodeSentInternalEvent(verificationId));
        },
        verificationFailed: (e) {
          add(AuthErrorInternalEvent(e.message ?? 'Verification failed'));
        },
        verificationCompleted: (credential) {
          // Optional: handle auto-retrieval
        },
        codeAutoRetrievalTimeout: (verificationId) {},
      );
    } catch (e) {
      emit(AuthError('Failed to start phone verification: ${e.toString()}'));
    }
  }

  Future<void> _onVerifyOtp(VerifyOtpEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      await _authRepository.verifyOTPAndLogin(
        verificationId: event.verificationId,
        smsCode: event.smsCode,
      );
      emit(AuthAuthenticated());
    } catch (e) {
      emit(AuthError('Failed to verify OTP: ${e.toString()}'));
    }
  }

  Future<void> _onCheckAuthStatus(CheckAuthStatusEvent event, Emitter<AuthState> emit) async {
    final isLoggedIn = await _authRepository.isLoggedIn();
    if (isLoggedIn) {
      emit(AuthAuthenticated());
    } else {
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onLogout(LogoutEvent event, Emitter<AuthState> emit) async {
    await _authRepository.logout();
    emit(AuthUnauthenticated());
  }
}
