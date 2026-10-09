// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $ScheduleCacheTable extends ScheduleCache
    with TableInfo<$ScheduleCacheTable, ScheduleCacheData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ScheduleCacheTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _groupIdMeta = const VerificationMeta(
    'groupId',
  );
  @override
  late final GeneratedColumn<String> groupId = GeneratedColumn<String>(
    'group_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<String> version = GeneratedColumn<String>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hashMeta = const VerificationMeta('hash');
  @override
  late final GeneratedColumn<String> hash = GeneratedColumn<String>(
    'hash',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _jsonMeta = const VerificationMeta('json');
  @override
  late final GeneratedColumn<String> json = GeneratedColumn<String>(
    'json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _etagMeta = const VerificationMeta('etag');
  @override
  late final GeneratedColumn<String> etag = GeneratedColumn<String>(
    'etag',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fetchedAtMeta = const VerificationMeta(
    'fetchedAt',
  );
  @override
  late final GeneratedColumn<DateTime> fetchedAt = GeneratedColumn<DateTime>(
    'fetched_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    groupId,
    version,
    hash,
    json,
    etag,
    fetchedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'schedule_cache';
  @override
  VerificationContext validateIntegrity(
    Insertable<ScheduleCacheData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('group_id')) {
      context.handle(
        _groupIdMeta,
        groupId.isAcceptableOrUnknown(data['group_id']!, _groupIdMeta),
      );
    } else if (isInserting) {
      context.missing(_groupIdMeta);
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    } else if (isInserting) {
      context.missing(_versionMeta);
    }
    if (data.containsKey('hash')) {
      context.handle(
        _hashMeta,
        hash.isAcceptableOrUnknown(data['hash']!, _hashMeta),
      );
    } else if (isInserting) {
      context.missing(_hashMeta);
    }
    if (data.containsKey('json')) {
      context.handle(
        _jsonMeta,
        json.isAcceptableOrUnknown(data['json']!, _jsonMeta),
      );
    } else if (isInserting) {
      context.missing(_jsonMeta);
    }
    if (data.containsKey('etag')) {
      context.handle(
        _etagMeta,
        etag.isAcceptableOrUnknown(data['etag']!, _etagMeta),
      );
    }
    if (data.containsKey('fetched_at')) {
      context.handle(
        _fetchedAtMeta,
        fetchedAt.isAcceptableOrUnknown(data['fetched_at']!, _fetchedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_fetchedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {groupId};
  @override
  ScheduleCacheData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ScheduleCacheData(
      groupId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}group_id'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}version'],
      )!,
      hash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hash'],
      )!,
      json: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}json'],
      )!,
      etag: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}etag'],
      ),
      fetchedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}fetched_at'],
      )!,
    );
  }

  @override
  $ScheduleCacheTable createAlias(String alias) {
    return $ScheduleCacheTable(attachedDatabase, alias);
  }
}

