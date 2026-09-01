import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../../../../core/theme/app_theme.dart';

class LoginView extends ConsumerStatefulWidget {
  const LoginView({super.key});

  @override
  ConsumerState<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends ConsumerState<LoginView> {
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    if (email.isEmpty || password.isEmpty) return;

    final success = await ref.read(authProvider.notifier).login(email, password);
    if (!success && mounted) {
      final err = ref.read(authProvider).error ?? 'Login gagal';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err), backgroundColor: AppTheme.dangerColor),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 30),
              // Logo Header
              Center(
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppTheme.zinc100,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.zinc200),
                  ),
                  child: const Icon(Icons.qr_code_scanner_rounded, size: 44, color: AppTheme.zinc950),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'WHITE LABEL',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                  color: AppTheme.zinc950,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Gate Access Staff & Organizer Control',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: AppTheme.zinc500, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 24),

              // Access Scope Banner
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.zinc100,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.zinc200),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, size: 18, color: AppTheme.zinc700),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Aplikasi Mobile ini khusus untuk Gate Staff dan Organizer Event.',
                        style: TextStyle(fontSize: 12, color: AppTheme.zinc800, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Tenant & Server Settings Button
              InkWell(
                onTap: () => context.push('/tenant-select'),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.zinc200),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.settings_ethernet, size: 20, color: AppTheme.zinc900),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Tenant: ${authState.tenantId}',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.zinc950),
                              ),
                              const Text(
                                'Atur IP Server Backend / Tenant',
                                style: TextStyle(fontSize: 10, color: AppTheme.zinc500),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const Icon(Icons.tune, size: 18, color: AppTheme.zinc400),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Email Input
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: AppTheme.zinc950, fontSize: 13, fontWeight: FontWeight.w600),
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined, size: 20, color: AppTheme.zinc500),
                ),
              ),
              const SizedBox(height: 16),

              // Password Input
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                style: const TextStyle(color: AppTheme.zinc950, fontSize: 13, fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outline, size: 20, color: AppTheme.zinc500),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, size: 20, color: AppTheme.zinc500),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Login Button
              ElevatedButton(
                onPressed: authState.isLoading ? null : _handleLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.zinc950,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: authState.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('MASUK KE AKUN', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
              ),

              const SizedBox(height: 24),

              const Text(
                'Gate Staff didaftarkan oleh Organizer melalui Web Dashboard. Pendaftaran akun dapat diakses melalui Portal Web.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: AppTheme.zinc500, height: 1.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
