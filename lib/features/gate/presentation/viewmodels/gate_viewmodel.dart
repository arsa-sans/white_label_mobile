import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/gate_repository.dart';
import '../../../../core/storage/local_database.dart';

class GateState {
  final bool isOnline;
  final bool isScanning;
  final bool showFlash;
  final bool flashSuccess;
  final int sessionScanCount;
  final int sessionValid;
  final int sessionInvalid;
  final int pendingSyncCount;
  final List<Map<String, dynamic>> sessionLogs;

  const GateState({
    this.isOnline = true,
    this.isScanning = false,
    this.showFlash = false,
    this.flashSuccess = true,
    this.sessionScanCount = 0,
    this.sessionValid = 0,
    this.sessionInvalid = 0,
    this.pendingSyncCount = 0,
    this.sessionLogs = const [],
  });

  GateState copyWith({
    bool? isOnline,
    bool? isScanning,
    bool? showFlash,
    bool? flashSuccess,
    int? sessionScanCount,
    int? sessionValid,
    int? sessionInvalid,
    int? pendingSyncCount,
    List<Map<String, dynamic>>? sessionLogs,
  }) {
    return GateState(
      isOnline: isOnline ?? this.isOnline,
      isScanning: isScanning ?? this.isScanning,
      showFlash: showFlash ?? this.showFlash,
      flashSuccess: flashSuccess ?? this.flashSuccess,
      sessionScanCount: sessionScanCount ?? this.sessionScanCount,
      sessionValid: sessionValid ?? this.sessionValid,
      sessionInvalid: sessionInvalid ?? this.sessionInvalid,
      pendingSyncCount: pendingSyncCount ?? this.pendingSyncCount,
      sessionLogs: sessionLogs ?? this.sessionLogs,
    );
  }
}

class GateViewModel extends Notifier<GateState> {
  late final GateRepository _repository;
  late final LocalDatabase _db;

  @override
  GateState build() {
    _repository = GateRepository();
    _db = LocalDatabase();
    refreshPendingCount();
    return const GateState();
  }

  void setOnline(bool online) {
    state = state.copyWith(isOnline: online);
    if (online) {
      syncPendingLogs();
    }
  }

  Future<void> refreshPendingCount() async {
    final pending = await _db.getPendingLogs();
    state = state.copyWith(pendingSyncCount: pending.length);
  }

  Future<void> syncPendingLogs() async {
    final pending = await _db.getPendingLogs();
    if (pending.isEmpty) return;

    try {
      await _repository.syncOfflineLogs(
        pending
            .map((l) => {
                  'token': l.token,
                  'result': l.result,
                  'scanned_at': l.scannedAt,
                })
            .toList(),
      );
      await _db.markAsSynced(pending.map((l) => l.id).toList());
      await _db.cleanOldSyncedLogs();
      await refreshPendingCount();
    } catch (_) {
      // Retry next time connectivity is restored
    }
  }

  Future<bool> handleScan(String qrToken) async {
    if (qrToken.isEmpty || state.isScanning) return false;

    state = state.copyWith(isScanning: true);

    String result = 'invalid';
    bool isValid = false;

    if (state.isOnline) {
      try {
        final res = await _repository.scanTicket(qrToken);
        result = res['data']?['result'] ?? 'invalid';
        isValid = result == 'valid';

        await _db.insertScanLog(
          token: qrToken,
          result: result,
          message: res['data']?['message']?.toString() ?? '',
        );

        final logs = await _db.getPendingLogs();
        if (logs.isNotEmpty) {
          await _db.markAsSynced([logs.last.id]);
        }
      } catch (_) {
        // Fallback to offline mode
        result = 'offline_valid';
        isValid = true;
        await _db.insertScanLog(
          token: qrToken,
          result: 'offline_valid',
          message: 'Saved offline — pending sync',
        );
        await refreshPendingCount();
      }
    } else {
      result = 'offline_valid';
      isValid = true;
      await _db.insertScanLog(
        token: qrToken,
        result: 'offline_valid',
        message: 'Saved offline — pending sync',
      );
      await refreshPendingCount();
    }

    final newLogs = [
      {
        'token': qrToken.length > 16 ? '${qrToken.substring(0, 16)}...' : qrToken,
        'result': result,
        'time': DateTime.now(),
        'synced': state.isOnline,
      },
      ...state.sessionLogs,
    ];

    state = state.copyWith(
      isScanning: false,
      showFlash: true,
      flashSuccess: isValid,
      sessionScanCount: state.sessionScanCount + 1,
      sessionValid: isValid ? state.sessionValid + 1 : state.sessionValid,
      sessionInvalid: !isValid ? state.sessionInvalid + 1 : state.sessionInvalid,
      sessionLogs: newLogs,
    );

    return isValid;
  }

  void hideFlash() {
    state = state.copyWith(showFlash: false);
  }
}

final gateProvider = NotifierProvider<GateViewModel, GateState>(GateViewModel.new);
