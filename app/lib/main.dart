import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:vibetalk/config/theme.dart';
import 'package:vibetalk/config/service_locator.dart';
import 'package:vibetalk/routes/app_router.dart';
import 'package:vibetalk/core/notifications/notification_service.dart';

/// VibeTalk — End-to-end encrypted messaging and calling.
///
/// Entry point: initializes Firebase, Sentry, service locator,
/// and FCM before launching the MaterialApp with GoRouter.
Future<void> main() async {
  // Ensure Flutter bindings are initialized before async operations
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();

  // Initialize Sentry for error tracking
  await SentryFlutter.init(
    (options) {
      options.dsn = const String.fromEnvironment(
        'SENTRY_DSN',
        defaultValue: '',
      );
      options.tracesSampleRate = 0.3;
      options.environment = const String.fromEnvironment(
        'ENV',
        defaultValue: 'development',
      );
      options.attachScreenshot = true;
      options.sendDefaultPii = false;
    },
    appRunner: () async {
      // Initialize dependency injection
      await initServiceLocator();

      // Set up background message handler for FCM
      FirebaseMessaging.onBackgroundMessage(
        firebaseMessagingBackgroundHandler,
      );

      // Run the app
      runApp(const VibeTalkApp());
    },
  );
}

/// Root application widget.
class VibeTalkApp extends StatelessWidget {
  const VibeTalkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      // ── App Identity ────────────────────────────────────────────────
      title: 'VibeTalk',
      debugShowCheckedModeBanner: false,

      // ── Theme ───────────────────────────────────────────────────────
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,

      // ── Navigation ──────────────────────────────────────────────────
      routerConfig: appRouter,
    );
  }
}
