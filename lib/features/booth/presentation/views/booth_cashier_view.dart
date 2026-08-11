import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/theme/app_theme.dart';

class BoothCashierView extends StatefulWidget {
  const BoothCashierView({super.key});

  @override
  State<BoothCashierView> createState() => _BoothCashierViewState();
}

class _BoothCashierViewState extends State<BoothCashierView> {
  final ApiClient _apiClient = ApiClient();
  final _nfcController = TextEditingController(text: 'NFC-994821');
  final _noteController = TextEditingController();

  int _amount = 0;
  bool _isProcessing = false;
  bool _showResult = false;
  bool _resultSuccess = false;
  String _resultTitle = '';
  String _resultMessage = '';
  int? _remainingBalance;
  int _totalSalesSession = 0;
  final List<Map<String, dynamic>> _sessionTx = [];

  final List<int> _presets = [15000, 25000, 35000, 50000, 75000, 100000];

  void _handleNumpad(String val) {
    setState(() {
      if (val == 'C') {
        _amount = 0;
      } else if (val == 'DEL') {
        if (_amount > 0) _amount = int.parse(_amount.toString().substring(0, _amount.toString().length - 1).isEmpty ? '0' : _amount.toString().substring(0, _amount.toString().length - 1));
      } else {
        _amount = int.parse('$_amount$val');
      }
    });
  }

  void _addPreset(int amount) {
    setState(() => _amount += amount);
  }

  Future<void> _handleCharge() async {
    if (_amount <= 0) return;
    final nfcUid = _nfcController.text.trim();
    if (nfcUid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan NFC UID Wristband pengunjung.')),
      );
      return;
    }

    setState(() => _isProcessing = true);
    HapticFeedback.mediumImpact();

    final referenceId = 'mobile-ref-${DateTime.now().millisecondsSinceEpoch}';

