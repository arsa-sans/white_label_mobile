import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static const String _keyToken = 'jwt_token';
  static const String _keyTenantId = 'tenant_id';
  static const String _keyUserRole = 'user_role';
  static const String _keyUserData = 'user_data_json';
  static const String _keyBaseUrl = 'base_backend_url';

  // Base URL
  Future<void> saveBaseUrl(String url) async {
    await _storage.write(key: _keyBaseUrl, value: url);
  }

  Future<String?> getBaseUrl() async {
    return await _storage.read(key: _keyBaseUrl);
  }

  // Token
  Future<void> saveToken(String token) async {
    await _storage.write(key: _keyToken, value: token);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: _keyToken);
  }

  Future<void> deleteToken() async {
    await _storage.delete(key: _keyToken);
  }

  // Tenant ID
  Future<void> saveTenantId(String tenantId) async {
    await _storage.write(key: _keyTenantId, value: tenantId);
  }

  Future<String> getTenantId() async {
    final t = await _storage.read(key: _keyTenantId);
    return t ?? 'tenant-001';
  }

  // User Role
  Future<void> saveRole(String role) async {
    await _storage.write(key: _keyUserRole, value: role);
  }

  Future<String?> getRole() async {
    return await _storage.read(key: _keyUserRole);
  }

  // User Data JSON
  Future<void> saveUserData(String json) async {
    await _storage.write(key: _keyUserData, value: json);
  }

  Future<String?> getUserData() async {
    return await _storage.read(key: _keyUserData);
  }

  // Clear all on logout
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
