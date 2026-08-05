import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/storage/local_database.dart';
import '../../../core/theme/app_theme.dart';
import '../widgets/offline_sync_indicator.dart';

class GateScannerScreen extends StatefulWidget {
  const GateScannerScreen({super.key});

  @override
  State<GateScannerScreen> createState() => _GateScannerScreenState();
}

class _GateScannerScreenState extends State<GateScannerScreen> with TickerProviderStateMixin {
  final ApiClient _apiClient = ApiClient();
  final _db = LocalDatabase();
  final _qrController = TextEditingController();

  bool _isOnline = true;
  bool _isScanning = false;
  bool _showFlash = false;
  bool _flashSuccess = true;
  int _sessionScanCount = 0;
  int _sessionValid = 0;
  int _sessionInvalid = 0;
  int _pendingSyncCount = 0;
  final List<Map<String, dynamic>> _sessionLogs = [];

  late AnimationController _flashAnimController;
  StreamSubscription? _connectivitySub;

  @override
  void initState() {
    super.initState();
    _flashAnimController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _initConnectivity();
    _refreshPendingCount();
  }

  Future<void> _refreshPendingCount() async {
    final pending = await _db.getPendingLogs();
    if (mounted) setState(() => _pendingSyncCount = pending.length);
  }

  void _initConnectivity() async {
    final result = await Connectivity().checkConnectivity();
    setState(() {
      _isOnline = result.first != ConnectivityResult.none;
    });
    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      if (!mounted) return;
      final online = results.first != ConnectivityResult.none;
      setState(() {
        _isOnline = online;
      });
      // Auto-sync pending logs when coming back online
      if (online) _syncPendingLogs();
    });
  }

  /// Syncs all pending offline logs to the backend.
  Future<void> _syncPendingLogs() async {
    final pending = await _db.getPendingLogs();
    if (pending.isEmpty) return;
    try {
      await _apiClient.dio.post(
        ApiEndpoints.gateSync,
        data: {
          'logs': pending.map((l) => {
            'token': l.token,
            'result': l.result,
            'scanned_at': l.scannedAt,
          }).toList(),
        },
      );
      await _db.markAsSynced(pending.map((l) => l.id).toList());
      await _db.cleanOldSyncedLogs();
      _refreshPendingCount();
    } catch (_) {
      // Will retry next time connectivity is restored
    }
  }

  @override
  void dispose() {
    _flashAnimController.dispose();
    _connectivitySub?.cancel();
    _qrController.dispose();
    _db.close();
    super.dispose();
  }

  Future<void> _handleScan(String qrToken) async {
    if (qrToken.isEmpty || _isScanning) return;
    setState(() => _isScanning = true);
    HapticFeedback.mediumImpact();

    String result = 'invalid';
    bool isValid = false;

    if (_isOnline) {
      // ── Online path: call backend ────────────────────────────────────────
      try {
        final res = await _apiClient.dio.post(
          ApiEndpoints.gateScan,
          data: {'token': qrToken},
        );
        result = res.data['data']?['result'] ?? 'invalid';
        isValid = result == 'valid';
        // Persist the online result as already-synced
        await _db.insertScanLog(
          token: qrToken,
          result: result,
          message: res.data['data']?['message']?.toString() ?? '',
        );
        // Mark it synced immediately (we got the result from backend)
        final logs = await _db.getRecentLogs(limit: 1);
        if (logs.isNotEmpty) await _db.markAsSynced([logs.first.id]);
      } catch (_) {
        // Network error while online — store as offline fallback
        result = 'offline';
        isValid = false;
        await _db.insertScanLog(token: qrToken, result: 'offline');
        await _refreshPendingCount();
      }
    } else {
      // ── Offline path: store locally, sync later ──────────────────────────
      result = 'offline';
      isValid = false;
      await _db.insertScanLog(token: qrToken, result: 'offline');
      await _refreshPendingCount();
    }

    // Full-screen flash feedback
    if (mounted) {
      setState(() {
        _showFlash = true;
        _flashSuccess = isValid;
        _sessionScanCount++;
        if (isValid) { _sessionValid++; } else { _sessionInvalid++; }
        _sessionLogs.insert(0, {
          'result': result,
          'token': qrToken.length < 20 ? qrToken : '${qrToken.substring(0, 20)}...',
          'time': TimeOfDay.now().format(context),
        });
      });
    }

    HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) {
      setState(() => _showFlash = false);
      _qrController.clear();
      setState(() => _isScanning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF030712),
      body: Stack(
        children: [
          // Main content
          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.primaryColor.withOpacity(0.4)),
                        ),
                        child: const Icon(Icons.qr_code_scanner, color: AppTheme.primaryColor, size: 22),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('GATE SCANNER', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1)),
                            Text('Validasi Tiket Pengunjung', style: TextStyle(fontSize: 11, color: AppTheme.slate400)),
                          ],
                        ),
                      ),
                      OfflineSyncIndicator(isOnline: _isOnline),
                    ],
                  ),
                ),

                // Session Stats Bar
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppTheme.cardDark,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.cardBorder),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatPill('Total', _sessionScanCount.toString(), Colors.white),
                      _StatPill('Valid ✓', _sessionValid.toString(), AppTheme.accentColor),
                      _StatPill('Invalid ✗', _sessionInvalid.toString(), AppTheme.dangerColor),
                      if (_pendingSyncCount > 0)
                        _StatPill('Pending ☁', _pendingSyncCount.toString(), AppTheme.warningColor),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Scan Input Area (simulating camera QR scan)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      // Simulated QR Scan Viewfinder
                      Container(
                        height: 220,
                        decoration: BoxDecoration(
                          color: const Color(0xFF020617),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppTheme.primaryColor.withOpacity(0.5), width: 2),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Scanner corners
                            _ScannerFrame(),
                            const SizedBox(height: 12),
                            const Text('Arahkan kamera ke QR Tiket', style: TextStyle(color: AppTheme.slate400, fontSize: 12)),
                            const Text('atau input manual di bawah', style: TextStyle(color: AppTheme.slate600, fontSize: 11)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Manual QR Input
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _qrController,
                              style: const TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 12),
                              decoration: const InputDecoration(
                                hintText: 'Input QR Token manual...',
                                prefixIcon: Icon(Icons.keyboard, size: 18),
                              ),
                              onSubmitted: _handleScan,
                            ),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton(
                            onPressed: _isScanning ? null : () => _handleScan(_qrController.text),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                            ),
                            child: _isScanning
                                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Icon(Icons.send),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Session Log
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text('LOG SESI SCAN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppTheme.slate500, letterSpacing: 1)),
                  ),
                ),
                const SizedBox(height: 8),

                Expanded(
                  child: _sessionLogs.isEmpty
                      ? const Center(
                          child: Text('Belum ada scan di sesi ini.', style: TextStyle(color: AppTheme.slate600, fontSize: 12)),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _sessionLogs.length,
                          itemBuilder: (ctx, i) {
                            final log = _sessionLogs[i];
                            final isValid = log['result'] == 'valid';
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: AppTheme.cardDark,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isValid ? AppTheme.accentColor.withOpacity(0.3) : AppTheme.dangerColor.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    isValid ? Icons.check_circle : Icons.cancel,
                                    size: 16,
                                    color: isValid ? AppTheme.accentColor : AppTheme.dangerColor,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(log['token'] ?? '', style: const TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 11)),
                                  ),
                                  Text(log['time'] ?? '', style: const TextStyle(color: AppTheme.slate500, fontSize: 11)),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),

          // Full-Screen Flash Overlay
          if (_showFlash)
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              color: _flashSuccess
                  ? AppTheme.accentColor.withOpacity(0.92)
                  : AppTheme.dangerColor.withOpacity(0.92),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _flashSuccess ? Icons.check_circle_outline : Icons.cancel_outlined,
                      size: 80,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _flashSuccess ? 'TIKET VALID ✓' : 'TIKET INVALID ✗',
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white),
                    ),
                  ],
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
