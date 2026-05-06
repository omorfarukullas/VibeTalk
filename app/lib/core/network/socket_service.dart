import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:vibetalk/shared/constants/app_constants.dart';
import 'package:vibetalk/core/storage/local_storage.dart';
import 'package:vibetalk/config/service_locator.dart';

/// Real-time Socket.IO client for messaging, presence, and call signaling.
class SocketService {
  io.Socket? _socket;
  bool _isConnected = false;

  bool get isConnected => _isConnected;
  io.Socket? get socket => _socket;

  /// Connects to the Socket.IO server with JWT authentication.
  void connect() {
    if (_isConnected) return;

    final storage = sl<LocalStorageService>();
    final token = storage.getAccessToken();

    _socket = io.io(
      AppConstants.socketBaseUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setAuth({'token': token ?? ''})
          .enableReconnection()
          .setReconnectionAttempts(5)
          .setReconnectionDelay(2000)
          .build(),
    );


    _socket!.connect();

    _socket!.onConnect((_) {
      _isConnected = true;
      // ignore: avoid_print
      print('Socket.IO connected: ${_socket!.id}');
    });

    _socket!.onDisconnect((_) {
      _isConnected = false;
      // ignore: avoid_print
      print('Socket.IO disconnected');
    });

    _socket!.onConnectError((error) {
      _isConnected = false;
      // ignore: avoid_print
      print('Socket.IO connection error: $error');
    });

    _socket!.onError((error) {
      // ignore: avoid_print
      print('Socket.IO error: $error');
    });
  }

  /// Disconnects from the Socket.IO server.
  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _isConnected = false;
  }

  /// Emits an event to the server with optional data.
  void emit(String event, [dynamic data]) {
    if (_socket == null || !_isConnected) {
      // ignore: avoid_print
      print('Socket not connected. Cannot emit "$event".');
      return;
    }
    _socket!.emit(event, data);
  }

  /// Listens for an event from the server.
  void on(String event, Function(dynamic) callback) {
    _socket?.on(event, callback);
  }

  /// Removes a listener for a specific event.
  void off(String event) {
    _socket?.off(event);
  }

  /// Joins a chat room for real-time messaging.
  void joinRoom(String roomId) {
    emit('join_room', {'roomId': roomId});
  }

  /// Leaves a chat room.
  void leaveRoom(String roomId) {
    emit('leave_room', {'roomId': roomId});
  }

  /// Sends a message via Socket.IO for instant delivery.
  void sendMessage(Map<String, dynamic> messageData) {
    emit('send_message', messageData);
  }

  /// Sends typing indicator to a room.
  void sendTyping(String roomId, bool isTyping) {
    emit('typing', {'roomId': roomId, 'isTyping': isTyping});
  }

  /// Emits a call signaling event (offer, answer, ICE candidates).
  void sendCallSignal(String event, Map<String, dynamic> data) {
    emit(event, data);
  }
}
