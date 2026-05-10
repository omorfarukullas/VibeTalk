import 'package:get_it/get_it.dart';
import 'package:vibetalk/core/network/api_client.dart';
import 'package:vibetalk/core/network/socket_service.dart';
import 'package:vibetalk/core/storage/local_storage.dart';
import 'package:vibetalk/core/encryption/encryption_service.dart';
import 'package:vibetalk/core/encryption/keys_service.dart';
import 'package:vibetalk/core/notifications/notification_service.dart';


// Auth Feature
import 'package:vibetalk/features/auth/data/services/firebase_auth_service.dart';
import 'package:vibetalk/features/auth/data/services/vibetalk_auth_service.dart';
import 'package:vibetalk/features/auth/data/repositories/auth_repository.dart';
import 'package:vibetalk/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// Chat Feature
import 'package:vibetalk/features/chat/data/repositories/chat_repository.dart';
import 'package:vibetalk/features/chat/data/repositories/media_repository.dart';
import 'package:vibetalk/features/chat/presentation/bloc/chat_bloc.dart';


// Group Feature
import 'package:vibetalk/features/groups/data/repositories/group_repository.dart';

// Friend Feature
import 'package:vibetalk/features/friends/data/repositories/friend_repository.dart';
import 'package:vibetalk/features/friends/presentation/bloc/friend_bloc.dart';




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
  
  // Secure Storage for JWTs
  sl.registerLazySingleton<FlutterSecureStorage>(
    () => const FlutterSecureStorage(),
  );

  // Network — API client (Dio-based HTTP)
  sl.registerLazySingleton<ApiClient>(
    () => ApiClient(),
  );

  // Network — Socket.IO real-time connection
  sl.registerLazySingleton<SocketService>(
    () => SocketService(),
  );

  // Encryption — Signal Protocol wrapper
  sl.registerLazySingleton<EncryptionService>(
    () => EncryptionService(),
  );

  // Encryption — Signal Key Service
  sl.registerLazySingleton<KeysService>(
    () => KeysService(apiClient: sl<ApiClient>()),
  );


  // Push notifications — FCM handler
  sl.registerLazySingleton<NotificationService>(
    () => NotificationService(),
  );

  // ── Auth Feature ────────────────────────────────────────────────────

  // Services
  sl.registerLazySingleton<FirebaseAuthService>(
    () => FirebaseAuthService(),
  );
  
  sl.registerLazySingleton<VibeTalkAuthService>(
    () => VibeTalkAuthService(apiClient: sl<ApiClient>()),
  );

  // Repositories
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepository(
      firebaseService: sl<FirebaseAuthService>(),
      vibeTalkService: sl<VibeTalkAuthService>(),
      secureStorage: sl<FlutterSecureStorage>(),
    ),
  );

  // BLoC
  sl.registerFactory(
    () => AuthBloc(sl<AuthRepository>(), sl<KeysService>()),
  );

  // ── Chat Feature ────────────────────────────────────────────────────
  sl.registerLazySingleton<ChatRepository>(
    () => ChatRepository(apiClient: sl<ApiClient>()),
  );
  sl.registerLazySingleton<MediaRepository>(
    () => MediaRepository(apiClient: sl<ApiClient>()),
  );

  sl.registerLazySingleton<ChatBloc>(

    () => ChatBloc(
      socketService: sl<SocketService>(),
      encryptionService: sl<EncryptionService>(),
      localStorage: sl<LocalStorageService>(),
      chatRepository: sl<ChatRepository>(),
    ),
  );

  // ── Group Feature ───────────────────────────────────────────────────
  sl.registerLazySingleton<GroupRepository>(
    () => GroupRepository(apiClient: sl<ApiClient>()),
  );

  // ── Friend Feature ──────────────────────────────────────────────────
  sl.registerLazySingleton<FriendRepository>(
    () => FriendRepository(apiClient: sl<ApiClient>()),
  );
  sl.registerFactory<FriendBloc>(
    () => FriendBloc(repository: sl<FriendRepository>()),
  );
}




