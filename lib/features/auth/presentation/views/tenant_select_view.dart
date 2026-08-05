import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../../../../core/theme/app_theme.dart';

class TenantSelectView extends ConsumerStatefulWidget {
  const TenantSelectView({super.key});

  @override
  ConsumerState<TenantSelectView> createState() => _TenantSelectViewState();
}

class _TenantSelectViewState extends ConsumerState<TenantSelectView> {
  late TextEditingController _tenantController;

  @override
  void initState() {
    super.initState();
    final currentTenant = ref.read(authProvider).tenantId;
    _tenantController = TextEditingController(text: currentTenant);
  }

  void _saveTenant(String tenantId) async {
    await ref.read(authProvider.notifier).updateTenant(tenantId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Tenant diubah ke: $tenantId'),
          backgroundColor: AppTheme.accentColor,
        ),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pilih Tenant White Label'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'White Label Tenant Selection',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 6),
            const Text(
              'Aplikasi mobile dikonfigurasi untuk terhubung ke tenant spesifik via header X-Tenant-Id.',
              style: TextStyle(fontSize: 12, color: AppTheme.slate400),
            ),
            const SizedBox(height: 24),

            // Tenant ID input
            TextField(
              controller: _tenantController,
              decoration: const InputDecoration(
                labelText: 'Tenant ID / Subdomain',
                prefixIcon: Icon(Icons.business_outlined, size: 20),
              ),
            ),
            const SizedBox(height: 16),

            ElevatedButton(
              onPressed: () => _saveTenant(_tenantController.text.trim()),
              child: const Text('SIMPAN TENANT'),
            ),

            const SizedBox(height: 32),
            const Text(
              'Pilihan Preset Tenant Available:',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.slate400),
            ),
            const SizedBox(height: 12),

            // Preset options
            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppTheme.cardBorder),
              ),
              tileColor: AppTheme.cardDark,
              leading: const Icon(Icons.music_note, color: AppTheme.primaryColor),
              title: const Text('tenant-001 (Soundwave Fest)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              subtitle: const Text('Default organizer tenant', style: TextStyle(color: AppTheme.slate400, fontSize: 11)),
              onTap: () => _saveTenant('tenant-001'),
            ),
            const SizedBox(height: 8),
            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppTheme.cardBorder),
              ),
              tileColor: AppTheme.cardDark,
              leading: const Icon(Icons.sports_esports, color: AppTheme.secondaryColor),
              title: const Text('tenant-neon (Neon Cyber Fest)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              subtitle: const Text('Secondary white label tenant', style: TextStyle(color: AppTheme.slate400, fontSize: 11)),
              onTap: () => _saveTenant('tenant-neon'),
            ),
          ],
        ),
      ),
    );
  }
}
