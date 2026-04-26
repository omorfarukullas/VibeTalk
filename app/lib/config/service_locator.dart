import 'package:get_it/get_it.dart';
import 'package:vibetalk/core/network/dio_client.dart';
import 'package:vibetalk/core/network/socket_service.dart';
import 'package:vibetalk/core/storage/local_storage.dart';
import 'package:vibetalk/core/encryption/encryption_service.dart';
import 'package:vibetalk/core/notifications/notification_service.dart';

// Auth Feature
import 'package:vibetalk/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:vibetalk/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:vibetalk/features/auth/domain/repositories/auth_repository.dart';
import 'package:vibetalk/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:vibetalk/features/auth/domain/usecases/login_usecase.dart';
import 'package:vibetalk/features/auth/domain/usecases/logout_usecase.dart';
import 'package:vibetalk/features/auth/domain/usecases/register_usecase.dart';
import 'package:vibetalk/features/auth/presentation/bloc/auth_bloc.dart';

/// Global service locator instance.
final GetIt sl = GetIt.instance;

/// Registers all dependencies in the service locator.
/// Called once during app initialization before runApp().
Future<void> initServiceLocator() async {
  // ── Core Services (Singletons) ──────────────────────────────────────

  // Local storage — must be initialized before registration
  final localStorage = LocalStorageService();
  await localStorage.init();
  sl.registerSingleton<LocalStorageService>(localStorage);

  // Network — API client (Dio-based HTTP)
  sl.registerLazySingleton<DioClient>(
    () => DioClient(),
  );

  // Network — Socket.IO real-time connection
  sl.registerLazySingleton<SocketService>(
    () => SocketService(),
  );

  // Encryption — Signal Protocol wrapper
  sl.registerLazySingleton<EncryptionService>(
    () => EncryptionService(),
  );

  // Push notifications — FCM handler
  sl.registerLazySingleton<NotificationService>(
    () => NotificationService(),
  );

  // ── Auth Feature ────────────────────────────────────────────────────

  // Datasources
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSource(sl<DioClient>().dio),
  );

  // Repositories
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remote: sl<AuthRemoteDataSource>(),
      local: sl<LocalStorageService>(),
    ),
  );

  // Use Cases
  sl.registerLazySingleton(() => RegisterUseCase(sl()));
  sl.registerLazySingleton(() => GetCurrentUserUseCase(sl()));
  sl.registerLazySingleton(() => LogoutUseCase(sl()));
  sl.registerLazySingleton(() => UpdateProfileUseCase(sl()));
  sl.registerLazySingleton(() => UploadAvatarUseCase(sl()));
  sl.registerLazySingleton(() => UploadKeysUseCase(sl()));

  // BLoC
  sl.registerFactory(
    () => AuthBloc(
      register: sl(),
      getCurrentUser: sl(),
      logout: sl(),
      updateProfile: sl(),
      uploadAvatar: sl(),
      uploadKeys: sl(),
    ),
  );
}
