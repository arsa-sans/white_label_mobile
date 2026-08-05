import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/theme/app_theme.dart';
import '../widgets/seat_map_grid.dart';

class EventDetailScreen extends ConsumerStatefulWidget {
  final String eventId;
  const EventDetailScreen({super.key, required this.eventId});

  @override
  ConsumerState<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends ConsumerState<EventDetailScreen> {
  final ApiClient _apiClient = ApiClient();
  dynamic _event;
  List<dynamic> _seats = [];
  bool _isLoading = true;
  String? _selectedSeatId;
  bool _isLocking = false;

  @override
  void initState() {
    super.initState();
    _fetchEventDetail();
  }

  Future<void> _fetchEventDetail() async {
    setState(() => _isLoading = true);
    try {
      final res = await _apiClient.dio.get('${ApiEndpoints.events}/${widget.eventId}');
      if (res.data['success'] == true) {
        setState(() {
          _event = res.data['data']['event'];
          _seats = res.data['data']['seats'] ?? [];
          _isLoading = false;
        });
      }
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleLockSeat() async {
    if (_selectedSeatId == null) return;
    setState(() => _isLocking = true);

    try {
      final res = await _apiClient.dio.post(
        ApiEndpoints.lockSeat,
        data: {
          'event_id': widget.eventId,
          'seat_id': _selectedSeatId,
        },
      );

      if (res.data['success'] == true) {
        if (mounted) {
          context.push('/checkout/${widget.eventId}?seatId=$_selectedSeatId');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengunci kursi. Coba lagi.'), backgroundColor: AppTheme.dangerColor),
        );
      }
    } finally {
      if (mounted) setState(() => _isLocking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_event == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Event tidak ditemukan.')),
      );
    }

    final selectedSeat = _seats.firstWhere((s) => s['id'] == _selectedSeatId, orElse: () => null);

    return Scaffold(
      appBar: AppBar(
        title: Text(_event['name'] ?? 'Detail Event'),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Banner Image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      _event['banner_url'] ?? '',
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 180,
                        color: AppTheme.cardBorder,
                        child: const Icon(Icons.image, size: 48),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Text(
                    _event['name'] ?? '',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white),
                  ),
                  const SizedBox(height: 8),

                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 16, color: AppTheme.secondaryColor),
                      const SizedBox(width: 4),
                      Text(_event['location'] ?? '', style: const TextStyle(color: AppTheme.slate300, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(_event['description'] ?? '', style: const TextStyle(color: AppTheme.slate400, fontSize: 13)),
                  const SizedBox(height: 24),

                  const Text(
                    'PETA KURSI VENUE (INTERAKTIF SEAT MAP)',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Pilih kursi yang tersedia. Kursi akan dikunci (TTL 5 mnt) saat Anda klik "Lanjut Checkout".',
                    style: TextStyle(fontSize: 11, color: AppTheme.slate400),
                  ),
                  const SizedBox(height: 16),

                  // Interactive Seat Grid
                  _buildSeatGrid(),
                ],
              ),
            ),
          ),

          // Bottom Bar for Checkout Action
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppTheme.cardDark,
              border: Border(top: BorderSide(color: AppTheme.cardBorder)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        selectedSeat != null ? 'Kursi: ${selectedSeat['category']} ${selectedSeat['row']}${selectedSeat['number']}' : 'Belum ada kursi dipilih',
                        style: const TextStyle(fontSize: 12, color: AppTheme.slate400),
                      ),
                      Text(
                        selectedSeat != null ? 'Rp ${(selectedSeat['price'] ?? 0).toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}' : 'Rp 0',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.accentColor),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: _selectedSeatId == null || _isLocking ? null : _handleLockSeat,
                  child: _isLocking
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Kunci & Checkout'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeatGrid() {
    if (_seats.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        alignment: Alignment.center,
        child: const Text('Belum ada data kursi.', style: TextStyle(color: AppTheme.slate500)),
      );
    }

    // Convert backend seat data to SeatData model rows.
    // Group by row label so each row becomes one List<SeatData?>.
    final Map<String, List<dynamic>> grouped = {};
    for (final s in _seats) {
      final row = (s['row'] ?? 'A') as String;
      grouped.putIfAbsent(row, () => []).add(s);
    }
    final rowKeys = grouped.keys.toList()..sort();
    final rows = rowKeys.map((rowKey) {
      return grouped[rowKey]!.map((s) {
        SeatStatus status;
        switch (s['status']) {
          case 'sold': status = SeatStatus.taken; break;
          case 'locked': status = SeatStatus.locked; break;
          default: status = SeatStatus.available;
        }
        return SeatData(
          id: s['id'],
          label: '${s['row']}${s['number']}',
          zone: s['category'] ?? 'Regular',
          price: (s['price'] ?? 0) as int,
          status: status,
        );
      }).toList();
    }).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF020617),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: SeatMapGrid(
        seats: rows,
        onSeatTapped: (selected) {
          setState(() {
            _selectedSeatId = selected.isNotEmpty ? selected.first.id : null;
          });
        },
        maxSelectable: 1,
      ),
    );
  }
}
