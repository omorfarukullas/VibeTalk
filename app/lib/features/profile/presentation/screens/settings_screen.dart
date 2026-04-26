import 'package:flutter/material.dart';

/// App settings screen.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          _buildSection(
            context,
            title: 'General',
            children: [
              SwitchListTile(
                title: const Text('Dark Mode'),
                subtitle: const Text('Use dark theme'),
                secondary: const Icon(Icons.dark_mode_outlined),
                value: theme.brightness == Brightness.dark,
                onChanged: (value) {
                  // TODO: Sprint 5 — Toggle theme
                },
              ),
              ListTile(
                leading: const Icon(Icons.language_rounded),
                title: const Text('Language'),
                subtitle: const Text('English'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  // TODO: Sprint 5 — Language picker
                },
              ),
            ],
          ),
          _buildSection(
            context,
            title: 'Notifications',
            children: [
              SwitchListTile(
                title: const Text('Push Notifications'),
                subtitle: const Text('Receive message notifications'),
                secondary: const Icon(Icons.notifications_outlined),
                value: true,
                onChanged: (value) {
                  // TODO: Sprint 5 — Toggle notifications
                },
              ),
              SwitchListTile(
                title: const Text('Sound'),
                subtitle: const Text('Play notification sounds'),
                secondary: const Icon(Icons.volume_up_outlined),
                value: true,
                onChanged: (value) {
                  // TODO: Sprint 5 — Toggle sound
                },
              ),
            ],
          ),
          _buildSection(
            context,
            title: 'Storage',
            children: [
              ListTile(
                leading: const Icon(Icons.storage_rounded),
                title: const Text('Storage Usage'),
                subtitle: const Text('Manage local data'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  // TODO: Sprint 5 — Storage management
                },
              ),
              ListTile(
                leading: Icon(Icons.delete_outline_rounded, color: theme.colorScheme.error),
                title: Text('Clear Cache', style: TextStyle(color: theme.colorScheme.error)),
                onTap: () {
                  // TODO: Sprint 5 — Clear cache
                },
              ),
            ],
          ),
          _buildSection(
            context,
            title: 'About',
            children: [
              const ListTile(
                leading: Icon(Icons.info_outline_rounded),
                title: Text('Version'),
                subtitle: Text('1.0.0 (1)'),
              ),
              ListTile(
                leading: const Icon(Icons.description_outlined),
                title: const Text('Terms of Service'),
                onTap: () {
                  // TODO: Sprint 5 — Open ToS
                },
              ),
              ListTile(
                leading: const Icon(Icons.privacy_tip_outlined),
                title: const Text('Privacy Policy'),
                onTap: () {
                  // TODO: Sprint 5 — Open Privacy Policy
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Text(
            title,
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
        ),
        ...children,
      ],
    );
  }
}
