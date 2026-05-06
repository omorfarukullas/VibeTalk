import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:vibetalk/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vibetalk/features/auth/presentation/bloc/auth_event.dart';
import 'package:vibetalk/features/auth/presentation/bloc/auth_state.dart';
import 'package:vibetalk/config/service_locator.dart';
import 'package:vibetalk/features/auth/data/services/vibetalk_auth_service.dart';

/// User profile screen — displays own profile info.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<Map<String, dynamic>> _userFuture;

  @override
  void initState() {
    super.initState();
    _userFuture = sl<VibeTalkAuthService>().getCurrentUser();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthUnauthenticated) {
          context.go('/login');
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: FutureBuilder<Map<String, dynamic>>(
          future: _userFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('Failed to load profile: ${snapshot.error}'));
            }

            final user = snapshot.data ?? {};
            final name = user['name'] ?? 'Your Name';
            final bio = user['bio'] ?? 'Hey there! I am using VibeTalk';
            final avatarUrl = user['avatarUrl'] ?? user['avatar_url'];

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 56,
                    backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.15),
                    backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                    child: avatarUrl == null 
                        ? Icon(Icons.person_rounded, size: 56, color: theme.colorScheme.primary)
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Text(name, style: theme.textTheme.headlineMedium),
                  const SizedBox(height: 8),
                  Text(bio, style: theme.textTheme.bodySmall),
                  const SizedBox(height: 32),
                  _buildMenuItem(
                    context,
                    icon: Icons.edit_rounded,
                    title: 'Edit Profile',
                    onTap: () {
                      // TODO: Navigate to edit profile
                    },
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.notifications_outlined,
                    title: 'Notifications',
                    onTap: () {},
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.lock_outline_rounded,
                    title: 'Privacy & Security',
                    onTap: () {},
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.palette_outlined,
                    title: 'Appearance',
                    onTap: () {},
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.settings_outlined,
                    title: 'Settings',
                    onTap: () {},
                  ),
                  const SizedBox(height: 16),
                  _buildMenuItem(
                    context,
                    icon: Icons.logout_rounded,
                    title: 'Log Out',
                    color: theme.colorScheme.error,
                    onTap: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Log Out'),
                          content: const Text('Are you sure you want to log out?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              style: TextButton.styleFrom(foregroundColor: theme.colorScheme.error),
                              child: const Text('Log Out'),
                            ),
                          ],
                        ),
                      );
                      if (confirmed == true && context.mounted) {
                        context.read<AuthBloc>().add(LogoutEvent());
                        // We wait for the BlocListener to trigger the redirect
                      }
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(icon, color: color ?? theme.colorScheme.onSurface),
      title: Text(title, style: TextStyle(color: color)),
      trailing: Icon(Icons.chevron_right_rounded, color: color ?? theme.colorScheme.onSurface.withValues(alpha: 0.4)),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}

