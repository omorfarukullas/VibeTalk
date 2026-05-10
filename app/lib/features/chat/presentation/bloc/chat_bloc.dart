import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vibetalk/core/network/socket_service.dart';
import 'package:vibetalk/core/encryption/encryption_service.dart';
import 'package:vibetalk/core/storage/local_storage.dart';
import 'package:vibetalk/features/chat/data/repositories/chat_repository.dart';


// --- Events ---
abstract class ChatEvent {}

class ConnectSocketEvent extends ChatEvent {}
class DisconnectSocketEvent extends ChatEvent {}
class ClearChatEvent extends ChatEvent {}
class LoadChatsEvent extends ChatEvent {}
class LoadMessagesEvent extends ChatEvent {
  final String chatId;
  LoadMessagesEvent(this.chatId);
}
class SendMessageEvent extends ChatEvent {
  final String roomId;
  final String text;
  final String? mediaUrl;
  final String messageType;

  SendMessageEvent(this.roomId, this.text, {this.mediaUrl, this.messageType = 'text'});
}

class ReceiveMessageEvent extends ChatEvent {
  final Map<String, dynamic> message;
  ReceiveMessageEvent(this.message);
}
class UserPresenceEvent extends ChatEvent {
  final String userId;
  final bool isOnline;
  UserPresenceEvent(this.userId, this.isOnline);
}
class UserTypingEvent extends ChatEvent {
  final String userId;
  final bool isTyping;
  UserTypingEvent(this.userId, this.isTyping);
}
class SendTypingEvent extends ChatEvent {
  final String roomId;
  final bool isTyping;
  SendTypingEvent(this.roomId, this.isTyping);
}
class MessageStatusEvent extends ChatEvent {
  final String messageId;
  final String status; // 'delivered' or 'read'
  MessageStatusEvent(this.messageId, this.status);
}
class SendMessageStatusEvent extends ChatEvent {
  final String roomId;
  final String messageId;
  final String status;
  SendMessageStatusEvent(this.roomId, this.messageId, this.status);
}

/// Phase 2: Marks all received messages in a room as read.
/// Emits socket events and resets unread count for that room.
class MarkMessagesAsReadEvent extends ChatEvent {
  final String roomId;
  MarkMessagesAsReadEvent(this.roomId);
}

/// Phase 2: Loads the next page of older messages (pagination).
class LoadMoreMessagesEvent extends ChatEvent {
  final String chatId;
  LoadMoreMessagesEvent(this.chatId);
}


// --- States ---
abstract class ChatState {}

class ChatInitial extends ChatState {}
class ChatLoading extends ChatState {}
class ChatLoaded extends ChatState {
  final List<Map<String, dynamic>> chats;
  final Map<String, List<Map<String, dynamic>>> messagesByRoom;
  final Map<String, bool> onlineUsers;
  final Map<String, bool> typingUsers;
  /// roomId → unread count (Phase 2)
  final Map<String, int> unreadCounts;
  /// Phase 2 pagination: whether older messages can be loaded for each room
  final Map<String, bool> hasMoreMessages;
  /// Phase 2 pagination: current fetch offset per room
  final Map<String, int> messageOffsets;
  /// Rooms currently loading more (shows spinner at top of list)
  final Set<String> loadingMoreRooms;

  ChatLoaded({
    required this.chats,
    required this.messagesByRoom,
    this.onlineUsers = const {},
    this.typingUsers = const {},
    this.unreadCounts = const {},
    this.hasMoreMessages = const {},
    this.messageOffsets = const {},
    this.loadingMoreRooms = const {},
  });

