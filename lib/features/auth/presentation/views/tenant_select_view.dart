import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../../core/constants/api_endpoints.dart';

class TenantSelectView extends ConsumerStatefulWidget {
  const TenantSelectView({super.key});

  @override
  ConsumerState<TenantSelectView> createState() => _TenantSelectViewState();
}

class _TenantSelectViewState extends ConsumerState<TenantSelectView> {
  late TextEditingController _tenantController;
  late TextEditingController _serverUrlController;
  final SecureStorageService _storage = SecureStorageService();
  bool _isTestingConnection = false;
  String? _testConnectionStatus;
  bool _testSuccess = false;

  @override
  void initState() {
    super.initState();
    final currentTenant = ref.read(authProvider).tenantId;
    _tenantController = TextEditingController(text: currentTenant);
    _serverUrlController = TextEditingController(text: ApiEndpoints.baseUrl);
    _loadCustomUrl();
  }

  void _loadCustomUrl() async {
    final custom = await _storage.getBaseUrl();
    if (custom != null && custom.isNotEmpty && mounted) {
      setState(() {
        _serverUrlController.text = custom;
      });
    }
  }

  @override
  void dispose() {
    _tenantController.dispose();
    _serverUrlController.dispose();
    super.dispose();
  }

  void _saveSettings() async {
    final tenantId = _tenantController.text.trim();
    final serverUrl = _serverUrlController.text.trim();

    if (tenantId.isNotEmpty) {
      await ref.read(authProvider.notifier).updateTenant(tenantId);
    }
    if (serverUrl.isNotEmpty) {
      await _storage.saveBaseUrl(serverUrl);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Konfigurasi server & tenant berhasil disimpan!'),
          backgroundColor: AppTheme.zinc900,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  void _testConnection() async {
    final url = _serverUrlController.text.trim();
    if (url.isEmpty) return;

    setState(() {
      _isTestingConnection = true;
      _testConnectionStatus = null;
    });

    try {
      final testDio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
        ),
      );

      final healthUrl = url.replaceAll('/api/v1', '/health');
      final res = await testDio.get(healthUrl);

      if (res.statusCode == 200) {
        setState(() {
          _isTestingConnection = false;
          _testSuccess = true;
          _testConnectionStatus = '✓ Terhubung! Backend status: Online (${res.data['data']?['status'] ?? 'OK'})';
        });
      } else {
        setState(() {
          _isTestingConnection = false;
          _testSuccess = false;
          _testConnectionStatus = '✗ HTTP ${res.statusCode}: Backend merespon tetapi status tidak OK';
        });
      }
    } on DioException catch (e) {
      setState(() {
        _isTestingConnection = false;
        _testSuccess = false;
        _testConnectionStatus = '✗ Gagal terhubung (${e.type.name}): Periksa IP laptop & pastikan HP di WiFi yang sama';
      });
    } catch (err) {
      setState(() {
        _isTestingConnection = false;
        _testSuccess = false;
        _testConnectionStatus = '✗ Gagal terhubung: $err';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: const Text('Pengaturan Server & Tenant'),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.zinc950,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Section 1: Backend Server URL ──
            const Text(
              'Alamat IP / URL Backend',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.zinc950),
            ),
            const SizedBox(height: 4),
            const Text(
              'Sesuaikan dengan IP WiFi laptop kamu agar HP dapat terhubung ke backend.',
              style: TextStyle(fontSize: 12, color: AppTheme.zinc500),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _serverUrlController,
              style: const TextStyle(color: AppTheme.zinc950, fontSize: 13, fontWeight: FontWeight.w600),
              decoration: const InputDecoration(
                labelText: 'Backend Base URL',
                prefixIcon: Icon(Icons.wifi, size: 20, color: AppTheme.zinc600),
                hintText: 'http://192.168.xxx.xxx:4000/api/v1',
              ),
            ),
            const SizedBox(height: 10),

            // Test Connection Button & Status
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: _isTestingConnection ? null : _testConnection,
                  icon: _isTestingConnection
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.zinc950),
                        )
                      : const Icon(Icons.network_check, size: 16),
                  label: const Text('Test Koneksi', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.zinc950,
                    side: const BorderSide(color: AppTheme.zinc300),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),

            if (_testConnectionStatus != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _testSuccess ? AppTheme.zinc100 : const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _testSuccess ? AppTheme.zinc300 : const Color(0xFFFECACA),
                  ),
                ),
                child: Text(
                  _testConnectionStatus!,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: _testSuccess ? AppTheme.zinc900 : AppTheme.dangerColor,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 14),
            const Text(
              'Pilihan Preset IP Cepat:',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.zinc500),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ActionChip(
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: AppTheme.zinc200),
                  label: const Text('WiFi Saat Ini (192.168.0.110)', style: TextStyle(fontSize: 11, color: AppTheme.zinc900, fontWeight: FontWeight.w600)),
                  onPressed: () {
                    setState(() {
                      _serverUrlController.text = 'http://192.168.0.110:4000/api/v1';
                    });
                  },
                ),
                ActionChip(
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: AppTheme.zinc200),
                  label: const Text('Emulator (10.0.2.2)', style: TextStyle(fontSize: 11, color: AppTheme.zinc900, fontWeight: FontWeight.w600)),
                  onPressed: () {
                    setState(() {
                      _serverUrlController.text = 'http://10.0.2.2:4000/api/v1';
                    });
                  },
                ),
                ActionChip(
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: AppTheme.zinc200),
                  label: const Text('Localhost (localhost)', style: TextStyle(fontSize: 11, color: AppTheme.zinc900, fontWeight: FontWeight.w600)),
                  onPressed: () {
                    setState(() {
                      _serverUrlController.text = 'http://localhost:4000/api/v1';
                    });
                  },
                ),
              ],
            ),

            const SizedBox(height: 24),
            const Divider(color: AppTheme.zinc200),
            const SizedBox(height: 16),

            // ── Section 2: Tenant Configuration ──
            const Text(
              'White Label Tenant',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.zinc950),
            ),
            const SizedBox(height: 4),
            const Text(
              'Tenant ID yang dikirim via header X-Tenant-Id.',
              style: TextStyle(fontSize: 12, color: AppTheme.zinc500),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _tenantController,
              style: const TextStyle(color: AppTheme.zinc950, fontSize: 13, fontWeight: FontWeight.w600),
              decoration: const InputDecoration(
                labelText: 'Tenant ID / Subdomain',
                prefixIcon: Icon(Icons.business_outlined, size: 20, color: AppTheme.zinc600),
              ),
            ),
            const SizedBox(height: 16),

            ElevatedButton(
              onPressed: _saveSettings,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.zinc950,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('SIMPAN KONFIGURASI', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
            ),

            const SizedBox(height: 24),
            const Text(
              'Pilihan Preset Tenant Available:',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.zinc500),
            ),
            const SizedBox(height: 10),

            // Preset options
            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppTheme.zinc200),
              ),
              tileColor: Colors.white,
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.zinc100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.music_note, color: AppTheme.zinc950, size: 20),
              ),
              title: const Text('tenant-001 (Soundwave Fest)', style: TextStyle(color: AppTheme.zinc950, fontWeight: FontWeight.bold, fontSize: 13)),
              subtitle: const Text('Default organizer tenant', style: TextStyle(color: AppTheme.zinc500, fontSize: 11)),
              onTap: () {
                _tenantController.text = 'tenant-001';
              },
            ),
            const SizedBox(height: 8),
            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppTheme.zinc200),
              ),
              tileColor: Colors.white,
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.zinc100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.sports_esports, color: AppTheme.zinc950, size: 20),
              ),
              title: const Text('tenant-neon (Neon Cyber Fest)', style: TextStyle(color: AppTheme.zinc950, fontWeight: FontWeight.bold, fontSize: 13)),
              subtitle: const Text('Secondary white label tenant', style: TextStyle(color: AppTheme.zinc500, fontSize: 11)),
              onTap: () {
                _tenantController.text = 'tenant-neon';
              },
            ),
          ],
        ),
      ),
    );
  }
}
