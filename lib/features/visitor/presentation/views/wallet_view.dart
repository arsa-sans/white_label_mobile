import 'package:flutter/material.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/theme/app_theme.dart';

class WalletView extends StatefulWidget {
  const WalletView({super.key});

  @override
  State<WalletView> createState() => _WalletViewState();
}

class _WalletViewState extends State<WalletView> {
  final ApiClient _apiClient = ApiClient();
  dynamic _wallet;
  List<dynamic> _txs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchWallet();
  }

  Future<void> _fetchWallet() async {
    setState(() => _isLoading = true);
    try {
      final res = await _apiClient.dio.get(ApiEndpoints.wallet);
      if (res.data['success'] == true && mounted) {
        setState(() {
          _wallet = res.data['data']['wallet'];
          _txs = res.data['data']['transactions'] ?? [];
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _topup(int amount) async {
    try {
      final res = await _apiClient.dio.post(
        ApiEndpoints.walletTopup,
        data: {'amount': amount, 'payment_method': 'QRIS Instant'},
      );
      if (res.data['success'] == true) {
        _fetchWallet();
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dompet Cashless Event')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Wallet Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4F46E5), Color(0xFF06B6D4)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Saldo Wristband NFC', style: TextStyle(color: Colors.white70, fontSize: 12)),
                        const SizedBox(height: 6),
                        Text(
                          'Rp ${(_wallet?['balance'] ?? 0).toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}',
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white),
                        ),
                        const SizedBox(height: 12),
                        Text('NFC UID: ${_wallet?['nfc_uid'] ?? 'NFC-UNPAIRED'}', style: const TextStyle(color: Colors.white60, fontSize: 11, fontFamily: 'monospace')),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Topup Buttons
                  const Text('Top-Up Saldo Instant:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.slate400)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: [50000, 100000, 200000].map((amt) {
                      return ElevatedButton(
                        onPressed: () => _topup(amt),
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cardDark),
                        child: Text('+Rp ${amt ~/ 1000}k'),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  const Text('Riwayat Transaksi:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.slate400)),
                  const SizedBox(height: 10),
                  Expanded(
                    child: _txs.isEmpty
                        ? const Center(child: Text('Belum ada transaksi.', style: TextStyle(color: AppTheme.slate500)))
                        : ListView.builder(
                            itemCount: _txs.length,
                            itemBuilder: (ctx, i) {
                              final tx = _txs[i];
                              return ListTile(
                                leading: Icon(
                                  tx['type'] == 'topup' ? Icons.add_circle_outline : Icons.remove_circle_outline,
                                  color: tx['type'] == 'topup' ? AppTheme.accentColor : AppTheme.dangerColor,
                                ),
                                title: Text(tx['description'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 12)),
                                trailing: Text(
                                  'Rp ${tx['amount']}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: tx['type'] == 'topup' ? AppTheme.accentColor : Colors.white,
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}
