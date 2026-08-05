import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/theme/app_theme.dart';
import '../widgets/dynamic_qr_view.dart';

class MyTicketsScreen extends StatefulWidget {
  const MyTicketsScreen({super.key});

  @override
  State<MyTicketsScreen> createState() => _MyTicketsScreenState();
}

class _MyTicketsScreenState extends State<MyTicketsScreen> {
  final ApiClient _apiClient = ApiClient();
  List<dynamic> _tickets = [];
  bool _isLoading = true;
  String? _selectedTicketId;

  @override
  void initState() {
    super.initState();
    _fetchTickets();
  }

  Future<void> _fetchTickets() async {
    setState(() => _isLoading = true);
    try {
      final res = await _apiClient.dio.get(ApiEndpoints.myTickets);
      if (res.data['success'] == true && mounted) {
        setState(() => _tickets = res.data['data'] ?? []);
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tiket Saya'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchTickets),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _tickets.isEmpty
              ? _buildEmptyState()
              : _selectedTicketId != null
                  ? _buildQrDetailView()
                  : _buildTicketList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.confirmation_number_outlined, size: 60, color: AppTheme.slate600),
          const SizedBox(height: 16),
          const Text('Belum ada tiket', style: TextStyle(color: AppTheme.slate400, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Beli tiket event favoritmu sekarang!', style: TextStyle(color: AppTheme.slate500, fontSize: 13)),
          const SizedBox(height: 20),
          ElevatedButton(onPressed: () => context.go('/catalog'), child: const Text('Browse Event')),
        ],
      ),
    );
  }

  Widget _buildTicketList() {
    return RefreshIndicator(
      onRefresh: _fetchTickets,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _tickets.length,
        itemBuilder: (context, index) {
          final ticket = _tickets[index];
          final status = ticket['status'] as String;

          return Card(
            margin: const EdgeInsets.only(bottom: 14),
            child: InkWell(
              onTap: status == 'valid' ? () => setState(() => _selectedTicketId = ticket['id']) : null,
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            ticket['event_name'] ?? 'Event',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                        _StatusBadge(status: status),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 14, color: AppTheme.secondaryColor),
                        const SizedBox(width: 4),
                        Text(ticket['location'] ?? '', style: const TextStyle(color: AppTheme.slate400, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined, size: 14, color: AppTheme.accentColor),
                        const SizedBox(width: 4),
                        Text(
                          ticket['event_date'] != null
                              ? DateTime.parse(ticket['event_date']).toLocal().toString().split(' ')[0]
                              : '',
                          style: const TextStyle(color: AppTheme.slate400, fontSize: 12),
                        ),
                      ],
                    ),
                    if (status == 'valid') ...[
                      const SizedBox(height: 14),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.qr_code_2, size: 16, color: AppTheme.primaryColor),
                            SizedBox(width: 8),
                            Text(
                              'Tap untuk tampilkan QR Tiket',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildQrDetailView() {
    final ticket = _tickets.firstWhere((t) => t['id'] == _selectedTicketId);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Back to list button
          TextButton.icon(
            onPressed: () => setState(() => _selectedTicketId = null),
            icon: const Icon(Icons.arrow_back, size: 16),
            label: const Text('Kembali ke daftar tiket'),
          ),
          const SizedBox(height: 8),

          Text(
            ticket['event_name'] ?? 'Event',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.location_on, size: 14, color: AppTheme.secondaryColor),
              const SizedBox(width: 4),
              Text(ticket['location'] ?? '', style: const TextStyle(color: AppTheme.slate400, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 20),

          // Dynamic QR
          DynamicQrView(ticketId: _selectedTicketId!),

          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.cardDark,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.cardBorder),
            ),
            child: Column(
              children: [
                _InfoRow('Ticket ID', _selectedTicketId!.substring(0, 16) + '...'),
                _InfoRow('Status', 'VALID ✅'),
                _InfoRow('Issued At', ticket['issued_at'] ?? '-'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.slate400, fontSize: 12)),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final Map<String, Color> colors = {
      'valid': AppTheme.accentColor,
      'used': AppTheme.slate500,
      'void': AppTheme.dangerColor,
      'refunded': AppTheme.warningColor,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: (colors[status] ?? AppTheme.slate500).withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: (colors[status] ?? AppTheme.slate500).withOpacity(0.5)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: colors[status] ?? AppTheme.slate400),
      ),
    );
  }
}
