import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vibetalk/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:vibetalk/features/chat/presentation/screens/chat_detail_screen.dart';
import 'package:vibetalk/features/chat/presentation/screens/contact_search_screen.dart';
import 'package:vibetalk/features/groups/presentation/screens/create_group_screen.dart';

/// Chat list screen — shows all conversations.

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('VibeTalk'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.more_vert_rounded),
            onPressed: () {},
          ),
        ],
      ),
      body: BlocBuilder<ChatBloc, ChatState>(
        builder: (context, state) {
          if (state is ChatLoading || state is ChatInitial) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is ChatLoaded) {
            if (state.chats.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 80,
                      color: theme.colorScheme.primary.withValues(alpha: 0.4),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No conversations yet',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Start a new chat to begin messaging',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.separated(
              itemCount: state.chats.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final chat = state.chats[index];
                final isGroup = chat['type'] == 'group';
                
                String chatName;
                String? avatarUrl;
                
                if (isGroup) {
                  chatName = chat['group_name'] ?? 'Unnamed Group';
                  avatarUrl = chat['group_avatar'];
                } else {
                  final otherUser = chat['other_participant'] ?? {'name': 'Unknown'};
                  chatName = otherUser['name'] ?? 'Unknown';
                  avatarUrl = otherUser['avatar_url'];
                }
                
                // Get the real last message from local state if available
                final messages = state.messagesByRoom[chat['id']] ?? [];
                String lastMessageText = 'No messages yet';
                
                if (messages.isNotEmpty) {
                  lastMessageText = messages.last['text'];
                } else if (chat['last_message'] != null) {
                   lastMessageText = '🔒 Encrypted message'; // Because it's encrypted in DB
                }

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    radius: 24,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                    child: avatarUrl == null 
                      ? (isGroup
                          ? Icon(Icons.group, color: theme.colorScheme.onPrimaryContainer)
                          : Text(
                              chatName.isNotEmpty ? chatName[0].toUpperCase() : '?',
                              style: TextStyle(
                                color: theme.colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.bold,
                              ),
                            ))
                      : null,
                  ),
                  title: Text(

                    chatName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    lastMessageText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatDetailScreen(chatId: chat['id']),
                      ),
                    );
                  },
                );
              },
            );
          } else if (state is ChatError) {
            return Center(child: Text('Error: ${state.message}'));
          }
          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.small(
            heroTag: 'createGroup',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreateGroupScreen()),
              );
            },
            child: const Icon(Icons.group_add),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: 'newChat',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ContactSearchScreen()),
              );
            },
            child: const Icon(Icons.message),
          ),
        ],
      ),
    );
  }
}
