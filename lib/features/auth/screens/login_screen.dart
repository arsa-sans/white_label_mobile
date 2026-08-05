import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController(text: 'visitor@soundwave.com');
  final _passwordController = TextEditingController(text: 'Password123!');
  bool _obscurePassword = true;

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

  void _quickFill(String email, String role) {
    _emailController.text = email;
    _passwordController.text = 'Password123!';
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
                    color: AppTheme.primaryColor.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.confirmation_number_outlined, size: 48, color: AppTheme.primaryColor),
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
                'Ticketing & Venue Cashless Mobile',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: AppTheme.slate400),
              ),
              const SizedBox(height: 40),

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
              const SizedBox(height: 24),

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

              const SizedBox(height: 16),

              // Quick Preset Accounts for Easy Demo Testing
              const Text(
                'Demo Accounts Quick Select:',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.slate400),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ActionChip(
                    label: const Text('Visitor', style: TextStyle(fontSize: 11)),
                    onPressed: () => _quickFill('visitor@soundwave.com', 'visitor'),
                  ),
                  ActionChip(
                    label: const Text('Gate Staff', style: TextStyle(fontSize: 11)),
                    onPressed: () => _quickFill('gate@soundwave.com', 'gate_staff'),
                  ),
                  ActionChip(
                    label: const Text('Vendor Booth', style: TextStyle(fontSize: 11)),
                    onPressed: () => _quickFill('vendor1@kopi.com', 'vendor'),
                  ),
                  ActionChip(
                    label: const Text('Organizer', style: TextStyle(fontSize: 11)),
                    onPressed: () => _quickFill('organizer@soundwave.com', 'organizer'),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Belum punya akun? ', style: TextStyle(fontSize: 13, color: AppTheme.slate400)),
                  GestureDetector(
                    onTap: () => context.push('/register'),
                    child: const Text(
                      'Daftar Sekarang',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
