import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import 'package:wl_mobile/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import '../viewmodels/organizer_viewmodel.dart';

class OrganizerSummaryView extends ConsumerStatefulWidget {
  const OrganizerSummaryView({super.key});

  @override
  ConsumerState<OrganizerSummaryView> createState() => _OrganizerSummaryViewState();
}

class _OrganizerSummaryViewState extends ConsumerState<OrganizerSummaryView> {
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      ref.read(organizerProvider.notifier).fetchMetrics();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  String _formatRupiah(num amount) {
    if (amount >= 1000000) return 'Rp ${(amount / 1000000).toStringAsFixed(1)}jt';
    if (amount >= 1000) return 'Rp ${(amount / 1000).toStringAsFixed(0)}rb';
    return 'Rp $amount';
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final orgState = ref.watch(organizerProvider);
    final metrics = orgState.metrics;

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('ORGANIZER OVERVIEW', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 0.5, color: AppTheme.zinc950)),
            Text(user?.name ?? 'Organizer', style: const TextStyle(fontSize: 11, color: AppTheme.zinc500)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 20, color: AppTheme.zinc800),
            tooltip: 'Refresh Data',
            onPressed: () => ref.read(organizerProvider.notifier).fetchMetrics(),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: AppTheme.zinc600, size: 20),
            onPressed: () => ref.read(authProvider.notifier).logout(),
          ),
        ],
      ),
      body: orgState.isLoading && metrics == null
          ? const Center(child: CircularProgressIndicator(color: AppTheme.zinc950))
          : metrics == null
              ? const Center(child: Text('Gagal memuat metrik.', style: TextStyle(color: AppTheme.zinc400)))
              : RefreshIndicator(
                  color: AppTheme.zinc950,
                  onRefresh: () => ref.read(organizerProvider.notifier).fetchMetrics(),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'METRIK REAL-TIME (AUTO-REFRESH 30s)',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppTheme.zinc500, letterSpacing: 1),
                        ),
                        const SizedBox(height: 14),

                        // KPI Grid (Bento Style)
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 1.4,
                          children: [
                            _KpiCard(
                              icon: Icons.payments_outlined,
                              label: 'Total Revenue',
                              value: _formatRupiah(metrics['total_revenue'] ?? 0),
                              sub: '${metrics['total_tickets_sold'] ?? 0} tiket terjual',
                            ),
                            _KpiCard(
                              icon: Icons.confirmation_number_outlined,
                              label: 'Tiket Sold',
                              value: '${metrics['total_tickets_sold'] ?? 0}',
                              sub: '${metrics['total_events'] ?? 0} event aktif',
                            ),
                            _KpiCard(
                              icon: Icons.qr_code_scanner,
                              label: 'Gate Check-In',
                              value: '${metrics['total_scanned'] ?? 0}',
                              sub: '${metrics['checkin_rate_percent'] ?? 0}% dari sold',
                            ),
                            _KpiCard(
                              icon: Icons.chair_outlined,
                              label: 'Occupancy',
                              value: '${metrics['occupancy_rate_percent'] ?? 0}%',
                              sub: 'vs total kapasitas',
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Occupancy & Check-In Bars
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppTheme.zinc200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'TINGKAT OCCUPANCY & CHECK-IN',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppTheme.zinc500, letterSpacing: 0.8),
                              ),
                              const SizedBox(height: 14),

                              _ProgressBar(
                                label: 'Seat Occupancy Rate',
                                percent: (metrics['occupancy_rate_percent'] ?? 0).toDouble(),
                              ),
                              const SizedBox(height: 14),
                              _ProgressBar(
                                label: 'Gate Check-In Rate',
                                percent: (metrics['checkin_rate_percent'] ?? 0).toDouble(),
                              ),
                            ],
                          ),
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

  const _KpiCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.sub,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.zinc200),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 2, offset: Offset(0, 1)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.zinc500)),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.zinc100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: AppTheme.zinc900, size: 16),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppTheme.zinc950, fontFamily: 'monospace')),
              const SizedBox(height: 2),
              Text(sub, style: const TextStyle(fontSize: 9, color: AppTheme.zinc400, fontWeight: FontWeight.w500)),
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

  const _ProgressBar({
    required this.label,
    required this.percent,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.zinc800)),
            Text('${percent.toStringAsFixed(1)}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppTheme.zinc950, fontFamily: 'monospace')),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: (percent / 100).clamp(0.0, 1.0),
            minHeight: 8,
            backgroundColor: AppTheme.zinc100,
            valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.zinc950),
          ),
        ),
      ],
    );
  }
}
