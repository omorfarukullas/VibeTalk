import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:vibetalk/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:vibetalk/features/friends/presentation/bloc/friend_bloc.dart';

/// Bottom navigation shell for the main app screens.
/// Used as the builder for the ShellRoute in GoRouter.
class ShellScaffold extends StatelessWidget {
  final Widget child;

  const ShellScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final chatState = context.watch<ChatBloc>().state;
    final friendState = context.watch<FriendBloc>().state;

    int totalUnreadChats = 0;
    if (chatState is ChatLoaded) {
      totalUnreadChats = chatState.unreadCounts.values.fold(0, (a, b) => a + b);
    }

    int totalPendingRequests = 0;
    if (friendState is FriendsLoaded) {
      totalPendingRequests = friendState.pendingRequests.length;
    }

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _calculateSelectedIndex(context),
        onDestinationSelected: (index) => _onItemTapped(index, context),
        destinations: [
          NavigationDestination(
            icon: totalUnreadChats > 0 
                ? Badge(label: Text(totalUnreadChats.toString()), child: const Icon(Icons.chat_bubble_outline_rounded))
                : const Icon(Icons.chat_bubble_outline_rounded),
            selectedIcon: totalUnreadChats > 0 
                ? Badge(label: Text(totalUnreadChats.toString()), child: const Icon(Icons.chat_bubble_rounded))
                : const Icon(Icons.chat_bubble_rounded),
            label: 'Chats',
          ),
          const NavigationDestination(
            icon: Icon(Icons.call_outlined),
            selectedIcon: Icon(Icons.call_rounded),
            label: 'Calls',
          ),
          const NavigationDestination(
            icon: Icon(Icons.group_outlined),
            selectedIcon: Icon(Icons.group_rounded),
            label: 'Groups',
          ),
          NavigationDestination(
            icon: totalPendingRequests > 0 
                ? Badge(label: Text(totalPendingRequests.toString()), child: const Icon(Icons.people_outline_rounded))
                : const Icon(Icons.people_outline_rounded),
            selectedIcon: totalPendingRequests > 0 
                ? Badge(label: Text(totalPendingRequests.toString()), child: const Icon(Icons.people_rounded))
                : const Icon(Icons.people_rounded),
            label: 'Friends',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/calls')) return 1;
    if (location.startsWith('/groups')) return 2;
    if (location.startsWith('/friends')) return 3;
    if (location.startsWith('/profile')) return 4;
    return 0; // Default to chats
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/chats');
        break;
      case 1:
        context.go('/calls');
        break;
      case 2:
        context.go('/groups');
        break;
      case 3:
        context.go('/friends');
        break;
      case 4:
        context.go('/profile');
        break;
    }
  }
}
