import 'dart:io';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vibetalk/features/auth/domain/entities/user_entity.dart';
import 'package:vibetalk/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:vibetalk/features/auth/domain/usecases/login_usecase.dart';
import 'package:vibetalk/features/auth/domain/usecases/logout_usecase.dart';
import 'package:vibetalk/features/auth/domain/usecases/register_usecase.dart';
import 'package:vibetalk/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vibetalk/features/auth/presentation/bloc/auth_event.dart';
import 'package:vibetalk/features/auth/presentation/bloc/auth_state.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MockRegisterUseCase extends Mock implements RegisterUseCase {}
class MockGetCurrentUserUseCase extends Mock implements GetCurrentUserUseCase {}
class MockLogoutUseCase extends Mock implements LogoutUseCase {}
class MockUpdateProfileUseCase extends Mock implements UpdateProfileUseCase {}
class MockUploadAvatarUseCase extends Mock implements UploadAvatarUseCase {}
class MockUploadKeysUseCase extends Mock implements UploadKeysUseCase {}
class MockFirebaseAuth extends Mock implements FirebaseAuth {}

void main() {
  late AuthBloc authBloc;
  late MockRegisterUseCase mockRegisterUseCase;
  late MockGetCurrentUserUseCase mockGetCurrentUserUseCase;
  late MockLogoutUseCase mockLogoutUseCase;
  late MockUpdateProfileUseCase mockUpdateProfileUseCase;
  late MockUploadAvatarUseCase mockUploadAvatarUseCase;
  late MockUploadKeysUseCase mockUploadKeysUseCase;

  final testDate = DateTime.now();
  final testUser = UserEntity(
    id: 'user_123',
    phoneNumber: '+1987654321',
    name: 'John Doe',
    avatarUrl: 'https://example.com/avatar.jpg',
    status: 'online',
    createdAt: testDate,
    updatedAt: testDate,
  );

  final testNewUser = UserEntity(
    id: 'user_456',
    phoneNumber: '+1987654321',
    name: null,
    createdAt: testDate,
    updatedAt: testDate,
  );

  setUp(() {
    mockRegisterUseCase = MockRegisterUseCase();
    mockGetCurrentUserUseCase = MockGetCurrentUserUseCase();
    mockLogoutUseCase = MockLogoutUseCase();
    mockUpdateProfileUseCase = MockUpdateProfileUseCase();
    mockUploadAvatarUseCase = MockUploadAvatarUseCase();
    mockUploadKeysUseCase = MockUploadKeysUseCase();
    final mockFirebaseAuth = MockFirebaseAuth();

    authBloc = AuthBloc(
      register: mockRegisterUseCase,
      getCurrentUser: mockGetCurrentUserUseCase,
      logout: mockLogoutUseCase,
      updateProfile: mockUpdateProfileUseCase,
      uploadAvatar: mockUploadAvatarUseCase,
      uploadKeys: mockUploadKeysUseCase,
      firebaseAuth: mockFirebaseAuth,
    );
  });

  tearDown(() {
    authBloc.close();
  });

  group('CheckAuthStatusEvent', () {
    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthAuthenticated] when user exists and has a complete profile',
      build: () {
        when(() => mockGetCurrentUserUseCase()).thenAnswer((_) async => testUser);
        return authBloc;
      },
      act: (bloc) => bloc.add(const CheckAuthStatusEvent()),
      expect: () => [
        const AuthLoading(),
        AuthAuthenticated(testUser),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthNewUser] when user exists but has an incomplete profile',
      build: () {
        when(() => mockGetCurrentUserUseCase()).thenAnswer((_) async => testNewUser);
        return authBloc;
      },
      act: (bloc) => bloc.add(const CheckAuthStatusEvent()),
      expect: () => [
        const AuthLoading(),
        AuthNewUser(testNewUser),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthUnauthenticated] when no user exists',
      build: () {
        when(() => mockGetCurrentUserUseCase()).thenAnswer((_) async => null);
        return authBloc;
      },
      act: (bloc) => bloc.add(const CheckAuthStatusEvent()),
      expect: () => [
        const AuthLoading(),
        const AuthUnauthenticated(),
      ],
    );
  });

  group('LogoutEvent', () {
    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthUnauthenticated] on successful logout',
      build: () {
        when(() => mockLogoutUseCase()).thenAnswer((_) async {});
        return authBloc;
      },
      act: (bloc) => bloc.add(const LogoutEvent()),
      expect: () => [
        const AuthLoading(),
        const AuthUnauthenticated(),
      ],
    );
  });
}
