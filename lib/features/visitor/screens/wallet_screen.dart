import 'package:flutter/material.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/theme/app_theme.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final ApiClient _apiClient = ApiClient();
  dynamic _wallet;
  List<dynamic> _transactions = [];
  bool _isLoading = true;
  bool _showTopUpModal = false;
  final _topUpController = TextEditingController();

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
        final data = res.data['data'];
        setState(() {
          _wallet = data['wallet'];
          _transactions = data['transactions'] ?? [];
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleTopUp() async {
    final amount = int.tryParse(_topUpController.text);
    if (amount == null || amount <= 0) return;

    try {
      final res = await _apiClient.dio.post(
        ApiEndpoints.walletTopup,
        data: {'amount': amount},
      );
      if (res.data['success'] == true && mounted) {
        setState(() => _showTopUpModal = false);
        _topUpController.clear();
        _fetchWallet();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Top-up Rp ${_formatRupiah(amount)} berhasil!'),
            backgroundColor: AppTheme.accentColor,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Top-up gagal. Coba lagi.'), backgroundColor: AppTheme.dangerColor),
        );
      }
    }
  }

  String _formatRupiah(num amount) {
    return amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wallet Cashless'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchWallet),
        ],
      ),
      body: Stack(
        children: [
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _fetchWallet,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Gradient Balance Card
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF312E81), Color(0xFF6366F1), Color(0xFF06B6D4)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryColor.withOpacity(0.4),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.account_balance_wallet, size: 20, color: Colors.white70),
                                  SizedBox(width: 8),
                                  Text('SALDO CASHLESS', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Text(
                                'Rp ${_formatRupiah(_wallet?['balance'] ?? 0)}',
                                style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'NFC: ${_wallet?['nfc_uid'] ?? 'Belum dipasangkan'}',
                                style: const TextStyle(color: Colors.white60, fontSize: 12),
                              ),
                              const SizedBox(height: 20),
                              ElevatedButton.icon(
                                onPressed: () => setState(() => _showTopUpModal = true),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: AppTheme.primaryDark,
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                icon: const Icon(Icons.add, size: 18),
                                label: const Text('TOP UP SALDO', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 28),
                        const Text(
                          'RIWAYAT TRANSAKSI',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppTheme.slate400, letterSpacing: 1),
                        ),
                        const SizedBox(height: 12),

                        if (_transactions.isEmpty)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(24.0),
                              child: Text('Belum ada transaksi.', style: TextStyle(color: AppTheme.slate500)),
                            ),
                          )
                        else
                          ...(_transactions.map((tx) => _buildTxRow(tx))),
                      ],
                    ),
                  ),
                ),

          // Top-Up Modal Overlay
          if (_showTopUpModal) _buildTopUpModal(),
        ],
      ),
    );
  }

  Widget _buildTxRow(dynamic tx) {
    final isDebit = tx['type'] == 'payment';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDebit ? AppTheme.dangerColor.withOpacity(0.15) : AppTheme.accentColor.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isDebit ? Icons.arrow_upward : Icons.arrow_downward,
              size: 16,
              color: isDebit ? AppTheme.dangerColor : AppTheme.accentColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tx['booth_name'] ?? (isDebit ? 'Pembayaran' : 'Top Up'), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13)),
                Text(tx['created_at'] ?? '', style: const TextStyle(color: AppTheme.slate500, fontSize: 11)),
              ],
            ),
          ),
          Text(
            '${isDebit ? '-' : '+'}Rp ${_formatRupiah(tx['nominal'] ?? 0)}',
            style: TextStyle(fontWeight: FontWeight.w900, color: isDebit ? AppTheme.dangerColor : AppTheme.accentColor),
          ),
        ],
      ),
    );
  }

  Widget _buildTopUpModal() {
    return GestureDetector(
      onTap: () => setState(() => _showTopUpModal = false),
      child: Container(
        color: Colors.black.withOpacity(0.6),
        child: Center(
          child: GestureDetector(
            onTap: () {},
            child: Container(
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.cardDark,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppTheme.cardBorder),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Top Up Saldo Cashless', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => setState(() => _showTopUpModal = false),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Preset amounts
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [100000, 250000, 500000, 1000000].map((amount) {
                      return ActionChip(
                        label: Text('Rp ${_formatRupiah(amount)}'),
                        onPressed: () => _topUpController.text = amount.toString(),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: _topUpController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Nominal Top Up (Rp)',
                      prefixText: 'Rp ',
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _handleTopUp,
                    child: const Text('PROSES TOP UP'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
