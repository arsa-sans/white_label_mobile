import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/theme/app_theme.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  final String eventId;
  final String seatId;
  const CheckoutScreen({super.key, required this.eventId, required this.seatId});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final ApiClient _apiClient = ApiClient();

  // Seat lock countdown — 5 minutes per spec
  static const int _lockTtlSeconds = 5 * 60;
  int _remaining = _lockTtlSeconds;
  Timer? _countdownTimer;

  String _selectedMethod = 'qris';
  bool _isProcessing = false;
  bool _isPaid = false;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_remaining <= 0) {
        timer.cancel();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('⏰ Waktu habis! Kursi dilepas otomatis.'),
              backgroundColor: AppTheme.warningColor,
            ),
          );
          if (context.canPop()) context.pop();
        }
        return;
      }
      setState(() => _remaining--);
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  String get _countdownFormatted {
    final m = (_remaining ~/ 60).toString().padLeft(2, '0');
    final s = (_remaining % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> _handlePay() async {
    setState(() => _isProcessing = true);
    try {
      final idempotencyKey = 'mobile-${DateTime.now().millisecondsSinceEpoch}';
      final res = await _apiClient.dio.post(
        ApiEndpoints.createOrder,
        options: Options(headers: {'x-idempotency-key': idempotencyKey}),
        data: {
          'event_id': widget.eventId,
          'seat_ids': [widget.seatId],
          'payment_method': _selectedMethod,
          'customer_name': 'Mobile User',
          'customer_email': 'user@wlmobile.app',
        },
      );

      if (res.data['success'] == true) {
        _countdownTimer?.cancel();
        setState(() => _isPaid = true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pembayaran gagal. Silakan coba lagi.'),
            backgroundColor: AppTheme.dangerColor,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isPaid) return _buildSuccessView();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout & Pembayaran'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Countdown Badge
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _remaining > 60
                      ? [AppTheme.primaryDark, AppTheme.primaryColor]
                      : [Colors.deepOrange.shade800, Colors.deepOrange.shade600],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(Icons.timer_outlined, color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Selesaikan pembayaran dalam',
                        style: TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                      Text(
                        _countdownFormatted,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Order Summary
            _buildInfoCard('Detail Pesanan', [
              {'label': 'Event ID', 'value': widget.eventId},
              {'label': 'Seat ID', 'value': widget.seatId},
              {'label': 'Status Kursi', 'value': '🔒 Terkunci (Anda)'},
            ]),
            const SizedBox(height: 16),

            // Payment Method Selection
            const Text(
              'METODE PEMBAYARAN',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.white54, letterSpacing: 1),
            ),
            const SizedBox(height: 8),

            for (final method in [
              {'id': 'qris', 'label': 'QRIS (Semua E-Wallet)', 'icon': Icons.qr_code_2},
              {'id': 'va_bca', 'label': 'Virtual Account BCA', 'icon': Icons.account_balance},
              {'id': 'wallet', 'label': 'GoPay / OVO / Dana', 'icon': Icons.account_balance_wallet},
            ])
              GestureDetector(
                onTap: () => setState(() => _selectedMethod = method['id'] as String),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _selectedMethod == method['id'] ? AppTheme.primaryColor.withOpacity(0.15) : AppTheme.cardDark,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _selectedMethod == method['id'] ? AppTheme.primaryColor : AppTheme.cardBorder,
                      width: _selectedMethod == method['id'] ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(method['icon'] as IconData, color: AppTheme.primaryColor, size: 22),
                      const SizedBox(width: 12),
                      Text(
                        method['label'] as String,
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      if (_selectedMethod == method['id']) ...[
                        const Spacer(),
                        const Icon(Icons.check_circle, color: AppTheme.primaryColor, size: 18),
                      ],
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: _isProcessing ? null : _handlePay,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isProcessing
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                        SizedBox(width: 10),
                        Text('Memproses Pembayaran...'),
                      ],
                    )
                  : const Text('BAYAR SEKARANG', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessView() {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppTheme.accentColor.withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.accentColor, width: 3),
                  ),
                  child: const Icon(Icons.check_circle_outline, size: 56, color: AppTheme.accentColor),
                ),
                const SizedBox(height: 24),
                const Text(
                  'TIKET BERHASIL DITERBITKAN!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white),
                ),
                const SizedBox(height: 8),
                const Text(
                  'QR Tiket Dinamis Anda sudah siap. Refresh otomatis setiap 30 detik.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white54, fontSize: 13),
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () => context.go('/my-tickets'),
                  icon: const Icon(Icons.confirmation_number),
                  label: const Text('LIHAT TIKET SAYA'),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => context.go('/catalog'),
                  child: const Text('Kembali ke Katalog'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, List<Map<String, String>> rows) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white38, letterSpacing: 1),
          ),
          const SizedBox(height: 10),
          ...rows.map((row) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(row['label']!, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                    Text(row['value']!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
