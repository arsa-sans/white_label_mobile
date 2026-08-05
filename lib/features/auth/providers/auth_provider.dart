import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/storage/secure_storage.dart';
import 'package:dio/dio.dart';

// ─── User Model ───────────────────────────────────────────────────────────────

class UserModel {
  final String id;
  final String name;
  final String email;
  final String role;
  final String tenantId;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.tenantId,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'visitor',
      tenantId: json['tenant_id'] ?? 'tenant-001',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'role': role,
        'tenant_id': tenantId,
      };
}

// ─── Auth State ───────────────────────────────────────────────────────────────

class AuthState {
  final bool isLoading;
  final bool isAuthenticated;
  final UserModel? user;
  final String tenantId;
  final String? error;

  const AuthState({
    this.isLoading = false,
    this.isAuthenticated = false,
    this.user,
    this.tenantId = 'tenant-001',
    this.error,
  });

  AuthState copyWith({
    bool? isLoading,
    bool? isAuthenticated,
    UserModel? user,
    String? tenantId,
    String? error,
    bool clearError = false,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      user: user ?? this.user,
      tenantId: tenantId ?? this.tenantId,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// ─── Auth Notifier (Riverpod 3 — Notifier) ────────────────────────────────────

class AuthNotifier extends Notifier<AuthState> {
  final ApiClient _apiClient = ApiClient();
  final SecureStorageService _storage = SecureStorageService();

  @override
  AuthState build() {
    // Kick off async initialisation without blocking.
    Future.microtask(checkInitialAuth);
    return const AuthState(isLoading: true);
  }

  Future<void> checkInitialAuth() async {
    state = state.copyWith(isLoading: true);
    try {
      final token = await _storage.getToken();
      final tenantId = await _storage.getTenantId();
      final savedUserJson = await _storage.getUserData();

      if (token != null && savedUserJson != null) {
        final userMap = jsonDecode(savedUserJson) as Map<String, dynamic>;
        state = state.copyWith(
          isLoading: false,
          isAuthenticated: true,
          user: UserModel.fromJson(userMap),
          tenantId: tenantId,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          isAuthenticated: false,
          tenantId: tenantId,
        );
      }
    } catch (_) {
      state = state.copyWith(isLoading: false, isAuthenticated: false);
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.login,
        data: {'email': email, 'password': password},
      );

      if (response.data['success'] == true) {
        final data = response.data['data'] as Map<String, dynamic>;
        final token = data['token'] as String;
        final userMap = data['user'] as Map<String, dynamic>;
        final user = UserModel.fromJson(userMap);

        await _storage.saveToken(token);
        await _storage.saveRole(user.role);
        await _storage.saveTenantId(user.tenantId);
        await _storage.saveUserData(jsonEncode(user.toJson()));

        state = state.copyWith(
          isLoading: false,
          isAuthenticated: true,
          user: user,
          tenantId: user.tenantId,
        );
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response.data['error']?.toString() ?? 'Login gagal',
        );
        return false;
      }
    } on DioException catch (e) {
      final msg =
          (e.response?.data as Map<String, dynamic>?)?['error']?.toString() ??
              'Gagal melakukan login. Periksa koneksi backend.';
      state = state.copyWith(isLoading: false, error: msg);
      return false;
    } catch (_) {
      state = state.copyWith(
          isLoading: false, error: 'Gagal melakukan login.');
      return false;
    }
  }

  Future<bool> register(
      String name, String email, String password, String role) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.register,
        data: {
          'name': name,
          'email': email,
          'password': password,
          'role': role,
        },
      );

      if (response.data['success'] == true) {
        final data = response.data['data'] as Map<String, dynamic>;
        final token = data['token'] as String;
        final userMap = data['user'] as Map<String, dynamic>;
        final user = UserModel.fromJson(userMap);

        await _storage.saveToken(token);
        await _storage.saveRole(user.role);
        await _storage.saveUserData(jsonEncode(user.toJson()));

        state = state.copyWith(
          isLoading: false,
          isAuthenticated: true,
          user: user,
        );
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response.data['error']?.toString() ?? 'Registrasi gagal',
        );
        return false;
      }
    } on DioException catch (e) {
      final msg =
          (e.response?.data as Map<String, dynamic>?)?['error']?.toString() ??
              'Gagal mendaftar akun.';
      state = state.copyWith(isLoading: false, error: msg);
      return false;
    } catch (_) {
      state =
          state.copyWith(isLoading: false, error: 'Gagal mendaftar akun.');
      return false;
    }
  }

  Future<void> updateTenant(String newTenantId) async {
    await _storage.saveTenantId(newTenantId);
    state = state.copyWith(tenantId: newTenantId);
  }

  Future<void> logout() async {
    await _storage.clearAll();
    state = const AuthState();
  }
}

// ─── Provider ────────────────────────────────────────────────────────────────

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
