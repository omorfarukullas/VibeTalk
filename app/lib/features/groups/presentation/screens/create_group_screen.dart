import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vibetalk/config/service_locator.dart';
import 'package:vibetalk/features/chat/data/repositories/chat_repository.dart';
import 'package:vibetalk/features/groups/data/repositories/group_repository.dart';
import 'package:vibetalk/features/chat/presentation/screens/chat_detail_screen.dart';
import 'package:vibetalk/features/chat/presentation/bloc/chat_bloc.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _nameController = TextEditingController();
  final _searchController = TextEditingController();
  
  List<Map<String, dynamic>> _searchResults = [];
  final Set<Map<String, dynamic>> _selectedMembers = {};
  
  bool _isSearching = false;
  bool _isCreating = false;

  @override
  void dispose() {
    _nameController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _searchUsers(String query) async {
    if (query.trim().length < 2) {
      setState(() => _searchResults = []);
      return;
    }

    setState(() => _isSearching = true);
    try {
      final repo = sl<ChatRepository>();
      final results = await repo.searchUsers(query);
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      setState(() => _isSearching = false);
    }
  }

  void _toggleMember(Map<String, dynamic> user) {
    setState(() {
      if (_selectedMembers.contains(user)) {
        _selectedMembers.remove(user);
      } else {
        _selectedMembers.add(user);
      }
    });
  }

  void _createGroup() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Group name is required')));
      return;
    }
    if (_selectedMembers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select at least one member')));
      return;
    }

    setState(() => _isCreating = true);
    try {
      final repo = sl<GroupRepository>();
      final participantIds = _selectedMembers.map((m) => m['id'] as String).toList();
      
      final chat = await repo.createGroupChat(name, participantIds);
      
      if (mounted) {
        context.read<ChatBloc>().add(LoadChatsEvent());
        Navigator.pop(context); // Close create screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => ChatDetailScreen(chatId: chat['id'])),
        );
      }
    } catch (e) {
      setState(() => _isCreating = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to create group: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Group'),
        actions: [
          if (_isCreating)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else
            TextButton(
              onPressed: _selectedMembers.isNotEmpty && _nameController.text.trim().isNotEmpty ? _createGroup : null,
              child: const Text('Create'),
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Group Name',
                prefixIcon: Icon(Icons.group_outlined),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          
          if (_selectedMembers.isNotEmpty) ...[
            SizedBox(
              height: 90,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _selectedMembers.length,
                itemBuilder: (context, index) {
                  final user = _selectedMembers.elementAt(index);
                  return Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: Column(
                      children: [
                        Stack(
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundImage: user['avatar_url'] != null ? NetworkImage(user['avatar_url']) : null,
                              child: user['avatar_url'] == null ? Text(user['name'][0].toUpperCase()) : null,
                            ),
                            Positioned(
                              right: 0,
                              top: 0,
                              child: GestureDetector(
                                onTap: () => _toggleMember(user),
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                  child: const Icon(Icons.close, size: 14, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(user['name'].split(' ')[0], style: theme.textTheme.bodySmall),
                      ],
                    ),
                  );
                },
              ),
            ),
            const Divider(),
          ],

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search contacts to add...',
                border: InputBorder.none,
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: _searchUsers,
            ),
          ),
          const Divider(),

          Expanded(
            child: _isSearching
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      final user = _searchResults[index];
                      final isSelected = _selectedMembers.contains(user);
                      
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: user['avatar_url'] != null ? NetworkImage(user['avatar_url']) : null,
                          child: user['avatar_url'] == null ? Text(user['name'][0].toUpperCase()) : null,
                        ),
                        title: Text(user['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(user['email']),
                        trailing: isSelected 
                            ? Icon(Icons.check_circle, color: theme.colorScheme.primary)
                            : const Icon(Icons.circle_outlined, color: Colors.grey),
                        onTap: () => _toggleMember(user),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

