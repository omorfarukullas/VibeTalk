import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vibetalk/features/chat/data/repositories/chat_repository.dart';
import 'package:vibetalk/config/service_locator.dart';
import 'package:vibetalk/features/chat/presentation/screens/chat_detail_screen.dart';
import 'package:vibetalk/features/chat/presentation/bloc/chat_bloc.dart';

class ContactSearchScreen extends StatefulWidget {
  const ContactSearchScreen({super.key});

  @override
  State<ContactSearchScreen> createState() => _ContactSearchScreenState();
}

class _ContactSearchScreenState extends State<ContactSearchScreen> {
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isLoading = false;

  void _searchUsers(String query) async {
    if (query.trim().length < 2) {
      setState(() => _searchResults = []);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final repo = sl<ChatRepository>();
      final results = await repo.searchUsers(query);
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
      // Show loading overlay
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final repo = sl<ChatRepository>();
      final chat = await repo.createOrGetChat(user['id']);
      
      // Refresh chats in BLoC
      if (mounted) {
        context.read<ChatBloc>().add(LoadChatsEvent());
        
        Navigator.pop(context); // Close loading overlay
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ChatDetailScreen(chatId: chat['id']),
          ),
        );
      }
    } catch (e) {
      Navigator.pop(context); // Close loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to start chat: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search users by name or email...',
            border: InputBorder.none,
          ),
          onChanged: _searchUsers,
        ),
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : _searchResults.isEmpty 
              ? Center(
                  child: Text(
                    _searchController.text.isEmpty 
                        ? 'Type to search contacts' 
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
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: user['avatar_url'] != null 
                            ? NetworkImage(user['avatar_url']) 
                            : null,
                        child: user['avatar_url'] == null 
                            ? Text(user['name'][0].toUpperCase()) 
                            : null,
                      ),
                      title: Text(user['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(user['email']),
                      onTap: () => _startChat(user),
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
