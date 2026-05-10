import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vibetalk/features/chat/data/repositories/chat_repository.dart';
import 'package:vibetalk/config/service_locator.dart';
import 'package:vibetalk/features/chat/presentation/screens/chat_detail_screen.dart';
import 'package:vibetalk/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:vibetalk/features/friends/presentation/bloc/friend_bloc.dart';

enum SearchType { name, username, email }

class ContactSearchScreen extends StatefulWidget {
  const ContactSearchScreen({super.key});

  @override
  State<ContactSearchScreen> createState() => _ContactSearchScreenState();
}

class _ContactSearchScreenState extends State<ContactSearchScreen> {
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isLoading = false;
  // Track which users have pending requests
  final Set<String> _pendingRequests = {};
  SearchType _searchType = SearchType.name;

  void _searchUsers(String query) async {
    if (query.trim().length < 2) {
      setState(() => _searchResults = []);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final repo = sl<ChatRepository>();
      final results = await repo.searchUsers(query, type: _searchType.name);
      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Search failed: $e')),
        );
      }
    }
  }

  void _startChat(Map<String, dynamic> user) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final repo = sl<ChatRepository>();
      final chat = await repo.createOrGetChat(user['id']);

      if (mounted) {
        context.read<ChatBloc>().add(LoadChatsEvent());
        Navigator.pop(context);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ChatDetailScreen(chatId: chat['id']),
          ),
        );
      }
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to start chat: $e')),
      );
    }
  }

  void _addFriend(Map<String, dynamic> user) {
    final userId = user['id'] as String;
    setState(() => _pendingRequests.add(userId));
    context.read<FriendBloc>().add(SendFriendRequestEvent(userId));
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text('Friend request sent to ${user['name']}!'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Theme.of(context).colorScheme.primary,
      ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: Container(
            height: 40,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: _searchType == SearchType.username
                    ? 'Search by @username...'
                    : _searchType == SearchType.email
                        ? 'Search by email...'
                        : 'Search by name...',
                prefixIcon: Icon(Icons.search_rounded,
                    size: 20, color: theme.colorScheme.onSurfaceVariant),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                          _searchUsers('');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
              onChanged: (val) {
                setState(() {}); // To show/hide clear button
                _searchUsers(val);
              },
            ),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('Name'),
                  selected: _searchType == SearchType.name,
                  onSelected: (_) {
                    setState(() => _searchType = SearchType.name);
                    _searchUsers(_searchController.text);
                  },
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('@Username'),
                  selected: _searchType == SearchType.username,
                  onSelected: (_) {
                    setState(() => _searchType = SearchType.username);
                    _searchUsers(_searchController.text);
                  },
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Email'),
                  selected: _searchType == SearchType.email,
                  onSelected: (_) {
                    setState(() => _searchType = SearchType.email);
                    _searchUsers(_searchController.text);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _searchResults.isEmpty
              ? Center(
                  child: Text(
                    _searchController.text.isEmpty
                        ? 'Type to search users'
                        : 'No users found',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
              : ListView.builder(
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    final user = _searchResults[index];
                    final userId = user['id'] as String;
                    final isPending = _pendingRequests.contains(userId) || user['friendship_status'] == 'pending';
                    final isAccepted = user['friendship_status'] == 'accepted';

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: user['avatar_url'] != null
                            ? NetworkImage(user['avatar_url'])
                            : null,
                        child: user['avatar_url'] == null
                            ? Text((user['name'] as String? ?? '?')[0].toUpperCase())
                            : null,
                      ),
                      title: Text(user['name'] ?? '',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: user['username'] != null
                          ? Text('@${user['username']}',
                              style: TextStyle(color: theme.colorScheme.primary))
                          : null,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isAccepted)
                            OutlinedButton(
                              onPressed: null,
                              style: OutlinedButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                                side: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.5)),
                              ),
                              child: const Text('Friends'),
                            )
                          else if (isPending)
                            FilledButton.tonal(
                              onPressed: null,
                              style: FilledButton.styleFrom(visualDensity: VisualDensity.compact),
                              child: const Text('Requested'),
                            )
                          else
                            FilledButton(
                              onPressed: () => _addFriend(user),
                              style: FilledButton.styleFrom(visualDensity: VisualDensity.compact),
                              child: const Text('Add'),
                            ),
                          const SizedBox(width: 4),
                          // Message button
                          IconButton(
                            icon: Icon(Icons.message_rounded,
                                color: theme.colorScheme.primary),
                            tooltip: 'Message',
                            onPressed: () => _startChat(user),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

