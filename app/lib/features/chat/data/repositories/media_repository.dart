import 'package:dio/dio.dart';
import 'package:vibetalk/core/network/api_client.dart';

class MediaRepository {
  final ApiClient _apiClient;

  MediaRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Uploads a file (image, video, document) and returns its public URL.
  Future<String> uploadMedia(String filePath) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath),
      });
      final response = await _apiClient.upload(
        'media/upload',
        formData: formData,
      );
      return response.data['data']['url'];
    } catch (e) {
      throw Exception('Failed to upload media: $e');
    }
  }
}
