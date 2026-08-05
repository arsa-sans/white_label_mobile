import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';

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

// ─── Auth ViewModel (Riverpod Notifier) ───────────────────────────────────────

class AuthViewModel extends Notifier<AuthState> {
  late final AuthRepository _repository;

  @override
  AuthState build() {
    _repository = AuthRepository();
    Future.microtask(checkInitialAuth);
    return const AuthState(isLoading: true);
  }

  Future<void> checkInitialAuth() async {
    state = state.copyWith(isLoading: true);
    try {
      final token = await _repository.getToken();
      final tenantId = await _repository.getTenantId();
      final savedUserJson = await _repository.getUserData();

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
      final resData = await _repository.login(email, password);

      if (resData['success'] == true) {
        final data = resData['data'] as Map<String, dynamic>;
        final token = data['token'] as String;
        final userMap = data['user'] as Map<String, dynamic>;
        final user = UserModel.fromJson(userMap);

        await _repository.saveSession(token, user);

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
          error: resData['error']?.toString() ?? 'Login gagal',
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
      final resData = await _repository.register(name, email, password, role);

      if (resData['success'] == true) {
        final data = resData['data'] as Map<String, dynamic>;
        final token = data['token'] as String;
        final userMap = data['user'] as Map<String, dynamic>;
        final user = UserModel.fromJson(userMap);

        await _repository.saveSession(token, user);

        state = state.copyWith(
          isLoading: false,
          isAuthenticated: true,
          user: user,
        );
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: resData['error']?.toString() ?? 'Registrasi gagal',
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
    await _repository.saveTenantId(newTenantId);
    state = state.copyWith(tenantId: newTenantId);
  }

  Future<void> logout() async {
    await _repository.clearSession();
    state = const AuthState();
  }
}

// ─── Provider Alias ───────────────────────────────────────────────────────────

final authProvider = NotifierProvider<AuthViewModel, AuthState>(AuthViewModel.new);
