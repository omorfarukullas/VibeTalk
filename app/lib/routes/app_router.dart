import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// ── Feature Screens (placeholders until Sprint 1+) ─────────────────────
import 'package:vibetalk/features/auth/presentation/login_screen.dart';
import 'package:vibetalk/features/auth/presentation/otp_screen.dart';
import 'package:vibetalk/features/auth/presentation/profile_setup_screen.dart';
import 'package:vibetalk/features/chat/presentation/chat_list_screen.dart';
import 'package:vibetalk/features/chat/presentation/chat_detail_screen.dart';
import 'package:vibetalk/features/calls/presentation/call_screen.dart';
import 'package:vibetalk/features/calls/presentation/call_history_screen.dart';
import 'package:vibetalk/features/groups/presentation/group_list_screen.dart';
import 'package:vibetalk/features/groups/presentation/group_detail_screen.dart';
import 'package:vibetalk/features/groups/presentation/create_group_screen.dart';
import 'package:vibetalk/features/media/presentation/media_viewer_screen.dart';
import 'package:vibetalk/features/media/presentation/camera_screen.dart';
import 'package:vibetalk/features/profile/presentation/profile_screen.dart';
import 'package:vibetalk/features/profile/presentation/edit_profile_screen.dart';
import 'package:vibetalk/features/profile/presentation/settings_screen.dart';
import 'package:vibetalk/shared/widgets/shell_scaffold.dart';

/// Application route paths — centralised for type-safe navigation.
abstract class RoutePaths {
  static const String login = '/login';
  static const String otp = '/otp';
  static const String profileSetup = '/profile-setup';
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

/// Global navigator key for GoRouter.
final GlobalKey<NavigatorState> _rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');

final GlobalKey<NavigatorState> _shellNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'shell');

/// GoRouter configuration for the entire app.
final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: RoutePaths.login,
  debugLogDiagnostics: true,
  routes: [
    // ── Auth Flow (no bottom nav) ─────────────────────────────────────
    GoRoute(
      path: RoutePaths.login,
      name: 'login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: RoutePaths.otp,
      name: 'otp',
      builder: (context, state) => const OtpScreen(),
    ),
    GoRoute(
      path: RoutePaths.profileSetup,
      name: 'profileSetup',
      builder: (context, state) => const ProfileSetupScreen(),
    ),

    // ── Main App (with bottom nav shell) ──────────────────────────────
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

    // ── Full-Screen Overlays (no bottom nav) ──────────────────────────
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

  // Redirect unauthenticated users to login
  redirect: (context, state) {
    // TODO: Sprint 1 — check auth state and redirect accordingly
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
        ],
      ),
    ),
  ),
);
