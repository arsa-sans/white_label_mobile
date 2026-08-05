// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_database.dart';

// ignore_for_file: type=lint
class $GateScanLogsTable extends GateScanLogs
    with TableInfo<$GateScanLogsTable, GateScanLog> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GateScanLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _tokenMeta = const VerificationMeta('token');
  @override
  late final GeneratedColumn<String> token = GeneratedColumn<String>(
    'token',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 512,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _resultMeta = const VerificationMeta('result');
  @override
  late final GeneratedColumn<String> result = GeneratedColumn<String>(
    'result',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('offline'),
  );
  static const VerificationMeta _messageMeta = const VerificationMeta(
    'message',
  );
  @override
  late final GeneratedColumn<String> message = GeneratedColumn<String>(
    'message',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _scannedAtMeta = const VerificationMeta(
    'scannedAt',
  );
  @override
  late final GeneratedColumn<String> scannedAt = GeneratedColumn<String>(
    'scanned_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncedMeta = const VerificationMeta('synced');
  @override
  late final GeneratedColumn<bool> synced = GeneratedColumn<bool>(
    'synced',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("synced" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _eventIdMeta = const VerificationMeta(
    'eventId',
  );
  @override
  late final GeneratedColumn<String> eventId = GeneratedColumn<String>(
    'event_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    token,
    result,
    message,
    scannedAt,
    synced,
    eventId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'gate_scan_logs';
  @override
  VerificationContext validateIntegrity(
    Insertable<GateScanLog> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('token')) {
      context.handle(
        _tokenMeta,
        token.isAcceptableOrUnknown(data['token']!, _tokenMeta),
      );
    } else if (isInserting) {
      context.missing(_tokenMeta);
    }
    if (data.containsKey('result')) {
      context.handle(
        _resultMeta,
        result.isAcceptableOrUnknown(data['result']!, _resultMeta),
      );
    }
    if (data.containsKey('message')) {
      context.handle(
        _messageMeta,
        message.isAcceptableOrUnknown(data['message']!, _messageMeta),
      );
    }
    if (data.containsKey('scanned_at')) {
      context.handle(
        _scannedAtMeta,
        scannedAt.isAcceptableOrUnknown(data['scanned_at']!, _scannedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_scannedAtMeta);
    }
    if (data.containsKey('synced')) {
      context.handle(
        _syncedMeta,
        synced.isAcceptableOrUnknown(data['synced']!, _syncedMeta),
      );
    }
    if (data.containsKey('event_id')) {
      context.handle(
        _eventIdMeta,
        eventId.isAcceptableOrUnknown(data['event_id']!, _eventIdMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  GateScanLog map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GateScanLog(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      token: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}token'],
      )!,
      result: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}result'],
      )!,
      message: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}message'],
      )!,
      scannedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}scanned_at'],
      )!,
      synced: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}synced'],
      )!,
      eventId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}event_id'],
      ),
    );
  }

  @override
  $GateScanLogsTable createAlias(String alias) {
    return $GateScanLogsTable(attachedDatabase, alias);
  }
}

class GateScanLog extends DataClass implements Insertable<GateScanLog> {
  final int id;

  /// QR token or NFC UID that was scanned.
  final String token;

  /// Backend scan result: 'valid', 'invalid', 'duplicate', 'offline'.
  final String result;

  /// Human-readable message returned by backend (or local fallback).
  final String message;

  /// ISO-8601 timestamp at scan moment (device local time).
  final String scannedAt;

  /// Whether this log has been synced to the backend.
  final bool synced;

