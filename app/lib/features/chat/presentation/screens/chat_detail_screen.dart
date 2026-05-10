import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:vibetalk/config/service_locator.dart';
import 'package:vibetalk/core/storage/local_storage.dart';
import 'package:vibetalk/features/chat/data/repositories/media_repository.dart';
import 'package:vibetalk/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

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
  bool _isComposing = false;
  bool _isEmojiVisible = false;
  final FocusNode _focusNode = FocusNode();

  late ChatBloc _chatBloc;

  @override
  void initState() {
    super.initState();
    _currentUserId = sl<LocalStorageService>().getUserId() ?? '';
    _chatBloc = context.read<ChatBloc>();
    _chatBloc.add(LoadMessagesEvent(widget.chatId));
    // Phase 2: Mark all existing messages as read when opening the chat
    _chatBloc.add(MarkMessagesAsReadEvent(widget.chatId));

    // Phase 2 pagination: load older messages when user scrolls to the top
    _scrollController.addListener(() {
      if (_scrollController.position.pixels <=
          _scrollController.position.minScrollExtent + 80) {
        _chatBloc.add(LoadMoreMessagesEvent(widget.chatId));
      }
    });

    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        setState(() {
          _isEmojiVisible = false;
        });
      }
    });
  }

  @override
  void dispose() {
    // Stop typing indicator when leaving
    _chatBloc.add(SendTypingEvent(widget.chatId, false));
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged(String text) {
    final wasComposing = _isComposing;
    final nowComposing = text.trim().isNotEmpty;
    if (wasComposing != nowComposing) {
      setState(() => _isComposing = nowComposing);
      // Phase 2: broadcast typing indicator
      context.read<ChatBloc>().add(SendTypingEvent(widget.chatId, nowComposing));
    }
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
    setState(() => _isComposing = false);
    // Stop typing after send
    context.read<ChatBloc>().add(SendTypingEvent(widget.chatId, false));

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
    final pickedFile =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile == null) return;

    setState(() => _isUploading = true);

    try {
      final mediaRepo = sl<MediaRepository>();
      final url = await mediaRepo.uploadMedia(pickedFile.path);
      _sendMessage(mediaUrl: url, messageType: 'image');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed to upload: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  Future<void> _pickAndUploadFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result == null || result.files.single.path == null) return;

    setState(() => _isUploading = true);

    try {
      final mediaRepo = sl<MediaRepository>();
      final url = await mediaRepo.uploadMedia(result.files.single.path!);
      _sendMessage(mediaUrl: url, messageType: 'file');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed to upload file: $e')));
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _showAttachmentMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.image_rounded, color: Colors.blue),
              title: const Text('Image'),
              onTap: () {
                Navigator.pop(context);
                _pickAndUploadMedia();
              },
            ),
            ListTile(
              leading: const Icon(Icons.insert_drive_file_rounded, color: Colors.orange),
              title: const Text('Document'),
              onTap: () {
                Navigator.pop(context);
                _pickAndUploadFile();
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(String isoTime) {
    try {
      final dt = DateTime.parse(isoTime).toLocal();
      final hour = dt.hour > 12
          ? dt.hour - 12
          : (dt.hour == 0 ? 12 : dt.hour);
      final amPm = dt.hour >= 12 ? 'PM' : 'AM';
      final min = dt.minute.toString().padLeft(2, '0');
      return '$hour:$min $amPm';
    } catch (_) {
      return '';
    }
  }

  String _formatTimeAgo(String? isoTime) {
    if (isoTime == null || isoTime.isEmpty) return '';
    try {
      final dt = DateTime.parse(isoTime).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return 'Active just now';
      if (diff.inHours < 1) return 'Active ${diff.inMinutes}m ago';
      if (diff.inDays < 1) return 'Active ${diff.inHours}h ago';
      if (diff.inDays < 7) return 'Active ${diff.inDays}d ago';
      return 'Active long ago';
    } catch (_) {
      return '';
    }
  }

  /// Build the double-tick status icon for sent messages.
  Widget _buildStatusIcon(String? status, Color color) {
    IconData icon;
    Color iconColor = color;
    if (status == 'read') {
      icon = Icons.done_all_rounded;
      iconColor = Colors.blue.shade200;
    } else if (status == 'delivered') {
      icon = Icons.done_all_rounded;
    } else {
      icon = Icons.check_rounded;
    }
    return Icon(icon, size: 14, color: iconColor);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: BlocBuilder<ChatBloc, ChatState>(
          builder: (context, state) {
            String chatName = 'Chat';
            String? otherUserId;
            String? lastSeen;
            bool isOnline = false;
            bool isTyping = false;

            if (state is ChatLoaded) {
              final chat = state.chats.firstWhere(
                (c) => c['id'] == widget.chatId,
                orElse: () => {},
              );
              if (chat.isNotEmpty) {
                if (chat['type'] == 'group') {
                  chatName = chat['group_name'] ?? 'Group';
                } else {
                  final other = chat['other_participant'] as Map<String, dynamic>?;
                  chatName = other?['name'] ?? 'Unknown';
                  otherUserId = other?['id'] as String?;
                  lastSeen = other?['last_seen'] as String?;
                }
              }
              if (otherUserId != null) {
                isOnline = state.onlineUsers[otherUserId] ?? false;
                isTyping = state.typingUsers[otherUserId] ?? false;
              }
            }

            return Row(
              children: [
                const SizedBox(width: 4),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(chatName, style: theme.textTheme.titleMedium),
                    // Phase 2: Typing / online subtitle
                    if (isTyping)
                      Text(
                        'typing...',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontStyle: FontStyle.italic,
                        ),
                      )
                    else if (isOnline)
                      Text(
                        'online',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF4CAF50),
                        ),
                      )
                    else if (lastSeen != null && _formatTimeAgo(lastSeen).isNotEmpty)
                      Text(
                        _formatTimeAgo(lastSeen),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                        ),
                      ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: BlocConsumer<ChatBloc, ChatState>(
              listenWhen: (prev, curr) {
                // When new messages arrive in this room, mark them as read
                if (curr is ChatLoaded) {
                  final msgs = curr.messagesByRoom[widget.chatId] ?? [];
                  final prevMsgs = prev is ChatLoaded
                      ? (prev.messagesByRoom[widget.chatId] ?? [])
                      : <Map<String, dynamic>>[];
                  return msgs.length > prevMsgs.length;
                }
                return false;
              },
              listener: (context, state) {
                // Phase 2: Auto-mark new incoming messages as read (chat is open)
                context.read<ChatBloc>().add(MarkMessagesAsReadEvent(widget.chatId));
                // Scroll to bottom on new message
                Future.delayed(const Duration(milliseconds: 100), () {
                  if (_scrollController.hasClients) {
                    _scrollController.animateTo(
                      _scrollController.position.maxScrollExtent,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    );
                  }
                });
              },
              builder: (context, state) {
                if (state is ChatLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is ChatLoaded) {
                  final messages = state.messagesByRoom[widget.chatId] ?? [];

                  if (messages.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.lock_outline_rounded,
                            size: 48,
                            color: theme.colorScheme.primary.withValues(alpha: 0.4),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Messages are encrypted end-to-end',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final isLoadingMore =
                      state.loadingMoreRooms.contains(widget.chatId);
                  final canLoadMore =
                      state.hasMoreMessages[widget.chatId] ?? false;

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length + (isLoadingMore || canLoadMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      // First item: loading indicator or "load more" hint at top
                      if (index == 0 && (isLoadingMore || canLoadMore)) {
                        if (isLoadingMore) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                          );
                        }
                        // Invisible spacer — scroll triggers load
                        return const SizedBox(height: 4);
                      }

                      // Adjust index for real messages
                      final msgIndex = (isLoadingMore || canLoadMore) ? index - 1 : index;
                      final message = messages[msgIndex];
                      final isMe = message['senderId'] == _currentUserId;

                      return Align(
                        alignment: isMe
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.75,
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: isMe
                                ? theme.colorScheme.primary
                                : theme.colorScheme.surfaceContainerHighest,
                            borderRadius:
                                BorderRadius.circular(20).copyWith(
                              bottomRight: isMe
                                  ? const Radius.circular(4)
                                  : const Radius.circular(20),
                              bottomLeft: !isMe
                                  ? const Radius.circular(4)
                                  : const Radius.circular(20),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: isMe
                                ? CrossAxisAlignment.end
                                : CrossAxisAlignment.start,
                            children: [
                              if (message['messageType'] == 'image' &&
                                  message['mediaUrl'] != null)
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
                              if ((message['messageType'] == 'file' || message['messageType'] == 'document') &&
                                  message['mediaUrl'] != null)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8.0),
                                  child: InkWell(
                                    onTap: () async {
                                      try {
                                        final url = Uri.parse(message['mediaUrl']);
                                        if (await canLaunchUrl(url)) {
                                          await launchUrl(url, mode: LaunchMode.externalApplication);
                                        }
                                      } catch (_) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Could not open document')),
                                          );
                                        }
                                      }
                                    },
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.insert_drive_file_rounded,
                                            color: isMe
                                                ? theme.colorScheme.onPrimary
                                                : theme.colorScheme.primary),
                                        const SizedBox(width: 8),
                                        const Text('Document',
                                            style: TextStyle(
                                                decoration: TextDecoration.underline)),
                                      ],
                                    ),
                                  ),
                                ),
                              if ((message['text'] as String? ?? '').trim().isNotEmpty)
                                Text(
                                  message['text'] as String,
                                  style: TextStyle(
                                    color: isMe
                                        ? theme.colorScheme.onPrimary
                                        : theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _formatTime(
                                        message['timestamp'] as String? ?? ''),
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: (isMe
                                              ? theme.colorScheme.onPrimary
                                              : theme
                                                  .colorScheme.onSurfaceVariant)
                                          .withValues(alpha: 0.7),
                                    ),
                                  ),
                                  if (isMe) ...[
                                    const SizedBox(width: 4),
                                    _buildStatusIcon(
                                      message['status'] as String?,
                                      (theme.colorScheme.onPrimary)
                                          .withValues(alpha: 0.7),
                                    ),
                                  ],
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

          if (_isUploading) const LinearProgressIndicator(),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
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
                    icon: Icon(_isEmojiVisible ? Icons.keyboard_rounded : Icons.emoji_emotions_outlined),
                    color: theme.colorScheme.primary,
                    onPressed: () {
                      if (_isEmojiVisible) {
                        _focusNode.requestFocus();
                      } else {
                        _focusNode.unfocus();
                        setState(() {
                          _isEmojiVisible = true;
                        });
                      }
                    },
                  ),
                  Expanded(
                    child: TextField(
                      focusNode: _focusNode,
                      controller: _messageController,
                      onChanged: _onTextChanged,
                      decoration: InputDecoration(
                        hintText: 'Message...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                      ),
                      onSubmitted: (_) =>
                          _sendMessage(text: _messageController.text),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.attach_file_rounded),
                    onPressed: _isUploading ? null : _showAttachmentMenu,
                  ),
                  const SizedBox(width: 4),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 8),
                    child: CircleAvatar(
                      backgroundColor: _isComposing
                          ? theme.colorScheme.primary
                          : theme.colorScheme.primary.withValues(alpha: 0.5),
                      child: IconButton(
                        icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                        onPressed: () =>
                            _sendMessage(text: _messageController.text),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isEmojiVisible)
            SizedBox(
              height: 250,
              child: EmojiPicker(
                textEditingController: _messageController,
                onEmojiSelected: (category, emoji) {
                  _onTextChanged(_messageController.text);
                },
                config: const Config(
                  bottomActionBarConfig: BottomActionBarConfig(
                    showBackspaceButton: false, 
                    showSearchViewButton: false
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
