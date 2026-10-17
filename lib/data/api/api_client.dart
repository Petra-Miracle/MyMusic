import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Error dari backend; [message] aman ditampilkan langsung ke user.
class ApiException implements Exception {
  const ApiException(this.message, {this.status});

  final String message;
  final int? status;

  bool get isUnauthorized => status == 401;

  @override
  String toString() => message;
}

/// Penyimpanan token login.
abstract interface class TokenStore {
  Future<String?> read();
  Future<void> write(String token);
  Future<void> clear();
}

class SecureTokenStore implements TokenStore {
  static const _key = 'auth_token';
  final _storage = const FlutterSecureStorage();

  @override
  Future<String?> read() => _storage.read(key: _key);

  @override
  Future<void> write(String token) => _storage.write(key: _key, value: token);

  @override
  Future<void> clear() => _storage.delete(key: _key);
}

/// Token hanya di memori (untuk test).
class MemoryTokenStore implements TokenStore {
  String? _token;

  @override
  Future<String?> read() async => _token;

  @override
  Future<void> write(String token) async => _token = token;

  @override
  Future<void> clear() async => _token = null;
}

/// HTTP client ke backend Nada: menambah header token & mengubah error jadi [ApiException].
class ApiClient {
  ApiClient({required String baseUrl, required this.tokens})
      : _dio = Dio(BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 20),
          contentType: Headers.jsonContentType,
        )) {
    _dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) async {
      final token = await tokens.read();
      if (token != null) options.headers['Authorization'] = 'Bearer $token';
      handler.next(options);
    }));
  }

  final Dio _dio;
  final TokenStore tokens;

  Future<T> get<T>(String path, {Map<String, dynamic>? query}) =>
      _send(() => _dio.get<T>(path, queryParameters: query));

  Future<T> post<T>(String path, [Object? body]) => _send(() => _dio.post<T>(path, data: body));

  Future<T> put<T>(String path, [Object? body]) => _send(() => _dio.put<T>(path, data: body));

  Future<T> patch<T>(String path, [Object? body]) => _send(() => _dio.patch<T>(path, data: body));

  Future<void> delete(String path) => _send(() => _dio.delete<void>(path));

  Future<T> _send<T>(Future<Response<T>> Function() request) async {
    try {
      return (await request()).data as T;
    } on DioException catch (e) {
      throw _toApiException(e);
    }
  }

  static ApiException _toApiException(DioException e) {
    final status = e.response?.statusCode;
    final data = e.response?.data;
    if (data is Map && data['error'] is String) return ApiException(data['error'] as String, status: status);
    return switch (e.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.sendTimeout =>
        const ApiException('Server terlalu lama merespons, coba lagi'),
      DioExceptionType.connectionError => const ApiException('Tidak ada koneksi internet'),
      _ => ApiException('Terjadi kesalahan (${status ?? 'jaringan'})', status: status),
    };
  }
}
