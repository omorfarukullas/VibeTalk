import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:vibetalk/config/service_locator.dart';
import 'package:vibetalk/core/storage/local_storage.dart';
import 'package:vibetalk/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vibetalk/features/auth/presentation/bloc/auth_state.dart';
import 'package:vibetalk/features/auth/presentation/bloc/auth_event.dart';

// ── Auth screens ───────────────────────────────────────────────────────
import 'package:vibetalk/features/auth/presentation/screens/splash_screen.dart';
import 'package:vibetalk/features/auth/presentation/screens/phone_input_screen.dart';
import 'package:vibetalk/features/auth/presentation/screens/otp_verification_screen.dart';
import 'package:vibetalk/features/auth/presentation/screens/profile_setup_screen.dart';

// ── Main app screens ───────────────────────────────────────────────────
import 'package:vibetalk/features/chat/presentation/screens/chat_list_screen.dart';
import 'package:vibetalk/features/chat/presentation/screens/chat_detail_screen.dart';
import 'package:vibetalk/features/calls/presentation/screens/call_screen.dart';
import 'package:vibetalk/features/calls/presentation/screens/call_history_screen.dart';
import 'package:vibetalk/features/groups/presentation/screens/group_list_screen.dart';
import 'package:vibetalk/features/groups/presentation/screens/group_detail_screen.dart';
import 'package:vibetalk/features/groups/presentation/screens/create_group_screen.dart';
import 'package:vibetalk/features/media/presentation/screens/media_viewer_screen.dart';
import 'package:vibetalk/features/media/presentation/screens/camera_screen.dart';
import 'package:vibetalk/features/profile/presentation/screens/profile_screen.dart';
import 'package:vibetalk/features/profile/presentation/screens/edit_profile_screen.dart';
import 'package:vibetalk/features/profile/presentation/screens/settings_screen.dart';
import 'package:vibetalk/shared/widgets/shell_scaffold.dart';

/// Centralised route path constants.
abstract class RoutePaths {
  static const String splash = '/';
  static const String login = '/login';
  static const String otp = '/otp';
  static const String profileSetup = '/profile-setup';
  static const String home = '/home';
  static const String chats = '/chats';
  static const String chatDetail = '/chats/:chatId';
  static const String calls = '/calls';
  static const String callActive = '/calls/:callId';
  static const String groups = '/groups';
  static const String groupDetail = '/groups/:groupId';
  static const String createGroup = '/groups/create';
  static const String mediaViewer = '/media/:mediaId';
  static const String camera = '/camera';
  static const String profile = '/profile';
  static const String editProfile = '/profile/edit';
  static const String settings = '/settings';
}

/// Determines whether the current user is authenticated.
bool _isAuthenticated() {
  final storage = sl<LocalStorageService>();
  return storage.getAccessToken() != null &&
      storage.getAccessToken()!.isNotEmpty;
}

final GlobalKey<NavigatorState> _rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');

final GlobalKey<NavigatorState> _shellNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'shell');

