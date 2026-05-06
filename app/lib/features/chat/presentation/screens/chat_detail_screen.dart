import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:vibetalk/config/service_locator.dart';
import 'package:vibetalk/core/storage/local_storage.dart';
import 'package:vibetalk/features/chat/data/repositories/media_repository.dart';
import 'package:vibetalk/features/chat/presentation/bloc/chat_bloc.dart';

class ChatDetailScreen extends StatefulWidget {
  final String chatId;

  const ChatDetailScreen({super.key, required this.chatId});

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();
  
  late String _currentUserId;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _currentUserId = sl<LocalStorageService>().getUserId() ?? '';
    context.read<ChatBloc>().add(LoadMessagesEvent(widget.chatId));
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage({String text = '', String? mediaUrl, String messageType = 'text'}) {
    if (text.trim().isEmpty && mediaUrl == null) return;
    
    context.read<ChatBloc>().add(
      SendMessageEvent(
        widget.chatId,
        text.trim(),
        mediaUrl: mediaUrl,
        messageType: messageType,
      ),
    );
    
    _messageController.clear();
    
    // Scroll to bottom
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _pickAndUploadMedia() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile == null) return;

    setState(() => _isUploading = true);

    try {
      final mediaRepo = sl<MediaRepository>();
      final url = await mediaRepo.uploadMedia(pickedFile.path);
      
      _sendMessage(mediaUrl: url, messageType: 'image');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to upload: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  String _formatTime(String isoTime) {
    try {
      final dt = DateTime.parse(isoTime).toLocal();
      final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
      final amPm = dt.hour >= 12 ? 'PM' : 'AM';
      final min = dt.minute.toString().padLeft(2, '0');
      return '$hour:$min $amPm';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: BlocBuilder<ChatBloc, ChatState>(
          builder: (context, state) {
            String chatName = 'Chat';
            if (state is ChatLoaded) {
              final chat = state.chats.firstWhere((c) => c['id'] == widget.chatId, orElse: () => {});
              if (chat.isNotEmpty) {
                if (chat['type'] == 'group') {
                  chatName = chat['group_name'] ?? 'Group';
                } else {
                  chatName = chat['other_participant']?['name'] ?? 'Unknown';
                }
              }
            }
            return Text(chatName, style: theme.textTheme.titleMedium);
          },
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: BlocBuilder<ChatBloc, ChatState>(
              builder: (context, state) {
                if (state is ChatLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (state is ChatLoaded) {
                  final messages = state.messagesByRoom[widget.chatId] ?? [];
                  
                  if (messages.isEmpty) {
                    return const Center(child: Text('No messages yet.'));
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      final isMe = message['senderId'] == _currentUserId;
                      
                      return Align(
                        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: isMe ? theme.colorScheme.primary : theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(20).copyWith(
                              bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(20),
                              bottomLeft: !isMe ? const Radius.circular(4) : const Radius.circular(20),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                            children: [
                              if (message['messageType'] == 'image' && message['mediaUrl'] != null)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8.0),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(
                                      message['mediaUrl'],
                                      width: 200,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              if ((message['text'] as String).isNotEmpty)
                                Text(
                                  message['text'],
                                  style: TextStyle(
                                    color: isMe ? theme.colorScheme.onPrimary : theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _formatTime(message['timestamp']),
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: (isMe ? theme.colorScheme.onPrimary : theme.colorScheme.onSurfaceVariant).withValues(alpha: 0.7),
                                    ),
                                  ),
                                  if (isMe) ...[
                                    const SizedBox(width: 4),
                                    Icon(
                                      message['status'] == 'read' 
                                        ? Icons.done_all_rounded 
                                        : (message['status'] == 'delivered' ? Icons.done_all_rounded : Icons.check_rounded),
                                      size: 14,
                                      color: message['status'] == 'read' 
                                        ? Colors.blue.shade200 
                                        : (isMe ? theme.colorScheme.onPrimary : theme.colorScheme.onSurfaceVariant).withValues(alpha: 0.7),
                                    ),
                                  ]
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          
          if (_isUploading)
            const LinearProgressIndicator(),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -2)),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.attach_file_rounded),
                    onPressed: _isUploading ? null : _pickAndUploadMedia,
                  ),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                        filled: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      onSubmitted: (_) => _sendMessage(text: _messageController.text),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: theme.colorScheme.primary,
                    child: IconButton(
                      icon: const Icon(Icons.send_rounded, color: Colors.white),
                      onPressed: () => _sendMessage(text: _messageController.text),
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