  ChatLoaded copyWith({
    List<Map<String, dynamic>>? chats,
    Map<String, List<Map<String, dynamic>>>? messagesByRoom,
    Map<String, bool>? onlineUsers,
    Map<String, bool>? typingUsers,
    Map<String, int>? unreadCounts,
    Map<String, bool>? hasMoreMessages,
    Map<String, int>? messageOffsets,
    Set<String>? loadingMoreRooms,
  }) {
    return ChatLoaded(
      chats: chats ?? this.chats,
      messagesByRoom: messagesByRoom ?? this.messagesByRoom,
      onlineUsers: onlineUsers ?? this.onlineUsers,
      typingUsers: typingUsers ?? this.typingUsers,
      unreadCounts: unreadCounts ?? this.unreadCounts,
      hasMoreMessages: hasMoreMessages ?? this.hasMoreMessages,
      messageOffsets: messageOffsets ?? this.messageOffsets,
      loadingMoreRooms: loadingMoreRooms ?? this.loadingMoreRooms,
    );
  }
}

class ChatError extends ChatState {
  final String message;
  ChatError(this.message);
}

// --- BLoC ---
class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final SocketService _socketService;
  final EncryptionService _encryptionService;
  final LocalStorageService _localStorage;
  final ChatRepository _chatRepository;
  
  ChatBloc({
    required SocketService socketService,
    required EncryptionService encryptionService,
    required LocalStorageService localStorage,
    required ChatRepository chatRepository,
  })  : _socketService = socketService,
        _encryptionService = encryptionService,
        _localStorage = localStorage,
        _chatRepository = chatRepository,
        super(ChatInitial()) {

    
    on<ConnectSocketEvent>(_onConnectSocket);
    on<DisconnectSocketEvent>(_onDisconnectSocket);
    on<LoadChatsEvent>(_onLoadChats);
    on<LoadMessagesEvent>(_onLoadMessages);
    on<SendMessageEvent>(_onSendMessage);

    on<ReceiveMessageEvent>(_onReceiveMessage);
    on<UserPresenceEvent>(_onUserPresence);
    on<UserTypingEvent>(_onUserTyping);
    on<SendTypingEvent>(_onSendTyping);
    on<MessageStatusEvent>(_onMessageStatus);
    on<SendMessageStatusEvent>(_onSendMessageStatus);
    on<MarkMessagesAsReadEvent>(_onMarkMessagesAsRead); // Phase 2
    on<LoadMoreMessagesEvent>(_onLoadMoreMessages);     // Phase 2 pagination
    on<ClearChatEvent>(_onClearChat);
  }


  bool _socketListenersRegistered = false;

  void _onConnectSocket(ConnectSocketEvent event, Emitter<ChatState> emit) {
    if (!_socketService.isConnected) {
      _socketService.connect();
    }
    
    // Guard against re-registering listeners on hot restart / reconnect
    if (_socketListenersRegistered) return;
    _socketListenersRegistered = true;

    _socketService.on('receive_message', (data) {
      add(ReceiveMessageEvent(data));
      // Auto-send delivered status so the sender sees ✓✓
      add(SendMessageStatusEvent(data['roomId'], data['id'], 'delivered'));
    });
    
    _socketService.on('user_online', (data) => add(UserPresenceEvent(data['userId'], true)));
    _socketService.on('user_offline', (data) => add(UserPresenceEvent(data['userId'], false)));
    _socketService.on('user_typing', (data) => add(UserTypingEvent(data['userId'], data['isTyping'])));
    _socketService.on('message_status', (data) => add(MessageStatusEvent(data['messageId'], data['status'])));
  }


  void _onDisconnectSocket(DisconnectSocketEvent event, Emitter<ChatState> emit) {
    _socketService.disconnect();
    _socketListenersRegistered = false;
  }

  void _onClearChat(ClearChatEvent event, Emitter<ChatState> emit) {
    emit(ChatInitial());
  }

  Future<void> _onLoadChats(LoadChatsEvent event, Emitter<ChatState> emit) async {
    try {
      if (state is! ChatLoaded) {
        emit(ChatLoading());
      }
      
      final chats = await _chatRepository.fetchChats();
      final Map<String, int> initialUnreadCounts = {};
      
      // Auto-join all socket rooms for these chats
      for (var chat in chats) {
        _socketService.joinRoom(chat['id']);
        initialUnreadCounts[chat['id']] = int.tryParse(chat['unread_count']?.toString() ?? '0') ?? 0;
      }
      
      if (state is ChatLoaded) {
        final currentState = state as ChatLoaded;
        // Merge with existing so we don't lose optimistic updates that happened while loading
        final mergedCounts = Map<String, int>.from(currentState.unreadCounts);
        initialUnreadCounts.forEach((key, value) {
          mergedCounts[key] = value;
        });
        emit(currentState.copyWith(chats: chats, unreadCounts: mergedCounts));
      } else {
        emit(ChatLoaded(chats: chats, messagesByRoom: {}, unreadCounts: initialUnreadCounts));
      }
    } catch (e) {
      emit(ChatError('Failed to load chats: $e'));
    }
  }

  static const int _pageSize = 50;

  List<Map<String, dynamic>> _decryptMessages(
    List<Map<String, dynamic>> rawMessages,
  ) {
    return rawMessages.map((msg) {
      String text = '🔒 [Encrypted]';
      try {
        final content = msg['content'] as String? ?? '';
        if (content.startsWith('{')) {
          final parsed = jsonDecode(content) as Map<String, dynamic>;
          text = _encryptionService.decryptMessage(
            parsed['ciphertext'] as String,
            parsed['sessionKey'] as String,
            parsed['iv'] as String,
          );
          if (parsed['mediaUrl'] != null) {
            msg['mediaUrl'] = parsed['mediaUrl'];
          }
        }
      } catch (_) {}
      return {
        ...msg,
        'text': text,
        'roomId': msg['chat_id'],
        'senderId': msg['sender_id'],
        'messageType': msg['message_type'] ?? 'text',
        'status': msg['status'] ?? 'sent',
      };
    }).toList();
  }

  Future<void> _onLoadMessages(LoadMessagesEvent event, Emitter<ChatState> emit) async {
    if (state is ChatLoaded) {
      final currentState = state as ChatLoaded;
      try {
        final rawMessages = await _chatRepository.fetchMessages(
          event.chatId,
          limit: _pageSize,
          offset: 0,
        );
        final decryptedMessages = _decryptMessages(rawMessages);

        final newMessagesByRoom = Map<String, List<Map<String, dynamic>>>.from(
            currentState.messagesByRoom);
        newMessagesByRoom[event.chatId] = decryptedMessages;

        // Phase 2 pagination: record offset and whether more pages exist
        final newOffsets = Map<String, int>.from(currentState.messageOffsets);
        newOffsets[event.chatId] = _pageSize;
        final newHasMore = Map<String, bool>.from(currentState.hasMoreMessages);
        newHasMore[event.chatId] = rawMessages.length == _pageSize;

        emit(currentState.copyWith(
          messagesByRoom: newMessagesByRoom,
          messageOffsets: newOffsets,
          hasMoreMessages: newHasMore,
        ));
      } catch (e) {
        debugPrint('Failed to load messages for ${event.chatId}: $e');
      }
    }
  }

  /// Phase 2: Fetches the next page of older messages and prepends them.
  Future<void> _onLoadMoreMessages(
      LoadMoreMessagesEvent event, Emitter<ChatState> emit) async {
    if (state is! ChatLoaded) return;
    final currentState = state as ChatLoaded;

    // Guard: already loading or no more pages
    if (currentState.loadingMoreRooms.contains(event.chatId)) return;
    if (!(currentState.hasMoreMessages[event.chatId] ?? false)) return;

    final offset = currentState.messageOffsets[event.chatId] ?? _pageSize;

    // Show loading indicator at top
    final newLoading = Set<String>.from(currentState.loadingMoreRooms)
      ..add(event.chatId);
    emit(currentState.copyWith(loadingMoreRooms: newLoading));

    try {
      final rawMessages = await _chatRepository.fetchMessages(
        event.chatId,
        limit: _pageSize,
        offset: offset,
      );
      final older = _decryptMessages(rawMessages);

      final updatedState = state as ChatLoaded;
      final existing = updatedState.messagesByRoom[event.chatId] ?? [];
      final combined = [...older, ...existing]; // prepend older messages

      final newMessagesByRoom =
          Map<String, List<Map<String, dynamic>>>.from(updatedState.messagesByRoom);
      newMessagesByRoom[event.chatId] = combined;

      final newOffsets = Map<String, int>.from(updatedState.messageOffsets);
      newOffsets[event.chatId] = offset + _pageSize;

      final newHasMore = Map<String, bool>.from(updatedState.hasMoreMessages);
      newHasMore[event.chatId] = rawMessages.length == _pageSize;

      final doneLoading = Set<String>.from(updatedState.loadingMoreRooms)
        ..remove(event.chatId);

      emit(updatedState.copyWith(
        messagesByRoom: newMessagesByRoom,
        messageOffsets: newOffsets,
        hasMoreMessages: newHasMore,
        loadingMoreRooms: doneLoading,
      ));
    } catch (e) {
      final updatedState = state as ChatLoaded;
      final doneLoading = Set<String>.from(updatedState.loadingMoreRooms)
        ..remove(event.chatId);
      emit(updatedState.copyWith(loadingMoreRooms: doneLoading));
      debugPrint('Failed to load more messages for ${event.chatId}: $e');
    }
  }


  void _onSendMessage(SendMessageEvent event, Emitter<ChatState> emit) {
    if (state is ChatLoaded) {
      final currentState = state as ChatLoaded;
      
      // 1. Mock Encryption (Sprint 1.5 prep)
      // Generates a mock key for the session just to show the flow
      final sessionKey = _encryptionService.generateKey();
      final encrypted = _encryptionService.encryptMessage(event.text, sessionKey);
      
      final messageData = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(), // Temp ID
        'roomId': event.roomId,
        'senderId': _localStorage.getUserId() ?? 'me', // Would be actual ID
        'text': event.text,
        'mediaUrl': event.mediaUrl,
        'messageType': event.messageType,
        'ciphertext': encrypted['ciphertext'],
        'iv': encrypted['iv'],
        'sessionKey': sessionKey, // In reality, this key is encrypted with Signal Protocol
        'timestamp': DateTime.now().toIso8601String(),
      };


      // 2. Add to local state immediately (optimistic UI)
      final roomMessages = List<Map<String, dynamic>>.from(currentState.messagesByRoom[event.roomId] ?? []);
      roomMessages.add(messageData);
      
      final newMessagesByRoom = Map<String, List<Map<String, dynamic>>>.from(currentState.messagesByRoom);
      newMessagesByRoom[event.roomId] = roomMessages;
      
      emit(currentState.copyWith(messagesByRoom: newMessagesByRoom));

      // 3. Emit via socket
      _socketService.sendMessage(messageData);
    }
  }

  void _onReceiveMessage(ReceiveMessageEvent event, Emitter<ChatState> emit) {
    if (state is ChatLoaded) {
      final currentState = state as ChatLoaded;
      final roomId = event.message['roomId'];
      
      // Decrypt message (Mock flow — will be replaced with Signal in Sprint 2.2)
      String decryptedText = event.message['text'] ?? ''; // Fallback
      if (event.message['ciphertext'] != null && event.message['sessionKey'] != null) {
         try {
           decryptedText = _encryptionService.decryptMessage(
             event.message['ciphertext'], 
             event.message['sessionKey'], 
             event.message['iv'],
           );
         } catch (e) {
           decryptedText = '🔒 [Decryption Failed]';
         }
      }
      
      final processedMessage = {
        ...event.message,
        'text': decryptedText,
        'mediaUrl': event.message['mediaUrl'],
        'messageType': event.message['messageType'] ?? 'text',
        'status': 'delivered',
      };

      final roomMessages = List<Map<String, dynamic>>.from(currentState.messagesByRoom[roomId] ?? []);
      roomMessages.add(processedMessage);
      
      final newMessagesByRoom = Map<String, List<Map<String, dynamic>>>.from(currentState.messagesByRoom);
      newMessagesByRoom[roomId] = roomMessages;
      
      // Phase 2: Increment unread count for rooms we are not actively viewing
      final newUnreadCounts = Map<String, int>.from(currentState.unreadCounts);
      newUnreadCounts[roomId] = (newUnreadCounts[roomId] ?? 0) + 1;
      
      emit(currentState.copyWith(
        messagesByRoom: newMessagesByRoom,
        unreadCounts: newUnreadCounts,
      ));
    }
  }

  /// Phase 2: Marks all received messages in a room as read.
  /// Uses both REST (guaranteed) and socket (real-time) for reliability.
  Future<void> _onMarkMessagesAsRead(
      MarkMessagesAsReadEvent event, Emitter<ChatState> emit) async {
    if (state is! ChatLoaded) return;
    final currentState = state as ChatLoaded;
    final messages = currentState.messagesByRoom[event.roomId] ?? [];
    final myUserId = _localStorage.getUserId();

    // Collect IDs of messages from others that are not yet read
    final unreadIds = messages
        .where((msg) =>
            msg['senderId'] != myUserId && msg['status'] != 'read')
        .map((msg) => msg['id'] as String)
        .toList();

    if (unreadIds.isEmpty) return;

    // 1. Update local state immediately (optimistic)
    final newUnreadCounts = Map<String, int>.from(currentState.unreadCounts);
    newUnreadCounts[event.roomId] = 0;
    emit(currentState.copyWith(unreadCounts: newUnreadCounts));

    // 2. Notify sender(s) via socket (low latency)
    for (final msgId in unreadIds) {
      add(SendMessageStatusEvent(event.roomId, msgId, 'read'));
    }

    // 3. Persist via REST (reliable — survives socket disconnections)
    try {
      await _chatRepository.markMessagesRead(event.roomId, unreadIds);
    } catch (e) {
      debugPrint('markMessagesRead HTTP failed (socket fallback active): $e');
    }
  }

  void _onUserPresence(UserPresenceEvent event, Emitter<ChatState> emit) {
    if (state is ChatLoaded) {
      final currentState = state as ChatLoaded;
      final newOnlineUsers = Map<String, bool>.from(currentState.onlineUsers);
      newOnlineUsers[event.userId] = event.isOnline;
      emit(currentState.copyWith(onlineUsers: newOnlineUsers));
    }
  }

  void _onUserTyping(UserTypingEvent event, Emitter<ChatState> emit) {
    if (state is ChatLoaded) {
      final currentState = state as ChatLoaded;
      final newTypingUsers = Map<String, bool>.from(currentState.typingUsers);
      newTypingUsers[event.userId] = event.isTyping;
      emit(currentState.copyWith(typingUsers: newTypingUsers));
    }
  }

  void _onSendTyping(SendTypingEvent event, Emitter<ChatState> emit) {
    _socketService.sendTyping(event.roomId, event.isTyping);
  }

  void _onMessageStatus(MessageStatusEvent event, Emitter<ChatState> emit) {
    if (state is ChatLoaded) {
      final currentState = state as ChatLoaded;
      
      // Deep copy to update the specific message status
      final newMessagesByRoom = Map<String, List<Map<String, dynamic>>>.from(currentState.messagesByRoom);
      
      for (final entry in newMessagesByRoom.entries) {
        final messages = List<Map<String, dynamic>>.from(entry.value);
        final msgIndex = messages.indexWhere((m) => m['id'] == event.messageId);
        
        if (msgIndex != -1) {
          final updatedMsg = Map<String, dynamic>.from(messages[msgIndex]);
          updatedMsg['status'] = event.status;
          messages[msgIndex] = updatedMsg;
          newMessagesByRoom[entry.key] = messages;
          break; // Found and updated
        }
      }
      
      emit(currentState.copyWith(messagesByRoom: newMessagesByRoom));
    }
  }

  void _onSendMessageStatus(SendMessageStatusEvent event, Emitter<ChatState> emit) {
    _socketService.emit('message_${event.status}', { // 'message_delivered' or 'message_read'
      'messageId': event.messageId,
      'roomId': event.roomId,
    });
  }
}

