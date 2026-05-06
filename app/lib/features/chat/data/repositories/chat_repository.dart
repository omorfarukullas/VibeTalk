import 'package:vibetalk/core/network/api_client.dart';

/// Repository handling all HTTP communication for the Chat feature.
class ChatRepository {
  final ApiClient _apiClient;

  ChatRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Fetches the authenticated user's active chats.
  Future<List<Map<String, dynamic>>> fetchChats() async {
    try {
      final response = await _apiClient.get('chats');
      final List<dynamic> data = response.data['data']['chats'];
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      throw Exception('Failed to load chats: $e');
    }
  }

  /// Fetches historical messages for a given chat room.
  Future<List<Map<String, dynamic>>> fetchMessages(
    String chatId, {
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await _apiClient.get(
        'messages',
        queryParameters: {
          'chatId': chatId,
          'limit': limit,
          'offset': offset,
        },
      );
      final List<dynamic> data = response.data['data']['messages'];
      // Reverse so oldest messages are at the top (DB returns DESC)
      return List<Map<String, dynamic>>.from(data).reversed.toList();
    } catch (e) {
      throw Exception('Failed to load messages: $e');
    }
  }

  /// Searches for registered users by name or email.
  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    try {
      final response = await _apiClient.get(
        'users/search',
        queryParameters: {'q': query},
      );
      final List<dynamic> data = response.data['data']['users'];
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      throw Exception('Failed to search users: $e');
    }
  }

  /// Creates a new direct chat or retrieves an existing one.
  Future<Map<String, dynamic>> createOrGetChat(String targetUserId) async {
    try {
      final response = await _apiClient.post(
        'chats',
        data: {'userId': targetUserId},
      );
      return response.data['data']['chat'];
    } catch (e) {
      throw Exception('Failed to create chat: $e');
    }
  }
}

