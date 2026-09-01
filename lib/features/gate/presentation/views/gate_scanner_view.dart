import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../widgets/offline_sync_indicator.dart';
import '../viewmodels/gate_viewmodel.dart';

class GateScannerView extends ConsumerStatefulWidget {
  const GateScannerView({super.key});

  @override
  ConsumerState<GateScannerView> createState() => _GateScannerViewState();
}

class _GateScannerViewState extends ConsumerState<GateScannerView>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  final _qrController = TextEditingController();
  late final MobileScannerController _cameraController;
  late AnimationController _flashAnimController;
  StreamSubscription? _connectivitySub;

  bool _isProcessingLiveScan = false;
  bool _torchOn = false;

  // Debounce & cooldown tracking for live camera scanning
  String? _lastScannedToken;
  DateTime? _lastScannedTime;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Initialize MobileScanner controller
    _cameraController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      torchEnabled: false,
    );

    _flashAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _initConnectivity();
    _requestPermissionDirectly();
  }

  void _requestPermissionDirectly() async {
    final status = await Permission.camera.status;
    if (!status.isGranted) {
      await Permission.camera.request();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.resumed:
        _cameraController.start();
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        _cameraController.stop();
        break;
    }
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
    WidgetsBinding.instance.removeObserver(this);
    _cameraController.dispose();
    _flashAnimController.dispose();
    _connectivitySub?.cancel();
    _qrController.dispose();
    super.dispose();
  }

  /// Trigger scan validation (from live camera or manual input)
  Future<void> _triggerScan(String qrToken) async {
    if (qrToken.isEmpty) return;

    // Cooldown check (prevent duplicate calls for the same QR code within 2 seconds)
    final now = DateTime.now();
    if (_lastScannedToken == qrToken &&
        _lastScannedTime != null &&
        now.difference(_lastScannedTime!).inMilliseconds < 2000) {
      return;
    }

    _lastScannedToken = qrToken;
    _lastScannedTime = now;
    _isProcessingLiveScan = true;

    HapticFeedback.mediumImpact();
    _qrController.clear();

    await ref.read(gateProvider.notifier).handleScan(qrToken);

    if (mounted) {
      _flashAnimController.forward(from: 0).then((_) {
        if (mounted) {
          ref.read(gateProvider.notifier).hideFlash();
          _isProcessingLiveScan = false;
        }
      });
    }
  }

  void _onBarcodeDetected(BarcodeCapture capture) {
    if (_isProcessingLiveScan) return;

    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      final String? code = barcode.rawValue;
      if (code != null && code.trim().isNotEmpty) {
        _triggerScan(code.trim());
        break;
      }
    }
  }

  void _toggleTorch() async {
    await _cameraController.toggleTorch();
    setState(() {
      _torchOn = !_torchOn;
    });
  }

  @override
  Widget build(BuildContext context) {
    final gateState = ref.watch(gateProvider);
    final user = ref.watch(authProvider).user;

    return Scaffold(
      backgroundColor: AppTheme.slate50,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Gate Scanner', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            Text(user?.name ?? 'Gate Staff', style: const TextStyle(fontSize: 10, color: AppTheme.slate500)),
          ],
        ),
        backgroundColor: Colors.white,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: OfflineSyncIndicator(
              isOnline: gateState.isOnline,
              pendingCount: gateState.pendingSyncCount,
              onSyncTap: () => ref.read(gateProvider.notifier).syncPendingLogs(),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: AppTheme.dangerColor, size: 20),
            tooltip: 'Logout',
            onPressed: () => ref.read(authProvider.notifier).logout(),
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
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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

              // Live Camera Viewport
              Expanded(
                flex: 4,
                child: Container(
                  color: Colors.black,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Camera Stream
                      MobileScanner(
                        controller: _cameraController,
                        onDetect: _onBarcodeDetected,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.camera_alt_outlined, color: Colors.white70, size: 48),
                                  const SizedBox(height: 10),
                                  const Text(
                                    'Kamera Belum Aktif',
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    error.errorCode == MobileScannerErrorCode.permissionDenied
                                        ? 'Izin kamera belum diberikan. Aktifkan izin untuk memindai tiket.'
                                        : 'Error kamera: ${error.errorCode.name}',
                                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      ElevatedButton.icon(
                                        icon: const Icon(Icons.refresh, size: 14),
                                        label: const Text('Buka Kamera', style: TextStyle(fontSize: 11)),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppTheme.primaryColor,
                                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                        ),
                                        onPressed: () async {
                                          await Permission.camera.request();
                                          await _cameraController.start();
                                        },
                                      ),
                                      const SizedBox(width: 8),
                                      OutlinedButton.icon(
                                        icon: const Icon(Icons.settings, size: 14),
                                        label: const Text('Pengaturan', style: TextStyle(fontSize: 11)),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.white,
                                          side: const BorderSide(color: Colors.white54),
                                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                        ),
                                        onPressed: () => openAppSettings(),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),

                      // Scanner Frame Overlay
                      _ScannerFrame(),

                      // Camera Helper Controls (Torch & Switch Camera)
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Row(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: IconButton(
                                icon: Icon(
                                  _torchOn ? Icons.flash_on : Icons.flash_off,
                                  color: _torchOn ? Colors.amber : Colors.white,
                                  size: 20,
                                ),
                                tooltip: 'Flashlight',
                                onPressed: _toggleTorch,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.cameraswitch, color: Colors.white, size: 20),
                                tooltip: 'Ganti Kamera',
                                onPressed: () => _cameraController.switchCamera(),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Scanning hint
                      Positioned(
                        bottom: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.qr_code_scanner, color: AppTheme.accentColor, size: 14),
                              SizedBox(width: 6),
                              Text(
                                'Arahkan QR Tiket ke dalam bingkai',
                                style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Manual Input / Paste Fallback
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _qrController,
                        decoration: InputDecoration(
                          hintText: 'Atau ketik / tempel token QR manual...',
                          hintStyle: const TextStyle(fontSize: 11, color: AppTheme.slate400),
                          prefixIcon: const Icon(Icons.keyboard, size: 18),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppTheme.slate200),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        onSubmitted: (val) => _triggerScan(val.trim()),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: gateState.isScanning ? null : () => _triggerScan(_qrController.text.trim()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: gateState.isScanning
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('VALIDASI', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.white)),
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
                        padding: EdgeInsets.fromLTRB(16, 10, 16, 4),
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
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
                                          size: 18,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            log['token'],
                                            style: const TextStyle(
                                              fontFamily: 'monospace',
                                              fontSize: 11,
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
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color)),
        Text(label, style: const TextStyle(fontSize: 9, color: AppTheme.slate500, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _ScannerFrame extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      height: 200,
      child: CustomPaint(painter: _ScannerCornerPainter()),
    );
  }
}

class _ScannerCornerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.primaryColor
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;
    const len = 30.0;

    // Top-left
    canvas.drawLine(Offset.zero, const Offset(len, 0), paint);
    canvas.drawLine(Offset.zero, const Offset(0, len), paint);
    // Top-right
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
