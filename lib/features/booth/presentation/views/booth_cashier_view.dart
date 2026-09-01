import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';
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
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: AppTheme.zinc100,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.zinc200),
              ),
              child: const Icon(Icons.storefront, size: 18, color: AppTheme.zinc950),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('KASIR BOOTH', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppTheme.zinc950)),
                Text('Cashless NFC Transaction', style: TextStyle(fontSize: 10, color: AppTheme.zinc500)),
              ],
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text('Omset Sesi', style: TextStyle(fontSize: 10, color: AppTheme.zinc500, fontWeight: FontWeight.w500)),
                Text(
                  'Rp ${_formatRupiah(boothState.totalSalesSession)}',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppTheme.zinc950, fontFamily: 'monospace'),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: AppTheme.zinc500, size: 20),
            tooltip: 'Logout',
            onPressed: () => ref.read(authProvider.notifier).logout(),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 640;

          return Stack(
            children: [
              if (isWide)
                // ── Landscape / Tablet: 2-Column Split ──
                Row(
                  children: [
                    Expanded(
                      flex: 6,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16.0),
                        child: _buildCashierPanel(boothState),
                      ),
                    ),
                    const VerticalDivider(width: 1, color: AppTheme.zinc200),
                    Expanded(
                      flex: 4,
                      child: _buildHistoryPanel(boothState),
                    ),
                  ],
                )
              else
                // ── Smartphone Portrait: Vertical Adaptive Layout ──
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _buildCashierPanel(boothState),
                      const SizedBox(height: 16),
                      Container(
                        height: 280,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppTheme.zinc200),
                        ),
                        child: _buildHistoryPanel(boothState),
                      ),
                    ],
                  ),
                ),

              // ── Fullscreen Result Modal Overlay ──
              if (boothState.showResult)
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.45),
                    child: Center(
                      child: Container(
                        width: 320,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: boothState.resultSuccess ? AppTheme.zinc900 : AppTheme.dangerColor,
                            width: 1.5,
                          ),
                          boxShadow: const [
                            BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, 10)),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: boothState.resultSuccess ? AppTheme.zinc100 : const Color(0xFFFEF2F2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                boothState.resultSuccess ? Icons.check_circle : Icons.cancel,
                                size: 48,
                                color: boothState.resultSuccess ? AppTheme.zinc950 : AppTheme.dangerColor,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              boothState.resultTitle,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: boothState.resultSuccess ? AppTheme.zinc950 : AppTheme.dangerColor,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              boothState.resultMessage,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 12, color: AppTheme.zinc600),
                            ),
                            if (boothState.remainingBalance != null) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: AppTheme.zinc50,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppTheme.zinc200),
                                ),
                                child: Text(
                                  'Sisa Saldo: Rp ${_formatRupiah(boothState.remainingBalance!)}',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.zinc900, fontFamily: 'monospace'),
                                ),
                              ),
                            ],
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _closeResult,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.zinc950,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: const Text('TRANSAKSI BERIKUTNYA', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCashierPanel(dynamic boothState) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Total Display (High-Contrast Bento Block)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.zinc950,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.zinc800),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text('TOTAL TAGIHAN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.zinc400, letterSpacing: 1)),
              const SizedBox(height: 4),
              Text(
                'Rp ${_formatRupiah(boothState.amount)}',
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white, fontFamily: 'monospace'),
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
                style: const TextStyle(fontSize: 12, fontFamily: 'monospace', fontWeight: FontWeight.bold, color: AppTheme.zinc950),
                decoration: const InputDecoration(
                  labelText: 'NFC UID Wristband',
                  prefixIcon: Icon(Icons.nfc, size: 18, color: AppTheme.zinc500),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _noteController,
                style: const TextStyle(fontSize: 12, color: AppTheme.zinc950),
                decoration: const InputDecoration(
                  labelText: 'Catatan item',
                  prefixIcon: Icon(Icons.receipt_long, size: 18, color: AppTheme.zinc500),
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
          children: _presets.map((p) => OutlinedButton(
            onPressed: () => ref.read(boothProvider.notifier).addPreset(p),
            style: OutlinedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppTheme.zinc900,
              side: const BorderSide(color: AppTheme.zinc200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: Size.zero,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
            ),
            child: Text('+${(p / 1000).toInt()}k'),
          )).toList(),
        ),
        const SizedBox(height: 12),

        // Numpad Grid
        GridView.count(
          crossAxisCount: 3,
          childAspectRatio: 1.8,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            '1', '2', '3',
            '4', '5', '6',
            '7', '8', '9',
            'C', '0', 'DEL',
          ].map((k) => _NumpadBtn(k, () => ref.read(boothProvider.notifier).handleNumpad(k))).toList(),
        ),
        const SizedBox(height: 12),

        // Action Button (Charge)
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: boothState.isProcessing ? null : _handleCharge,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.zinc950,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            icon: boothState.isProcessing
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.contactless, size: 22),
            label: Text(
              boothState.isProcessing ? 'MEMPROSES TRANSAKSI...' : 'TAP WRISTBAND (DEBIT Rp ${_formatRupiah(boothState.amount)})',
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryPanel(dynamic boothState) {
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 10),
            child: Text(
              'RIWAYAT TRANSAKSI SESI INI',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppTheme.zinc500, letterSpacing: 0.8),
            ),
          ),
          Expanded(
            child: boothState.sessionTx.isEmpty
                ? const Center(
                    child: Text('Belum ada transaksi.', style: TextStyle(color: AppTheme.zinc400, fontSize: 12)),
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
                          color: AppTheme.zinc50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.zinc200),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Rp ${_formatRupiah(tx['amount'])}',
                                  style: const TextStyle(fontWeight: FontWeight.w900, color: AppTheme.zinc950, fontSize: 13, fontFamily: 'monospace'),
                                ),
                                Text(
                                  '${tx['nfc']} • ${tx['note'].isEmpty ? 'Item Tagihan' : tx['note']}',
                                  style: const TextStyle(fontSize: 10, color: AppTheme.zinc500),
                                ),
                              ],
                            ),
                            Text(
                              tx['time'],
                              style: const TextStyle(fontSize: 10, color: AppTheme.zinc500, fontFamily: 'monospace'),
                            ),
                          ],
                        ),
                      );
                    },
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
          color: isAction ? AppTheme.zinc100 : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.zinc200),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: isAction ? 13 : 17,
            fontWeight: FontWeight.w900,
            color: isAction ? AppTheme.zinc700 : AppTheme.zinc950,
            fontFamily: 'monospace',
          ),
        ),
      ),
    );
  }
}
