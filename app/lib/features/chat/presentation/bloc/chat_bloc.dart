import 'dart:async';
import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vibetalk/core/network/socket_service.dart';
import 'package:vibetalk/core/encryption/encryption_service.dart';
import 'package:vibetalk/core/storage/local_storage.dart';
import 'package:vibetalk/features/chat/data/repositories/chat_repository.dart';


// --- Events ---
abstract class ChatEvent {}

class ConnectSocketEvent extends ChatEvent {}
class DisconnectSocketEvent extends ChatEvent {}
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


// --- States ---
abstract class ChatState {}

class ChatInitial extends ChatState {}
class ChatLoading extends ChatState {}
class ChatLoaded extends ChatState {
  final List<Map<String, dynamic>> chats;
  final Map<String, List<Map<String, dynamic>>> messagesByRoom;
  final Map<String, bool> onlineUsers;
  final Map<String, bool> typingUsers;
  
  ChatLoaded({
    required this.chats, 
    required this.messagesByRoom,
    this.onlineUsers = const {},
    this.typingUsers = const {},
  });

  ChatLoaded copyWith({
    List<Map<String, dynamic>>? chats,
    Map<String, List<Map<String, dynamic>>>? messagesByRoom,
    Map<String, bool>? onlineUsers,
    Map<String, bool>? typingUsers,
  }) {
    return ChatLoaded(
      chats: chats ?? this.chats,
      messagesByRoom: messagesByRoom ?? this.messagesByRoom,
      onlineUsers: onlineUsers ?? this.onlineUsers,
      typingUsers: typingUsers ?? this.typingUsers,
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
  }


  void _onConnectSocket(ConnectSocketEvent event, Emitter<ChatState> emit) {
    if (!_socketService.isConnected) {
      _socketService.connect();
    }
    
    _socketService.on('receive_message', (data) {
      add(ReceiveMessageEvent(data));
      // Auto-send delivered status
      add(SendMessageStatusEvent(data['roomId'], data['id'], 'delivered'));
    });
    
    _socketService.on('user_online', (data) => add(UserPresenceEvent(data['userId'], true)));
    _socketService.on('user_offline', (data) => add(UserPresenceEvent(data['userId'], false)));
    _socketService.on('user_typing', (data) => add(UserTypingEvent(data['userId'], data['isTyping'])));
    _socketService.on('message_status', (data) => add(MessageStatusEvent(data['messageId'], data['status'])));
    
  }


  void _onDisconnectSocket(DisconnectSocketEvent event, Emitter<ChatState> emit) {
    _socketService.disconnect();
  }

  Future<void> _onLoadChats(LoadChatsEvent event, Emitter<ChatState> emit) async {
    try {
      if (state is! ChatLoaded) {
        emit(ChatLoading());
      }
      
      final chats = await _chatRepository.fetchChats();
      
      // Auto-join all socket rooms for these chats
      for (var chat in chats) {
        _socketService.joinRoom(chat['id']);
      }
      
      if (state is ChatLoaded) {
        final currentState = state as ChatLoaded;
        emit(currentState.copyWith(chats: chats));
      } else {
        emit(ChatLoaded(chats: chats, messagesByRoom: {}));
      }
    } catch (e) {
      emit(ChatError('Failed to load chats: $e'));
    }
  }

  Future<void> _onLoadMessages(LoadMessagesEvent event, Emitter<ChatState> emit) async {
    if (state is ChatLoaded) {
      final currentState = state as ChatLoaded;
      try {
        final rawMessages = await _chatRepository.fetchMessages(event.chatId);
        
        // Decrypt messages
        final decryptedMessages = rawMessages.map((msg) {
          String text = '🔒 [Encrypted]';
          try {
            final content = msg['content'];
            // If it's the mock JSON string we stored
            if (content.startsWith('{')) {
              final parsed = jsonDecode(content);
              text = _encryptionService.decryptMessage(parsed['ciphertext'], parsed['sessionKey'], parsed['iv']);
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
          };
        }).toList();


        final newMessagesByRoom = Map<String, List<Map<String, dynamic>>>.from(currentState.messagesByRoom);
        newMessagesByRoom[event.chatId] = decryptedMessages;
        emit(currentState.copyWith(messagesByRoom: newMessagesByRoom));
        
      } catch (e) {
        // Log error but don't crash UI
        print('Failed to load messages for ${event.chatId}: $e');
      }
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
      
      // Decrypt message (Mock flow)
      String decryptedText = event.message['text']; // Fallback
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
        'text': decryptedText, // Show decrypted content in UI
        'mediaUrl': event.message['mediaUrl'],
        'messageType': event.message['messageType'] ?? 'text',
      };


      final roomMessages = List<Map<String, dynamic>>.from(currentState.messagesByRoom[roomId] ?? []);
      roomMessages.add(processedMessage);
      
      final newMessagesByRoom = Map<String, List<Map<String, dynamic>>>.from(currentState.messagesByRoom);
      newMessagesByRoom[roomId] = roomMessages;
      
      emit(currentState.copyWith(messagesByRoom: newMessagesByRoom));
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

