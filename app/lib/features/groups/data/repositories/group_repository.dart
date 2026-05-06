import 'package:dio/dio.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:vibetalk/core/network/api_client.dart';

class GroupRepository {
  final ApiClient _apiClient;

  GroupRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Creates a new group chat
  Future<Map<String, dynamic>> createGroupChat(String name, List<String> participantIds) async {
    try {
      final response = await _apiClient.post(
        'groups',
        data: {
          'name': name,
          'participantIds': participantIds,
        },
      );
      return response.data['data']['chat'];
    } catch (e) {
      throw Exception('Failed to create group chat: $e');
    }
  }

  /// Adds a member to an existing group chat
  Future<void> addGroupMember(String groupId, String userId) async {
    try {
      await _apiClient.post(
        'groups/$groupId/members',
        data: {'userId': userId},
      );
    } catch (e) {
      throw Exception('Failed to add member to group: $e');
    }
  }

  /// Fetches all members of a group chat
  Future<List<Map<String, dynamic>>> getGroupMembers(String groupId) async {
    try {
      final response = await _apiClient.get('groups/$groupId/members');
      final List<dynamic> data = response.data['data']['members'];
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      throw Exception('Failed to load group members: $e');
    }
  }
}
