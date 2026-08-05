import 'package:dio/dio.dart';
import '../storage/secure_storage.dart';
import '../constants/api_endpoints.dart';

class ApiClient {
  late final Dio dio;
  final SecureStorageService _storage = SecureStorageService();

  ApiClient() {
    dio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          final tenantId = await _storage.getTenantId();
          options.headers['x-tenant-id'] = tenantId;
          return handler.next(options);
        },
        onError: (DioException error, handler) async {
          // Handle 401 Unauthorized globally
          if (error.response?.statusCode == 401) {
            await _storage.deleteToken();
          }
          return handler.next(error);
        },
      ),
    );
  }
}