class ScheduleCacheData extends DataClass
    implements Insertable<ScheduleCacheData> {
  final String groupId;
  final String version;
  final String hash;
  final String json;
  final String? etag;
  final DateTime fetchedAt;
  const ScheduleCacheData({
    required this.groupId,
    required this.version,
    required this.hash,
    required this.json,
    this.etag,
    required this.fetchedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['group_id'] = Variable<String>(groupId);
    map['version'] = Variable<String>(version);
    map['hash'] = Variable<String>(hash);
    map['json'] = Variable<String>(json);
    if (!nullToAbsent || etag != null) {
      map['etag'] = Variable<String>(etag);
    }
    map['fetched_at'] = Variable<DateTime>(fetchedAt);
    return map;
  }

  ScheduleCacheCompanion toCompanion(bool nullToAbsent) {
    return ScheduleCacheCompanion(
      groupId: Value(groupId),
      version: Value(version),
      hash: Value(hash),
      json: Value(json),
      etag: etag == null && nullToAbsent ? const Value.absent() : Value(etag),
      fetchedAt: Value(fetchedAt),
    );
  }

  factory ScheduleCacheData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ScheduleCacheData(
      groupId: serializer.fromJson<String>(json['groupId']),
      version: serializer.fromJson<String>(json['version']),
      hash: serializer.fromJson<String>(json['hash']),
      json: serializer.fromJson<String>(json['json']),
      etag: serializer.fromJson<String?>(json['etag']),
      fetchedAt: serializer.fromJson<DateTime>(json['fetchedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'groupId': serializer.toJson<String>(groupId),
      'version': serializer.toJson<String>(version),
      'hash': serializer.toJson<String>(hash),
      'json': serializer.toJson<String>(json),
      'etag': serializer.toJson<String?>(etag),
      'fetchedAt': serializer.toJson<DateTime>(fetchedAt),
    };
  }

  ScheduleCacheData copyWith({
    String? groupId,
    String? version,
    String? hash,
    String? json,
    Value<String?> etag = const Value.absent(),
    DateTime? fetchedAt,
  }) => ScheduleCacheData(
    groupId: groupId ?? this.groupId,
    version: version ?? this.version,
    hash: hash ?? this.hash,
    json: json ?? this.json,
    etag: etag.present ? etag.value : this.etag,
    fetchedAt: fetchedAt ?? this.fetchedAt,
  );
  ScheduleCacheData copyWithCompanion(ScheduleCacheCompanion data) {
    return ScheduleCacheData(
      groupId: data.groupId.present ? data.groupId.value : this.groupId,
      version: data.version.present ? data.version.value : this.version,
      hash: data.hash.present ? data.hash.value : this.hash,
      json: data.json.present ? data.json.value : this.json,
      etag: data.etag.present ? data.etag.value : this.etag,
      fetchedAt: data.fetchedAt.present ? data.fetchedAt.value : this.fetchedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ScheduleCacheData(')
          ..write('groupId: $groupId, ')
          ..write('version: $version, ')
          ..write('hash: $hash, ')
          ..write('json: $json, ')
          ..write('etag: $etag, ')
          ..write('fetchedAt: $fetchedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(groupId, version, hash, json, etag, fetchedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ScheduleCacheData &&
          other.groupId == this.groupId &&
          other.version == this.version &&
          other.hash == this.hash &&
          other.json == this.json &&
          other.etag == this.etag &&
          other.fetchedAt == this.fetchedAt);
}

class ScheduleCacheCompanion extends UpdateCompanion<ScheduleCacheData> {
  final Value<String> groupId;
  final Value<String> version;
  final Value<String> hash;
  final Value<String> json;
  final Value<String?> etag;
  final Value<DateTime> fetchedAt;
  final Value<int> rowid;
  const ScheduleCacheCompanion({
    this.groupId = const Value.absent(),
    this.version = const Value.absent(),
    this.hash = const Value.absent(),
    this.json = const Value.absent(),
    this.etag = const Value.absent(),
    this.fetchedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ScheduleCacheCompanion.insert({
    required String groupId,
    required String version,
    required String hash,
    required String json,
    this.etag = const Value.absent(),
    required DateTime fetchedAt,
    this.rowid = const Value.absent(),
  }) : groupId = Value(groupId),
       version = Value(version),
       hash = Value(hash),
       json = Value(json),
       fetchedAt = Value(fetchedAt);
  static Insertable<ScheduleCacheData> custom({
    Expression<String>? groupId,
    Expression<String>? version,
    Expression<String>? hash,
    Expression<String>? json,
    Expression<String>? etag,
    Expression<DateTime>? fetchedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (groupId != null) 'group_id': groupId,
      if (version != null) 'version': version,
      if (hash != null) 'hash': hash,
      if (json != null) 'json': json,
      if (etag != null) 'etag': etag,
      if (fetchedAt != null) 'fetched_at': fetchedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ScheduleCacheCompanion copyWith({
    Value<String>? groupId,
    Value<String>? version,
    Value<String>? hash,
    Value<String>? json,
    Value<String?>? etag,
    Value<DateTime>? fetchedAt,
    Value<int>? rowid,
  }) {
    return ScheduleCacheCompanion(
      groupId: groupId ?? this.groupId,
      version: version ?? this.version,
      hash: hash ?? this.hash,
      json: json ?? this.json,
      etag: etag ?? this.etag,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (groupId.present) {
      map['group_id'] = Variable<String>(groupId.value);
    }
    if (version.present) {
      map['version'] = Variable<String>(version.value);
    }
    if (hash.present) {
      map['hash'] = Variable<String>(hash.value);
    }
    if (json.present) {
      map['json'] = Variable<String>(json.value);
    }
    if (etag.present) {
      map['etag'] = Variable<String>(etag.value);
    }
    if (fetchedAt.present) {
      map['fetched_at'] = Variable<DateTime>(fetchedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ScheduleCacheCompanion(')
          ..write('groupId: $groupId, ')
          ..write('version: $version, ')
          ..write('hash: $hash, ')
          ..write('json: $json, ')
          ..write('etag: $etag, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $IndexCacheTable extends IndexCache
    with TableInfo<$IndexCacheTable, IndexCacheData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $IndexCacheTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<String> version = GeneratedColumn<String>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _jsonMeta = const VerificationMeta('json');
  @override
  late final GeneratedColumn<String> json = GeneratedColumn<String>(
    'json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _etagMeta = const VerificationMeta('etag');
  @override
  late final GeneratedColumn<String> etag = GeneratedColumn<String>(
    'etag',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fetchedAtMeta = const VerificationMeta(
    'fetchedAt',
  );
  @override
  late final GeneratedColumn<DateTime> fetchedAt = GeneratedColumn<DateTime>(
    'fetched_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, version, json, etag, fetchedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'index_cache';
  @override
  VerificationContext validateIntegrity(
    Insertable<IndexCacheData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    } else if (isInserting) {
      context.missing(_versionMeta);
    }
    if (data.containsKey('json')) {
      context.handle(
        _jsonMeta,
        json.isAcceptableOrUnknown(data['json']!, _jsonMeta),
      );
    } else if (isInserting) {
      context.missing(_jsonMeta);
    }
    if (data.containsKey('etag')) {
      context.handle(
        _etagMeta,
        etag.isAcceptableOrUnknown(data['etag']!, _etagMeta),
      );
    }
    if (data.containsKey('fetched_at')) {
      context.handle(
        _fetchedAtMeta,
        fetchedAt.isAcceptableOrUnknown(data['fetched_at']!, _fetchedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_fetchedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  IndexCacheData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return IndexCacheData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}version'],
      )!,
      json: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}json'],
      )!,
      etag: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}etag'],
      ),
      fetchedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}fetched_at'],
      )!,
    );
  }

  @override
  $IndexCacheTable createAlias(String alias) {
    return $IndexCacheTable(attachedDatabase, alias);
  }
}

class IndexCacheData extends DataClass implements Insertable<IndexCacheData> {
  final int id;
  final String version;
  final String json;
  final String? etag;
  final DateTime fetchedAt;
  const IndexCacheData({
    required this.id,
    required this.version,
    required this.json,
    this.etag,
    required this.fetchedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['version'] = Variable<String>(version);
    map['json'] = Variable<String>(json);
    if (!nullToAbsent || etag != null) {
      map['etag'] = Variable<String>(etag);
    }
    map['fetched_at'] = Variable<DateTime>(fetchedAt);
    return map;
  }

  IndexCacheCompanion toCompanion(bool nullToAbsent) {
    return IndexCacheCompanion(
      id: Value(id),
      version: Value(version),
      json: Value(json),
      etag: etag == null && nullToAbsent ? const Value.absent() : Value(etag),
      fetchedAt: Value(fetchedAt),
    );
  }

  factory IndexCacheData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return IndexCacheData(
      id: serializer.fromJson<int>(json['id']),
      version: serializer.fromJson<String>(json['version']),
      json: serializer.fromJson<String>(json['json']),
      etag: serializer.fromJson<String?>(json['etag']),
      fetchedAt: serializer.fromJson<DateTime>(json['fetchedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'version': serializer.toJson<String>(version),
      'json': serializer.toJson<String>(json),
      'etag': serializer.toJson<String?>(etag),
      'fetchedAt': serializer.toJson<DateTime>(fetchedAt),
    };
  }

  IndexCacheData copyWith({
    int? id,
    String? version,
    String? json,
    Value<String?> etag = const Value.absent(),
    DateTime? fetchedAt,
  }) => IndexCacheData(
    id: id ?? this.id,
    version: version ?? this.version,
    json: json ?? this.json,
    etag: etag.present ? etag.value : this.etag,
    fetchedAt: fetchedAt ?? this.fetchedAt,
  );
  IndexCacheData copyWithCompanion(IndexCacheCompanion data) {
    return IndexCacheData(
      id: data.id.present ? data.id.value : this.id,
      version: data.version.present ? data.version.value : this.version,
      json: data.json.present ? data.json.value : this.json,
      etag: data.etag.present ? data.etag.value : this.etag,
      fetchedAt: data.fetchedAt.present ? data.fetchedAt.value : this.fetchedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('IndexCacheData(')
          ..write('id: $id, ')
          ..write('version: $version, ')
          ..write('json: $json, ')
          ..write('etag: $etag, ')
          ..write('fetchedAt: $fetchedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, version, json, etag, fetchedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is IndexCacheData &&
          other.id == this.id &&
          other.version == this.version &&
          other.json == this.json &&
          other.etag == this.etag &&
          other.fetchedAt == this.fetchedAt);
}

class IndexCacheCompanion extends UpdateCompanion<IndexCacheData> {
  final Value<int> id;
  final Value<String> version;
  final Value<String> json;
  final Value<String?> etag;
  final Value<DateTime> fetchedAt;
  const IndexCacheCompanion({
    this.id = const Value.absent(),
    this.version = const Value.absent(),
    this.json = const Value.absent(),
    this.etag = const Value.absent(),
    this.fetchedAt = const Value.absent(),
  });
  IndexCacheCompanion.insert({
    this.id = const Value.absent(),
    required String version,
    required String json,
    this.etag = const Value.absent(),
    required DateTime fetchedAt,
  }) : version = Value(version),
       json = Value(json),
       fetchedAt = Value(fetchedAt);
  static Insertable<IndexCacheData> custom({
    Expression<int>? id,
    Expression<String>? version,
    Expression<String>? json,
    Expression<String>? etag,
    Expression<DateTime>? fetchedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (version != null) 'version': version,
      if (json != null) 'json': json,
      if (etag != null) 'etag': etag,
      if (fetchedAt != null) 'fetched_at': fetchedAt,
    });
  }

  IndexCacheCompanion copyWith({
    Value<int>? id,
    Value<String>? version,
    Value<String>? json,
    Value<String?>? etag,
    Value<DateTime>? fetchedAt,
  }) {
    return IndexCacheCompanion(
      id: id ?? this.id,
      version: version ?? this.version,
      json: json ?? this.json,
      etag: etag ?? this.etag,
      fetchedAt: fetchedAt ?? this.fetchedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (version.present) {
      map['version'] = Variable<String>(version.value);
    }
    if (json.present) {
      map['json'] = Variable<String>(json.value);
    }
    if (etag.present) {
      map['etag'] = Variable<String>(etag.value);
    }
    if (fetchedAt.present) {
      map['fetched_at'] = Variable<DateTime>(fetchedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('IndexCacheCompanion(')
          ..write('id: $id, ')
          ..write('version: $version, ')
          ..write('json: $json, ')
          ..write('etag: $etag, ')
          ..write('fetchedAt: $fetchedAt')
          ..write(')'))
        .toString();
  }
}

class $HomeworkTable extends Homework
    with TableInfo<$HomeworkTable, HomeworkRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HomeworkTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _subjectMeta = const VerificationMeta(
    'subject',
  );
  @override
  late final GeneratedColumn<String> subject = GeneratedColumn<String>(
    'subject',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dueDateMeta = const VerificationMeta(
    'dueDate',
  );
  @override
  late final GeneratedColumn<DateTime> dueDate = GeneratedColumn<DateTime>(
    'due_date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindHintMeta = const VerificationMeta(
    'kindHint',
  );
  @override
  late final GeneratedColumn<String> kindHint = GeneratedColumn<String>(
    'kind_hint',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _doneMeta = const VerificationMeta('done');
  @override
  late final GeneratedColumn<bool> done = GeneratedColumn<bool>(
    'done',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("done" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _photoPathMeta = const VerificationMeta(
    'photoPath',
  );
  @override
  late final GeneratedColumn<String> photoPath = GeneratedColumn<String>(
    'photo_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    subject,
    content,
    dueDate,
    kindHint,
    done,
    createdAt,
    photoPath,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'homework';
  @override
  VerificationContext validateIntegrity(
    Insertable<HomeworkRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('subject')) {
      context.handle(
        _subjectMeta,
        subject.isAcceptableOrUnknown(data['subject']!, _subjectMeta),
      );
    } else if (isInserting) {
      context.missing(_subjectMeta);
    }
    if (data.containsKey('text')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['text']!, _contentMeta),
      );
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('due_date')) {
      context.handle(
        _dueDateMeta,
        dueDate.isAcceptableOrUnknown(data['due_date']!, _dueDateMeta),
      );
    } else if (isInserting) {
      context.missing(_dueDateMeta);
    }
    if (data.containsKey('kind_hint')) {
      context.handle(
        _kindHintMeta,
        kindHint.isAcceptableOrUnknown(data['kind_hint']!, _kindHintMeta),
      );
    }
    if (data.containsKey('done')) {
      context.handle(
        _doneMeta,
        done.isAcceptableOrUnknown(data['done']!, _doneMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('photo_path')) {
      context.handle(
        _photoPathMeta,
        photoPath.isAcceptableOrUnknown(data['photo_path']!, _photoPathMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  HomeworkRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HomeworkRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      subject: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}subject'],
      )!,
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}text'],
      )!,
      dueDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}due_date'],
      )!,
      kindHint: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind_hint'],
      ),
      done: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}done'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      photoPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}photo_path'],
      ),
    );
  }

  @override
  $HomeworkTable createAlias(String alias) {
    return $HomeworkTable(attachedDatabase, alias);
  }
}

class HomeworkRow extends DataClass implements Insertable<HomeworkRow> {
  final int id;
  final String subject;
  final String content;
  final DateTime dueDate;
  final String? kindHint;
  final bool done;
  final DateTime createdAt;
  final String? photoPath;
  const HomeworkRow({
    required this.id,
    required this.subject,
    required this.content,
    required this.dueDate,
    this.kindHint,
    required this.done,
    required this.createdAt,
    this.photoPath,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['subject'] = Variable<String>(subject);
    map['text'] = Variable<String>(content);
    map['due_date'] = Variable<DateTime>(dueDate);
    if (!nullToAbsent || kindHint != null) {
      map['kind_hint'] = Variable<String>(kindHint);
    }
    map['done'] = Variable<bool>(done);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || photoPath != null) {
      map['photo_path'] = Variable<String>(photoPath);
    }
    return map;
  }

  HomeworkCompanion toCompanion(bool nullToAbsent) {
    return HomeworkCompanion(
      id: Value(id),
      subject: Value(subject),
      content: Value(content),
      dueDate: Value(dueDate),
      kindHint: kindHint == null && nullToAbsent
          ? const Value.absent()
          : Value(kindHint),
      done: Value(done),
      createdAt: Value(createdAt),
      photoPath: photoPath == null && nullToAbsent
          ? const Value.absent()
          : Value(photoPath),
    );
  }

  factory HomeworkRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HomeworkRow(
      id: serializer.fromJson<int>(json['id']),
      subject: serializer.fromJson<String>(json['subject']),
      content: serializer.fromJson<String>(json['content']),
      dueDate: serializer.fromJson<DateTime>(json['dueDate']),
      kindHint: serializer.fromJson<String?>(json['kindHint']),
      done: serializer.fromJson<bool>(json['done']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      photoPath: serializer.fromJson<String?>(json['photoPath']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'subject': serializer.toJson<String>(subject),
      'content': serializer.toJson<String>(content),
      'dueDate': serializer.toJson<DateTime>(dueDate),
      'kindHint': serializer.toJson<String?>(kindHint),
      'done': serializer.toJson<bool>(done),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'photoPath': serializer.toJson<String?>(photoPath),
    };
  }

  HomeworkRow copyWith({
    int? id,
    String? subject,
    String? content,
    DateTime? dueDate,
    Value<String?> kindHint = const Value.absent(),
    bool? done,
    DateTime? createdAt,
    Value<String?> photoPath = const Value.absent(),
  }) => HomeworkRow(
    id: id ?? this.id,
    subject: subject ?? this.subject,
    content: content ?? this.content,
    dueDate: dueDate ?? this.dueDate,
    kindHint: kindHint.present ? kindHint.value : this.kindHint,
    done: done ?? this.done,
    createdAt: createdAt ?? this.createdAt,
    photoPath: photoPath.present ? photoPath.value : this.photoPath,
  );
  HomeworkRow copyWithCompanion(HomeworkCompanion data) {
    return HomeworkRow(
      id: data.id.present ? data.id.value : this.id,
      subject: data.subject.present ? data.subject.value : this.subject,
      content: data.content.present ? data.content.value : this.content,
      dueDate: data.dueDate.present ? data.dueDate.value : this.dueDate,
      kindHint: data.kindHint.present ? data.kindHint.value : this.kindHint,
      done: data.done.present ? data.done.value : this.done,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      photoPath: data.photoPath.present ? data.photoPath.value : this.photoPath,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HomeworkRow(')
          ..write('id: $id, ')
          ..write('subject: $subject, ')
          ..write('content: $content, ')
          ..write('dueDate: $dueDate, ')
          ..write('kindHint: $kindHint, ')
          ..write('done: $done, ')
          ..write('createdAt: $createdAt, ')
          ..write('photoPath: $photoPath')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    subject,
    content,
    dueDate,
    kindHint,
    done,
    createdAt,
    photoPath,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HomeworkRow &&
          other.id == this.id &&
          other.subject == this.subject &&
          other.content == this.content &&
          other.dueDate == this.dueDate &&
          other.kindHint == this.kindHint &&
          other.done == this.done &&
          other.createdAt == this.createdAt &&
          other.photoPath == this.photoPath);
}

class HomeworkCompanion extends UpdateCompanion<HomeworkRow> {
  final Value<int> id;
  final Value<String> subject;
  final Value<String> content;
  final Value<DateTime> dueDate;
  final Value<String?> kindHint;
  final Value<bool> done;
  final Value<DateTime> createdAt;
  final Value<String?> photoPath;
  const HomeworkCompanion({
    this.id = const Value.absent(),
    this.subject = const Value.absent(),
    this.content = const Value.absent(),
    this.dueDate = const Value.absent(),
    this.kindHint = const Value.absent(),
    this.done = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.photoPath = const Value.absent(),
  });
  HomeworkCompanion.insert({
    this.id = const Value.absent(),
    required String subject,
    required String content,
    required DateTime dueDate,
    this.kindHint = const Value.absent(),
    this.done = const Value.absent(),
    required DateTime createdAt,
    this.photoPath = const Value.absent(),
  }) : subject = Value(subject),
       content = Value(content),
       dueDate = Value(dueDate),
       createdAt = Value(createdAt);
  static Insertable<HomeworkRow> custom({
    Expression<int>? id,
    Expression<String>? subject,
    Expression<String>? content,
    Expression<DateTime>? dueDate,
    Expression<String>? kindHint,
    Expression<bool>? done,
    Expression<DateTime>? createdAt,
    Expression<String>? photoPath,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (subject != null) 'subject': subject,
      if (content != null) 'text': content,
      if (dueDate != null) 'due_date': dueDate,
      if (kindHint != null) 'kind_hint': kindHint,
      if (done != null) 'done': done,
      if (createdAt != null) 'created_at': createdAt,
      if (photoPath != null) 'photo_path': photoPath,
    });
  }

  HomeworkCompanion copyWith({
    Value<int>? id,
    Value<String>? subject,
    Value<String>? content,
    Value<DateTime>? dueDate,
    Value<String?>? kindHint,
    Value<bool>? done,
    Value<DateTime>? createdAt,
    Value<String?>? photoPath,
  }) {
    return HomeworkCompanion(
      id: id ?? this.id,
      subject: subject ?? this.subject,
      content: content ?? this.content,
      dueDate: dueDate ?? this.dueDate,
      kindHint: kindHint ?? this.kindHint,
      done: done ?? this.done,
      createdAt: createdAt ?? this.createdAt,
      photoPath: photoPath ?? this.photoPath,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (subject.present) {
      map['subject'] = Variable<String>(subject.value);
    }
    if (content.present) {
      map['text'] = Variable<String>(content.value);
    }
    if (dueDate.present) {
      map['due_date'] = Variable<DateTime>(dueDate.value);
    }
    if (kindHint.present) {
      map['kind_hint'] = Variable<String>(kindHint.value);
    }
    if (done.present) {
      map['done'] = Variable<bool>(done.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (photoPath.present) {
      map['photo_path'] = Variable<String>(photoPath.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HomeworkCompanion(')
          ..write('id: $id, ')
          ..write('subject: $subject, ')
          ..write('content: $content, ')
          ..write('dueDate: $dueDate, ')
          ..write('kindHint: $kindHint, ')
          ..write('done: $done, ')
          ..write('createdAt: $createdAt, ')
          ..write('photoPath: $photoPath')
          ..write(')'))
        .toString();
  }
}

class $HomeworkAttachmentsTable extends HomeworkAttachments
    with TableInfo<$HomeworkAttachmentsTable, AttachmentRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HomeworkAttachmentsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _homeworkIdMeta = const VerificationMeta(
    'homeworkId',
  );
  @override
  late final GeneratedColumn<int> homeworkId = GeneratedColumn<int>(
    'homework_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pathMeta = const VerificationMeta('path');
  @override
  late final GeneratedColumn<String> path = GeneratedColumn<String>(
    'path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sizeBytesMeta = const VerificationMeta(
    'sizeBytes',
  );
  @override
  late final GeneratedColumn<int> sizeBytes = GeneratedColumn<int>(
    'size_bytes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [id, homeworkId, name, path, sizeBytes];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'homework_attachments';
  @override
  VerificationContext validateIntegrity(
    Insertable<AttachmentRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('homework_id')) {
      context.handle(
        _homeworkIdMeta,
        homeworkId.isAcceptableOrUnknown(data['homework_id']!, _homeworkIdMeta),
      );
    } else if (isInserting) {
      context.missing(_homeworkIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('path')) {
      context.handle(
        _pathMeta,
        path.isAcceptableOrUnknown(data['path']!, _pathMeta),
      );
    } else if (isInserting) {
      context.missing(_pathMeta);
    }
    if (data.containsKey('size_bytes')) {
      context.handle(
        _sizeBytesMeta,
        sizeBytes.isAcceptableOrUnknown(data['size_bytes']!, _sizeBytesMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AttachmentRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AttachmentRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      homeworkId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}homework_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      path: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}path'],
      )!,
      sizeBytes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}size_bytes'],
      ),
    );
  }

  @override
  $HomeworkAttachmentsTable createAlias(String alias) {
    return $HomeworkAttachmentsTable(attachedDatabase, alias);
  }
}

class AttachmentRow extends DataClass implements Insertable<AttachmentRow> {
  final int id;
  final int homeworkId;
  final String name;
  final String path;
  final int? sizeBytes;
  const AttachmentRow({
    required this.id,
    required this.homeworkId,
    required this.name,
    required this.path,
    this.sizeBytes,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['homework_id'] = Variable<int>(homeworkId);
    map['name'] = Variable<String>(name);
    map['path'] = Variable<String>(path);
    if (!nullToAbsent || sizeBytes != null) {
      map['size_bytes'] = Variable<int>(sizeBytes);
    }
    return map;
  }

  HomeworkAttachmentsCompanion toCompanion(bool nullToAbsent) {
    return HomeworkAttachmentsCompanion(
      id: Value(id),
      homeworkId: Value(homeworkId),
      name: Value(name),
      path: Value(path),
      sizeBytes: sizeBytes == null && nullToAbsent
          ? const Value.absent()
          : Value(sizeBytes),
    );
  }

  factory AttachmentRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AttachmentRow(
      id: serializer.fromJson<int>(json['id']),
      homeworkId: serializer.fromJson<int>(json['homeworkId']),
      name: serializer.fromJson<String>(json['name']),
      path: serializer.fromJson<String>(json['path']),
      sizeBytes: serializer.fromJson<int?>(json['sizeBytes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'homeworkId': serializer.toJson<int>(homeworkId),
      'name': serializer.toJson<String>(name),
      'path': serializer.toJson<String>(path),
      'sizeBytes': serializer.toJson<int?>(sizeBytes),
    };
  }

  AttachmentRow copyWith({
    int? id,
    int? homeworkId,
    String? name,
    String? path,
    Value<int?> sizeBytes = const Value.absent(),
  }) => AttachmentRow(
    id: id ?? this.id,
    homeworkId: homeworkId ?? this.homeworkId,
    name: name ?? this.name,
    path: path ?? this.path,
    sizeBytes: sizeBytes.present ? sizeBytes.value : this.sizeBytes,
  );
  AttachmentRow copyWithCompanion(HomeworkAttachmentsCompanion data) {
    return AttachmentRow(
      id: data.id.present ? data.id.value : this.id,
      homeworkId: data.homeworkId.present
          ? data.homeworkId.value
          : this.homeworkId,
      name: data.name.present ? data.name.value : this.name,
      path: data.path.present ? data.path.value : this.path,
      sizeBytes: data.sizeBytes.present ? data.sizeBytes.value : this.sizeBytes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AttachmentRow(')
          ..write('id: $id, ')
          ..write('homeworkId: $homeworkId, ')
          ..write('name: $name, ')
          ..write('path: $path, ')
          ..write('sizeBytes: $sizeBytes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, homeworkId, name, path, sizeBytes);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AttachmentRow &&
          other.id == this.id &&
          other.homeworkId == this.homeworkId &&
          other.name == this.name &&
          other.path == this.path &&
          other.sizeBytes == this.sizeBytes);
}

class HomeworkAttachmentsCompanion extends UpdateCompanion<AttachmentRow> {
  final Value<int> id;
  final Value<int> homeworkId;
  final Value<String> name;
  final Value<String> path;
  final Value<int?> sizeBytes;
  const HomeworkAttachmentsCompanion({
    this.id = const Value.absent(),
    this.homeworkId = const Value.absent(),
    this.name = const Value.absent(),
    this.path = const Value.absent(),
    this.sizeBytes = const Value.absent(),
  });
  HomeworkAttachmentsCompanion.insert({
    this.id = const Value.absent(),
    required int homeworkId,
    required String name,
    required String path,
    this.sizeBytes = const Value.absent(),
  }) : homeworkId = Value(homeworkId),
       name = Value(name),
       path = Value(path);
  static Insertable<AttachmentRow> custom({
    Expression<int>? id,
    Expression<int>? homeworkId,
    Expression<String>? name,
    Expression<String>? path,
    Expression<int>? sizeBytes,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (homeworkId != null) 'homework_id': homeworkId,
      if (name != null) 'name': name,
      if (path != null) 'path': path,
      if (sizeBytes != null) 'size_bytes': sizeBytes,
    });
  }

  HomeworkAttachmentsCompanion copyWith({
    Value<int>? id,
    Value<int>? homeworkId,
    Value<String>? name,
    Value<String>? path,
    Value<int?>? sizeBytes,
  }) {
    return HomeworkAttachmentsCompanion(
      id: id ?? this.id,
      homeworkId: homeworkId ?? this.homeworkId,
      name: name ?? this.name,
      path: path ?? this.path,
      sizeBytes: sizeBytes ?? this.sizeBytes,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (homeworkId.present) {
      map['homework_id'] = Variable<int>(homeworkId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (path.present) {
      map['path'] = Variable<String>(path.value);
    }
    if (sizeBytes.present) {
      map['size_bytes'] = Variable<int>(sizeBytes.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HomeworkAttachmentsCompanion(')
          ..write('id: $id, ')
          ..write('homeworkId: $homeworkId, ')
          ..write('name: $name, ')
          ..write('path: $path, ')
          ..write('sizeBytes: $sizeBytes')
          ..write(')'))
        .toString();
  }
}

class $AttachmentBlobsTable extends AttachmentBlobs
    with TableInfo<$AttachmentBlobsTable, AttachmentBlobRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AttachmentBlobsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _bytesMeta = const VerificationMeta('bytes');
  @override
  late final GeneratedColumn<Uint8List> bytes = GeneratedColumn<Uint8List>(
    'bytes',
    aliasedName,
    false,
    type: DriftSqlType.blob,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, bytes];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'attachment_blobs';
  @override
  VerificationContext validateIntegrity(
    Insertable<AttachmentBlobRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('bytes')) {
      context.handle(
        _bytesMeta,
        bytes.isAcceptableOrUnknown(data['bytes']!, _bytesMeta),
      );
    } else if (isInserting) {
      context.missing(_bytesMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AttachmentBlobRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AttachmentBlobRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      bytes: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}bytes'],
      )!,
    );
  }

  @override
  $AttachmentBlobsTable createAlias(String alias) {
    return $AttachmentBlobsTable(attachedDatabase, alias);
  }
}

class AttachmentBlobRow extends DataClass
    implements Insertable<AttachmentBlobRow> {
  final int id;
  final Uint8List bytes;
  const AttachmentBlobRow({required this.id, required this.bytes});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['bytes'] = Variable<Uint8List>(bytes);
    return map;
  }

  AttachmentBlobsCompanion toCompanion(bool nullToAbsent) {
    return AttachmentBlobsCompanion(id: Value(id), bytes: Value(bytes));
  }

  factory AttachmentBlobRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AttachmentBlobRow(
      id: serializer.fromJson<int>(json['id']),
      bytes: serializer.fromJson<Uint8List>(json['bytes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'bytes': serializer.toJson<Uint8List>(bytes),
    };
  }

  AttachmentBlobRow copyWith({int? id, Uint8List? bytes}) =>
      AttachmentBlobRow(id: id ?? this.id, bytes: bytes ?? this.bytes);
  AttachmentBlobRow copyWithCompanion(AttachmentBlobsCompanion data) {
    return AttachmentBlobRow(
      id: data.id.present ? data.id.value : this.id,
      bytes: data.bytes.present ? data.bytes.value : this.bytes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AttachmentBlobRow(')
          ..write('id: $id, ')
          ..write('bytes: $bytes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, $driftBlobEquality.hash(bytes));
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AttachmentBlobRow &&
          other.id == this.id &&
          $driftBlobEquality.equals(other.bytes, this.bytes));
}

class AttachmentBlobsCompanion extends UpdateCompanion<AttachmentBlobRow> {
  final Value<int> id;
  final Value<Uint8List> bytes;
  const AttachmentBlobsCompanion({
    this.id = const Value.absent(),
    this.bytes = const Value.absent(),
  });
  AttachmentBlobsCompanion.insert({
    this.id = const Value.absent(),
    required Uint8List bytes,
  }) : bytes = Value(bytes);
  static Insertable<AttachmentBlobRow> custom({
    Expression<int>? id,
    Expression<Uint8List>? bytes,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (bytes != null) 'bytes': bytes,
    });
  }

  AttachmentBlobsCompanion copyWith({Value<int>? id, Value<Uint8List>? bytes}) {
    return AttachmentBlobsCompanion(
      id: id ?? this.id,
      bytes: bytes ?? this.bytes,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (bytes.present) {
      map['bytes'] = Variable<Uint8List>(bytes.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AttachmentBlobsCompanion(')
          ..write('id: $id, ')
          ..write('bytes: $bytes')
          ..write(')'))
        .toString();
  }
}

class $GroupSharedCacheTable extends GroupSharedCache
    with TableInfo<$GroupSharedCacheTable, GroupSharedRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GroupSharedCacheTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _groupIdMeta = const VerificationMeta(
    'groupId',
  );
  @override
  late final GeneratedColumn<String> groupId = GeneratedColumn<String>(
    'group_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _jsonMeta = const VerificationMeta('json');
  @override
  late final GeneratedColumn<String> json = GeneratedColumn<String>(
    'json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [groupId, json];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'group_shared_cache';
  @override
  VerificationContext validateIntegrity(
    Insertable<GroupSharedRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('group_id')) {
      context.handle(
        _groupIdMeta,
        groupId.isAcceptableOrUnknown(data['group_id']!, _groupIdMeta),
      );
    } else if (isInserting) {
      context.missing(_groupIdMeta);
    }
    if (data.containsKey('json')) {
      context.handle(
        _jsonMeta,
        json.isAcceptableOrUnknown(data['json']!, _jsonMeta),
      );
    } else if (isInserting) {
      context.missing(_jsonMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {groupId};
  @override
  GroupSharedRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GroupSharedRow(
      groupId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}group_id'],
      )!,
      json: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}json'],
      )!,
    );
  }

  @override
  $GroupSharedCacheTable createAlias(String alias) {
    return $GroupSharedCacheTable(attachedDatabase, alias);
  }
}

class GroupSharedRow extends DataClass implements Insertable<GroupSharedRow> {
  final String groupId;
  final String json;
  const GroupSharedRow({required this.groupId, required this.json});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['group_id'] = Variable<String>(groupId);
    map['json'] = Variable<String>(json);
    return map;
  }

  GroupSharedCacheCompanion toCompanion(bool nullToAbsent) {
    return GroupSharedCacheCompanion(
      groupId: Value(groupId),
      json: Value(json),
    );
  }

  factory GroupSharedRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GroupSharedRow(
      groupId: serializer.fromJson<String>(json['groupId']),
      json: serializer.fromJson<String>(json['json']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'groupId': serializer.toJson<String>(groupId),
      'json': serializer.toJson<String>(json),
    };
  }

  GroupSharedRow copyWith({String? groupId, String? json}) =>
      GroupSharedRow(groupId: groupId ?? this.groupId, json: json ?? this.json);
  GroupSharedRow copyWithCompanion(GroupSharedCacheCompanion data) {
    return GroupSharedRow(
      groupId: data.groupId.present ? data.groupId.value : this.groupId,
      json: data.json.present ? data.json.value : this.json,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GroupSharedRow(')
          ..write('groupId: $groupId, ')
          ..write('json: $json')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(groupId, json);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GroupSharedRow &&
          other.groupId == this.groupId &&
          other.json == this.json);
}

class GroupSharedCacheCompanion extends UpdateCompanion<GroupSharedRow> {
  final Value<String> groupId;
  final Value<String> json;
  final Value<int> rowid;
  const GroupSharedCacheCompanion({
    this.groupId = const Value.absent(),
    this.json = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GroupSharedCacheCompanion.insert({
    required String groupId,
    required String json,
    this.rowid = const Value.absent(),
  }) : groupId = Value(groupId),
       json = Value(json);
  static Insertable<GroupSharedRow> custom({
    Expression<String>? groupId,
    Expression<String>? json,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (groupId != null) 'group_id': groupId,
      if (json != null) 'json': json,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GroupSharedCacheCompanion copyWith({
    Value<String>? groupId,
    Value<String>? json,
    Value<int>? rowid,
  }) {
    return GroupSharedCacheCompanion(
      groupId: groupId ?? this.groupId,
      json: json ?? this.json,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (groupId.present) {
      map['group_id'] = Variable<String>(groupId.value);
    }
    if (json.present) {
      map['json'] = Variable<String>(json.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GroupSharedCacheCompanion(')
          ..write('groupId: $groupId, ')
          ..write('json: $json, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OverridesTable extends Overrides
    with TableInfo<$OverridesTable, OverrideRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OverridesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pairMeta = const VerificationMeta('pair');
  @override
  late final GeneratedColumn<int> pair = GeneratedColumn<int>(
    'pair',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _subjectMeta = const VerificationMeta(
    'subject',
  );
  @override
  late final GeneratedColumn<String> subject = GeneratedColumn<String>(
    'subject',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _roomMeta = const VerificationMeta('room');
  @override
  late final GeneratedColumn<String> room = GeneratedColumn<String>(
    'room',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _teacherMeta = const VerificationMeta(
    'teacher',
  );
  @override
  late final GeneratedColumn<String> teacher = GeneratedColumn<String>(
    'teacher',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _repeatWeeklyMeta = const VerificationMeta(
    'repeatWeekly',
  );
  @override
  late final GeneratedColumn<bool> repeatWeekly = GeneratedColumn<bool>(
    'repeat_weekly',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("repeat_weekly" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _matchSubjectMeta = const VerificationMeta(
    'matchSubject',
  );
  @override
  late final GeneratedColumn<String> matchSubject = GeneratedColumn<String>(
    'match_subject',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    date,
    pair,
    type,
    subject,
    room,
    teacher,
    note,
    kind,
    repeatWeekly,
    matchSubject,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'overrides';
  @override
  VerificationContext validateIntegrity(
    Insertable<OverrideRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('pair')) {
      context.handle(
        _pairMeta,
        pair.isAcceptableOrUnknown(data['pair']!, _pairMeta),
      );
    } else if (isInserting) {
      context.missing(_pairMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('subject')) {
      context.handle(
        _subjectMeta,
        subject.isAcceptableOrUnknown(data['subject']!, _subjectMeta),
      );
    }
    if (data.containsKey('room')) {
      context.handle(
        _roomMeta,
        room.isAcceptableOrUnknown(data['room']!, _roomMeta),
      );
    }
    if (data.containsKey('teacher')) {
      context.handle(
        _teacherMeta,
        teacher.isAcceptableOrUnknown(data['teacher']!, _teacherMeta),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    }
    if (data.containsKey('repeat_weekly')) {
      context.handle(
        _repeatWeeklyMeta,
        repeatWeekly.isAcceptableOrUnknown(
          data['repeat_weekly']!,
          _repeatWeeklyMeta,
        ),
      );
    }
    if (data.containsKey('match_subject')) {
      context.handle(
        _matchSubjectMeta,
        matchSubject.isAcceptableOrUnknown(
          data['match_subject']!,
          _matchSubjectMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  OverrideRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OverrideRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date'],
      )!,
      pair: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}pair'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      subject: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}subject'],
      ),
      room: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}room'],
      ),
      teacher: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}teacher'],
      ),
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      ),
      repeatWeekly: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}repeat_weekly'],
      )!,
      matchSubject: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}match_subject'],
      ),
    );
  }

  @override
  $OverridesTable createAlias(String alias) {
    return $OverridesTable(attachedDatabase, alias);
  }
}

class OverrideRow extends DataClass implements Insertable<OverrideRow> {
  final int id;
  final DateTime date;
  final int pair;
  final String type;
  final String? subject;
  final String? room;
  final String? teacher;
  final String? note;
  final String? kind;
  final bool repeatWeekly;
  final String? matchSubject;
  const OverrideRow({
    required this.id,
    required this.date,
    required this.pair,
    required this.type,
    this.subject,
    this.room,
    this.teacher,
    this.note,
    this.kind,
    required this.repeatWeekly,
    this.matchSubject,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['date'] = Variable<DateTime>(date);
    map['pair'] = Variable<int>(pair);
    map['type'] = Variable<String>(type);
    if (!nullToAbsent || subject != null) {
      map['subject'] = Variable<String>(subject);
    }
    if (!nullToAbsent || room != null) {
      map['room'] = Variable<String>(room);
    }
    if (!nullToAbsent || teacher != null) {
      map['teacher'] = Variable<String>(teacher);
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    if (!nullToAbsent || kind != null) {
      map['kind'] = Variable<String>(kind);
    }
    map['repeat_weekly'] = Variable<bool>(repeatWeekly);
    if (!nullToAbsent || matchSubject != null) {
      map['match_subject'] = Variable<String>(matchSubject);
    }
    return map;
  }

  OverridesCompanion toCompanion(bool nullToAbsent) {
    return OverridesCompanion(
      id: Value(id),
      date: Value(date),
      pair: Value(pair),
      type: Value(type),
      subject: subject == null && nullToAbsent
          ? const Value.absent()
          : Value(subject),
      room: room == null && nullToAbsent ? const Value.absent() : Value(room),
      teacher: teacher == null && nullToAbsent
          ? const Value.absent()
          : Value(teacher),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      kind: kind == null && nullToAbsent ? const Value.absent() : Value(kind),
      repeatWeekly: Value(repeatWeekly),
      matchSubject: matchSubject == null && nullToAbsent
          ? const Value.absent()
          : Value(matchSubject),
    );
  }

  factory OverrideRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OverrideRow(
      id: serializer.fromJson<int>(json['id']),
      date: serializer.fromJson<DateTime>(json['date']),
      pair: serializer.fromJson<int>(json['pair']),
      type: serializer.fromJson<String>(json['type']),
      subject: serializer.fromJson<String?>(json['subject']),
      room: serializer.fromJson<String?>(json['room']),
      teacher: serializer.fromJson<String?>(json['teacher']),
      note: serializer.fromJson<String?>(json['note']),
      kind: serializer.fromJson<String?>(json['kind']),
      repeatWeekly: serializer.fromJson<bool>(json['repeatWeekly']),
      matchSubject: serializer.fromJson<String?>(json['matchSubject']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'date': serializer.toJson<DateTime>(date),
      'pair': serializer.toJson<int>(pair),
      'type': serializer.toJson<String>(type),
      'subject': serializer.toJson<String?>(subject),
      'room': serializer.toJson<String?>(room),
      'teacher': serializer.toJson<String?>(teacher),
      'note': serializer.toJson<String?>(note),
      'kind': serializer.toJson<String?>(kind),
      'repeatWeekly': serializer.toJson<bool>(repeatWeekly),
      'matchSubject': serializer.toJson<String?>(matchSubject),
    };
  }

  OverrideRow copyWith({
    int? id,
    DateTime? date,
    int? pair,
    String? type,
    Value<String?> subject = const Value.absent(),
    Value<String?> room = const Value.absent(),
    Value<String?> teacher = const Value.absent(),
    Value<String?> note = const Value.absent(),
    Value<String?> kind = const Value.absent(),
    bool? repeatWeekly,
    Value<String?> matchSubject = const Value.absent(),
  }) => OverrideRow(
    id: id ?? this.id,
    date: date ?? this.date,
    pair: pair ?? this.pair,
    type: type ?? this.type,
    subject: subject.present ? subject.value : this.subject,
    room: room.present ? room.value : this.room,
    teacher: teacher.present ? teacher.value : this.teacher,
    note: note.present ? note.value : this.note,
    kind: kind.present ? kind.value : this.kind,
    repeatWeekly: repeatWeekly ?? this.repeatWeekly,
    matchSubject: matchSubject.present ? matchSubject.value : this.matchSubject,
  );
  OverrideRow copyWithCompanion(OverridesCompanion data) {
    return OverrideRow(
      id: data.id.present ? data.id.value : this.id,
      date: data.date.present ? data.date.value : this.date,
      pair: data.pair.present ? data.pair.value : this.pair,
      type: data.type.present ? data.type.value : this.type,
      subject: data.subject.present ? data.subject.value : this.subject,
      room: data.room.present ? data.room.value : this.room,
      teacher: data.teacher.present ? data.teacher.value : this.teacher,
      note: data.note.present ? data.note.value : this.note,
      kind: data.kind.present ? data.kind.value : this.kind,
      repeatWeekly: data.repeatWeekly.present
          ? data.repeatWeekly.value
          : this.repeatWeekly,
      matchSubject: data.matchSubject.present
          ? data.matchSubject.value
          : this.matchSubject,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OverrideRow(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('pair: $pair, ')
          ..write('type: $type, ')
          ..write('subject: $subject, ')
          ..write('room: $room, ')
          ..write('teacher: $teacher, ')
          ..write('note: $note, ')
          ..write('kind: $kind, ')
          ..write('repeatWeekly: $repeatWeekly, ')
          ..write('matchSubject: $matchSubject')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    date,
    pair,
    type,
    subject,
    room,
    teacher,
    note,
    kind,
    repeatWeekly,
    matchSubject,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OverrideRow &&
          other.id == this.id &&
          other.date == this.date &&
          other.pair == this.pair &&
          other.type == this.type &&
          other.subject == this.subject &&
          other.room == this.room &&
          other.teacher == this.teacher &&
          other.note == this.note &&
          other.kind == this.kind &&
          other.repeatWeekly == this.repeatWeekly &&
          other.matchSubject == this.matchSubject);
}

class OverridesCompanion extends UpdateCompanion<OverrideRow> {
  final Value<int> id;
  final Value<DateTime> date;
  final Value<int> pair;
  final Value<String> type;
  final Value<String?> subject;
  final Value<String?> room;
  final Value<String?> teacher;
  final Value<String?> note;
  final Value<String?> kind;
  final Value<bool> repeatWeekly;
  final Value<String?> matchSubject;
  const OverridesCompanion({
    this.id = const Value.absent(),
    this.date = const Value.absent(),
    this.pair = const Value.absent(),
    this.type = const Value.absent(),
    this.subject = const Value.absent(),
    this.room = const Value.absent(),
    this.teacher = const Value.absent(),
    this.note = const Value.absent(),
    this.kind = const Value.absent(),
    this.repeatWeekly = const Value.absent(),
    this.matchSubject = const Value.absent(),
  });
  OverridesCompanion.insert({
    this.id = const Value.absent(),
    required DateTime date,
    required int pair,
    required String type,
    this.subject = const Value.absent(),
    this.room = const Value.absent(),
    this.teacher = const Value.absent(),
    this.note = const Value.absent(),
    this.kind = const Value.absent(),
    this.repeatWeekly = const Value.absent(),
    this.matchSubject = const Value.absent(),
  }) : date = Value(date),
       pair = Value(pair),
       type = Value(type);
  static Insertable<OverrideRow> custom({
    Expression<int>? id,
    Expression<DateTime>? date,
    Expression<int>? pair,
    Expression<String>? type,
    Expression<String>? subject,
    Expression<String>? room,
    Expression<String>? teacher,
    Expression<String>? note,
    Expression<String>? kind,
    Expression<bool>? repeatWeekly,
    Expression<String>? matchSubject,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (date != null) 'date': date,
      if (pair != null) 'pair': pair,
      if (type != null) 'type': type,
      if (subject != null) 'subject': subject,
      if (room != null) 'room': room,
      if (teacher != null) 'teacher': teacher,
      if (note != null) 'note': note,
      if (kind != null) 'kind': kind,
      if (repeatWeekly != null) 'repeat_weekly': repeatWeekly,
      if (matchSubject != null) 'match_subject': matchSubject,
    });
  }

  OverridesCompanion copyWith({
    Value<int>? id,
    Value<DateTime>? date,
    Value<int>? pair,
    Value<String>? type,
    Value<String?>? subject,
    Value<String?>? room,
    Value<String?>? teacher,
    Value<String?>? note,
    Value<String?>? kind,
    Value<bool>? repeatWeekly,
    Value<String?>? matchSubject,
  }) {
    return OverridesCompanion(
      id: id ?? this.id,
      date: date ?? this.date,
      pair: pair ?? this.pair,
      type: type ?? this.type,
      subject: subject ?? this.subject,
      room: room ?? this.room,
      teacher: teacher ?? this.teacher,
      note: note ?? this.note,
      kind: kind ?? this.kind,
      repeatWeekly: repeatWeekly ?? this.repeatWeekly,
      matchSubject: matchSubject ?? this.matchSubject,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (pair.present) {
      map['pair'] = Variable<int>(pair.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (subject.present) {
      map['subject'] = Variable<String>(subject.value);
    }
    if (room.present) {
      map['room'] = Variable<String>(room.value);
    }
    if (teacher.present) {
      map['teacher'] = Variable<String>(teacher.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (repeatWeekly.present) {
      map['repeat_weekly'] = Variable<bool>(repeatWeekly.value);
    }
    if (matchSubject.present) {
      map['match_subject'] = Variable<String>(matchSubject.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OverridesCompanion(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('pair: $pair, ')
          ..write('type: $type, ')
          ..write('subject: $subject, ')
          ..write('room: $room, ')
          ..write('teacher: $teacher, ')
          ..write('note: $note, ')
          ..write('kind: $kind, ')
          ..write('repeatWeekly: $repeatWeekly, ')
          ..write('matchSubject: $matchSubject')
          ..write(')'))
        .toString();
  }
}

class $SubjectAliasesTable extends SubjectAliases
    with TableInfo<$SubjectAliasesTable, SubjectAliasRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SubjectAliasesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _subjectMeta = const VerificationMeta(
    'subject',
  );
  @override
  late final GeneratedColumn<String> subject = GeneratedColumn<String>(
    'subject',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _shortNameMeta = const VerificationMeta(
    'shortName',
  );
  @override
  late final GeneratedColumn<String> shortName = GeneratedColumn<String>(
    'short_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _colorIndexMeta = const VerificationMeta(
    'colorIndex',
  );
  @override
  late final GeneratedColumn<int> colorIndex = GeneratedColumn<int>(
    'color_index',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [subject, shortName, colorIndex];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'subject_aliases';
  @override
  VerificationContext validateIntegrity(
    Insertable<SubjectAliasRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('subject')) {
      context.handle(
        _subjectMeta,
        subject.isAcceptableOrUnknown(data['subject']!, _subjectMeta),
      );
    } else if (isInserting) {
      context.missing(_subjectMeta);
    }
    if (data.containsKey('short_name')) {
      context.handle(
        _shortNameMeta,
        shortName.isAcceptableOrUnknown(data['short_name']!, _shortNameMeta),
      );
    } else if (isInserting) {
      context.missing(_shortNameMeta);
    }
    if (data.containsKey('color_index')) {
      context.handle(
        _colorIndexMeta,
        colorIndex.isAcceptableOrUnknown(data['color_index']!, _colorIndexMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {subject};
  @override
  SubjectAliasRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SubjectAliasRow(
      subject: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}subject'],
      )!,
      shortName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}short_name'],
      )!,
      colorIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}color_index'],
      ),
    );
  }

  @override
  $SubjectAliasesTable createAlias(String alias) {
    return $SubjectAliasesTable(attachedDatabase, alias);
  }
}

class SubjectAliasRow extends DataClass implements Insertable<SubjectAliasRow> {
  final String subject;
  final String shortName;
  final int? colorIndex;
  const SubjectAliasRow({
    required this.subject,
    required this.shortName,
    this.colorIndex,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['subject'] = Variable<String>(subject);
    map['short_name'] = Variable<String>(shortName);
    if (!nullToAbsent || colorIndex != null) {
      map['color_index'] = Variable<int>(colorIndex);
    }
    return map;
  }

  SubjectAliasesCompanion toCompanion(bool nullToAbsent) {
    return SubjectAliasesCompanion(
      subject: Value(subject),
      shortName: Value(shortName),
      colorIndex: colorIndex == null && nullToAbsent
          ? const Value.absent()
          : Value(colorIndex),
    );
  }

  factory SubjectAliasRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SubjectAliasRow(
      subject: serializer.fromJson<String>(json['subject']),
      shortName: serializer.fromJson<String>(json['shortName']),
      colorIndex: serializer.fromJson<int?>(json['colorIndex']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'subject': serializer.toJson<String>(subject),
      'shortName': serializer.toJson<String>(shortName),
      'colorIndex': serializer.toJson<int?>(colorIndex),
    };
  }

  SubjectAliasRow copyWith({
    String? subject,
    String? shortName,
    Value<int?> colorIndex = const Value.absent(),
  }) => SubjectAliasRow(
    subject: subject ?? this.subject,
    shortName: shortName ?? this.shortName,
    colorIndex: colorIndex.present ? colorIndex.value : this.colorIndex,
  );
  SubjectAliasRow copyWithCompanion(SubjectAliasesCompanion data) {
    return SubjectAliasRow(
      subject: data.subject.present ? data.subject.value : this.subject,
      shortName: data.shortName.present ? data.shortName.value : this.shortName,
      colorIndex: data.colorIndex.present
          ? data.colorIndex.value
          : this.colorIndex,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SubjectAliasRow(')
          ..write('subject: $subject, ')
          ..write('shortName: $shortName, ')
          ..write('colorIndex: $colorIndex')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(subject, shortName, colorIndex);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SubjectAliasRow &&
          other.subject == this.subject &&
          other.shortName == this.shortName &&
          other.colorIndex == this.colorIndex);
}

class SubjectAliasesCompanion extends UpdateCompanion<SubjectAliasRow> {
  final Value<String> subject;
  final Value<String> shortName;
  final Value<int?> colorIndex;
  final Value<int> rowid;
  const SubjectAliasesCompanion({
    this.subject = const Value.absent(),
    this.shortName = const Value.absent(),
    this.colorIndex = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SubjectAliasesCompanion.insert({
    required String subject,
    required String shortName,
    this.colorIndex = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : subject = Value(subject),
       shortName = Value(shortName);
  static Insertable<SubjectAliasRow> custom({
    Expression<String>? subject,
    Expression<String>? shortName,
    Expression<int>? colorIndex,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (subject != null) 'subject': subject,
      if (shortName != null) 'short_name': shortName,
      if (colorIndex != null) 'color_index': colorIndex,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SubjectAliasesCompanion copyWith({
    Value<String>? subject,
    Value<String>? shortName,
    Value<int?>? colorIndex,
    Value<int>? rowid,
  }) {
    return SubjectAliasesCompanion(
      subject: subject ?? this.subject,
      shortName: shortName ?? this.shortName,
      colorIndex: colorIndex ?? this.colorIndex,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (subject.present) {
      map['subject'] = Variable<String>(subject.value);
    }
    if (shortName.present) {
      map['short_name'] = Variable<String>(shortName.value);
    }
    if (colorIndex.present) {
      map['color_index'] = Variable<int>(colorIndex.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SubjectAliasesCompanion(')
          ..write('subject: $subject, ')
          ..write('shortName: $shortName, ')
          ..write('colorIndex: $colorIndex, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $NotesTable extends Notes with TableInfo<$NotesTable, NoteRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NotesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _subjectMeta = const VerificationMeta(
    'subject',
  );
  @override
  late final GeneratedColumn<String> subject = GeneratedColumn<String>(
    'subject',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, subject, content];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'notes';
  @override
  VerificationContext validateIntegrity(
    Insertable<NoteRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('subject')) {
      context.handle(
        _subjectMeta,
        subject.isAcceptableOrUnknown(data['subject']!, _subjectMeta),
      );
    } else if (isInserting) {
      context.missing(_subjectMeta);
    }
    if (data.containsKey('text')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['text']!, _contentMeta),
      );
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  NoteRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return NoteRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      subject: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}subject'],
      )!,
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}text'],
      )!,
    );
  }

  @override
  $NotesTable createAlias(String alias) {
    return $NotesTable(attachedDatabase, alias);
  }
}

class NoteRow extends DataClass implements Insertable<NoteRow> {
  final int id;
  final String subject;
  final String content;
  const NoteRow({
    required this.id,
    required this.subject,
    required this.content,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['subject'] = Variable<String>(subject);
    map['text'] = Variable<String>(content);
    return map;
  }

  NotesCompanion toCompanion(bool nullToAbsent) {
    return NotesCompanion(
      id: Value(id),
      subject: Value(subject),
      content: Value(content),
    );
  }

  factory NoteRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return NoteRow(
      id: serializer.fromJson<int>(json['id']),
      subject: serializer.fromJson<String>(json['subject']),
      content: serializer.fromJson<String>(json['content']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'subject': serializer.toJson<String>(subject),
      'content': serializer.toJson<String>(content),
    };
  }

  NoteRow copyWith({int? id, String? subject, String? content}) => NoteRow(
    id: id ?? this.id,
    subject: subject ?? this.subject,
    content: content ?? this.content,
  );
  NoteRow copyWithCompanion(NotesCompanion data) {
    return NoteRow(
      id: data.id.present ? data.id.value : this.id,
      subject: data.subject.present ? data.subject.value : this.subject,
      content: data.content.present ? data.content.value : this.content,
    );
  }

  @override
  String toString() {
    return (StringBuffer('NoteRow(')
          ..write('id: $id, ')
          ..write('subject: $subject, ')
          ..write('content: $content')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, subject, content);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NoteRow &&
          other.id == this.id &&
          other.subject == this.subject &&
          other.content == this.content);
}

class NotesCompanion extends UpdateCompanion<NoteRow> {
  final Value<int> id;
  final Value<String> subject;
  final Value<String> content;
  const NotesCompanion({
    this.id = const Value.absent(),
    this.subject = const Value.absent(),
    this.content = const Value.absent(),
  });
  NotesCompanion.insert({
    this.id = const Value.absent(),
    required String subject,
    required String content,
  }) : subject = Value(subject),
       content = Value(content);
  static Insertable<NoteRow> custom({
    Expression<int>? id,
    Expression<String>? subject,
    Expression<String>? content,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (subject != null) 'subject': subject,
      if (content != null) 'text': content,
    });
  }

  NotesCompanion copyWith({
    Value<int>? id,
    Value<String>? subject,
    Value<String>? content,
  }) {
    return NotesCompanion(
      id: id ?? this.id,
      subject: subject ?? this.subject,
      content: content ?? this.content,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (subject.present) {
      map['subject'] = Variable<String>(subject.value);
    }
    if (content.present) {
      map['text'] = Variable<String>(content.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NotesCompanion(')
          ..write('id: $id, ')
          ..write('subject: $subject, ')
          ..write('content: $content')
          ..write(')'))
        .toString();
  }
}

class $DeadlinesTable extends Deadlines
    with TableInfo<$DeadlinesTable, DeadlineRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DeadlinesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _subjectMeta = const VerificationMeta(
    'subject',
  );
  @override
  late final GeneratedColumn<String> subject = GeneratedColumn<String>(
    'subject',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [id, title, date, kind, subject];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'deadlines';
  @override
  VerificationContext validateIntegrity(
    Insertable<DeadlineRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('subject')) {
      context.handle(
        _subjectMeta,
        subject.isAcceptableOrUnknown(data['subject']!, _subjectMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DeadlineRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DeadlineRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      subject: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}subject'],
      ),
    );
  }

  @override
  $DeadlinesTable createAlias(String alias) {
    return $DeadlinesTable(attachedDatabase, alias);
  }
}

class DeadlineRow extends DataClass implements Insertable<DeadlineRow> {
  final int id;
  final String title;
  final DateTime date;
  final String kind;
  final String? subject;
  const DeadlineRow({
    required this.id,
    required this.title,
    required this.date,
    required this.kind,
    this.subject,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['title'] = Variable<String>(title);
    map['date'] = Variable<DateTime>(date);
    map['kind'] = Variable<String>(kind);
    if (!nullToAbsent || subject != null) {
      map['subject'] = Variable<String>(subject);
    }
    return map;
  }

  DeadlinesCompanion toCompanion(bool nullToAbsent) {
    return DeadlinesCompanion(
      id: Value(id),
      title: Value(title),
      date: Value(date),
      kind: Value(kind),
      subject: subject == null && nullToAbsent
          ? const Value.absent()
          : Value(subject),
    );
  }

  factory DeadlineRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DeadlineRow(
      id: serializer.fromJson<int>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      date: serializer.fromJson<DateTime>(json['date']),
      kind: serializer.fromJson<String>(json['kind']),
      subject: serializer.fromJson<String?>(json['subject']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'title': serializer.toJson<String>(title),
      'date': serializer.toJson<DateTime>(date),
      'kind': serializer.toJson<String>(kind),
      'subject': serializer.toJson<String?>(subject),
    };
  }

  DeadlineRow copyWith({
    int? id,
    String? title,
    DateTime? date,
    String? kind,
    Value<String?> subject = const Value.absent(),
  }) => DeadlineRow(
    id: id ?? this.id,
    title: title ?? this.title,
    date: date ?? this.date,
    kind: kind ?? this.kind,
    subject: subject.present ? subject.value : this.subject,
  );
  DeadlineRow copyWithCompanion(DeadlinesCompanion data) {
    return DeadlineRow(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      date: data.date.present ? data.date.value : this.date,
      kind: data.kind.present ? data.kind.value : this.kind,
      subject: data.subject.present ? data.subject.value : this.subject,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DeadlineRow(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('date: $date, ')
          ..write('kind: $kind, ')
          ..write('subject: $subject')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, title, date, kind, subject);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DeadlineRow &&
          other.id == this.id &&
          other.title == this.title &&
          other.date == this.date &&
          other.kind == this.kind &&
          other.subject == this.subject);
}

class DeadlinesCompanion extends UpdateCompanion<DeadlineRow> {
  final Value<int> id;
  final Value<String> title;
  final Value<DateTime> date;
  final Value<String> kind;
  final Value<String?> subject;
  const DeadlinesCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.date = const Value.absent(),
    this.kind = const Value.absent(),
    this.subject = const Value.absent(),
  });
  DeadlinesCompanion.insert({
    this.id = const Value.absent(),
    required String title,
    required DateTime date,
    required String kind,
    this.subject = const Value.absent(),
  }) : title = Value(title),
       date = Value(date),
       kind = Value(kind);
  static Insertable<DeadlineRow> custom({
    Expression<int>? id,
    Expression<String>? title,
    Expression<DateTime>? date,
    Expression<String>? kind,
    Expression<String>? subject,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (date != null) 'date': date,
      if (kind != null) 'kind': kind,
      if (subject != null) 'subject': subject,
    });
  }

  DeadlinesCompanion copyWith({
    Value<int>? id,
    Value<String>? title,
    Value<DateTime>? date,
    Value<String>? kind,
    Value<String?>? subject,
  }) {
    return DeadlinesCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      date: date ?? this.date,
      kind: kind ?? this.kind,
      subject: subject ?? this.subject,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (subject.present) {
      map['subject'] = Variable<String>(subject.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DeadlinesCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('date: $date, ')
          ..write('kind: $kind, ')
          ..write('subject: $subject')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ScheduleCacheTable scheduleCache = $ScheduleCacheTable(this);
  late final $IndexCacheTable indexCache = $IndexCacheTable(this);
  late final $HomeworkTable homework = $HomeworkTable(this);
  late final $HomeworkAttachmentsTable homeworkAttachments =
      $HomeworkAttachmentsTable(this);
  late final $AttachmentBlobsTable attachmentBlobs = $AttachmentBlobsTable(
    this,
  );
  late final $GroupSharedCacheTable groupSharedCache = $GroupSharedCacheTable(
    this,
  );
  late final $OverridesTable overrides = $OverridesTable(this);
  late final $SubjectAliasesTable subjectAliases = $SubjectAliasesTable(this);
  late final $NotesTable notes = $NotesTable(this);
  late final $DeadlinesTable deadlines = $DeadlinesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    scheduleCache,
    indexCache,
    homework,
    homeworkAttachments,
    attachmentBlobs,
    groupSharedCache,
    overrides,
    subjectAliases,
    notes,
    deadlines,
  ];
}

typedef $$ScheduleCacheTableCreateCompanionBuilder =
    ScheduleCacheCompanion Function({
      required String groupId,
      required String version,
      required String hash,
      required String json,
      Value<String?> etag,
      required DateTime fetchedAt,
      Value<int> rowid,
    });
typedef $$ScheduleCacheTableUpdateCompanionBuilder =
    ScheduleCacheCompanion Function({
      Value<String> groupId,
      Value<String> version,
      Value<String> hash,
      Value<String> json,
      Value<String?> etag,
      Value<DateTime> fetchedAt,
      Value<int> rowid,
    });

class $$ScheduleCacheTableFilterComposer
    extends Composer<_$AppDatabase, $ScheduleCacheTable> {
  $$ScheduleCacheTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get groupId => $composableBuilder(
    column: $table.groupId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get hash => $composableBuilder(
    column: $table.hash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get json => $composableBuilder(
    column: $table.json,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get etag => $composableBuilder(
    column: $table.etag,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ScheduleCacheTableOrderingComposer
    extends Composer<_$AppDatabase, $ScheduleCacheTable> {
  $$ScheduleCacheTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get groupId => $composableBuilder(
    column: $table.groupId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get hash => $composableBuilder(
    column: $table.hash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get json => $composableBuilder(
    column: $table.json,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get etag => $composableBuilder(
    column: $table.etag,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ScheduleCacheTableAnnotationComposer
    extends Composer<_$AppDatabase, $ScheduleCacheTable> {
  $$ScheduleCacheTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get groupId =>
      $composableBuilder(column: $table.groupId, builder: (column) => column);

  GeneratedColumn<String> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<String> get hash =>
      $composableBuilder(column: $table.hash, builder: (column) => column);

  GeneratedColumn<String> get json =>
      $composableBuilder(column: $table.json, builder: (column) => column);

  GeneratedColumn<String> get etag =>
      $composableBuilder(column: $table.etag, builder: (column) => column);

  GeneratedColumn<DateTime> get fetchedAt =>
      $composableBuilder(column: $table.fetchedAt, builder: (column) => column);
}

class $$ScheduleCacheTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ScheduleCacheTable,
          ScheduleCacheData,
          $$ScheduleCacheTableFilterComposer,
          $$ScheduleCacheTableOrderingComposer,
          $$ScheduleCacheTableAnnotationComposer,
          $$ScheduleCacheTableCreateCompanionBuilder,
          $$ScheduleCacheTableUpdateCompanionBuilder,
          (
            ScheduleCacheData,
            BaseReferences<
              _$AppDatabase,
              $ScheduleCacheTable,
              ScheduleCacheData
            >,
          ),
          ScheduleCacheData,
          PrefetchHooks Function()
        > {
  $$ScheduleCacheTableTableManager(_$AppDatabase db, $ScheduleCacheTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ScheduleCacheTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ScheduleCacheTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ScheduleCacheTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> groupId = const Value.absent(),
                Value<String> version = const Value.absent(),
                Value<String> hash = const Value.absent(),
                Value<String> json = const Value.absent(),
                Value<String?> etag = const Value.absent(),
                Value<DateTime> fetchedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ScheduleCacheCompanion(
                groupId: groupId,
                version: version,
                hash: hash,
                json: json,
                etag: etag,
                fetchedAt: fetchedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String groupId,
                required String version,
                required String hash,
                required String json,
                Value<String?> etag = const Value.absent(),
                required DateTime fetchedAt,
                Value<int> rowid = const Value.absent(),
              }) => ScheduleCacheCompanion.insert(
                groupId: groupId,
                version: version,
                hash: hash,
                json: json,
                etag: etag,
                fetchedAt: fetchedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ScheduleCacheTable, ScheduleCacheData>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $ScheduleCacheTable,
                    ScheduleCacheData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ScheduleCacheTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ScheduleCacheTable,
      ScheduleCacheData,
      $$ScheduleCacheTableFilterComposer,
      $$ScheduleCacheTableOrderingComposer,
      $$ScheduleCacheTableAnnotationComposer,
      $$ScheduleCacheTableCreateCompanionBuilder,
      $$ScheduleCacheTableUpdateCompanionBuilder,
      (
        ScheduleCacheData,
        BaseReferences<_$AppDatabase, $ScheduleCacheTable, ScheduleCacheData>,
      ),
      ScheduleCacheData,
      PrefetchHooks Function()
    >;
typedef $$IndexCacheTableCreateCompanionBuilder = IndexCacheCompanion Function({
  Value<int> id,
  required String version,
  required String json,
  Value<String?> etag,
  required DateTime fetchedAt,
});
typedef $$IndexCacheTableUpdateCompanionBuilder = IndexCacheCompanion Function({
  Value<int> id,
  Value<String> version,
  Value<String> json,
  Value<String?> etag,
  Value<DateTime> fetchedAt,
});

class $$IndexCacheTableFilterComposer
    extends Composer<_$AppDatabase, $IndexCacheTable> {
  $$IndexCacheTableFilterComposer({
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

  ColumnFilters<String> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get json => $composableBuilder(
    column: $table.json,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get etag => $composableBuilder(
    column: $table.etag,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$IndexCacheTableOrderingComposer
    extends Composer<_$AppDatabase, $IndexCacheTable> {
  $$IndexCacheTableOrderingComposer({
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

  ColumnOrderings<String> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get json => $composableBuilder(
    column: $table.json,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get etag => $composableBuilder(
    column: $table.etag,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$IndexCacheTableAnnotationComposer
    extends Composer<_$AppDatabase, $IndexCacheTable> {
  $$IndexCacheTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<String> get json =>
      $composableBuilder(column: $table.json, builder: (column) => column);

  GeneratedColumn<String> get etag =>
      $composableBuilder(column: $table.etag, builder: (column) => column);

  GeneratedColumn<DateTime> get fetchedAt =>
      $composableBuilder(column: $table.fetchedAt, builder: (column) => column);
}

class $$IndexCacheTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $IndexCacheTable,
          IndexCacheData,
          $$IndexCacheTableFilterComposer,
          $$IndexCacheTableOrderingComposer,
          $$IndexCacheTableAnnotationComposer,
          $$IndexCacheTableCreateCompanionBuilder,
          $$IndexCacheTableUpdateCompanionBuilder,
          (
            IndexCacheData,
            BaseReferences<_$AppDatabase, $IndexCacheTable, IndexCacheData>,
          ),
          IndexCacheData,
          PrefetchHooks Function()
        > {
  $$IndexCacheTableTableManager(_$AppDatabase db, $IndexCacheTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$IndexCacheTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$IndexCacheTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$IndexCacheTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> version = const Value.absent(),
                Value<String> json = const Value.absent(),
                Value<String?> etag = const Value.absent(),
                Value<DateTime> fetchedAt = const Value.absent(),
              }) => IndexCacheCompanion(
                id: id,
                version: version,
                json: json,
                etag: etag,
                fetchedAt: fetchedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String version,
                required String json,
                Value<String?> etag = const Value.absent(),
                required DateTime fetchedAt,
              }) => IndexCacheCompanion.insert(
                id: id,
                version: version,
                json: json,
                etag: etag,
                fetchedAt: fetchedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$IndexCacheTable, IndexCacheData>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $IndexCacheTable,
                    IndexCacheData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$IndexCacheTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $IndexCacheTable,
      IndexCacheData,
      $$IndexCacheTableFilterComposer,
      $$IndexCacheTableOrderingComposer,
      $$IndexCacheTableAnnotationComposer,
      $$IndexCacheTableCreateCompanionBuilder,
      $$IndexCacheTableUpdateCompanionBuilder,
      (
        IndexCacheData,
        BaseReferences<_$AppDatabase, $IndexCacheTable, IndexCacheData>,
      ),
      IndexCacheData,
      PrefetchHooks Function()
    >;
typedef $$HomeworkTableCreateCompanionBuilder = HomeworkCompanion Function({
  Value<int> id,
  required String subject,
  required String content,
  required DateTime dueDate,
  Value<String?> kindHint,
  Value<bool> done,
  required DateTime createdAt,
  Value<String?> photoPath,
});
typedef $$HomeworkTableUpdateCompanionBuilder = HomeworkCompanion Function({
  Value<int> id,
  Value<String> subject,
  Value<String> content,
  Value<DateTime> dueDate,
  Value<String?> kindHint,
  Value<bool> done,
  Value<DateTime> createdAt,
  Value<String?> photoPath,
});

class $$HomeworkTableFilterComposer
    extends Composer<_$AppDatabase, $HomeworkTable> {
  $$HomeworkTableFilterComposer({
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

  ColumnFilters<String> get subject => $composableBuilder(
    column: $table.subject,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get dueDate => $composableBuilder(
    column: $table.dueDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kindHint => $composableBuilder(
    column: $table.kindHint,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get done => $composableBuilder(
    column: $table.done,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get photoPath => $composableBuilder(
    column: $table.photoPath,
    builder: (column) => ColumnFilters(column),
  );
}

class $$HomeworkTableOrderingComposer
    extends Composer<_$AppDatabase, $HomeworkTable> {
  $$HomeworkTableOrderingComposer({
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

  ColumnOrderings<String> get subject => $composableBuilder(
    column: $table.subject,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get dueDate => $composableBuilder(
    column: $table.dueDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kindHint => $composableBuilder(
    column: $table.kindHint,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get done => $composableBuilder(
    column: $table.done,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get photoPath => $composableBuilder(
    column: $table.photoPath,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$HomeworkTableAnnotationComposer
    extends Composer<_$AppDatabase, $HomeworkTable> {
  $$HomeworkTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get subject =>
      $composableBuilder(column: $table.subject, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<DateTime> get dueDate =>
      $composableBuilder(column: $table.dueDate, builder: (column) => column);

  GeneratedColumn<String> get kindHint =>
      $composableBuilder(column: $table.kindHint, builder: (column) => column);

  GeneratedColumn<bool> get done =>
      $composableBuilder(column: $table.done, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get photoPath =>
      $composableBuilder(column: $table.photoPath, builder: (column) => column);
}

class $$HomeworkTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $HomeworkTable,
          HomeworkRow,
          $$HomeworkTableFilterComposer,
          $$HomeworkTableOrderingComposer,
          $$HomeworkTableAnnotationComposer,
          $$HomeworkTableCreateCompanionBuilder,
          $$HomeworkTableUpdateCompanionBuilder,
          (
            HomeworkRow,
            BaseReferences<_$AppDatabase, $HomeworkTable, HomeworkRow>,
          ),
          HomeworkRow,
          PrefetchHooks Function()
        > {
  $$HomeworkTableTableManager(_$AppDatabase db, $HomeworkTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HomeworkTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HomeworkTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HomeworkTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> subject = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<DateTime> dueDate = const Value.absent(),
                Value<String?> kindHint = const Value.absent(),
                Value<bool> done = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<String?> photoPath = const Value.absent(),
              }) => HomeworkCompanion(
                id: id,
                subject: subject,
                content: content,
                dueDate: dueDate,
                kindHint: kindHint,
                done: done,
                createdAt: createdAt,
                photoPath: photoPath,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String subject,
                required String content,
                required DateTime dueDate,
                Value<String?> kindHint = const Value.absent(),
                Value<bool> done = const Value.absent(),
                required DateTime createdAt,
                Value<String?> photoPath = const Value.absent(),
              }) => HomeworkCompanion.insert(
                id: id,
                subject: subject,
                content: content,
                dueDate: dueDate,
                kindHint: kindHint,
                done: done,
                createdAt: createdAt,
                photoPath: photoPath,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$HomeworkTable, HomeworkRow>(table),
                  BaseReferences<_$AppDatabase, $HomeworkTable, HomeworkRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$HomeworkTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $HomeworkTable,
      HomeworkRow,
      $$HomeworkTableFilterComposer,
      $$HomeworkTableOrderingComposer,
      $$HomeworkTableAnnotationComposer,
      $$HomeworkTableCreateCompanionBuilder,
      $$HomeworkTableUpdateCompanionBuilder,
      (HomeworkRow, BaseReferences<_$AppDatabase, $HomeworkTable, HomeworkRow>),
      HomeworkRow,
      PrefetchHooks Function()
    >;
typedef $$HomeworkAttachmentsTableCreateCompanionBuilder =
    HomeworkAttachmentsCompanion Function({
      Value<int> id,
      required int homeworkId,
      required String name,
      required String path,
      Value<int?> sizeBytes,
    });
typedef $$HomeworkAttachmentsTableUpdateCompanionBuilder =
    HomeworkAttachmentsCompanion Function({
      Value<int> id,
      Value<int> homeworkId,
      Value<String> name,
      Value<String> path,
      Value<int?> sizeBytes,
    });

class $$HomeworkAttachmentsTableFilterComposer
    extends Composer<_$AppDatabase, $HomeworkAttachmentsTable> {
  $$HomeworkAttachmentsTableFilterComposer({
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

  ColumnFilters<int> get homeworkId => $composableBuilder(
    column: $table.homeworkId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get path => $composableBuilder(
    column: $table.path,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sizeBytes => $composableBuilder(
    column: $table.sizeBytes,
    builder: (column) => ColumnFilters(column),
  );
}

class $$HomeworkAttachmentsTableOrderingComposer
    extends Composer<_$AppDatabase, $HomeworkAttachmentsTable> {
  $$HomeworkAttachmentsTableOrderingComposer({
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

  ColumnOrderings<int> get homeworkId => $composableBuilder(
    column: $table.homeworkId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get path => $composableBuilder(
    column: $table.path,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sizeBytes => $composableBuilder(
    column: $table.sizeBytes,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$HomeworkAttachmentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $HomeworkAttachmentsTable> {
  $$HomeworkAttachmentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get homeworkId => $composableBuilder(
    column: $table.homeworkId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get path =>
      $composableBuilder(column: $table.path, builder: (column) => column);

  GeneratedColumn<int> get sizeBytes =>
      $composableBuilder(column: $table.sizeBytes, builder: (column) => column);
}

class $$HomeworkAttachmentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $HomeworkAttachmentsTable,
          AttachmentRow,
          $$HomeworkAttachmentsTableFilterComposer,
          $$HomeworkAttachmentsTableOrderingComposer,
          $$HomeworkAttachmentsTableAnnotationComposer,
          $$HomeworkAttachmentsTableCreateCompanionBuilder,
          $$HomeworkAttachmentsTableUpdateCompanionBuilder,
          (
            AttachmentRow,
            BaseReferences<
              _$AppDatabase,
              $HomeworkAttachmentsTable,
              AttachmentRow
            >,
          ),
          AttachmentRow,
          PrefetchHooks Function()
        > {
  $$HomeworkAttachmentsTableTableManager(
    _$AppDatabase db,
    $HomeworkAttachmentsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HomeworkAttachmentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HomeworkAttachmentsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$HomeworkAttachmentsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> homeworkId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> path = const Value.absent(),
                Value<int?> sizeBytes = const Value.absent(),
              }) => HomeworkAttachmentsCompanion(
                id: id,
                homeworkId: homeworkId,
                name: name,
                path: path,
                sizeBytes: sizeBytes,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int homeworkId,
                required String name,
                required String path,
                Value<int?> sizeBytes = const Value.absent(),
              }) => HomeworkAttachmentsCompanion.insert(
                id: id,
                homeworkId: homeworkId,
                name: name,
                path: path,
                sizeBytes: sizeBytes,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$HomeworkAttachmentsTable, AttachmentRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $HomeworkAttachmentsTable,
                    AttachmentRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$HomeworkAttachmentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $HomeworkAttachmentsTable,
      AttachmentRow,
      $$HomeworkAttachmentsTableFilterComposer,
      $$HomeworkAttachmentsTableOrderingComposer,
      $$HomeworkAttachmentsTableAnnotationComposer,
      $$HomeworkAttachmentsTableCreateCompanionBuilder,
      $$HomeworkAttachmentsTableUpdateCompanionBuilder,
      (
        AttachmentRow,
        BaseReferences<_$AppDatabase, $HomeworkAttachmentsTable, AttachmentRow>,
      ),
      AttachmentRow,
      PrefetchHooks Function()
    >;
typedef $$AttachmentBlobsTableCreateCompanionBuilder =
    AttachmentBlobsCompanion Function({
      Value<int> id,
      required Uint8List bytes,
    });
typedef $$AttachmentBlobsTableUpdateCompanionBuilder =
    AttachmentBlobsCompanion Function({Value<int> id, Value<Uint8List> bytes});

class $$AttachmentBlobsTableFilterComposer
    extends Composer<_$AppDatabase, $AttachmentBlobsTable> {
  $$AttachmentBlobsTableFilterComposer({
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

  ColumnFilters<Uint8List> get bytes => $composableBuilder(
    column: $table.bytes,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AttachmentBlobsTableOrderingComposer
    extends Composer<_$AppDatabase, $AttachmentBlobsTable> {
  $$AttachmentBlobsTableOrderingComposer({
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

  ColumnOrderings<Uint8List> get bytes => $composableBuilder(
    column: $table.bytes,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AttachmentBlobsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AttachmentBlobsTable> {
  $$AttachmentBlobsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<Uint8List> get bytes =>
      $composableBuilder(column: $table.bytes, builder: (column) => column);
}

class $$AttachmentBlobsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AttachmentBlobsTable,
          AttachmentBlobRow,
          $$AttachmentBlobsTableFilterComposer,
          $$AttachmentBlobsTableOrderingComposer,
          $$AttachmentBlobsTableAnnotationComposer,
          $$AttachmentBlobsTableCreateCompanionBuilder,
          $$AttachmentBlobsTableUpdateCompanionBuilder,
          (
            AttachmentBlobRow,
            BaseReferences<
              _$AppDatabase,
              $AttachmentBlobsTable,
              AttachmentBlobRow
            >,
          ),
          AttachmentBlobRow,
          PrefetchHooks Function()
        > {
  $$AttachmentBlobsTableTableManager(
    _$AppDatabase db,
    $AttachmentBlobsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AttachmentBlobsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AttachmentBlobsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AttachmentBlobsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<Uint8List> bytes = const Value.absent(),
          }) => AttachmentBlobsCompanion(id: id, bytes: bytes),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required Uint8List bytes,
          }) => AttachmentBlobsCompanion.insert(id: id, bytes: bytes),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AttachmentBlobsTable, AttachmentBlobRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $AttachmentBlobsTable,
                    AttachmentBlobRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AttachmentBlobsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AttachmentBlobsTable,
      AttachmentBlobRow,
      $$AttachmentBlobsTableFilterComposer,
      $$AttachmentBlobsTableOrderingComposer,
      $$AttachmentBlobsTableAnnotationComposer,
      $$AttachmentBlobsTableCreateCompanionBuilder,
      $$AttachmentBlobsTableUpdateCompanionBuilder,
      (
        AttachmentBlobRow,
        BaseReferences<_$AppDatabase, $AttachmentBlobsTable, AttachmentBlobRow>,
      ),
      AttachmentBlobRow,
      PrefetchHooks Function()
    >;
typedef $$GroupSharedCacheTableCreateCompanionBuilder =
    GroupSharedCacheCompanion Function({
      required String groupId,
      required String json,
      Value<int> rowid,
    });
typedef $$GroupSharedCacheTableUpdateCompanionBuilder =
    GroupSharedCacheCompanion Function({
      Value<String> groupId,
      Value<String> json,
      Value<int> rowid,
    });

class $$GroupSharedCacheTableFilterComposer
    extends Composer<_$AppDatabase, $GroupSharedCacheTable> {
  $$GroupSharedCacheTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get groupId => $composableBuilder(
    column: $table.groupId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get json => $composableBuilder(
    column: $table.json,
    builder: (column) => ColumnFilters(column),
  );
}

class $$GroupSharedCacheTableOrderingComposer
    extends Composer<_$AppDatabase, $GroupSharedCacheTable> {
  $$GroupSharedCacheTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get groupId => $composableBuilder(
    column: $table.groupId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get json => $composableBuilder(
    column: $table.json,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$GroupSharedCacheTableAnnotationComposer
    extends Composer<_$AppDatabase, $GroupSharedCacheTable> {
  $$GroupSharedCacheTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get groupId =>
      $composableBuilder(column: $table.groupId, builder: (column) => column);

  GeneratedColumn<String> get json =>
      $composableBuilder(column: $table.json, builder: (column) => column);
}

class $$GroupSharedCacheTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $GroupSharedCacheTable,
          GroupSharedRow,
          $$GroupSharedCacheTableFilterComposer,
          $$GroupSharedCacheTableOrderingComposer,
          $$GroupSharedCacheTableAnnotationComposer,
          $$GroupSharedCacheTableCreateCompanionBuilder,
          $$GroupSharedCacheTableUpdateCompanionBuilder,
          (
            GroupSharedRow,
            BaseReferences<
              _$AppDatabase,
              $GroupSharedCacheTable,
              GroupSharedRow
            >,
          ),
          GroupSharedRow,
          PrefetchHooks Function()
        > {
  $$GroupSharedCacheTableTableManager(
    _$AppDatabase db,
    $GroupSharedCacheTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GroupSharedCacheTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GroupSharedCacheTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GroupSharedCacheTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> groupId = const Value.absent(),
                Value<String> json = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GroupSharedCacheCompanion(
                groupId: groupId,
                json: json,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String groupId,
                required String json,
                Value<int> rowid = const Value.absent(),
              }) => GroupSharedCacheCompanion.insert(
                groupId: groupId,
                json: json,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$GroupSharedCacheTable, GroupSharedRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $GroupSharedCacheTable,
                    GroupSharedRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$GroupSharedCacheTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $GroupSharedCacheTable,
      GroupSharedRow,
      $$GroupSharedCacheTableFilterComposer,
      $$GroupSharedCacheTableOrderingComposer,
      $$GroupSharedCacheTableAnnotationComposer,
      $$GroupSharedCacheTableCreateCompanionBuilder,
      $$GroupSharedCacheTableUpdateCompanionBuilder,
      (
        GroupSharedRow,
        BaseReferences<_$AppDatabase, $GroupSharedCacheTable, GroupSharedRow>,
      ),
      GroupSharedRow,
      PrefetchHooks Function()
    >;
typedef $$OverridesTableCreateCompanionBuilder = OverridesCompanion Function({
  Value<int> id,
  required DateTime date,
  required int pair,
  required String type,
  Value<String?> subject,
  Value<String?> room,
  Value<String?> teacher,
  Value<String?> note,
  Value<String?> kind,
  Value<bool> repeatWeekly,
  Value<String?> matchSubject,
});
typedef $$OverridesTableUpdateCompanionBuilder = OverridesCompanion Function({
  Value<int> id,
  Value<DateTime> date,
  Value<int> pair,
  Value<String> type,
  Value<String?> subject,
  Value<String?> room,
  Value<String?> teacher,
  Value<String?> note,
  Value<String?> kind,
  Value<bool> repeatWeekly,
  Value<String?> matchSubject,
});

class $$OverridesTableFilterComposer
    extends Composer<_$AppDatabase, $OverridesTable> {
  $$OverridesTableFilterComposer({
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

  ColumnFilters<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get pair => $composableBuilder(
    column: $table.pair,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get subject => $composableBuilder(
    column: $table.subject,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get room => $composableBuilder(
    column: $table.room,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get teacher => $composableBuilder(
    column: $table.teacher,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get repeatWeekly => $composableBuilder(
    column: $table.repeatWeekly,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get matchSubject => $composableBuilder(
    column: $table.matchSubject,
    builder: (column) => ColumnFilters(column),
  );
}

class $$OverridesTableOrderingComposer
    extends Composer<_$AppDatabase, $OverridesTable> {
  $$OverridesTableOrderingComposer({
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

  ColumnOrderings<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get pair => $composableBuilder(
    column: $table.pair,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subject => $composableBuilder(
    column: $table.subject,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get room => $composableBuilder(
    column: $table.room,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get teacher => $composableBuilder(
    column: $table.teacher,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get repeatWeekly => $composableBuilder(
    column: $table.repeatWeekly,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get matchSubject => $composableBuilder(
    column: $table.matchSubject,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$OverridesTableAnnotationComposer
    extends Composer<_$AppDatabase, $OverridesTable> {
  $$OverridesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<int> get pair =>
      $composableBuilder(column: $table.pair, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get subject =>
      $composableBuilder(column: $table.subject, builder: (column) => column);

  GeneratedColumn<String> get room =>
      $composableBuilder(column: $table.room, builder: (column) => column);

  GeneratedColumn<String> get teacher =>
      $composableBuilder(column: $table.teacher, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<bool> get repeatWeekly => $composableBuilder(
    column: $table.repeatWeekly,
    builder: (column) => column,
  );

  GeneratedColumn<String> get matchSubject => $composableBuilder(
    column: $table.matchSubject,
    builder: (column) => column,
  );
}

class $$OverridesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $OverridesTable,
          OverrideRow,
          $$OverridesTableFilterComposer,
          $$OverridesTableOrderingComposer,
          $$OverridesTableAnnotationComposer,
          $$OverridesTableCreateCompanionBuilder,
          $$OverridesTableUpdateCompanionBuilder,
          (
            OverrideRow,
            BaseReferences<_$AppDatabase, $OverridesTable, OverrideRow>,
          ),
          OverrideRow,
          PrefetchHooks Function()
        > {
  $$OverridesTableTableManager(_$AppDatabase db, $OverridesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OverridesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OverridesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OverridesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime> date = const Value.absent(),
                Value<int> pair = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String?> subject = const Value.absent(),
                Value<String?> room = const Value.absent(),
                Value<String?> teacher = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<String?> kind = const Value.absent(),
                Value<bool> repeatWeekly = const Value.absent(),
                Value<String?> matchSubject = const Value.absent(),
              }) => OverridesCompanion(
                id: id,
                date: date,
                pair: pair,
                type: type,
                subject: subject,
                room: room,
                teacher: teacher,
                note: note,
                kind: kind,
                repeatWeekly: repeatWeekly,
                matchSubject: matchSubject,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required DateTime date,
                required int pair,
                required String type,
                Value<String?> subject = const Value.absent(),
                Value<String?> room = const Value.absent(),
                Value<String?> teacher = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<String?> kind = const Value.absent(),
                Value<bool> repeatWeekly = const Value.absent(),
                Value<String?> matchSubject = const Value.absent(),
              }) => OverridesCompanion.insert(
                id: id,
                date: date,
                pair: pair,
                type: type,
                subject: subject,
                room: room,
                teacher: teacher,
                note: note,
                kind: kind,
                repeatWeekly: repeatWeekly,
                matchSubject: matchSubject,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$OverridesTable, OverrideRow>(table),
                  BaseReferences<_$AppDatabase, $OverridesTable, OverrideRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$OverridesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $OverridesTable,
      OverrideRow,
      $$OverridesTableFilterComposer,
      $$OverridesTableOrderingComposer,
      $$OverridesTableAnnotationComposer,
      $$OverridesTableCreateCompanionBuilder,
      $$OverridesTableUpdateCompanionBuilder,
      (
        OverrideRow,
        BaseReferences<_$AppDatabase, $OverridesTable, OverrideRow>,
      ),
      OverrideRow,
      PrefetchHooks Function()
    >;
typedef $$SubjectAliasesTableCreateCompanionBuilder =
    SubjectAliasesCompanion Function({
      required String subject,
      required String shortName,
      Value<int?> colorIndex,
      Value<int> rowid,
    });
typedef $$SubjectAliasesTableUpdateCompanionBuilder =
    SubjectAliasesCompanion Function({
      Value<String> subject,
      Value<String> shortName,
      Value<int?> colorIndex,
      Value<int> rowid,
    });

class $$SubjectAliasesTableFilterComposer
    extends Composer<_$AppDatabase, $SubjectAliasesTable> {
  $$SubjectAliasesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get subject => $composableBuilder(
    column: $table.subject,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get shortName => $composableBuilder(
    column: $table.shortName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get colorIndex => $composableBuilder(
    column: $table.colorIndex,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SubjectAliasesTableOrderingComposer
    extends Composer<_$AppDatabase, $SubjectAliasesTable> {
  $$SubjectAliasesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get subject => $composableBuilder(
    column: $table.subject,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get shortName => $composableBuilder(
    column: $table.shortName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get colorIndex => $composableBuilder(
    column: $table.colorIndex,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SubjectAliasesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SubjectAliasesTable> {
  $$SubjectAliasesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get subject =>
      $composableBuilder(column: $table.subject, builder: (column) => column);

  GeneratedColumn<String> get shortName =>
      $composableBuilder(column: $table.shortName, builder: (column) => column);

  GeneratedColumn<int> get colorIndex => $composableBuilder(
    column: $table.colorIndex,
    builder: (column) => column,
  );
}

class $$SubjectAliasesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SubjectAliasesTable,
          SubjectAliasRow,
          $$SubjectAliasesTableFilterComposer,
          $$SubjectAliasesTableOrderingComposer,
          $$SubjectAliasesTableAnnotationComposer,
          $$SubjectAliasesTableCreateCompanionBuilder,
          $$SubjectAliasesTableUpdateCompanionBuilder,
          (
            SubjectAliasRow,
            BaseReferences<
              _$AppDatabase,
              $SubjectAliasesTable,
              SubjectAliasRow
            >,
          ),
          SubjectAliasRow,
          PrefetchHooks Function()
        > {
  $$SubjectAliasesTableTableManager(
    _$AppDatabase db,
    $SubjectAliasesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SubjectAliasesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SubjectAliasesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SubjectAliasesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> subject = const Value.absent(),
                Value<String> shortName = const Value.absent(),
                Value<int?> colorIndex = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SubjectAliasesCompanion(
                subject: subject,
                shortName: shortName,
                colorIndex: colorIndex,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String subject,
                required String shortName,
                Value<int?> colorIndex = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SubjectAliasesCompanion.insert(
                subject: subject,
                shortName: shortName,
                colorIndex: colorIndex,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SubjectAliasesTable, SubjectAliasRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $SubjectAliasesTable,
                    SubjectAliasRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SubjectAliasesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SubjectAliasesTable,
      SubjectAliasRow,
      $$SubjectAliasesTableFilterComposer,
      $$SubjectAliasesTableOrderingComposer,
      $$SubjectAliasesTableAnnotationComposer,
      $$SubjectAliasesTableCreateCompanionBuilder,
      $$SubjectAliasesTableUpdateCompanionBuilder,
      (
        SubjectAliasRow,
        BaseReferences<_$AppDatabase, $SubjectAliasesTable, SubjectAliasRow>,
      ),
      SubjectAliasRow,
      PrefetchHooks Function()
    >;
typedef $$NotesTableCreateCompanionBuilder = NotesCompanion Function({
  Value<int> id,
  required String subject,
  required String content,
});
typedef $$NotesTableUpdateCompanionBuilder = NotesCompanion Function({
  Value<int> id,
  Value<String> subject,
  Value<String> content,
});

class $$NotesTableFilterComposer extends Composer<_$AppDatabase, $NotesTable> {
  $$NotesTableFilterComposer({
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

  ColumnFilters<String> get subject => $composableBuilder(
    column: $table.subject,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );
}

class $$NotesTableOrderingComposer
    extends Composer<_$AppDatabase, $NotesTable> {
  $$NotesTableOrderingComposer({
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

  ColumnOrderings<String> get subject => $composableBuilder(
    column: $table.subject,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$NotesTableAnnotationComposer
    extends Composer<_$AppDatabase, $NotesTable> {
  $$NotesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get subject =>
      $composableBuilder(column: $table.subject, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);
}

class $$NotesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $NotesTable,
          NoteRow,
          $$NotesTableFilterComposer,
          $$NotesTableOrderingComposer,
          $$NotesTableAnnotationComposer,
          $$NotesTableCreateCompanionBuilder,
          $$NotesTableUpdateCompanionBuilder,
          (NoteRow, BaseReferences<_$AppDatabase, $NotesTable, NoteRow>),
          NoteRow,
          PrefetchHooks Function()
        > {
  $$NotesTableTableManager(_$AppDatabase db, $NotesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NotesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$NotesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$NotesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> subject = const Value.absent(),
            Value<String> content = const Value.absent(),
          }) => NotesCompanion(id: id, subject: subject, content: content),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String subject,
                required String content,
              }) => NotesCompanion.insert(
                id: id,
                subject: subject,
                content: content,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$NotesTable, NoteRow>(table),
                  BaseReferences<_$AppDatabase, $NotesTable, NoteRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$NotesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $NotesTable,
      NoteRow,
      $$NotesTableFilterComposer,
      $$NotesTableOrderingComposer,
      $$NotesTableAnnotationComposer,
      $$NotesTableCreateCompanionBuilder,
      $$NotesTableUpdateCompanionBuilder,
      (NoteRow, BaseReferences<_$AppDatabase, $NotesTable, NoteRow>),
      NoteRow,
      PrefetchHooks Function()
    >;
typedef $$DeadlinesTableCreateCompanionBuilder = DeadlinesCompanion Function({
  Value<int> id,
  required String title,
  required DateTime date,
  required String kind,
  Value<String?> subject,
});
typedef $$DeadlinesTableUpdateCompanionBuilder = DeadlinesCompanion Function({
  Value<int> id,
  Value<String> title,
  Value<DateTime> date,
  Value<String> kind,
  Value<String?> subject,
});

class $$DeadlinesTableFilterComposer
    extends Composer<_$AppDatabase, $DeadlinesTable> {
  $$DeadlinesTableFilterComposer({
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

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get subject => $composableBuilder(
    column: $table.subject,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DeadlinesTableOrderingComposer
    extends Composer<_$AppDatabase, $DeadlinesTable> {
  $$DeadlinesTableOrderingComposer({
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

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subject => $composableBuilder(
    column: $table.subject,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DeadlinesTableAnnotationComposer
    extends Composer<_$AppDatabase, $DeadlinesTable> {
  $$DeadlinesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get subject =>
      $composableBuilder(column: $table.subject, builder: (column) => column);
}

class $$DeadlinesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DeadlinesTable,
          DeadlineRow,
          $$DeadlinesTableFilterComposer,
          $$DeadlinesTableOrderingComposer,
          $$DeadlinesTableAnnotationComposer,
          $$DeadlinesTableCreateCompanionBuilder,
          $$DeadlinesTableUpdateCompanionBuilder,
          (
            DeadlineRow,
            BaseReferences<_$AppDatabase, $DeadlinesTable, DeadlineRow>,
          ),
          DeadlineRow,
          PrefetchHooks Function()
        > {
  $$DeadlinesTableTableManager(_$AppDatabase db, $DeadlinesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DeadlinesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DeadlinesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DeadlinesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<DateTime> date = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String?> subject = const Value.absent(),
              }) => DeadlinesCompanion(
                id: id,
                title: title,
                date: date,
                kind: kind,
                subject: subject,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String title,
                required DateTime date,
                required String kind,
                Value<String?> subject = const Value.absent(),
              }) => DeadlinesCompanion.insert(
                id: id,
                title: title,
                date: date,
                kind: kind,
                subject: subject,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$DeadlinesTable, DeadlineRow>(table),
                  BaseReferences<_$AppDatabase, $DeadlinesTable, DeadlineRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DeadlinesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DeadlinesTable,
      DeadlineRow,
      $$DeadlinesTableFilterComposer,
      $$DeadlinesTableOrderingComposer,
      $$DeadlinesTableAnnotationComposer,
      $$DeadlinesTableCreateCompanionBuilder,
      $$DeadlinesTableUpdateCompanionBuilder,
      (
        DeadlineRow,
        BaseReferences<_$AppDatabase, $DeadlinesTable, DeadlineRow>,
      ),
      DeadlineRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ScheduleCacheTableTableManager get scheduleCache =>
      $$ScheduleCacheTableTableManager(_db, _db.scheduleCache);
  $$IndexCacheTableTableManager get indexCache =>
      $$IndexCacheTableTableManager(_db, _db.indexCache);
  $$HomeworkTableTableManager get homework =>
      $$HomeworkTableTableManager(_db, _db.homework);
  $$HomeworkAttachmentsTableTableManager get homeworkAttachments =>
      $$HomeworkAttachmentsTableTableManager(_db, _db.homeworkAttachments);
  $$AttachmentBlobsTableTableManager get attachmentBlobs =>
      $$AttachmentBlobsTableTableManager(_db, _db.attachmentBlobs);
  $$GroupSharedCacheTableTableManager get groupSharedCache =>
      $$GroupSharedCacheTableTableManager(_db, _db.groupSharedCache);
  $$OverridesTableTableManager get overrides =>
      $$OverridesTableTableManager(_db, _db.overrides);
  $$SubjectAliasesTableTableManager get subjectAliases =>
      $$SubjectAliasesTableTableManager(_db, _db.subjectAliases);
  $$NotesTableTableManager get notes =>
      $$NotesTableTableManager(_db, _db.notes);
  $$DeadlinesTableTableManager get deadlines =>
      $$DeadlinesTableTableManager(_db, _db.deadlines);
}