/// Application router.
final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: RoutePaths.splash,
  debugLogDiagnostics: true,
  routes: [
    // ── Splash ──────────────────────────────────────────────────────────
    GoRoute(
      path: RoutePaths.splash,
      name: 'splash',
      builder: (context, state) => const SplashScreen(),
    ),

    // ── Auth flow ────────────────────────────────────────────────────────
    GoRoute(
      path: RoutePaths.login,
      name: 'login',
      builder: (context, state) => const PhoneInputScreen(),
    ),
    GoRoute(
      path: RoutePaths.otp,
      name: 'otp',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>? ?? {};
        return OtpVerificationScreen(
          verificationId: extra['verificationId'] as String? ?? '',
          phoneNumber: extra['phoneNumber'] as String? ?? '',
        );
      },
    ),
    GoRoute(
      path: RoutePaths.profileSetup,
      name: 'profileSetup',
      builder: (context, state) => const ProfileSetupScreen(),
    ),

    // ── Home (placeholder shell) ─────────────────────────────────────────
    GoRoute(
      path: RoutePaths.home,
      name: 'home',
      builder: (context, state) => const _HomeScreen(),
    ),

    // ── Main app with bottom nav shell ───────────────────────────────────
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) => ShellScaffold(child: child),
      routes: [
        GoRoute(
          path: RoutePaths.chats,
          name: 'chats',
          builder: (context, state) => const ChatListScreen(),
          routes: [
            GoRoute(
              path: ':chatId',
              name: 'chatDetail',
              parentNavigatorKey: _rootNavigatorKey,
              builder: (context, state) => ChatDetailScreen(
                chatId: state.pathParameters['chatId']!,
              ),
            ),
          ],
        ),
        GoRoute(
          path: RoutePaths.calls,
          name: 'calls',
          builder: (context, state) => const CallHistoryScreen(),
        ),
        GoRoute(
          path: RoutePaths.groups,
          name: 'groups',
          builder: (context, state) => const GroupListScreen(),
          routes: [
            GoRoute(
              path: 'create',
              name: 'createGroup',
              parentNavigatorKey: _rootNavigatorKey,
              builder: (context, state) => const CreateGroupScreen(),
            ),
            GoRoute(
              path: ':groupId',
              name: 'groupDetail',
              parentNavigatorKey: _rootNavigatorKey,
              builder: (context, state) => GroupDetailScreen(
                groupId: state.pathParameters['groupId']!,
              ),
            ),
          ],
        ),
        GoRoute(
          path: RoutePaths.profile,
          name: 'profile',
          builder: (context, state) => const ProfileScreen(),
        ),
      ],
    ),

    // ── Full-screen overlays ─────────────────────────────────────────────
    GoRoute(
      path: '/calls/:callId',
      name: 'callActive',
      builder: (context, state) => CallScreen(
        callId: state.pathParameters['callId']!,
      ),
    ),
    GoRoute(
      path: '/media/:mediaId',
      name: 'mediaViewer',
      builder: (context, state) => MediaViewerScreen(
        mediaId: state.pathParameters['mediaId']!,
      ),
    ),
    GoRoute(
      path: RoutePaths.camera,
      name: 'camera',
      builder: (context, state) => const CameraScreen(),
    ),
    GoRoute(
      path: RoutePaths.editProfile,
      name: 'editProfile',
      builder: (context, state) => const EditProfileScreen(),
    ),
    GoRoute(
      path: RoutePaths.settings,
      name: 'settings',
      builder: (context, state) => const SettingsScreen(),
    ),
  ],

  // ── Auth guard redirect ──────────────────────────────────────────────
  redirect: (context, state) {
    final authenticated = _isAuthenticated();
    final path = state.matchedLocation;

    // Public paths that don't require auth
    final publicPaths = ['/', '/login', '/otp', '/profile-setup'];
    final isPublic = publicPaths.any((p) => path == p || path.startsWith(p));

    // Redirect unauthenticated users away from protected routes
    if (!authenticated && !isPublic) {
      return RoutePaths.login;
    }

    // Redirect authenticated users away from login screen
    if (authenticated && path == RoutePaths.login) {
      return RoutePaths.home;
    }

    return null;
  },

  errorBuilder: (context, state) => Scaffold(
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Page not found',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            state.uri.toString(),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.go(RoutePaths.home),
            child: const Text('Go Home'),
          ),
        ],
      ),
    ),
  ),
);

// ── Home screen placeholder ──────────────────────────────────────────────

class _HomeScreen extends StatelessWidget {
  const _HomeScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.chat_bubble_rounded,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'Home',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Sprint 2 will build this screen.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.5),
                    ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  context.read<AuthBloc>().add(LogoutEvent());
                  context.go(RoutePaths.login);
                },
                child: const Text('Sign Out'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
