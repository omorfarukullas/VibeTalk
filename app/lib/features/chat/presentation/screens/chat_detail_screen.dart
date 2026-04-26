import 'package:flutter/material.dart';

/// Individual chat conversation screen with message input.
class ChatDetailScreen extends StatelessWidget {
  final String chatId;

  const ChatDetailScreen({super.key, required this.chatId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Chat', style: theme.textTheme.titleMedium),
            Text(
              'online',
              style: theme.textTheme.bodySmall?.copyWith(
                color: const Color(0xFF4CAF50),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.call_rounded),
            onPressed: () {
              // TODO: Sprint 3 — Initiate voice call
            },
          ),
          IconButton(
            icon: const Icon(Icons.videocam_rounded),
            onPressed: () {
              // TODO: Sprint 3 — Initiate video call
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Message list area
          Expanded(
            child: Center(
              child: Text(
                'Chat ID: $chatId\nMessages will appear here',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          // Message input bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.attach_file_rounded),
                    onPressed: () {
                      // TODO: Sprint 2 — Open attachment picker
                    },
                  ),
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: theme.colorScheme.primary,
                    child: IconButton(
                      icon: const Icon(Icons.send_rounded, color: Colors.white),
                      onPressed: () {
                        // TODO: Sprint 2 — Send encrypted message
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
