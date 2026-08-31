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
    _emailController = TextEditingController(text: 'gate@soundwave.com');
    _passwordController = TextEditingController(text: 'GateStaff@2026!');
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

  void _quickFill(String email, String password) {
    setState(() {
      _emailController.text = email;
      _passwordController.text = password;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
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
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.qr_code_scanner_rounded, size: 48, color: AppTheme.primaryColor),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'WHITE LABEL',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                  color: Colors.white,
                ),
              ),
              const Text(
                'Gate Access Staff & Organizer Control',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: AppTheme.slate400),
              ),
              const SizedBox(height: 24),

              // Access Scope Banner
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, size: 20, color: AppTheme.primaryColor),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Aplikasi Mobile ini khusus untuk Gate Staff, Organizer Event, dan Vendor.',
                        style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Tenant Badge Button
              InkWell(
                onTap: () => context.push('/tenant-select'),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppTheme.cardDark,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.cardBorder),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.business, size: 18, color: AppTheme.secondaryColor),
                          const SizedBox(width: 10),
                          Text(
                            'Tenant: ${authState.tenantId}',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ],
                      ),
                      const Icon(Icons.swap_horiz, size: 18, color: AppTheme.slate400),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Email Input
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined, size: 20),
                ),
              ),
              const SizedBox(height: 16),

              // Password Input
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outline, size: 20),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, size: 20),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Login Button
              ElevatedButton(
                onPressed: authState.isLoading ? null : _handleLogin,
                child: authState.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('MASUK KE AKUN'),
              ),

              const SizedBox(height: 20),

              // Quick Preset Accounts for Demo
              const Text(
                'Akses Demo Cepat:',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.slate400),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ActionChip(
                    avatar: const Icon(Icons.qr_code_scanner, size: 16, color: AppTheme.primaryColor),
                    label: const Text('Gate Staff', style: TextStyle(fontSize: 11)),
                    onPressed: () => _quickFill('gate@soundwave.com', 'GateStaff@2026!'),
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.analytics_outlined, size: 16, color: AppTheme.secondaryColor),
                    label: const Text('Organizer', style: TextStyle(fontSize: 11)),
                    onPressed: () => _quickFill('organizer@soundwave.com', 'Organizer@2026!'),
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.storefront_outlined, size: 16, color: AppTheme.accentColor),
                    label: const Text('Vendor Booth', style: TextStyle(fontSize: 11)),
                    onPressed: () => _quickFill('vendor@demo.wl', 'Vendor@2026!'),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              const Text(
                'Gate Staff & Vendor didaftarkan oleh Organizer melalui Web Dashboard. Visitor & Organizer pendaftaran dapat diakses melalui Portal Web.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: AppTheme.slate400, height: 1.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
