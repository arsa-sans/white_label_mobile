import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../../../core/theme/app_theme.dart';
import '../../widgets/offline_sync_indicator.dart';
import '../viewmodels/gate_viewmodel.dart';

class GateScannerView extends ConsumerStatefulWidget {
  const GateScannerView({super.key});

  @override
  ConsumerState<GateScannerView> createState() => _GateScannerViewState();
}

class _GateScannerViewState extends ConsumerState<GateScannerView> with TickerProviderStateMixin {
  final _qrController = TextEditingController();
  late AnimationController _flashAnimController;
  StreamSubscription? _connectivitySub;

  @override
  void initState() {
    super.initState();
    _flashAnimController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _initConnectivity();
  }

  void _initConnectivity() async {
    final result = await Connectivity().checkConnectivity();
    final online = result.first != ConnectivityResult.none;
    ref.read(gateProvider.notifier).setOnline(online);

    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      if (!mounted) return;
      final isOnline = results.first != ConnectivityResult.none;
      ref.read(gateProvider.notifier).setOnline(isOnline);
    });

    // Listen for remote scan notifications (from other devices via Socket.IO)
    ref.listenManual(
      gateProvider.select((s) => s.remoteNotification),
      (previous, next) {
        if (next != null && next.isNotEmpty && mounted) {
          final isSuccess = next.startsWith('✓');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(next, style: const TextStyle(fontWeight: FontWeight.w600)),
              backgroundColor: isSuccess ? AppTheme.emerald600 : AppTheme.amber600,
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              duration: const Duration(seconds: 3),
            ),
          );
          ref.read(gateProvider.notifier).clearNotification();
        }
      },
    );
  }

  @override
  void dispose() {
    _flashAnimController.dispose();
    _connectivitySub?.cancel();
    _qrController.dispose();
    super.dispose();
  }

  Future<void> _triggerScan(String qrToken) async {
    if (qrToken.isEmpty) return;
    HapticFeedback.mediumImpact();
    _qrController.clear();

    await ref.read(gateProvider.notifier).handleScan(qrToken);
    _flashAnimController.forward(from: 0).then((_) {
      if (mounted) {
        ref.read(gateProvider.notifier).hideFlash();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final gateState = ref.watch(gateProvider);

    return Scaffold(
      backgroundColor: AppTheme.slate50,
      appBar: AppBar(
        title: const Text('Gate Scanner'),
        backgroundColor: Colors.white,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: OfflineSyncIndicator(
              isOnline: gateState.isOnline,
              pendingCount: gateState.pendingSyncCount,
              onSyncTap: () => ref.read(gateProvider.notifier).syncPendingLogs(),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Session Stats Header
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatPill('TOTAL SCAN', '${gateState.sessionScanCount}', AppTheme.slate900),
                    _StatPill('VALID', '${gateState.sessionValid}', AppTheme.emerald600),
                    _StatPill('INVALID', '${gateState.sessionInvalid}', AppTheme.red600),
                    _StatPill('PENDING SYNC', '${gateState.pendingSyncCount}', AppTheme.amber600),
                  ],
                ),
              ),

              // Mock Camera Viewport
              Expanded(
                flex: 4,
                child: Container(
                  color: Colors.black,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.qr_code_scanner, size: 80, color: Colors.white38),
                            SizedBox(height: 12),
                            Text(
                              'Arahkan kamera ke Dynamic QR tiket',
                              style: TextStyle(color: Colors.white60, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      // Scanner box frame
                      _ScannerFrame(),
                    ],
                  ),
                ),
              ),

              // Input QR manual & trigger
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _qrController,
                        decoration: InputDecoration(
                          hintText: 'Simulasi scan: tempel / ketik token...',
                          hintStyle: const TextStyle(fontSize: 12, color: AppTheme.slate400),
                          prefixIcon: const Icon(Icons.qr_code, size: 20),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppTheme.slate200),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        onSubmitted: (val) => _triggerScan(val.trim()),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: gateState.isScanning ? null : () => _triggerScan(_qrController.text.trim()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: gateState.isScanning
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('VALIDASI', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white)),
                    ),
                  ],
                ),
              ),

              // Session Scans Log
              Expanded(
                flex: 3,
                child: Container(
                  color: AppTheme.slate50,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.fromLTRB(16, 12, 16, 6),
                        child: Text(
                          'LOG SCAN SESI INI',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.slate500,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      Expanded(
                        child: gateState.sessionLogs.isEmpty
                            ? const Center(
                                child: Text(
                                  'Belum ada tiket yang di-scan.',
                                  style: TextStyle(fontSize: 12, color: AppTheme.slate400),
                                ),
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                itemCount: gateState.sessionLogs.length,
                                separatorBuilder: (_, _) => const SizedBox(height: 6),
                                itemBuilder: (_, i) {
                                  final log = gateState.sessionLogs[i];
                                  final isValid = log['result'] == 'valid' || log['result'] == 'offline_valid';
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: AppTheme.slate200),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          isValid ? Icons.check_circle : Icons.cancel,
                                          color: isValid ? AppTheme.emerald600 : AppTheme.red600,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            log['token'],
                                            style: const TextStyle(
                                              fontFamily: 'monospace',
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: AppTheme.slate800,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          log['result'].toString().toUpperCase(),
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: isValid ? AppTheme.emerald600 : AppTheme.red600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Fullscreen Flash Feedback Overlay
          if (gateState.showFlash)
            Positioned.fill(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                color: gateState.flashSuccess
                    ? AppTheme.emerald600.withAlpha(225)
                    : AppTheme.red600.withAlpha(225),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        gateState.flashSuccess ? Icons.check_circle_outline : Icons.highlight_off,
                        size: 96,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        gateState.flashSuccess ? 'TIKET VALID ✓' : 'TIKET INVALID ✗',
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatPill(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: color)),
        Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.slate500, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _ScannerFrame extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      height: 120,
      child: CustomPaint(painter: _ScannerCornerPainter()),
    );
  }
}

class _ScannerCornerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.primaryColor
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    const len = 20.0;

    // Top-left
    canvas.drawLine(Offset.zero, Offset(len, 0), paint);
    canvas.drawLine(Offset.zero, Offset(0, len), paint);
    // Top-right (Fixed: Offset(size.width, 0) instead of Offset.zero)
    canvas.drawLine(Offset(size.width, 0), Offset(size.width - len, 0), paint);
    canvas.drawLine(Offset(size.width, 0), Offset(size.width, len), paint);
    // Bottom-left
    canvas.drawLine(Offset(0, size.height), Offset(len, size.height), paint);
    canvas.drawLine(Offset(0, size.height), Offset(0, size.height - len), paint);
    // Bottom-right
    canvas.drawLine(Offset(size.width, size.height), Offset(size.width - len, size.height), paint);
    canvas.drawLine(Offset(size.width, size.height), Offset(size.width, size.height - len), paint);
  }

  @override
  bool shouldRepaint(_) => false;
}
