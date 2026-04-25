import 'package:flutter/material.dart';

/// User profile screen — displays own profile info.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            CircleAvatar(
              radius: 56,
              backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.15),
              child: Icon(Icons.person_rounded, size: 56, color: theme.colorScheme.primary),
            ),
            const SizedBox(height: 16),
            Text('Your Name', style: theme.textTheme.headlineMedium),
            const SizedBox(height: 4),
            Text('+1 (555) 000-0000', style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            )),
            const SizedBox(height: 8),
            Text('Hey there! I am using VibeTalk', style: theme.textTheme.bodySmall),
            const SizedBox(height: 32),
            _buildMenuItem(
              context,
              icon: Icons.edit_rounded,
              title: 'Edit Profile',
              onTap: () {
                // TODO: Sprint 1 — Navigate to edit profile
              },
            ),
            _buildMenuItem(
              context,
              icon: Icons.notifications_outlined,
              title: 'Notifications',
              onTap: () {
                // TODO: Sprint 5 — Notification settings
              },
            ),
            _buildMenuItem(
              context,
              icon: Icons.lock_outline_rounded,
              title: 'Privacy & Security',
              onTap: () {
                // TODO: Sprint 5 — Privacy settings
              },
            ),
            _buildMenuItem(
              context,
              icon: Icons.palette_outlined,
              title: 'Appearance',
              onTap: () {
                // TODO: Sprint 5 — Theme settings
              },
            ),
            _buildMenuItem(
              context,
              icon: Icons.settings_outlined,
              title: 'Settings',
              onTap: () {
                // TODO: Sprint 5 — App settings
              },
            ),
            const SizedBox(height: 16),
            _buildMenuItem(
              context,
              icon: Icons.logout_rounded,
              title: 'Log Out',
              color: theme.colorScheme.error,
              onTap: () {
                // TODO: Sprint 1 — Logout
              },
            ),
          ],
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
