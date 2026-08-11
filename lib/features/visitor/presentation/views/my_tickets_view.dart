import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/theme/app_theme.dart';
import '../../widgets/dynamic_qr_view.dart';

class MyTicketsView extends StatefulWidget {
  const MyTicketsView({super.key});

  @override
  State<MyTicketsView> createState() => _MyTicketsViewState();
}

class _MyTicketsViewState extends State<MyTicketsView> {
  final ApiClient _apiClient = ApiClient();
  List<dynamic> _tickets = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMyTickets();
  }

  Future<void> _fetchMyTickets() async {
    setState(() => _isLoading = true);
    try {
      final res = await _apiClient.dio.get(ApiEndpoints.myTickets);
      if (res.data['success'] == true && mounted) {
        setState(() {
          _tickets = res.data['data'] ?? [];
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showQrModal(dynamic ticket) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              ticket['event_name'] ?? 'Tiket Masuk Event',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            Text(
              'Kursi: ${ticket['seat_name']} (${ticket['category']})',
              style: const TextStyle(fontSize: 12, color: AppTheme.slate400),
            ),
            const SizedBox(height: 20),

            DynamicQrView(ticketId: ticket['id']),

            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => context.pop(),
              child: const Text('TUTUP'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tiket Saya')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _tickets.isEmpty
              ? const Center(child: Text('Belum ada tiket dibeli.', style: TextStyle(color: AppTheme.slate400)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _tickets.length,
                  itemBuilder: (context, index) {
                    final t = _tickets[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: const Icon(Icons.qr_code, color: AppTheme.primaryColor, size: 36),
                        title: Text(t['event_name'] ?? 'Event Ticket', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                        subtitle: Text('Seat: ${t['seat_name']} (${t['category']})', style: const TextStyle(color: AppTheme.slate400, fontSize: 12)),
                        trailing: ElevatedButton(
                          onPressed: () => _showQrModal(t),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            minimumSize: Size.zero,
                          ),
                          child: const Text('Tampilkan QR', style: TextStyle(fontSize: 11)),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
