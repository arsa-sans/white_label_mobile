import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/theme/app_theme.dart';

class CheckoutView extends ConsumerStatefulWidget {
  final String eventId;
  final String seatId;
  const CheckoutView({super.key, required this.eventId, required this.seatId});

  @override
  ConsumerState<CheckoutView> createState() => _CheckoutViewState();
}

class _CheckoutViewState extends ConsumerState<CheckoutView> {
  final ApiClient _apiClient = ApiClient();
  bool _isLocking = true;
  bool _isPaying = false;
  String? _error;
  int _secondsRemaining = 300;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _lockSeat();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _lockSeat() async {
    try {
      final res = await _apiClient.dio.post(
        ApiEndpoints.lockSeat,
        data: {'event_id': widget.eventId, 'seat_id': widget.seatId},
      );
      if (res.data['success'] == true) {
        if (mounted) {
          setState(() {
            _isLocking = false;
          });
          _startTimer();
        }
      } else {
        throw Exception(res.data['message'] ?? 'Seat lock failed');
      }
    } on DioException catch (e) {
      if (mounted) {
        setState(() {
          _isLocking = false;
          _error = (e.response?.data as Map<String, dynamic>?)?['error']?.toString() ??
              'Kursi telah dikunci pengguna lain.';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLocking = false;
          _error = 'Gagal mengunci kursi.';
        });
      }
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_secondsRemaining <= 1) {
        t.cancel();
        setState(() {
          _secondsRemaining = 0;
          _error = 'Waktu penguncian kursi telah habis.';
        });
      } else {
        setState(() => _secondsRemaining--);
      }
    });
  }

  Future<void> _handlePayment() async {
    setState(() => _isPaying = true);
    try {
      final idempotencyKey = 'idemp-${DateTime.now().millisecondsSinceEpoch}';
      final res = await _apiClient.dio.post(
        ApiEndpoints.createOrder,
        data: {
          'event_id': widget.eventId,
          'seat_ids': [widget.seatId],
          'idempotency_key': idempotencyKey,
          'payment_gateway': 'Midtrans QRIS Instant',
        },
      );

      if (res.data['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Pembayaran Berhasil! Tiket diterbitkan.'),
              backgroundColor: AppTheme.accentColor,
            ),
          );
          context.go('/my-tickets');
        }
      } else {
        throw Exception(res.data['message'] ?? 'Payment failed');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pembayaran gagal dikonfirmasi.'),
            backgroundColor: AppTheme.dangerColor,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isPaying = false);
    }
  }

  String get _timerString {
    final m = _secondsRemaining ~/ 60;
    final s = _secondsRemaining % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Checkout Tiket')),
      body: _isLocking
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Mengunci Kursi Pilihan (Distributed Lock)...', style: TextStyle(color: AppTheme.slate400, fontSize: 12)),
                ],
              ),
            )
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 64, color: AppTheme.dangerColor),
                        const SizedBox(height: 16),
                        Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 16)),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () => context.pop(),
                          child: const Text('Kembali Pilih Kursi'),
                        ),
                      ],
                    ),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Lock Expiry Banner
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.warningColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.warningColor.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.timer_outlined, color: AppTheme.warningColor),
                                SizedBox(width: 10),
                                Text('Sisa Waktu Kunci Kursi:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                              ],
                            ),
                            Text(_timerString, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.warningColor)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      const Text('Rincian Pesanan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(height: 12),

                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.cardDark,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.cardBorder),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Kursi Terpilih', style: TextStyle(color: AppTheme.slate400, fontSize: 13)),
                                Text(widget.seatId, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                              ],
                            ),
                            const Divider(height: 24, color: AppTheme.cardBorder),
                            const Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Metode Pembayaran', style: TextStyle(color: AppTheme.slate400, fontSize: 13)),
                                Text('QRIS Instant', style: TextStyle(color: AppTheme.accentColor, fontWeight: FontWeight.bold, fontSize: 13)),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const Spacer(),

                      ElevatedButton(
                        onPressed: _isPaying || _secondsRemaining <= 0 ? null : _handlePayment,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accentColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: _isPaying
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('BAYAR SEKARANG (SIMULASI QRIS)', style: TextStyle(fontWeight: FontWeight.w900)),
                      ),
                    ],
                  ),
                ),
    );
  }
}
