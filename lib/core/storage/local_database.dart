import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

// Part Directive (must appear after imports, before declarations)
// Run: dart run build_runner build
// to generate the `local_database.g.dart` file.
part 'local_database.g.dart';

// Table Definition

/// Represents one gate-scan event stored locally (offline-first).
class GateScanLogs extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// QR token or NFC UID that was scanned.
  TextColumn get token => text().withLength(min: 1, max: 512)();

  /// Backend scan result: 'valid', 'invalid', 'duplicate', 'offline'.
  TextColumn get result => text().withDefault(const Constant('offline'))();

  /// Human-readable message returned by backend (or local fallback).
  TextColumn get message => text().withDefault(const Constant(''))();

  /// ISO-8601 timestamp at scan moment (device local time).
  TextColumn get scannedAt => text()();

  /// Whether this log has been synced to the backend.
  BoolColumn get synced => boolean().withDefault(const Constant(false))();

  /// Optional event-id context for filtering.
  TextColumn get eventId => text().nullable()();
}

// Database Class

@DriftDatabase(tables: [GateScanLogs])
class LocalDatabase extends _$LocalDatabase {
  LocalDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  // Insert

  /// Persists a new scan log entry. Returns the generated row id.
  Future<int> insertScanLog({
    required String token,
    required String result,
    String message = '',
    String? eventId,
  }) =>
      into(gateScanLogs).insert(
        GateScanLogsCompanion.insert(
          token: token,
          result: Value(result),
          message: Value(message),
          scannedAt: DateTime.now().toIso8601String(),
          synced: const Value(false),
          eventId: Value(eventId),
        ),
      );

  // Query

  /// Returns all pending (un-synced) logs, oldest-first, for batch upload.
  Future<List<GateScanLog>> getPendingLogs() =>
      (select(gateScanLogs)
            ..where((t) => t.synced.equals(false))
            ..orderBy([(t) => OrderingTerm.asc(t.scannedAt)]))
          .get();

  /// Returns the most recent [limit] logs for the session log UI.
  Future<List<GateScanLog>> getRecentLogs({int limit = 50}) =>
      (select(gateScanLogs)
            ..orderBy([(t) => OrderingTerm.desc(t.scannedAt)])
            ..limit(limit))
          .get();

  /// Total scans stored in DB.
  Future<int> totalCount() async {
    final count = gateScanLogs.id.count();
    final query = selectOnly(gateScanLogs)..addColumns([count]);
    final result = await query.getSingle();
    return result.read(count) ?? 0;
  }

  // Update

  /// Marks a batch of log ids as synced after a successful upload.
  Future<void> markAsSynced(List<int> ids) async {
    await (update(gateScanLogs)..where((t) => t.id.isIn(ids))).write(
      const GateScanLogsCompanion(synced: Value(true)),
    );
  }

  // Delete

  /// Removes all synced logs older than [days] days to keep DB small.
  Future<int> cleanOldSyncedLogs({int days = 7}) {
    final cutoff =
        DateTime.now().subtract(Duration(days: days)).toIso8601String();
    return (delete(gateScanLogs)
          ..where((t) => t.synced.equals(true) & t.scannedAt.isSmallerThanValue(cutoff)))
        .go();
  }
}

// Connection Factory

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'wl_gate_scans.db'));
    return NativeDatabase.createInBackground(file);
  });
}
