import 'package:dio/dio.dart';
import 'package:vibetalk/config/env.dart';
import 'package:vibetalk/core/errors/app_exception.dart';
import 'package:vibetalk/core/storage/local_storage.dart';
import 'package:vibetalk/config/service_locator.dart';

/// Production-grade Dio HTTP client.
///
/// Interceptors (in order):
///   1. [_AuthInterceptor]    — attaches Bearer token; auto-refreshes on 401
///   2. [_LoggingInterceptor] — logs requests/responses in debug builds
///   3. [_ErrorInterceptor]   — translates DioException → AppException hierarchy
class DioClient {
  late final Dio _dio;

  DioClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: Env.apiBaseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.addAll([
      _AuthInterceptor(_dio),
      _LoggingInterceptor(),
      _ErrorInterceptor(),
    ]);
  }

  Dio get dio => _dio;

  // ── HTTP helpers ──────────────────────────────────────────────────────

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) =>
      _dio.get<T>(path, queryParameters: queryParameters, options: options);

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Options? options,
  }) =>
      _dio.post<T>(path, data: data, options: options);

  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Options? options,
  }) =>
      _dio.put<T>(path, data: data, options: options);

  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Options? options,
  }) =>
      _dio.patch<T>(path, data: data, options: options);

  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Options? options,
  }) =>
      _dio.delete<T>(path, data: data, options: options);

  Future<Response> upload(
    String path, {
    required FormData formData,
    ProgressCallback? onSendProgress,
  }) =>
      _dio.post(
        path,
        data: formData,
        onSendProgress: onSendProgress,
        options: Options(contentType: 'multipart/form-data'),
      );
}

// ── Auth Interceptor ─────────────────────────────────────────────────────

/// Attaches the stored access token to every request.
/// On 401: attempts token refresh and retries the original request once.
/// On refresh failure: clears tokens and signals unauthenticated state.
class _AuthInterceptor extends QueuedInterceptor {
  final Dio _dio;

  _AuthInterceptor(this._dio);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Skip injecting token when registering (client sends Firebase token)
    if (options.path.contains('/auth/register') ||
        options.path.contains('/auth/refresh')) {
      return handler.next(options);
    }

    final storage = sl<LocalStorageService>();
    final token = storage.getAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode != 401) {
      return handler.next(err);
    }

    final storage = sl<LocalStorageService>();
    final refreshToken = storage.getRefreshToken();

    if (refreshToken == null || refreshToken.isEmpty) {
      await storage.clearAuth();
      return handler.next(err);
    }

    try {
      // Attempt token refresh
      final refreshDio = Dio(
        BaseOptions(
          baseUrl: Env.apiBaseUrl,
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

      final refreshResponse = await refreshDio.post(
        '/auth/refresh',
        data: {'refresh_token': refreshToken},
      );

      final body = refreshResponse.data as Map<String, dynamic>;
      final newAccess = body['data']['access_token'] as String;
      final newRefresh = body['data']['refresh_token'] as String;

      await storage.saveTokens(
        accessToken: newAccess,
        refreshToken: newRefresh,
      );

      // Retry original request with new token
      final retryOptions = err.requestOptions;
      retryOptions.headers['Authorization'] = 'Bearer $newAccess';

      final retryResponse = await _dio.fetch(retryOptions);
      return handler.resolve(retryResponse);
    } catch (_) {
      // Refresh failed — clear all auth data and propagate
      await storage.clearAuth();
      handler.next(err);
    }
  }
}

// ── Logging Interceptor ───────────────────────────────────────────────────

class _LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    assert(() {
      // ignore: avoid_print
      print('→ ${options.method} ${options.uri}');
      return true;
    }());
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    assert(() {
      // ignore: avoid_print
      print('← ${response.statusCode} ${response.requestOptions.uri}');
      return true;
    }());
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    assert(() {
      // ignore: avoid_print
      print('✗ ${err.response?.statusCode} ${err.requestOptions.uri}');
      return true;
    }());
    handler.next(err);
  }
}

// ── Error Interceptor ────────────────────────────────────────────────────

/// Converts [DioException] into typed [AppException] subclasses.
class _ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    AppException appException;

    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        appException = const NetworkException(
          'Connection timed out. Check your internet and try again.',
          code: 'TIMEOUT',
        );
        break;
      case DioExceptionType.connectionError:
        appException = const NetworkException(
          'No internet connection. Please check your network settings.',
        );
        break;
      case DioExceptionType.badResponse:
        final status = err.response?.statusCode ?? 0;
        final data = err.response?.data;
        final msg = data is Map
            ? (data['error']?['message'] as String?)
            : null;
        appException = ApiException(
          statusCode: status,
          message: msg ?? 'Request failed (HTTP $status).',
        );
        break;
      case DioExceptionType.cancel:
        appException = const AppException('Request cancelled.');
        break;
      default:
        appException = AppException(
          err.message ?? 'An unexpected error occurred.',
        );
    }

    handler.next(
      DioException(
        requestOptions: err.requestOptions,
        response: err.response,
        type: err.type,
        error: appException,
      ),
    );
  }
}
