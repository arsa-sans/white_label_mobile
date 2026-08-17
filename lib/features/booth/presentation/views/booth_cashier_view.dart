import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../viewmodels/booth_viewmodel.dart';

class BoothCashierView extends ConsumerStatefulWidget {
  const BoothCashierView({super.key});

  @override
  ConsumerState<BoothCashierView> createState() => _BoothCashierViewState();
}

class _BoothCashierViewState extends ConsumerState<BoothCashierView> {
  final _nfcController = TextEditingController(text: 'NFC-994821');
  final _noteController = TextEditingController();
  final List<int> _presets = [15000, 25000, 35000, 50000, 75000, 100000];

  @override
  void dispose() {
    _nfcController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _handleCharge() async {
    final boothState = ref.read(boothProvider);
    if (boothState.amount <= 0) return;
    final nfcUid = _nfcController.text.trim();
    if (nfcUid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan NFC UID Wristband pengunjung.')),
      );
      return;
    }

    HapticFeedback.mediumImpact();
    final timeStr = TimeOfDay.now().format(context);

    final success = await ref.read(boothProvider.notifier).handleCharge(
      nfcUid: nfcUid,
      note: _noteController.text,
      timeFormatted: timeStr,
    );

    if (success) {
      HapticFeedback.heavyImpact();
    } else {
      HapticFeedback.vibrate();
    }
  }

  void _closeResult() {
    ref.read(boothProvider.notifier).closeResult();
    _noteController.clear();
  }

  String _formatRupiah(int amount) {
    return amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final boothState = ref.watch(boothProvider);

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
                  'Rp ${_formatRupiah(boothState.totalSalesSession)}',
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
                              'Rp ${_formatRupiah(boothState.amount)}',
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
                          onPressed: () => ref.read(boothProvider.notifier).addPreset(p),
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
                          childAspectRatio: 1.6,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                          physics: const NeverScrollableScrollPhysics(),
                          children: [
                            '1', '2', '3',
                            '4', '5', '6',
                            '7', '8', '9',
                            'C', '0', 'DEL',
                          ].map((k) => _NumpadBtn(k, () => ref.read(boothProvider.notifier).handleNumpad(k))).toList(),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Action Button (Charge)
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: boothState.isProcessing ? null : _handleCharge,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.emerald600,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          icon: boothState.isProcessing
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Icon(Icons.contactless, size: 24),
                          label: Text(
                            boothState.isProcessing ? 'MEMPROSES TRANSAKSI...' : 'TAP WRISTBAND (DEBIT Rp ${_formatRupiah(boothState.amount)})',
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Right: Session History
              Expanded(
                flex: 4,
                child: Container(
                  color: const Color(0xFF1E293B),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.fromLTRB(16, 16, 16, 10),
                        child: Text(
                          'RIWAYAT TRANSAKSI SESI INI',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppTheme.slate400, letterSpacing: 0.8),
                        ),
                      ),
                      Expanded(
                        child: boothState.sessionTx.isEmpty
                            ? const Center(
                                child: Text('Belum ada transaksi.', style: TextStyle(color: AppTheme.slate500, fontSize: 12)),
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                                itemCount: boothState.sessionTx.length,
                                separatorBuilder: (_, _) => const SizedBox(height: 6),
                                itemBuilder: (_, i) {
                                  final tx = boothState.sessionTx[i];
                                  return Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0F172A),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: AppTheme.cardBorder),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Rp ${_formatRupiah(tx['amount'])}',
                                              style: const TextStyle(fontWeight: FontWeight.w900, color: AppTheme.emerald600, fontSize: 13),
                                            ),
                                            Text(
                                              '${tx['nfc']} • ${tx['note'].isEmpty ? 'Item Tagihan' : tx['note']}',
                                              style: const TextStyle(fontSize: 10, color: AppTheme.slate400),
                                            ),
                                          ],
                                        ),
                                        Text(
                                          tx['time'],
                                          style: const TextStyle(fontSize: 10, color: AppTheme.slate500, fontFamily: 'monospace'),
                                        ),
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

          // Fullscreen Result Modal
          if (boothState.showResult)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.85),
                child: Center(
                  child: Container(
                    width: 320,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: boothState.resultSuccess ? AppTheme.emerald600 : AppTheme.red600,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          boothState.resultSuccess ? Icons.check_circle_outline : Icons.highlight_off,
                          size: 64,
                          color: boothState.resultSuccess ? AppTheme.emerald600 : AppTheme.red600,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          boothState.resultTitle,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: boothState.resultSuccess ? AppTheme.emerald600 : AppTheme.red600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          boothState.resultMessage,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 12, color: AppTheme.slate300),
                        ),
                        if (boothState.remainingBalance != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F172A),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'Sisa Saldo: Rp ${_formatRupiah(boothState.remainingBalance!)}',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.accentColor),
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _closeResult,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('TRANSAKSI BERIKUTNYA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _NumpadBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _NumpadBtn(this.label, this.onTap);

  @override
  Widget build(BuildContext context) {
    final isAction = label == 'C' || label == 'DEL';
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: isAction ? const Color(0xFF334155) : const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.cardBorder),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: isAction ? 14 : 18,
            fontWeight: FontWeight.w900,
            color: isAction ? AppTheme.amber400 : Colors.white,
          ),
        ),
      ),
    );
  }
}
