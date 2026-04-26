import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:vibetalk/core/storage/local_storage.dart';
import 'package:vibetalk/config/service_locator.dart';
import 'package:vibetalk/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vibetalk/features/auth/presentation/bloc/auth_event.dart';
import 'package:vibetalk/features/auth/presentation/bloc/auth_state.dart';

/// Splash screen shown on cold launch.
///
/// Logic:
///  1. Checks Hive for an access token.
///  2. If present and not expired → navigate to /home.
///  3. If expired → attempt refresh → success: /home, fail: /login.
///  4. If absent → navigate to /login after a 2-second brand delay.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();

    // Dispatch auth check to BLoC
    context.read<AuthBloc>().add(const CheckAuthStatusEvent());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          context.go('/home');
        } else if (state is AuthNewUser) {
          context.go('/profile-setup');
        } else if (state is AuthUnauthenticated) {
          Future.delayed(
            const Duration(seconds: 2),
            () {
              if (mounted) context.go('/login');
            },
          );
        }
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Center(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // App logo / icon
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [primary, primary.withOpacity(0.6)],
                    ),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: primary.withOpacity(0.4),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.chat_bubble_rounded,
                    color: Colors.white,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'VibeTalk',
                  style: theme.textTheme.displayLarge?.copyWith(
                    color: theme.colorScheme.onSurface,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Secure messaging, redefined.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
                const SizedBox(height: 48),
                SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(primary),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
