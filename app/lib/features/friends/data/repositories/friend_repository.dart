import 'package:vibetalk/core/network/api_client.dart';

/// Repository handling all HTTP calls for the Friends feature.
class FriendRepository {
  final ApiClient _apiClient;

  FriendRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Sends a friend request to [addresseeId].
  Future<Map<String, dynamic>> sendRequest(String addresseeId) async {
    final response = await _apiClient.post(
      'friends/request',
      data: {'addresseeId': addresseeId},
    );
    return response.data as Map<String, dynamic>;
  }

  /// Gets all pending incoming friend requests.
  Future<List<Map<String, dynamic>>> getPendingRequests() async {
    final response = await _apiClient.get('friends/requests');
    final List<dynamic> data = response.data['data']['requests'];
    return List<Map<String, dynamic>>.from(data);
  }

  /// Accepts or declines a request by [requestId].
  /// [action] must be 'accept' or 'decline'.
  Future<void> respondToRequest(String requestId, String action) async {
    await _apiClient.put(
      'friends/requests/$requestId',
      data: {'action': action},
    );
  }

  /// Gets the full accepted friends list.
  Future<List<Map<String, dynamic>>> getFriends() async {
    final response = await _apiClient.get('friends');
    final List<dynamic> data = response.data['data']['friends'];
    return List<Map<String, dynamic>>.from(data);
  }

  /// Removes a friend by [friendId].
  Future<void> removeFriend(String friendId) async {
    await _apiClient.delete('friends/$friendId');
  }

  /// Checks the friendship status with [userId].
  Future<Map<String, dynamic>?> getFriendStatus(String userId) async {
    final response = await _apiClient.get('friends/status/$userId');
    return response.data['data'] as Map<String, dynamic>?;
  }
}
