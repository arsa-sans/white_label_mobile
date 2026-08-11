import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/theme/app_theme.dart';
import '../../widgets/seat_map_grid.dart';

class EventDetailView extends ConsumerStatefulWidget {
  final String eventId;
  const EventDetailView({super.key, required this.eventId});

  @override
  ConsumerState<EventDetailView> createState() => _EventDetailViewState();
}

class _EventDetailViewState extends ConsumerState<EventDetailView> {
  final ApiClient _apiClient = ApiClient();
  dynamic _event;
  List<dynamic> _seats = [];
  bool _isLoading = true;
  String? _selectedSeatId;
  int _selectedSeatPrice = 0;
  String _selectedSeatName = '';

  @override
  void initState() {
    super.initState();
    _fetchEventAndSeats();
  }

  Future<void> _fetchEventAndSeats() async {
    setState(() => _isLoading = true);
    try {
      final evtRes = await _apiClient.dio.get(ApiEndpoints.eventDetail(widget.eventId));
      final seatsRes = await _apiClient.dio.get('/events/${widget.eventId}/seats');

      if (mounted) {
        setState(() {
          if (evtRes.data['success'] == true) _event = evtRes.data['data'];
          if (seatsRes.data['success'] == true) _seats = seatsRes.data['data']['seats'] ?? [];
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<List<SeatData?>> _buildSeatGrid() {
    if (_seats.isEmpty) return [];

    final Map<String, List<dynamic>> rowsMap = {};
    for (final s in _seats) {
      final row = (s['row'] ?? 'A').toString();
      rowsMap.putIfAbsent(row, () => []).add(s);
    }

    final List<List<SeatData?>> grid = [];
    rowsMap.forEach((rowName, list) {
      final List<SeatData?> seatRow = list.map((s) {
        final statusStr = (s['status'] ?? 'available').toString();
        SeatStatus status = SeatStatus.available;
        if (statusStr == 'sold' || statusStr == 'taken') {
          status = SeatStatus.taken;
        } else if (statusStr == 'locked') {
          status = SeatStatus.locked;
        }
        return SeatData(
          id: s['id'] ?? '',
          label: '${s['row']}${s['number']}',
          zone: s['category'] ?? 'General',
          price: (s['price'] ?? 0) is num ? (s['price'] as num).toInt() : 0,
          status: status,
        );
      }).toList();
      grid.add(seatRow);
    });

    return grid;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_event?['name'] ?? 'Detail Event'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _event == null
              ? const Center(child: Text('Event tidak ditemukan.', style: TextStyle(color: AppTheme.slate400)))
              : Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Banner
                            Image.network(
                              _event['banner_url'] ?? '',
                              height: 180,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => Container(
                                height: 180,
                                color: AppTheme.cardBorder,
                                child: const Icon(Icons.event, size: 64, color: AppTheme.slate500),
                              ),
                            ),

                            Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _event['name'] ?? '',
                                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(Icons.location_on_outlined, size: 16, color: AppTheme.secondaryColor),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          _event['location'] ?? '',
                                          style: const TextStyle(fontSize: 13, color: AppTheme.slate400),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    _event['description'] ?? '',
                                    style: const TextStyle(fontSize: 13, color: AppTheme.slate300, height: 1.5),
                                  ),
                                  const SizedBox(height: 24),

                                  // Seat Selection Header
                                  const Text(
                                    'PILIH KURSI (SEAT MAP REAL-TIME)',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppTheme.slate400, letterSpacing: 1),
                                  ),
                                  const SizedBox(height: 12),

                                  SeatMapGrid(
                                    seats: _buildSeatGrid(),
                                    onSeatTapped: (selectedSeats) {
                                      if (selectedSeats.isNotEmpty) {
                                        final first = selectedSeats.first;
                                        setState(() {
                                          _selectedSeatId = first.id;
                                          _selectedSeatPrice = first.price;
                                          _selectedSeatName = first.label;
                                        });
                                      } else {
                                        setState(() {
                                          _selectedSeatId = null;
                                          _selectedSeatPrice = 0;
                                          _selectedSeatName = '';
                                        });
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Checkout Sticky Bar
                    if (_selectedSeatId != null)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(
                          color: AppTheme.cardDark,
                          border: Border(top: BorderSide(color: AppTheme.cardBorder)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Kursi $_selectedSeatName', style: const TextStyle(fontSize: 12, color: AppTheme.slate400)),
                                Text(
                                  'Rp ${_selectedSeatPrice.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}',
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.accentColor),
                                ),
                              ],
                            ),
                            ElevatedButton(
                              onPressed: () {
                                context.push('/checkout/${widget.eventId}?seatId=$_selectedSeatId');
                              },
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                              ),
                              child: const Text('PROSES CHECKOUT'),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
    );
  }
}
