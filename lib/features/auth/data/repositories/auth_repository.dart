import 'dart:convert';
import '../../../../core/network/api_client.dart';
import '../../../../core/api/api_endpoints.dart';
import '../../../../core/storage/secure_storage.dart';
import '../models/user_model.dart';

class AuthRepository {
  final ApiClient _apiClient;
  final SecureStorageService _storage;

  AuthRepository({ApiClient? apiClient, SecureStorageService? storage})
      : _apiClient = apiClient ?? ApiClient(),
        _storage = storage ?? SecureStorageService();

  Future<String?> getToken() => _storage.getToken();
  Future<String> getTenantId() => _storage.getTenantId();
  Future<String?> getUserData() => _storage.getUserData();

  Future<void> saveSession(String token, UserModel user) async {
    await _storage.saveToken(token);
    await _storage.saveRole(user.role);
    await _storage.saveTenantId(user.tenantId);
    await _storage.saveUserData(jsonEncode(user.toJson()));
  }

  Future<void> clearSession() => _storage.clearAll();

  Future<void> saveTenantId(String tenantId) => _storage.saveTenantId(tenantId);

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await _apiClient.dio.post(
      ApiEndpoints.login,
      data: {'email': email, 'password': password},
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> register(
      String name, String email, String password, String role) async {
    final response = await _apiClient.dio.post(
      ApiEndpoints.register,
      data: {
        'name': name,
        'email': email,
        'password': password,
        'role': role,
      },
    );
    return response.data as Map<String, dynamic>;
  }
}