  /// Optional event-id context for filtering.
  final String? eventId;
  const GateScanLog({
    required this.id,
    required this.token,
    required this.result,
    required this.message,
    required this.scannedAt,
    required this.synced,
    this.eventId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['token'] = Variable<String>(token);
    map['result'] = Variable<String>(result);
    map['message'] = Variable<String>(message);
    map['scanned_at'] = Variable<String>(scannedAt);
    map['synced'] = Variable<bool>(synced);
    if (!nullToAbsent || eventId != null) {
      map['event_id'] = Variable<String>(eventId);
    }
    return map;
  }

  GateScanLogsCompanion toCompanion(bool nullToAbsent) {
    return GateScanLogsCompanion(
      id: Value(id),
      token: Value(token),
      result: Value(result),
      message: Value(message),
      scannedAt: Value(scannedAt),
      synced: Value(synced),
      eventId: eventId == null && nullToAbsent
          ? const Value.absent()
          : Value(eventId),
    );
  }

  factory GateScanLog.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GateScanLog(
      id: serializer.fromJson<int>(json['id']),
      token: serializer.fromJson<String>(json['token']),
      result: serializer.fromJson<String>(json['result']),
      message: serializer.fromJson<String>(json['message']),
      scannedAt: serializer.fromJson<String>(json['scannedAt']),
      synced: serializer.fromJson<bool>(json['synced']),
      eventId: serializer.fromJson<String?>(json['eventId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'token': serializer.toJson<String>(token),
      'result': serializer.toJson<String>(result),
      'message': serializer.toJson<String>(message),
      'scannedAt': serializer.toJson<String>(scannedAt),
      'synced': serializer.toJson<bool>(synced),
      'eventId': serializer.toJson<String?>(eventId),
    };
  }

  GateScanLog copyWith({
    int? id,
    String? token,
    String? result,
    String? message,
    String? scannedAt,
    bool? synced,
    Value<String?> eventId = const Value.absent(),
  }) => GateScanLog(
    id: id ?? this.id,
    token: token ?? this.token,
    result: result ?? this.result,
    message: message ?? this.message,
    scannedAt: scannedAt ?? this.scannedAt,
    synced: synced ?? this.synced,
    eventId: eventId.present ? eventId.value : this.eventId,
  );
  GateScanLog copyWithCompanion(GateScanLogsCompanion data) {
    return GateScanLog(
      id: data.id.present ? data.id.value : this.id,
      token: data.token.present ? data.token.value : this.token,
      result: data.result.present ? data.result.value : this.result,
      message: data.message.present ? data.message.value : this.message,
      scannedAt: data.scannedAt.present ? data.scannedAt.value : this.scannedAt,
      synced: data.synced.present ? data.synced.value : this.synced,
      eventId: data.eventId.present ? data.eventId.value : this.eventId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GateScanLog(')
          ..write('id: $id, ')
          ..write('token: $token, ')
          ..write('result: $result, ')
          ..write('message: $message, ')
          ..write('scannedAt: $scannedAt, ')
          ..write('synced: $synced, ')
          ..write('eventId: $eventId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, token, result, message, scannedAt, synced, eventId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GateScanLog &&
          other.id == this.id &&
          other.token == this.token &&
          other.result == this.result &&
          other.message == this.message &&
          other.scannedAt == this.scannedAt &&
          other.synced == this.synced &&
          other.eventId == this.eventId);
}

class GateScanLogsCompanion extends UpdateCompanion<GateScanLog> {
  final Value<int> id;
  final Value<String> token;
  final Value<String> result;
  final Value<String> message;
  final Value<String> scannedAt;
  final Value<bool> synced;
  final Value<String?> eventId;
  const GateScanLogsCompanion({
    this.id = const Value.absent(),
    this.token = const Value.absent(),
    this.result = const Value.absent(),
    this.message = const Value.absent(),
    this.scannedAt = const Value.absent(),
    this.synced = const Value.absent(),
    this.eventId = const Value.absent(),
  });
  GateScanLogsCompanion.insert({
    this.id = const Value.absent(),
    required String token,
    this.result = const Value.absent(),
    this.message = const Value.absent(),
    required String scannedAt,
    this.synced = const Value.absent(),
    this.eventId = const Value.absent(),
  }) : token = Value(token),
       scannedAt = Value(scannedAt);
  static Insertable<GateScanLog> custom({
    Expression<int>? id,
    Expression<String>? token,
    Expression<String>? result,
    Expression<String>? message,
    Expression<String>? scannedAt,
    Expression<bool>? synced,
    Expression<String>? eventId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (token != null) 'token': token,
      if (result != null) 'result': result,
      if (message != null) 'message': message,
      if (scannedAt != null) 'scanned_at': scannedAt,
      if (synced != null) 'synced': synced,
      if (eventId != null) 'event_id': eventId,
    });
  }

  GateScanLogsCompanion copyWith({
    Value<int>? id,
    Value<String>? token,
    Value<String>? result,
    Value<String>? message,
    Value<String>? scannedAt,
    Value<bool>? synced,
    Value<String?>? eventId,
  }) {
    return GateScanLogsCompanion(
      id: id ?? this.id,
      token: token ?? this.token,
      result: result ?? this.result,
      message: message ?? this.message,
      scannedAt: scannedAt ?? this.scannedAt,
      synced: synced ?? this.synced,
      eventId: eventId ?? this.eventId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (token.present) {
      map['token'] = Variable<String>(token.value);
    }
    if (result.present) {
      map['result'] = Variable<String>(result.value);
    }
    if (message.present) {
      map['message'] = Variable<String>(message.value);
    }
    if (scannedAt.present) {
      map['scanned_at'] = Variable<String>(scannedAt.value);
    }
    if (synced.present) {
      map['synced'] = Variable<bool>(synced.value);
    }
    if (eventId.present) {
      map['event_id'] = Variable<String>(eventId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GateScanLogsCompanion(')
          ..write('id: $id, ')
          ..write('token: $token, ')
          ..write('result: $result, ')
          ..write('message: $message, ')
          ..write('scannedAt: $scannedAt, ')
          ..write('synced: $synced, ')
          ..write('eventId: $eventId')
          ..write(')'))
        .toString();
  }
}

abstract class _$LocalDatabase extends GeneratedDatabase {
  _$LocalDatabase(QueryExecutor e) : super(e);
  $LocalDatabaseManager get managers => $LocalDatabaseManager(this);
  late final $GateScanLogsTable gateScanLogs = $GateScanLogsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [gateScanLogs];
}

typedef $$GateScanLogsTableCreateCompanionBuilder =
    GateScanLogsCompanion Function({
      Value<int> id,
      required String token,
      Value<String> result,
      Value<String> message,
      required String scannedAt,
      Value<bool> synced,
      Value<String?> eventId,
    });
typedef $$GateScanLogsTableUpdateCompanionBuilder =
    GateScanLogsCompanion Function({
      Value<int> id,
      Value<String> token,
      Value<String> result,
      Value<String> message,
      Value<String> scannedAt,
      Value<bool> synced,
      Value<String?> eventId,
    });

class $$GateScanLogsTableFilterComposer
    extends Composer<_$LocalDatabase, $GateScanLogsTable> {
  $$GateScanLogsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get token => $composableBuilder(
    column: $table.token,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get result => $composableBuilder(
    column: $table.result,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get message => $composableBuilder(
    column: $table.message,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get scannedAt => $composableBuilder(
    column: $table.scannedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get eventId => $composableBuilder(
    column: $table.eventId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$GateScanLogsTableOrderingComposer
    extends Composer<_$LocalDatabase, $GateScanLogsTable> {
  $$GateScanLogsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get token => $composableBuilder(
    column: $table.token,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get result => $composableBuilder(
    column: $table.result,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get message => $composableBuilder(
    column: $table.message,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get scannedAt => $composableBuilder(
    column: $table.scannedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get eventId => $composableBuilder(
    column: $table.eventId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$GateScanLogsTableAnnotationComposer
    extends Composer<_$LocalDatabase, $GateScanLogsTable> {
  $$GateScanLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get token =>
      $composableBuilder(column: $table.token, builder: (column) => column);

  GeneratedColumn<String> get result =>
      $composableBuilder(column: $table.result, builder: (column) => column);

  GeneratedColumn<String> get message =>
      $composableBuilder(column: $table.message, builder: (column) => column);

  GeneratedColumn<String> get scannedAt =>
      $composableBuilder(column: $table.scannedAt, builder: (column) => column);

  GeneratedColumn<bool> get synced =>
      $composableBuilder(column: $table.synced, builder: (column) => column);

  GeneratedColumn<String> get eventId =>
      $composableBuilder(column: $table.eventId, builder: (column) => column);
}

class $$GateScanLogsTableTableManager
    extends
        RootTableManager<
          _$LocalDatabase,
          $GateScanLogsTable,
          GateScanLog,
          $$GateScanLogsTableFilterComposer,
          $$GateScanLogsTableOrderingComposer,
          $$GateScanLogsTableAnnotationComposer,
          $$GateScanLogsTableCreateCompanionBuilder,
          $$GateScanLogsTableUpdateCompanionBuilder,
          (
            GateScanLog,
            BaseReferences<_$LocalDatabase, $GateScanLogsTable, GateScanLog>,
          ),
          GateScanLog,
          PrefetchHooks Function()
        > {
  $$GateScanLogsTableTableManager(_$LocalDatabase db, $GateScanLogsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GateScanLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GateScanLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GateScanLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> token = const Value.absent(),
                Value<String> result = const Value.absent(),
                Value<String> message = const Value.absent(),
                Value<String> scannedAt = const Value.absent(),
                Value<bool> synced = const Value.absent(),
                Value<String?> eventId = const Value.absent(),
              }) => GateScanLogsCompanion(
                id: id,
                token: token,
                result: result,
                message: message,
                scannedAt: scannedAt,
                synced: synced,
                eventId: eventId,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String token,
                Value<String> result = const Value.absent(),
                Value<String> message = const Value.absent(),
                required String scannedAt,
                Value<bool> synced = const Value.absent(),
                Value<String?> eventId = const Value.absent(),
              }) => GateScanLogsCompanion.insert(
                id: id,
                token: token,
                result: result,
                message: message,
                scannedAt: scannedAt,
                synced: synced,
                eventId: eventId,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$GateScanLogsTableProcessedTableManager =
    ProcessedTableManager<
      _$LocalDatabase,
      $GateScanLogsTable,
      GateScanLog,
      $$GateScanLogsTableFilterComposer,
      $$GateScanLogsTableOrderingComposer,
      $$GateScanLogsTableAnnotationComposer,
      $$GateScanLogsTableCreateCompanionBuilder,
      $$GateScanLogsTableUpdateCompanionBuilder,
      (
        GateScanLog,
        BaseReferences<_$LocalDatabase, $GateScanLogsTable, GateScanLog>,
      ),
      GateScanLog,
      PrefetchHooks Function()
    >;

class $LocalDatabaseManager {
  final _$LocalDatabase _db;
  $LocalDatabaseManager(this._db);
  $$GateScanLogsTableTableManager get gateScanLogs =>
      $$GateScanLogsTableTableManager(_db, _db.gateScanLogs);
}
