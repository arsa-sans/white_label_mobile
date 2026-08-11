import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/theme/app_theme.dart';
import 'package:wl_mobile/features/auth/presentation/viewmodels/auth_viewmodel.dart';

class CatalogView extends ConsumerStatefulWidget {
  const CatalogView({super.key});

  @override
  ConsumerState<CatalogView> createState() => _CatalogViewState();
}

class _CatalogViewState extends ConsumerState<CatalogView> {
  final ApiClient _apiClient = ApiClient();
  List<dynamic> _events = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedCategory = 'All';

  final List<String> _categories = ['All', 'Concert', 'Festival', 'Conference', 'Sport'];

  @override
  void initState() {
    super.initState();
    _fetchEvents();
  }

  Future<void> _fetchEvents() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiClient.dio.get(ApiEndpoints.events);
      if (response.data['success'] == true) {
        setState(() {
          _events = response.data['data'] ?? [];
          _isLoading = false;
        });
      }
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;

    final filtered = _events.where((e) {
      final matchesSearch = e['name'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
          e['location'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCategory = _selectedCategory == 'All' || e['category'] == _selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('E-TICKETING CATALOG', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
            Text(
              'Halo, ${user?.name ?? 'Visitor'} 👋',
              style: const TextStyle(fontSize: 11, color: AppTheme.slate400),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.confirmation_number_outlined),
            tooltip: 'Tiket Saya',
            onPressed: () => context.push('/my-tickets'),
          ),
          IconButton(
            icon: const Icon(Icons.account_balance_wallet_outlined),
            tooltip: 'Wallet Cashless',
            onPressed: () => context.push('/wallet'),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: AppTheme.dangerColor),
            onPressed: () => ref.read(authProvider.notifier).logout(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchEvents,
        child: Column(
          children: [
            // Search Bar & Categories
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(
                    onChanged: (val) => setState(() => _searchQuery = val),
                    decoration: const InputDecoration(
                      hintText: 'Cari event musik, konser, lokasi...',
                      prefixIcon: Icon(Icons.search, size: 20),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 36,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _categories.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final cat = _categories[index];
                        final isSelected = cat == _selectedCategory;
                        return ChoiceChip(
                          label: Text(cat),
                          selected: isSelected,
                          selectedColor: AppTheme.primaryColor,
                          backgroundColor: AppTheme.cardDark,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : AppTheme.slate400,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                          onSelected: (_) => setState(() => _selectedCategory = cat),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Event List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filtered.isEmpty
                      ? const Center(
                          child: Text(
                            'Tidak ada event ditemukan.',
                            style: TextStyle(color: AppTheme.slate400, fontSize: 13),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final event = filtered[index];
                            return _buildEventCard(context, event);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventCard(BuildContext context, dynamic event) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => context.push('/event-detail/${event['id']}'),
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: Stack(
                children: [
                  Image.network(
                    event['banner_url'] ?? '',
                    height: 140,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 140,
                      color: AppTheme.cardBorder,
                      child: const Icon(Icons.event, size: 48, color: AppTheme.slate500),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        event['category'] ?? 'Event',
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Content Details
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event['name'] ?? '',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 14, color: AppTheme.secondaryColor),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          event['location'] ?? '',
                          style: const TextStyle(fontSize: 12, color: AppTheme.slate400),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined, size: 14, color: AppTheme.accentColor),
                      const SizedBox(width: 4),
                      Text(
                        event['start_date'] != null
                            ? DateTime.parse(event['start_date']).toLocal().toString().split(' ')[0]
                            : '',
                        style: const TextStyle(fontSize: 12, color: AppTheme.slate400),
                      ),
                    ],
                  ),
                  const Divider(height: 24, color: AppTheme.cardBorder),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Harga Tiket Mula', style: TextStyle(fontSize: 10, color: AppTheme.slate400)),
                          Text(
                            'Rp ${(event['price_min'] ?? 150000).toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppTheme.accentColor),
                          ),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: () => context.push('/event-detail/${event['id']}'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        ),
                        child: const Text('Beli Tiket', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
