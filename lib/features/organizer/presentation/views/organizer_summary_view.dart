import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/theme/app_theme.dart';
import 'package:wl_mobile/features/auth/presentation/viewmodels/auth_viewmodel.dart';

class OrganizerSummaryView extends ConsumerStatefulWidget {
  const OrganizerSummaryView({super.key});

  @override
  ConsumerState<OrganizerSummaryView> createState() => _OrganizerSummaryViewState();
}

class _OrganizerSummaryViewState extends ConsumerState<OrganizerSummaryView> {
  final ApiClient _apiClient = ApiClient();
  dynamic _metrics;
  bool _isLoading = true;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _fetchMetrics();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) => _fetchMetrics());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchMetrics() async {
    try {
      final res = await _apiClient.dio.get(ApiEndpoints.analyticsDashboard);
      if (res.data['success'] == true && mounted) {
        setState(() {
          _metrics = res.data['data'];
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatRupiah(num amount) {
    if (amount >= 1000000) return 'Rp ${(amount / 1000000).toStringAsFixed(1)}jt';
    if (amount >= 1000) return 'Rp ${(amount / 1000).toStringAsFixed(0)}rb';
    return 'Rp $amount';
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('ORGANIZER OVERVIEW', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
            Text(user?.name ?? 'Organizer', style: const TextStyle(fontSize: 11, color: AppTheme.slate400)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            tooltip: 'Refresh Data',
            onPressed: _fetchMetrics,
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: AppTheme.dangerColor, size: 20),
            onPressed: () => ref.read(authProvider.notifier).logout(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _metrics == null
              ? const Center(child: Text('Gagal memuat metrik.', style: TextStyle(color: AppTheme.slate400)))
              : RefreshIndicator(
                  onRefresh: _fetchMetrics,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'METRIK REAL-TIME (auto-refresh 30s)',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppTheme.slate500, letterSpacing: 1),
                        ),
                        const SizedBox(height: 14),

                        // KPI Grid
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 1.5,
                          children: [
                            _KpiCard(
                              icon: Icons.payments_outlined,
                              label: 'Total Revenue',
                              value: _formatRupiah(_metrics['total_revenue'] ?? 0),
                              sub: '${_metrics['total_tickets_sold'] ?? 0} tiket terjual',
                              gradient: const [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                            ),
                            _KpiCard(
                              icon: Icons.confirmation_number_outlined,
                              label: 'Tiket Sold',
                              value: '${_metrics['total_tickets_sold'] ?? 0}',
                              sub: '${_metrics['total_events'] ?? 0} event aktif',
                              gradient: const [Color(0xFF0891B2), Color(0xFF06B6D4)],
                            ),
                            _KpiCard(
                              icon: Icons.qr_code_scanner,
                              label: 'Gate Check-In',
                              value: '${_metrics['total_scanned'] ?? 0}',
                              sub: '${_metrics['checkin_rate_percent'] ?? 0}% dari sold',
                              gradient: const [Color(0xFF059669), Color(0xFF10B981)],
                            ),
                            _KpiCard(
                              icon: Icons.chair_outlined,
                              label: 'Occupancy',
                              value: '${_metrics['occupancy_rate_percent'] ?? 0}%',
                              sub: 'vs total kapasitas',
                              gradient: const [Color(0xFFB45309), Color(0xFFF59E0B)],
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Occupancy Bars
                        const Text(
                          'TINGKAT OCCUPANCY & CHECK-IN',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppTheme.slate500, letterSpacing: 1),
                        ),
                        const SizedBox(height: 12),

                        _ProgressBar(
                          label: 'Seat Occupancy Rate',
                          percent: (_metrics['occupancy_rate_percent'] ?? 0).toDouble(),
                          color: AppTheme.primaryColor,
                        ),
                        const SizedBox(height: 10),
                        _ProgressBar(
                          label: 'Gate Check-In Rate',
                          percent: (_metrics['checkin_rate_percent'] ?? 0).toDouble(),
                          color: AppTheme.accentColor,
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String sub;
  final List<Color> gradient;

  const _KpiCard({required this.icon, required this.label, required this.value, required this.sub, required this.gradient});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: Colors.white70, size: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
              Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white70)),
              Text(sub, style: const TextStyle(fontSize: 9, color: Colors.white54)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final String label;
  final double percent;
  final Color color;

  const _ProgressBar({required this.label, required this.percent, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.slate300)),
            Text('${percent.toStringAsFixed(1)}%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: color)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: (percent / 100).clamp(0.0, 1.0),
            minHeight: 8,
            backgroundColor: AppTheme.cardBorder,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}
