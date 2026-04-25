import 'package:flutter/material.dart';

/// Group detail / info screen.
class GroupDetailScreen extends StatelessWidget {
  final String groupId;

  const GroupDetailScreen({super.key, required this.groupId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Group Info')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            CircleAvatar(
              radius: 48,
              backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.15),
              child: Icon(Icons.group_rounded, size: 48, color: theme.colorScheme.primary),
            ),
            const SizedBox(height: 16),
            Text('Group Name', style: theme.textTheme.headlineMedium),
            const SizedBox(height: 4),
            Text(
              'Group ID: $groupId',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.people_outline_rounded),
              title: const Text('Members'),
              subtitle: const Text('0 members'),
              onTap: () {
                // TODO: Sprint 4 — Show member list
              },
            ),
            ListTile(
              leading: const Icon(Icons.link_rounded),
              title: const Text('Invite Link'),
              subtitle: const Text('Tap to copy'),
              onTap: () {
                // TODO: Sprint 4 — Copy invite link
              },
            ),
            ListTile(
              leading: Icon(Icons.exit_to_app_rounded, color: theme.colorScheme.error),
              title: Text('Leave Group', style: TextStyle(color: theme.colorScheme.error)),
              onTap: () {
                // TODO: Sprint 4 — Leave group
              },
            ),
          ],
        ),
      ),
    );
  }
}
