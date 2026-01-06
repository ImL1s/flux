import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flux_vm/flux_vm.dart';

/// Enhanced HTTP client module for Flux using Dio
///
/// Features:
/// - Configurable base URL and timeouts
/// - Global headers
/// - Request cancellation
/// - Interceptors for logging and error handling
///
/// Usage in Flux:
/// ```
/// // Configure client
/// http.setBaseUrl("https://api.example.com");
/// http.setTimeout(30000);
/// http.setHeader("Authorization", "Bearer token");
///
/// // Make requests
/// var res = await http.get("/users");
/// var res = await http.post("/users", { "body": { "name": "John" } });
/// ```
class HttpModule extends FluxModule {
  late Dio _dio;
  final Map<String, CancelToken> _cancelTokens = {};

  HttpModule() : super('http') {
    _dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ));

    // Add logging interceptor
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      logPrint: (obj) {
        // Silent by default, can be enabled via setLogEnabled
      },
    ));

    _registerFunctions();
  }

  void _registerFunctions() {
    // Configuration
    register('setBaseUrl', NativeFunction('http.setBaseUrl', 1, _setBaseUrl));
    register('setTimeout', NativeFunction('http.setTimeout', 1, _setTimeout));
    register('setHeader', NativeFunction('http.setHeader', 2, _setHeader));
    register('removeHeader', NativeFunction('http.removeHeader', 1, _removeHeader));

    // HTTP Methods
    register('get', AsyncNativeFunction('http.get', -1, _get));
    register('post', AsyncNativeFunction('http.post', -1, _post));
    register('put', AsyncNativeFunction('http.put', -1, _put));
    register('patch', AsyncNativeFunction('http.patch', -1, _patch));
    register('delete', AsyncNativeFunction('http.delete', -1, _delete));

    // Request Control
    register('cancel', NativeFunction('http.cancel', 1, _cancel));
    register('cancelAll', NativeFunction('http.cancelAll', 0, _cancelAll));
  }

  // Configuration Methods
  Object? _setBaseUrl(List<Object?> args) {
    final url = args[0] as String;
    _dio.options.baseUrl = url;
    return null;
  }

  Object? _setTimeout(List<Object?> args) {
    final ms = (args[0] as num).toInt();
    _dio.options.connectTimeout = Duration(milliseconds: ms);
    _dio.options.receiveTimeout = Duration(milliseconds: ms);
    return null;
  }

  Object? _setHeader(List<Object?> args) {
    final key = args[0] as String;
    final value = args[1] as String;
    _dio.options.headers[key] = value;
    return null;
  }

  Object? _removeHeader(List<Object?> args) {
    final key = args[0] as String;
    _dio.options.headers.remove(key);
    return null;
  }

  // HTTP Methods
  Future<Object?> _get(List<Object?> args) async {
    final url = args[0] as String;
    final options = args.length > 1 ? args[1] as Map? : null;
    final requestId = options?['requestId'] as String?;

    try {
      final cancelToken = _getCancelToken(requestId);
      final response = await _dio.get(
        url,
        queryParameters: _extractQueryParams(options),
        cancelToken: cancelToken,
      );
      return _formatResponse(response);
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  Future<Object?> _post(List<Object?> args) async {
    final url = args[0] as String;
    final options = args.length > 1 ? args[1] as Map? : null;
    final requestId = options?['requestId'] as String?;

    try {
      final cancelToken = _getCancelToken(requestId);
      final response = await _dio.post(
        url,
        data: options?['body'],
        queryParameters: _extractQueryParams(options),
        options: _extractOptions(options),
        cancelToken: cancelToken,
      );
      return _formatResponse(response);
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  Future<Object?> _put(List<Object?> args) async {
    final url = args[0] as String;
    final options = args.length > 1 ? args[1] as Map? : null;
    final requestId = options?['requestId'] as String?;

    try {
      final cancelToken = _getCancelToken(requestId);
      final response = await _dio.put(
        url,
        data: options?['body'],
        queryParameters: _extractQueryParams(options),
        options: _extractOptions(options),
        cancelToken: cancelToken,
      );
      return _formatResponse(response);
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  Future<Object?> _patch(List<Object?> args) async {
    final url = args[0] as String;
    final options = args.length > 1 ? args[1] as Map? : null;
    final requestId = options?['requestId'] as String?;

    try {
      final cancelToken = _getCancelToken(requestId);
      final response = await _dio.patch(
        url,
        data: options?['body'],
        queryParameters: _extractQueryParams(options),
        options: _extractOptions(options),
        cancelToken: cancelToken,
      );
      return _formatResponse(response);
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  Future<Object?> _delete(List<Object?> args) async {
    final url = args[0] as String;
    final options = args.length > 1 ? args[1] as Map? : null;
    final requestId = options?['requestId'] as String?;

    try {
      final cancelToken = _getCancelToken(requestId);
      final response = await _dio.delete(
        url,
        data: options?['body'],
        queryParameters: _extractQueryParams(options),
        cancelToken: cancelToken,
      );
      return _formatResponse(response);
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  // Request Control
  Object? _cancel(List<Object?> args) {
    final requestId = args[0] as String;
    final token = _cancelTokens[requestId];
    if (token != null && !token.isCancelled) {
      token.cancel('Request cancelled by user');
      _cancelTokens.remove(requestId);
    }
    return null;
  }

  Object? _cancelAll(List<Object?> args) {
    for (final token in _cancelTokens.values) {
      if (!token.isCancelled) {
        token.cancel('All requests cancelled');
      }
    }
    _cancelTokens.clear();
    return null;
  }

  // Helper Methods
  CancelToken? _getCancelToken(String? requestId) {
    if (requestId == null) return null;
    final token = CancelToken();
    _cancelTokens[requestId] = token;
    return token;
  }

  Map<String, dynamic>? _extractQueryParams(Map? options) {
    if (options == null) return null;
    final params = options['params'] ?? options['queryParams'];
    if (params is Map) {
      return params.cast<String, dynamic>();
    }
    return null;
  }

  Options? _extractOptions(Map? options) {
    if (options == null) return null;
    final headers = options['headers'] as Map?;
    if (headers != null) {
      return Options(headers: headers.cast<String, dynamic>());
    }
    return null;
  }

  Map<String, dynamic> _formatResponse(Response response) {
    return {
      'statusCode': response.statusCode,
      'body': response.data,
      'headers': response.headers.map,
      'ok': response.statusCode != null && 
            response.statusCode! >= 200 && 
            response.statusCode! < 300,
    };
  }

  Map<String, dynamic> _handleError(DioException e) {
    String errorType;
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        errorType = 'connectionTimeout';
        break;
      case DioExceptionType.sendTimeout:
        errorType = 'sendTimeout';
        break;
      case DioExceptionType.receiveTimeout:
        errorType = 'receiveTimeout';
        break;
      case DioExceptionType.badResponse:
        errorType = 'badResponse';
        break;
      case DioExceptionType.cancel:
        errorType = 'cancelled';
        break;
      case DioExceptionType.connectionError:
        errorType = 'connectionError';
        break;
      default:
        errorType = 'unknown';
    }

    return {
      'ok': false,
      'error': true,
      'errorType': errorType,
      'message': e.message ?? 'Unknown error',
      'statusCode': e.response?.statusCode,
      'body': e.response?.data,
    };
  }
}
