import 'package:dio/dio.dart';
import 'package:vibetalk/shared/constants/app_constants.dart';
import 'package:vibetalk/core/storage/local_storage.dart';
import 'package:vibetalk/config/service_locator.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:vibetalk/core/errors/app_exception.dart';



/// Dio-based HTTP client with interceptors for authentication,
/// logging, and error transformation.
class ApiClient {
  late final Dio _dio;

  ApiClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.apiBaseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.addAll([
      _LoggingInterceptor(),
      _AuthInterceptor(),
      _ErrorInterceptor(),
    ]);

  }

  Dio get dio => _dio;

  // ── HTTP Methods ────────────────────────────────────────────────────

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _dio.get<T>(path, queryParameters: queryParameters, options: options);
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _dio.post<T>(path,
        data: data, queryParameters: queryParameters, options: options);
  }

  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _dio.put<T>(path,
        data: data, queryParameters: queryParameters, options: options);
  }

  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _dio.patch<T>(path,
        data: data, queryParameters: queryParameters, options: options);
  }

  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _dio.delete<T>(path,
        data: data, queryParameters: queryParameters, options: options);
  }

  Future<Response> upload(
    String path, {
    required FormData formData,
    ProgressCallback? onSendProgress,
  }) {
    return _dio.post(
      path,
      data: formData,
      onSendProgress: onSendProgress,
      // Setting contentType property (not headers map) allows Dio to append boundary
      options: Options(contentType: 'multipart/form-data'),
    );
  }
}

// ── Interceptors ──────────────────────────────────────────────────────

/// Attaches JWT access token to every outgoing request.
/// Reads synchronously from Hive to avoid async-void issues with Dio.
class _AuthInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Synchronous read — Hive supports this without async
    final token = sl<LocalStorageService>().getAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }


  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      final secureStorage = sl<FlutterSecureStorage>();
      final refreshToken = await secureStorage.read(key: 'refresh_token');

      if (refreshToken != null && refreshToken.isNotEmpty) {
        try {
          // Use a plain Dio instance (no interceptors) to avoid infinite loops
          final plainDio = Dio(BaseOptions(baseUrl: AppConstants.apiBaseUrl));
          final refreshResponse = await plainDio.post(
            'auth/refresh',
            data: {'refreshToken': refreshToken},
          );

          final newAccessToken = refreshResponse.data['accessToken'];
          final newRefreshToken = refreshResponse.data['refreshToken'];

          if (newAccessToken != null) {
            await secureStorage.write(key: 'access_token', value: newAccessToken);
            // Also update Hive for synchronous reads in the interceptor
            await sl<LocalStorageService>().saveAccessToken(newAccessToken);
            if (newRefreshToken != null) {
              await secureStorage.write(key: 'refresh_token', value: newRefreshToken);
            }

            final retryOptions = err.requestOptions;
            retryOptions.headers['Authorization'] = 'Bearer $newAccessToken';
            final retryResponse = await plainDio.fetch(retryOptions);
            return handler.resolve(retryResponse);
          }

        } catch (_) {
          // Refresh failed — fall through to propagate the 401
        }
      }
    }
    handler.next(err);
  }


}

/// Logs request & response details in debug mode.
class _LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // ignore: avoid_print
    print('→ ${options.method} ${options.uri}');
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    // ignore: avoid_print
    print('← ${response.statusCode} ${response.requestOptions.uri}');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // ignore: avoid_print
    print('✗ ${err.response?.statusCode} ${err.requestOptions.uri}');
    handler.next(err);
  }
}

/// Transforms Dio errors into application-specific exceptions.
/// Skips 401 errors — those are handled by _AuthInterceptor (token refresh).
class _ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // 401 is handled by _AuthInterceptor (token refresh + retry). Let it pass.
    if (err.response?.statusCode == 401) {
      return handler.next(err);
    }
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        throw NetworkException('Connection timed out. Please try again.');
      case DioExceptionType.connectionError:
        throw NetworkException(
            'No internet connection. Check your network settings.');
      case DioExceptionType.badResponse:
        final statusCode = err.response?.statusCode ?? 0;
        final data = err.response?.data;
        
        String? message;
        if (data is Map) {
          if (data['error'] is Map && data['error']['message'] != null) {
            message = data['error']['message'] as String;
          } else if (data['message'] != null) {
            message = data['message'] as String;
          }
        }
        
        throw ApiException(
          statusCode: statusCode,
          message: message ?? 'Request failed with status $statusCode',
        );
      default:
        throw AppException('An unexpected error occurred.');
    }
  }
}

