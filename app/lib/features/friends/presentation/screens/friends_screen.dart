import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/friend_bloc.dart';
import 'package:vibetalk/features/chat/presentation/screens/contact_search_screen.dart';

/// Friends screen — shows accepted friends and pending requests.
class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FriendBloc>().add(LoadFriendsEvent());
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocConsumer<FriendBloc, FriendState>(
      listener: (context, state) {
        if (state is FriendActionSuccess) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(
              content: Text(state.message),
              backgroundColor: theme.colorScheme.primary,
              behavior: SnackBarBehavior.floating,
            ));
        } else if (state is FriendError) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(
              content: Text(state.message),
              backgroundColor: theme.colorScheme.error,
              behavior: SnackBarBehavior.floating,
            ));
        }
      },
      builder: (context, state) {
        final friends =
            state is FriendsLoaded ? state.friends : <Map<String, dynamic>>[];
        final pending =
            state is FriendsLoaded ? state.pendingRequests : <Map<String, dynamic>>[];

        return Scaffold(
          appBar: AppBar(
            title: const Text('Friends'),
            actions: [
              IconButton(
                icon: const Icon(Icons.person_add_rounded),
                tooltip: 'Add Friend',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ContactSearchScreen(),
                    ),
                  );
                },
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              tabs: [
                Tab(text: 'Friends (${friends.length})'),
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Requests'),
                      if (pending.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.error,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${pending.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          body: state is FriendLoading
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _FriendsList(friends: friends),
                    _PendingRequestsList(requests: pending),
                  ],
                ),
        );
      },
    );
  }
}

// ── Friends list tab ──────────────────────────────────────────────────────────
class _FriendsList extends StatelessWidget {
  final List<Map<String, dynamic>> friends;

  const _FriendsList({required this.friends});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (friends.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.people_outline_rounded,
                size: 72,
                color: theme.colorScheme.primary.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            Text('No friends yet',
                style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
            const SizedBox(height: 8),
            Text('Search for users and send them a request!',
                style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4))),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async =>
          context.read<FriendBloc>().add(LoadFriendsEvent()),
      child: ListView.separated(
        itemCount: friends.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final friend = friends[index];
          final name = friend['name'] as String? ?? 'Unknown';
          final avatar = friend['avatar_url'] as String?;

          return ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            leading: CircleAvatar(
              radius: 24,
              backgroundColor: theme.colorScheme.primaryContainer,
              backgroundImage: avatar != null ? NetworkImage(avatar) : null,
              child: avatar == null
                  ? Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: TextStyle(
                          color: theme.colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold))
                  : null,
            ),
            title: Text(name,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(friend['email'] as String? ?? '',
                style: theme.textTheme.bodySmall?.copyWith(
                    color:
                        theme.colorScheme.onSurface.withValues(alpha: 0.5))),
            trailing: PopupMenuButton<String>(
              onSelected: (val) {
                if (val == 'remove') {
                  _confirmRemove(context, friend);
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                    value: 'remove',
                    child: Row(children: [
                      Icon(Icons.person_remove_outlined, size: 18),
                      SizedBox(width: 8),
                      Text('Remove Friend'),
                    ])),
              ],
              icon: const Icon(Icons.more_vert),
            ),
          );
        },
      ),
    );
  }

  Future<void> _confirmRemove(
      BuildContext context, Map<String, dynamic> friend) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove Friend'),
        content: Text('Remove ${friend['name']} from your friends?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error),
              child: const Text('Remove')),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      context
          .read<FriendBloc>()
          .add(RemoveFriendEvent(friend['friend_id'] as String));
    }
  }
}

// ── Pending requests tab ──────────────────────────────────────────────────────
class _PendingRequestsList extends StatelessWidget {
  final List<Map<String, dynamic>> requests;

  const _PendingRequestsList({required this.requests});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (requests.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_outlined,
                size: 72,
                color: theme.colorScheme.primary.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            Text('No pending requests',
                style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async =>
          context.read<FriendBloc>().add(LoadFriendsEvent()),
      child: ListView.separated(
        itemCount: requests.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final req = requests[index];
          final name = req['name'] as String? ?? 'Unknown';
          final avatar = req['avatar_url'] as String?;
          final requestId = req['id'] as String;

          return ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            leading: CircleAvatar(
              radius: 24,
              backgroundColor: theme.colorScheme.primaryContainer,
              backgroundImage: avatar != null ? NetworkImage(avatar) : null,
              child: avatar == null
                  ? Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: TextStyle(
                          color: theme.colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold))
                  : null,
            ),
            title: Text(name,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(req['email'] as String? ?? ''),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Decline
                IconButton(
                  icon: Icon(Icons.close_rounded,
                      color: theme.colorScheme.error),
                  tooltip: 'Decline',
                  onPressed: () => context
                      .read<FriendBloc>()
                      .add(RespondToRequestEvent(requestId, 'decline')),
                ),
                // Accept
                FilledButton.icon(
                  onPressed: () => context
                      .read<FriendBloc>()
                      .add(RespondToRequestEvent(requestId, 'accept')),
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: const Text('Accept'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