    try {
      final res = await _apiClient.dio.post(
        ApiEndpoints.boothDebit,
        data: {
          'amount': _amount,
          'nfc_uid': nfcUid,
          'reference_id': referenceId,
          'booth_name': 'Mobile Booth Cashier',
          'items_summary': _noteController.text.isNotEmpty ? _noteController.text : 'Booth Transaction',
        },
      );

      if (res.data['success'] == true) {
        final data = res.data['data'];
        final remaining = data['remaining_balance'] ?? data['wallet']?['balance'] ?? 0;
        HapticFeedback.heavyImpact();
        setState(() {
          _resultSuccess = true;
          _resultTitle = 'TRANSAKSI BERHASIL!';
          _resultMessage = 'Pembayaran Rp ${_formatRupiah(_amount)} diterima.';
          _remainingBalance = remaining;
          _showResult = true;
          _totalSalesSession += _amount;
          _sessionTx.insert(0, {
            'amount': _amount,
            'nfc': nfcUid,
            'note': _noteController.text,
            'remaining': remaining,
            'time': TimeOfDay.now().format(context),
          });
        });
      } else {
        throw Exception(res.data['message'] ?? 'Debit gagal');
      }
    } catch (e) {
      HapticFeedback.vibrate();
      setState(() {
        _resultSuccess = false;
        _resultTitle = 'TRANSAKSI GAGAL!';
        _resultMessage = 'Saldo tidak cukup atau NFC tidak valid.';
        _showResult = true;
      });
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _closeResult() {
    setState(() {
      _showResult = false;
      _amount = 0;
      _noteController.clear();
      _remainingBalance = null;
    });
  }

  String _formatRupiah(int amount) {
    return amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.storefront, size: 18, color: AppTheme.primaryColor),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('KASIR BOOTH', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white)),
                Text('Cashless NFC Transaction', style: TextStyle(fontSize: 10, color: AppTheme.slate400)),
              ],
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text('Omset Sesi', style: TextStyle(fontSize: 10, color: AppTheme.slate400)),
                Text(
                  'Rp ${_formatRupiah(_totalSalesSession)}',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppTheme.accentColor),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Row(
            children: [
              // Left: Numpad & Charge
              Expanded(
                flex: 6,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // Amount Display
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF020617),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.cardBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text('TOTAL TAGIHAN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.slate500, letterSpacing: 1)),
                            const SizedBox(height: 4),
                            Text(
                              'Rp ${_formatRupiah(_amount)}',
                              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppTheme.accentColor),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // NFC Input + Note
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _nfcController,
                              style: const TextStyle(fontSize: 12, fontFamily: 'monospace', fontWeight: FontWeight.bold),
                              decoration: const InputDecoration(
                                labelText: 'NFC UID Wristband',
                                prefixIcon: Icon(Icons.nfc, size: 18),
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _noteController,
                              style: const TextStyle(fontSize: 12),
                              decoration: const InputDecoration(
                                labelText: 'Catatan item',
                                prefixIcon: Icon(Icons.receipt_long, size: 18),
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Quick Presets
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: _presets.map((p) => ElevatedButton(
                          onPressed: () => _addPreset(p),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF334155),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            minimumSize: Size.zero,
                            textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                          child: Text('+${(p / 1000).toInt()}k'),
                        )).toList(),
                      ),
                      const SizedBox(height: 12),

                      // Numpad
                      Expanded(
                        child: GridView.count(
                          crossAxisCount: 3,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                          childAspectRatio: 1.6,
                          physics: const NeverScrollableScrollPhysics(),
                          children: [
                            ...['1','2','3','4','5','6','7','8','9','C','0','DEL'].map((btn) {
                              return ElevatedButton(
                                onPressed: () => _handleNumpad(btn),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: btn == 'C'
                                      ? const Color(0xFF451A03).withValues(alpha: 0.8)
                                      : btn == 'DEL'
                                          ? const Color(0xFF450A0A).withValues(alpha: 0.8)
                                          : const Color(0xFF1E293B),
                                  foregroundColor: btn == 'C'
                                      ? AppTheme.warningColor
                                      : btn == 'DEL'
                                          ? AppTheme.dangerColor
                                          : Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: const BorderSide(color: AppTheme.cardBorder),
                                  ),
                                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                                ),
                                child: Text(btn),
                              );
                            }),
                          ],
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Charge Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isProcessing || _amount <= 0 ? null : _handleCharge,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.accentColor,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: _isProcessing
                              ? const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                                    SizedBox(width: 10),
                                    Text('Memproses...'),
                                  ],
                                )
                              : Text(
                                  'BAYAR NFC WRISTBAND\nRp ${_formatRupiah(_amount)}',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, height: 1.3),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Right: Transaction Log
              Expanded(
                flex: 4,
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.cardDark,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.cardBorder),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            const Icon(Icons.receipt, size: 14, color: AppTheme.primaryColor),
                            const SizedBox(width: 6),
                            Text(
                              'LOG SESI (${_sessionTx.length})',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppTheme.slate300, letterSpacing: 0.5),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1, color: AppTheme.cardBorder),
                      Expanded(
                        child: _sessionTx.isEmpty
                            ? const Center(child: Text('Belum ada transaksi', style: TextStyle(color: AppTheme.slate600, fontSize: 11)))
                            : ListView.builder(
                                padding: const EdgeInsets.all(8),
                                itemCount: _sessionTx.length,
                                itemBuilder: (ctx, i) {
                                  final tx = _sessionTx[i];
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF020617),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '+Rp ${_formatRupiah(tx['amount'] as int)}',
                                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppTheme.accentColor),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(tx['nfc'] ?? '', style: const TextStyle(fontSize: 10, color: AppTheme.slate500, fontFamily: 'monospace')),
                                        if (tx['note']?.isNotEmpty == true)
                                          Text(tx['note'], style: const TextStyle(fontSize: 10, color: AppTheme.slate600)),
                                        Text(tx['time'] ?? '', style: const TextStyle(fontSize: 10, color: AppTheme.slate600)),
                                      ],
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Result Modal Overlay
          if (_showResult)
            Container(
              color: Colors.black.withValues(alpha: 0.85),
              child: Center(
                child: Container(
                  margin: const EdgeInsets.all(32),
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: _resultSuccess ? AppTheme.accentColor.withValues(alpha: 0.5) : AppTheme.dangerColor.withValues(alpha: 0.5),
                      width: 2,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: (_resultSuccess ? AppTheme.accentColor : AppTheme.dangerColor).withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _resultSuccess ? Icons.check_circle_outline : Icons.cancel_outlined,
                          size: 50,
                          color: _resultSuccess ? AppTheme.accentColor : AppTheme.dangerColor,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        _resultTitle,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: _resultSuccess ? AppTheme.accentColor : AppTheme.dangerColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(_resultMessage, textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.slate300, fontSize: 13)),
                      if (_resultSuccess && _remainingBalance != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFF020617),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            children: [
                              const Text('Sisa Saldo Wristband', style: TextStyle(fontSize: 11, color: AppTheme.slate400)),
                              Text(
                                'Rp ${_formatRupiah(_remainingBalance!)}',
                                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _closeResult,
                          child: const Text('TUTUP & TRANSAKSI BERIKUTNYA'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
