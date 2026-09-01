import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/gate_repository.dart';
import '../../../../core/storage/local_database.dart';
import '../../../../core/network/socket_service.dart';

class GateScanDetail {
  final String result;
  final String ticketId;
  final String ownerName;
  final String ownerEmail;
  final String eventName;
  final String tierName;
  final String scannedAt;
  final String message;

  const GateScanDetail({
    required this.result,
    this.ticketId = '',
    this.ownerName = '',
    this.ownerEmail = '',
    this.eventName = '',
    this.tierName = '',
    this.scannedAt = '',
    this.message = '',
  });
}

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
  final GateScanDetail? lastScanDetail;
  /// Real-time notification message from another device's scan
  final String? remoteNotification;

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
    this.lastScanDetail,
    this.remoteNotification,
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
    GateScanDetail? lastScanDetail,
    String? remoteNotification,
    bool clearNotification = false,
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
      lastScanDetail: lastScanDetail ?? this.lastScanDetail,
      remoteNotification: clearNotification ? null : (remoteNotification ?? this.remoteNotification),
    );
  }
}

class GateViewModel extends Notifier<GateState> {
  late final GateRepository _repository;
  late final LocalDatabase _db;
  late final SocketService _socketService;

  @override
  GateState build() {
    _repository = GateRepository();
    _db = LocalDatabase();
    _socketService = SocketService();
    refreshPendingCount();
    _initSocketConnection();
    return const GateState();
  }

  /// Initialize Socket.IO connection and listen for remote scan events
  void _initSocketConnection() {
    _socketService.onGateScanResult = (data) {
      final result = data['result']?.toString() ?? 'unknown';
      final ticketId = data['ticket_id']?.toString() ?? '';
      final staffEmail = data['staff_email']?.toString() ?? '';
      final deviceId = data['gate_device_id']?.toString() ?? '';

      // Only show notification if scan came from a DIFFERENT device
      if (deviceId != 'GATE-MOBILE-01') {
        final isValid = result == 'valid';
        final msg = isValid
            ? '✓ Tiket $ticketId validated by $staffEmail ($deviceId)'
            : '✗ Scan $result: $ticketId ($deviceId)';

        state = state.copyWith(remoteNotification: msg);
      }
    };

    _socketService.onSyncCompleted = (data) {
      final syncedCount = data['synced_count'] ?? 0;
      state = state.copyWith(
        remoteNotification: '🔄 $syncedCount log(s) synced by ${data['staff_email'] ?? 'staff'}',
      );
    };

    _socketService.connect();
  }

  void clearNotification() {
    state = state.copyWith(clearNotification: true);
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
            .map((l) => <String, dynamic>{
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
    GateScanDetail? detail;

    if (state.isOnline) {
      try {
        final res = await _repository.scanTicket(qrToken);
        final data = res['data'] ?? {};
        result = data['result'] ?? 'invalid';
        isValid = result == 'valid';

        detail = GateScanDetail(
          result: result,
          ticketId: data['ticket_id']?.toString() ?? '',
          ownerName: data['ticket_owner_name']?.toString() ?? '',
          ownerEmail: data['ticket_owner_email']?.toString() ?? '',
          eventName: data['event_name']?.toString() ?? '',
          tierName: data['tier_name']?.toString() ?? data['seat_name']?.toString() ?? '',
          scannedAt: data['scanned_at']?.toString() ?? DateTime.now().toIso8601String(),
          message: data['message']?.toString() ?? '',
        );

        await _db.insertScanLog(
          token: qrToken,
          result: result,
          message: data['message']?.toString() ?? '',
        );

        final logs = await _db.getPendingLogs();
        if (logs.isNotEmpty) {
          await _db.markAsSynced([logs.last.id]);
        }
      } catch (_) {
        // Fallback to offline mode
        result = 'offline_valid';
        isValid = true;
        detail = GateScanDetail(
          result: 'offline_valid',
          message: 'Saved offline — pending sync',
          scannedAt: DateTime.now().toIso8601String(),
        );
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
      detail = GateScanDetail(
        result: 'offline_valid',
        message: 'Saved offline — pending sync',
        scannedAt: DateTime.now().toIso8601String(),
      );
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
        'owner_name': detail.ownerName,
        'tier_name': detail.tierName,
        'event_name': detail.eventName,
        'message': detail.message,
        'time': DateTime.now(),
        'synced': state.isOnline,
      },
      ...state.sessionLogs,
    ];

    state = state.copyWith(
      isScanning: false,
      showFlash: true,
      flashSuccess: isValid,
      lastScanDetail: detail,
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
