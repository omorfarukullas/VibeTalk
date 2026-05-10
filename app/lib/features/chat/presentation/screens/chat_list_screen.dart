import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vibetalk/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:vibetalk/features/chat/presentation/screens/chat_detail_screen.dart';
import 'package:vibetalk/features/chat/presentation/screens/contact_search_screen.dart';
import 'package:vibetalk/features/groups/presentation/screens/create_group_screen.dart';
import 'package:vibetalk/shared/themes/vibetalk_theme_extension.dart';

/// Chat list screen — shows all conversations with presence & unread badges.
/// Phase 2: added online dots, typing subtitles, and unread count badges.
class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  @override
  void initState() {
    super.initState();
    // Use post-frame callback to safely read context after mount
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatBloc>().add(ConnectSocketEvent());
      context.read<ChatBloc>().add(LoadChatsEvent());
    });
  }

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
                final chatId = chat['id'] as String;
                final isGroup = chat['type'] == 'group';

                String chatName;
                String? avatarUrl;
                String? otherUserId;

                if (isGroup) {
                  chatName = chat['group_name'] ?? 'Unnamed Group';
                  avatarUrl = chat['group_avatar'];
                } else {
                  final otherUser = chat['other_participant'] ?? {'name': 'Unknown'};
                  chatName = otherUser['name'] ?? 'Unknown';
                  avatarUrl = otherUser['avatar_url'];
                  otherUserId = otherUser['id'] as String?;
                }

                // Phase 2: presence & typing state
                final isOnline = otherUserId != null
                    ? (state.onlineUsers[otherUserId] ?? false)
                    : false;
                final isTyping = otherUserId != null
                    ? (state.typingUsers[otherUserId] ?? false)
                    : false;
                final unreadCount = state.unreadCounts[chatId] ?? 0;

                // Subtitle text
                final messages = state.messagesByRoom[chatId] ?? [];
                String lastMessageText;
                if (isTyping) {
                  lastMessageText = 'Typing...';
                } else if (messages.isNotEmpty) {
                  lastMessageText = messages.last['text'] as String? ?? '';
                } else if (chat['last_message'] != null) {
                  lastMessageText = '🔒 Encrypted message';
                } else {
                  lastMessageText = 'No messages yet';
                }

                final themeExt = theme.extension<VibeTalkThemeExtension>();

                return ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: theme.colorScheme.primaryContainer,
                        backgroundImage:
                            avatarUrl != null ? NetworkImage(avatarUrl) : null,
                        child: avatarUrl == null
                            ? (isGroup
                                ? Icon(Icons.group,
                                    color: theme.colorScheme.onPrimaryContainer)
                                : Text(
                                    chatName.isNotEmpty
                                        ? chatName[0].toUpperCase()
                                        : '?',
                                    style: TextStyle(
                                      color:
                                          theme.colorScheme.onPrimaryContainer,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ))
                            : null,
                      ),
                      // Phase 2: Online presence dot
                      if (!isGroup && isOnline)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: themeExt?.onlineIndicator ??
                                  const Color(0xFF4CAF50),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: theme.colorScheme.surface,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  title: Text(
                    chatName,
                    style: TextStyle(
                      fontWeight: unreadCount > 0
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  subtitle: Text(
                    lastMessageText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isTyping
                          ? theme.colorScheme.primary
                          : (unreadCount > 0
                              ? theme.colorScheme.onSurface
                              : theme.colorScheme.onSurface
                                  .withValues(alpha: 0.6)),
                      fontStyle: isTyping ? FontStyle.italic : FontStyle.normal,
                      fontWeight: unreadCount > 0
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Phase 2: Unread count badge
                      if (unreadCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: themeExt?.unreadBadge ??
                                theme.colorScheme.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            unreadCount > 99 ? '99+' : '$unreadCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      else
                        const Icon(Icons.chevron_right_rounded,
                            color: Colors.grey),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatDetailScreen(chatId: chatId),
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
