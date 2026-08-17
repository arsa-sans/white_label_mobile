import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/booth_repository.dart';

class BoothState {
  final int amount;
  final bool isProcessing;
  final bool showResult;
  final bool resultSuccess;
  final String resultTitle;
  final String resultMessage;
  final int? remainingBalance;
  final int totalSalesSession;
  final List<Map<String, dynamic>> sessionTx;

  const BoothState({
    this.amount = 0,
    this.isProcessing = false,
    this.showResult = false,
    this.resultSuccess = false,
    this.resultTitle = '',
    this.resultMessage = '',
    this.remainingBalance,
    this.totalSalesSession = 0,
    this.sessionTx = const [],
  });

  BoothState copyWith({
    int? amount,
    bool? isProcessing,
    bool? showResult,
    bool? resultSuccess,
    String? resultTitle,
    String? resultMessage,
    int? remainingBalance,
    int? totalSalesSession,
    List<Map<String, dynamic>>? sessionTx,
  }) {
    return BoothState(
      amount: amount ?? this.amount,
      isProcessing: isProcessing ?? this.isProcessing,
      showResult: showResult ?? this.showResult,
      resultSuccess: resultSuccess ?? this.resultSuccess,
      resultTitle: resultTitle ?? this.resultTitle,
      resultMessage: resultMessage ?? this.resultMessage,
      remainingBalance: remainingBalance ?? this.remainingBalance,
      totalSalesSession: totalSalesSession ?? this.totalSalesSession,
      sessionTx: sessionTx ?? this.sessionTx,
    );
  }
}

class BoothViewModel extends Notifier<BoothState> {
  late final BoothRepository _repository;

  @override
  BoothState build() {
    _repository = BoothRepository();
    return const BoothState();
  }

  void handleNumpad(String val) {
    int newAmount = state.amount;
    if (val == 'C') {
      newAmount = 0;
    } else if (val == 'DEL') {
      if (newAmount > 0) {
        final str = newAmount.toString();
        final trimmed = str.substring(0, str.length - 1);
        newAmount = trimmed.isEmpty ? 0 : int.parse(trimmed);
      }
    } else {
      newAmount = int.parse('${state.amount}$val');
    }
    state = state.copyWith(amount: newAmount);
  }

  void addPreset(int preset) {
    state = state.copyWith(amount: state.amount + preset);
  }

  Future<bool> handleCharge({
    required String nfcUid,
    String? note,
    String? timeFormatted,
  }) async {
    if (state.amount <= 0 || nfcUid.isEmpty) return false;

    state = state.copyWith(isProcessing: true);

    final referenceId = 'mobile-ref-${DateTime.now().millisecondsSinceEpoch}';
    final itemsSummary = (note != null && note.isNotEmpty) ? note : 'Booth Transaction';

    try {
      final res = await _repository.debitBooth(
        amount: state.amount,
        nfcUid: nfcUid,
        referenceId: referenceId,
        boothName: 'Mobile Booth Cashier',
        itemsSummary: itemsSummary,
      );

      if (res['success'] == true) {
        final data = res['data'];
        final remaining = data['remaining_balance'] ?? data['wallet']?['balance'] ?? 0;

        final newSessionTx = [
          {
            'amount': state.amount,
            'nfc': nfcUid,
            'note': note ?? '',
            'remaining': remaining,
            'time': timeFormatted ?? 'Sekarang',
          },
          ...state.sessionTx,
        ];

        state = state.copyWith(
          isProcessing: false,
          resultSuccess: true,
          resultTitle: 'TRANSAKSI BERHASIL!',
          resultMessage: 'Pembayaran Rp ${state.amount} diterima.',
          remainingBalance: remaining,
          showResult: true,
          totalSalesSession: state.totalSalesSession + state.amount,
          sessionTx: newSessionTx,
        );
        return true;
      } else {
        throw Exception(res['message'] ?? 'Debit gagal');
      }
    } catch (_) {
      state = state.copyWith(
        isProcessing: false,
        resultSuccess: false,
        resultTitle: 'TRANSAKSI GAGAL!',
        resultMessage: 'Saldo tidak cukup atau NFC tidak valid.',
        showResult: true,
      );
      return false;
    }
  }

  void closeResult() {
    state = state.copyWith(
      showResult: false,
      amount: 0,
      remainingBalance: null,
    );
  }
}

final boothProvider = NotifierProvider<BoothViewModel, BoothState>(BoothViewModel.new);
