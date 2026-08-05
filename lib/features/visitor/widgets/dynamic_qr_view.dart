import 'dart:async';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_endpoints.dart';
import '../../../../core/theme/app_theme.dart';

class DynamicQrView extends StatefulWidget {
  final String ticketId;
  const DynamicQrView({super.key, required this.ticketId});

  @override
  State<DynamicQrView> createState() => _DynamicQrViewState();
}

class _DynamicQrViewState extends State<DynamicQrView> {
  final ApiClient _apiClient = ApiClient();

  String? _qrToken;
  int _expiresInSeconds = 30;
  Timer? _refreshTimer;
  Timer? _countdownTimer;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchQrToken();
    _scheduleAutoRefresh();
  }

  void _scheduleAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 28), (_) {
      _fetchQrToken();
    });
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (_expiresInSeconds > 0) _expiresInSeconds--;
      });
    });
  }

  Future<void> _fetchQrToken() async {
    try {
      final res = await _apiClient.dio.get(ApiEndpoints.qrToken(widget.ticketId));
      if (res.data['success'] == true && mounted) {
        setState(() {
          _qrToken = res.data['data']['qr_token'];
          _expiresInSeconds = res.data['data']['expires_in_seconds'] ?? 30;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = _expiresInSeconds / 30.0;
    final isExpiringSoon = _expiresInSeconds <= 5;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        children: [
          if (_isLoading)
            const SizedBox(
              height: 180,
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_qrToken == null)
            const SizedBox(
              height: 180,
              child: Center(
                child: Text('QR tidak tersedia', style: TextStyle(color: AppTheme.slate400)),
              ),
            )
          else ...[
            // QR Code Container with glow effect
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: QrImageView(
                data: _qrToken!,
                version: QrVersions.auto,
                size: 180,
                backgroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),

            // Countdown Timer
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isExpiringSoon ? AppTheme.warningColor : AppTheme.accentColor,
                    ),
                    backgroundColor: AppTheme.cardBorder,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Refresh dalam $_expiresInSeconds detik',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isExpiringSoon ? AppTheme.warningColor : AppTheme.slate400,
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.accentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.accentColor.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.security, size: 12, color: AppTheme.accentColor),
                const SizedBox(width: 4),
                const Text(
                  'HMAC-SHA256 · Auto-rotate 30s · Server-signed',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.accentColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
