import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/encryption/key_generator.dart';
import '../../../../core/encryption/keys_service.dart';
import '../../data/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;
  final KeysService _keysService;

  AuthBloc(this._authRepository, this._keysService) : super(AuthInitial()) {
    on<LoginWithGoogleEvent>(_onLoginWithGoogle);
    on<LoginWithEmailEvent>(_onLoginWithEmail);
    on<RegisterWithEmailEvent>(_onRegisterWithEmail);
    on<CheckAuthStatusEvent>(_onCheckAuthStatus);
    on<UpdateProfileEvent>(_onUpdateProfile);
    on<LogoutEvent>(_onLogout);

  }

  Future<void> _onLoginWithGoogle(
    LoginWithGoogleEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final isComplete = await _authRepository.loginWithGoogle();
      await _ensureKeysUploaded();
      if (isComplete) {
        emit(AuthAuthenticated());
      } else {
        emit(AuthProfileIncomplete());
      }
    } catch (e) {
      emit(AuthError('Google Sign-In failed: ${e.toString()}'));
    }
  }

  Future<void> _onLoginWithEmail(
    LoginWithEmailEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final isComplete = await _authRepository.loginWithEmail(
        event.email,
        event.password,
      );
      await _ensureKeysUploaded();
      if (isComplete) {
        emit(AuthAuthenticated());
      } else {
        emit(AuthProfileIncomplete());
      }
    } catch (e) {
      emit(AuthError('Email login failed: ${e.toString()}'));
    }
  }

  Future<void> _onRegisterWithEmail(
    RegisterWithEmailEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final isComplete = await _authRepository.registerWithEmail(
        event.email,
        event.password,
      );
      await _ensureKeysUploaded();
      if (isComplete) {
        emit(AuthAuthenticated());
      } else {
        emit(AuthProfileIncomplete());
      }
    } catch (e) {
      emit(AuthError('Registration failed: ${e.toString()}'));
    }
  }

  Future<void> _onCheckAuthStatus(
    CheckAuthStatusEvent event,
    Emitter<AuthState> emit,
  ) async {
    final isLoggedIn = await _authRepository.isLoggedIn();
    if (isLoggedIn) {
      final isComplete = await _authRepository.isProfileComplete();
      await _ensureKeysUploaded();
      if (isComplete) {
        emit(AuthAuthenticated());
      } else {
        emit(AuthProfileIncomplete());
      }
    } else {
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _ensureKeysUploaded() async {
    try {
      final hasKeys = await KeyGenerator.hasKeys();
      if (!hasKeys) {
        final bundle = await KeyGenerator.generateAndStoreKeys();
        await _keysService.uploadKeys(bundle);
      }
    } catch (e) {
      // Log the error but don't fail authentication
      print('Error uploading keys: $e');
    }
  }

  Future<void> _onUpdateProfile(
    UpdateProfileEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      await _authRepository.updateProfile(
        name: event.name,
        bio: event.bio,
        imagePath: event.imagePath,
      );
      emit(AuthAuthenticated());
    } catch (e) {
      emit(AuthError('Profile update failed: ${e.toString()}'));
    }
  }

  Future<void> _onLogout(LogoutEvent event, Emitter<AuthState> emit) async {
    await _authRepository.logout();
    await KeyGenerator.clearAllKeys();
    emit(AuthUnauthenticated());
  }
}
