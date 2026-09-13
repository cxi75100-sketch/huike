// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $SchoolsTable extends Schools with TableInfo<$SchoolsTable, School> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SchoolsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _displayNameMeta = const VerificationMeta(
    'displayName',
  );
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
    'display_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _adapterIdMeta = const VerificationMeta(
    'adapterId',
  );
  @override
  late final GeneratedColumn<String> adapterId = GeneratedColumn<String>(
    'adapter_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _presetIdMeta = const VerificationMeta(
    'presetId',
  );
  @override
  late final GeneratedColumn<String> presetId = GeneratedColumn<String>(
    'preset_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _loginUrlMeta = const VerificationMeta(
    'loginUrl',
  );
  @override
  late final GeneratedColumn<String> loginUrl = GeneratedColumn<String>(
    'login_url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _acceptedHostsJsonMeta = const VerificationMeta(
    'acceptedHostsJson',
  );
  @override
  late final GeneratedColumn<String> acceptedHostsJson =
      GeneratedColumn<String>(
        'accepted_hosts_json',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('[]'),
      );
  static const VerificationMeta _scheduleVariantsJsonMeta =
      const VerificationMeta('scheduleVariantsJson');
  @override
  late final GeneratedColumn<String> scheduleVariantsJson =
      GeneratedColumn<String>(
        'schedule_variants_json',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('[]'),
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
  @override
  List<GeneratedColumn> get $columns => [
    id,
    displayName,
    adapterId,
    presetId,
    loginUrl,
    acceptedHostsJson,
    scheduleVariantsJson,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'schools';
  @override
  VerificationContext validateIntegrity(
    Insertable<School> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
        _displayNameMeta,
        displayName.isAcceptableOrUnknown(
          data['display_name']!,
          _displayNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_displayNameMeta);
    }
    if (data.containsKey('adapter_id')) {
      context.handle(
        _adapterIdMeta,
        adapterId.isAcceptableOrUnknown(data['adapter_id']!, _adapterIdMeta),
      );
    }
    if (data.containsKey('preset_id')) {
      context.handle(
        _presetIdMeta,
        presetId.isAcceptableOrUnknown(data['preset_id']!, _presetIdMeta),
      );
    }
    if (data.containsKey('login_url')) {
      context.handle(
        _loginUrlMeta,
        loginUrl.isAcceptableOrUnknown(data['login_url']!, _loginUrlMeta),
      );
    }
    if (data.containsKey('accepted_hosts_json')) {
      context.handle(
        _acceptedHostsJsonMeta,
        acceptedHostsJson.isAcceptableOrUnknown(
          data['accepted_hosts_json']!,
          _acceptedHostsJsonMeta,
        ),
      );
    }
    if (data.containsKey('schedule_variants_json')) {
      context.handle(
        _scheduleVariantsJsonMeta,
        scheduleVariantsJson.isAcceptableOrUnknown(
          data['schedule_variants_json']!,
          _scheduleVariantsJsonMeta,
        ),
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
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  School map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return School(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      )!,
      adapterId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}adapter_id'],
      )!,
      presetId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}preset_id'],
      )!,
      loginUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}login_url'],
      )!,
      acceptedHostsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}accepted_hosts_json'],
      )!,
      scheduleVariantsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}schedule_variants_json'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $SchoolsTable createAlias(String alias) {
    return $SchoolsTable(attachedDatabase, alias);
  }
}

class School extends DataClass implements Insertable<School> {
  final String id;
  final String displayName;
  final String adapterId;

  /// 内置学校档案 id（如南工）；空串表示走通用兜底作息。
  final String presetId;
  final String loginUrl;
  final String acceptedHostsJson;

  /// 按教室匹配的作息变体（ScheduleVariant 列表 JSON）。
  final String scheduleVariantsJson;
  final DateTime createdAt;
  const School({
    required this.id,
    required this.displayName,
    required this.adapterId,
    required this.presetId,
    required this.loginUrl,
    required this.acceptedHostsJson,
    required this.scheduleVariantsJson,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['display_name'] = Variable<String>(displayName);
    map['adapter_id'] = Variable<String>(adapterId);
    map['preset_id'] = Variable<String>(presetId);
    map['login_url'] = Variable<String>(loginUrl);
    map['accepted_hosts_json'] = Variable<String>(acceptedHostsJson);
    map['schedule_variants_json'] = Variable<String>(scheduleVariantsJson);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  SchoolsCompanion toCompanion(bool nullToAbsent) {
    return SchoolsCompanion(
      id: Value(id),
      displayName: Value(displayName),
      adapterId: Value(adapterId),
      presetId: Value(presetId),
      loginUrl: Value(loginUrl),
      acceptedHostsJson: Value(acceptedHostsJson),
      scheduleVariantsJson: Value(scheduleVariantsJson),
      createdAt: Value(createdAt),
    );
  }

  factory School.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return School(
      id: serializer.fromJson<String>(json['id']),
      displayName: serializer.fromJson<String>(json['displayName']),
      adapterId: serializer.fromJson<String>(json['adapterId']),
      presetId: serializer.fromJson<String>(json['presetId']),
      loginUrl: serializer.fromJson<String>(json['loginUrl']),
      acceptedHostsJson: serializer.fromJson<String>(json['acceptedHostsJson']),
      scheduleVariantsJson: serializer.fromJson<String>(
        json['scheduleVariantsJson'],
      ),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'displayName': serializer.toJson<String>(displayName),
      'adapterId': serializer.toJson<String>(adapterId),
      'presetId': serializer.toJson<String>(presetId),
      'loginUrl': serializer.toJson<String>(loginUrl),
      'acceptedHostsJson': serializer.toJson<String>(acceptedHostsJson),
      'scheduleVariantsJson': serializer.toJson<String>(scheduleVariantsJson),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  School copyWith({
    String? id,
    String? displayName,
    String? adapterId,
    String? presetId,
    String? loginUrl,
    String? acceptedHostsJson,
    String? scheduleVariantsJson,
    DateTime? createdAt,
  }) => School(
    id: id ?? this.id,
    displayName: displayName ?? this.displayName,
    adapterId: adapterId ?? this.adapterId,
    presetId: presetId ?? this.presetId,
    loginUrl: loginUrl ?? this.loginUrl,
    acceptedHostsJson: acceptedHostsJson ?? this.acceptedHostsJson,
    scheduleVariantsJson: scheduleVariantsJson ?? this.scheduleVariantsJson,
    createdAt: createdAt ?? this.createdAt,
  );
  School copyWithCompanion(SchoolsCompanion data) {
    return School(
      id: data.id.present ? data.id.value : this.id,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
      adapterId: data.adapterId.present ? data.adapterId.value : this.adapterId,
      presetId: data.presetId.present ? data.presetId.value : this.presetId,
      loginUrl: data.loginUrl.present ? data.loginUrl.value : this.loginUrl,
      acceptedHostsJson: data.acceptedHostsJson.present
          ? data.acceptedHostsJson.value
          : this.acceptedHostsJson,
      scheduleVariantsJson: data.scheduleVariantsJson.present
          ? data.scheduleVariantsJson.value
          : this.scheduleVariantsJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('School(')
          ..write('id: $id, ')
          ..write('displayName: $displayName, ')
          ..write('adapterId: $adapterId, ')
          ..write('presetId: $presetId, ')
          ..write('loginUrl: $loginUrl, ')
          ..write('acceptedHostsJson: $acceptedHostsJson, ')
          ..write('scheduleVariantsJson: $scheduleVariantsJson, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    displayName,
    adapterId,
    presetId,
    loginUrl,
    acceptedHostsJson,
    scheduleVariantsJson,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is School &&
          other.id == this.id &&
          other.displayName == this.displayName &&
          other.adapterId == this.adapterId &&
          other.presetId == this.presetId &&
          other.loginUrl == this.loginUrl &&
          other.acceptedHostsJson == this.acceptedHostsJson &&
          other.scheduleVariantsJson == this.scheduleVariantsJson &&
          other.createdAt == this.createdAt);
}

class SchoolsCompanion extends UpdateCompanion<School> {
  final Value<String> id;
  final Value<String> displayName;
  final Value<String> adapterId;
  final Value<String> presetId;
  final Value<String> loginUrl;
  final Value<String> acceptedHostsJson;
  final Value<String> scheduleVariantsJson;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const SchoolsCompanion({
    this.id = const Value.absent(),
    this.displayName = const Value.absent(),
    this.adapterId = const Value.absent(),
    this.presetId = const Value.absent(),
    this.loginUrl = const Value.absent(),
    this.acceptedHostsJson = const Value.absent(),
    this.scheduleVariantsJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SchoolsCompanion.insert({
    required String id,
    required String displayName,
    this.adapterId = const Value.absent(),
    this.presetId = const Value.absent(),
    this.loginUrl = const Value.absent(),
    this.acceptedHostsJson = const Value.absent(),
    this.scheduleVariantsJson = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       displayName = Value(displayName),
       createdAt = Value(createdAt);
  static Insertable<School> custom({
    Expression<String>? id,
    Expression<String>? displayName,
    Expression<String>? adapterId,
    Expression<String>? presetId,
    Expression<String>? loginUrl,
    Expression<String>? acceptedHostsJson,
    Expression<String>? scheduleVariantsJson,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (displayName != null) 'display_name': displayName,
      if (adapterId != null) 'adapter_id': adapterId,
      if (presetId != null) 'preset_id': presetId,
      if (loginUrl != null) 'login_url': loginUrl,
      if (acceptedHostsJson != null) 'accepted_hosts_json': acceptedHostsJson,
      if (scheduleVariantsJson != null)
        'schedule_variants_json': scheduleVariantsJson,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SchoolsCompanion copyWith({
    Value<String>? id,
    Value<String>? displayName,
    Value<String>? adapterId,
    Value<String>? presetId,
    Value<String>? loginUrl,
    Value<String>? acceptedHostsJson,
    Value<String>? scheduleVariantsJson,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return SchoolsCompanion(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      adapterId: adapterId ?? this.adapterId,
      presetId: presetId ?? this.presetId,
      loginUrl: loginUrl ?? this.loginUrl,
      acceptedHostsJson: acceptedHostsJson ?? this.acceptedHostsJson,
      scheduleVariantsJson: scheduleVariantsJson ?? this.scheduleVariantsJson,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (adapterId.present) {
      map['adapter_id'] = Variable<String>(adapterId.value);
    }
    if (presetId.present) {
      map['preset_id'] = Variable<String>(presetId.value);
    }
    if (loginUrl.present) {
      map['login_url'] = Variable<String>(loginUrl.value);
    }
    if (acceptedHostsJson.present) {
      map['accepted_hosts_json'] = Variable<String>(acceptedHostsJson.value);
    }
    if (scheduleVariantsJson.present) {
      map['schedule_variants_json'] = Variable<String>(
        scheduleVariantsJson.value,
      );
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SchoolsCompanion(')
          ..write('id: $id, ')
          ..write('displayName: $displayName, ')
          ..write('adapterId: $adapterId, ')
          ..write('presetId: $presetId, ')
          ..write('loginUrl: $loginUrl, ')
          ..write('acceptedHostsJson: $acceptedHostsJson, ')
          ..write('scheduleVariantsJson: $scheduleVariantsJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SemestersTable extends Semesters
    with TableInfo<$SemestersTable, SemesterRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SemestersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _schoolIdMeta = const VerificationMeta(
    'schoolId',
  );
  @override
  late final GeneratedColumn<String> schoolId = GeneratedColumn<String>(
    'school_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _firstWeekMondayIsoMeta =
      const VerificationMeta('firstWeekMondayIso');
  @override
  late final GeneratedColumn<String> firstWeekMondayIso =
      GeneratedColumn<String>(
        'first_week_monday_iso',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _totalWeeksMeta = const VerificationMeta(
    'totalWeeks',
  );
  @override
  late final GeneratedColumn<int> totalWeeks = GeneratedColumn<int>(
    'total_weeks',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    schoolId,
    firstWeekMondayIso,
    totalWeeks,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'semesters';
  @override
  VerificationContext validateIntegrity(
    Insertable<SemesterRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('school_id')) {
      context.handle(
        _schoolIdMeta,
        schoolId.isAcceptableOrUnknown(data['school_id']!, _schoolIdMeta),
      );
    } else if (isInserting) {
      context.missing(_schoolIdMeta);
    }
    if (data.containsKey('first_week_monday_iso')) {
      context.handle(
        _firstWeekMondayIsoMeta,
        firstWeekMondayIso.isAcceptableOrUnknown(
          data['first_week_monday_iso']!,
          _firstWeekMondayIsoMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_firstWeekMondayIsoMeta);
    }
    if (data.containsKey('total_weeks')) {
      context.handle(
        _totalWeeksMeta,
        totalWeeks.isAcceptableOrUnknown(data['total_weeks']!, _totalWeeksMeta),
      );
    } else if (isInserting) {
      context.missing(_totalWeeksMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SemesterRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SemesterRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      schoolId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}school_id'],
      )!,
      firstWeekMondayIso: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}first_week_monday_iso'],
      )!,
      totalWeeks: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_weeks'],
      )!,
    );
  }

  @override
  $SemestersTable createAlias(String alias) {
    return $SemestersTable(attachedDatabase, alias);
  }
}

class SemesterRow extends DataClass implements Insertable<SemesterRow> {
  final String id;
  final String schoolId;
  final String firstWeekMondayIso;
  final int totalWeeks;
  const SemesterRow({
    required this.id,
    required this.schoolId,
    required this.firstWeekMondayIso,
    required this.totalWeeks,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['school_id'] = Variable<String>(schoolId);
    map['first_week_monday_iso'] = Variable<String>(firstWeekMondayIso);
    map['total_weeks'] = Variable<int>(totalWeeks);
    return map;
  }

  SemestersCompanion toCompanion(bool nullToAbsent) {
    return SemestersCompanion(
      id: Value(id),
      schoolId: Value(schoolId),
      firstWeekMondayIso: Value(firstWeekMondayIso),
      totalWeeks: Value(totalWeeks),
    );
  }

  factory SemesterRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SemesterRow(
      id: serializer.fromJson<String>(json['id']),
      schoolId: serializer.fromJson<String>(json['schoolId']),
      firstWeekMondayIso: serializer.fromJson<String>(
        json['firstWeekMondayIso'],
      ),
      totalWeeks: serializer.fromJson<int>(json['totalWeeks']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'schoolId': serializer.toJson<String>(schoolId),
      'firstWeekMondayIso': serializer.toJson<String>(firstWeekMondayIso),
      'totalWeeks': serializer.toJson<int>(totalWeeks),
    };
  }

  SemesterRow copyWith({
    String? id,
    String? schoolId,
    String? firstWeekMondayIso,
    int? totalWeeks,
  }) => SemesterRow(
    id: id ?? this.id,
    schoolId: schoolId ?? this.schoolId,
    firstWeekMondayIso: firstWeekMondayIso ?? this.firstWeekMondayIso,
    totalWeeks: totalWeeks ?? this.totalWeeks,
  );
  SemesterRow copyWithCompanion(SemestersCompanion data) {
    return SemesterRow(
      id: data.id.present ? data.id.value : this.id,
      schoolId: data.schoolId.present ? data.schoolId.value : this.schoolId,
      firstWeekMondayIso: data.firstWeekMondayIso.present
          ? data.firstWeekMondayIso.value
          : this.firstWeekMondayIso,
      totalWeeks: data.totalWeeks.present
          ? data.totalWeeks.value
          : this.totalWeeks,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SemesterRow(')
          ..write('id: $id, ')
          ..write('schoolId: $schoolId, ')
          ..write('firstWeekMondayIso: $firstWeekMondayIso, ')
          ..write('totalWeeks: $totalWeeks')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, schoolId, firstWeekMondayIso, totalWeeks);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SemesterRow &&
          other.id == this.id &&
          other.schoolId == this.schoolId &&
          other.firstWeekMondayIso == this.firstWeekMondayIso &&
          other.totalWeeks == this.totalWeeks);
}

class SemestersCompanion extends UpdateCompanion<SemesterRow> {
  final Value<String> id;
  final Value<String> schoolId;
  final Value<String> firstWeekMondayIso;
  final Value<int> totalWeeks;
  final Value<int> rowid;
  const SemestersCompanion({
    this.id = const Value.absent(),
    this.schoolId = const Value.absent(),
    this.firstWeekMondayIso = const Value.absent(),
    this.totalWeeks = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SemestersCompanion.insert({
    required String id,
    required String schoolId,
    required String firstWeekMondayIso,
    required int totalWeeks,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       schoolId = Value(schoolId),
       firstWeekMondayIso = Value(firstWeekMondayIso),
       totalWeeks = Value(totalWeeks);
  static Insertable<SemesterRow> custom({
    Expression<String>? id,
    Expression<String>? schoolId,
    Expression<String>? firstWeekMondayIso,
    Expression<int>? totalWeeks,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (schoolId != null) 'school_id': schoolId,
      if (firstWeekMondayIso != null)
        'first_week_monday_iso': firstWeekMondayIso,
      if (totalWeeks != null) 'total_weeks': totalWeeks,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SemestersCompanion copyWith({
    Value<String>? id,
    Value<String>? schoolId,
    Value<String>? firstWeekMondayIso,
    Value<int>? totalWeeks,
    Value<int>? rowid,
  }) {
    return SemestersCompanion(
      id: id ?? this.id,
      schoolId: schoolId ?? this.schoolId,
      firstWeekMondayIso: firstWeekMondayIso ?? this.firstWeekMondayIso,
      totalWeeks: totalWeeks ?? this.totalWeeks,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (schoolId.present) {
      map['school_id'] = Variable<String>(schoolId.value);
    }
    if (firstWeekMondayIso.present) {
      map['first_week_monday_iso'] = Variable<String>(firstWeekMondayIso.value);
    }
    if (totalWeeks.present) {
      map['total_weeks'] = Variable<int>(totalWeeks.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SemestersCompanion(')
          ..write('id: $id, ')
          ..write('schoolId: $schoolId, ')
          ..write('firstWeekMondayIso: $firstWeekMondayIso, ')
          ..write('totalWeeks: $totalWeeks, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CourseEntriesTable extends CourseEntries
    with TableInfo<$CourseEntriesTable, CourseEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CourseEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _schoolIdMeta = const VerificationMeta(
    'schoolId',
  );
  @override
  late final GeneratedColumn<String> schoolId = GeneratedColumn<String>(
    'school_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _semesterIdMeta = const VerificationMeta(
    'semesterId',
  );
  @override
  late final GeneratedColumn<String> semesterId = GeneratedColumn<String>(
    'semester_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<CourseSource, String> source =
      GeneratedColumn<String>(
        'source',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<CourseSource>($CourseEntriesTable.$convertersource);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _teacherMeta = const VerificationMeta(
    'teacher',
  );
  @override
  late final GeneratedColumn<String> teacher = GeneratedColumn<String>(
    'teacher',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _classroomMeta = const VerificationMeta(
    'classroom',
  );
  @override
  late final GeneratedColumn<String> classroom = GeneratedColumn<String>(
    'classroom',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _weekdayMeta = const VerificationMeta(
    'weekday',
  );
  @override
  late final GeneratedColumn<int> weekday = GeneratedColumn<int>(
    'weekday',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startSectionMeta = const VerificationMeta(
    'startSection',
  );
  @override
  late final GeneratedColumn<int> startSection = GeneratedColumn<int>(
    'start_section',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endSectionMeta = const VerificationMeta(
    'endSection',
  );
  @override
  late final GeneratedColumn<int> endSection = GeneratedColumn<int>(
    'end_section',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _weeksJsonMeta = const VerificationMeta(
    'weeksJson',
  );
  @override
  late final GeneratedColumn<String> weeksJson = GeneratedColumn<String>(
    'weeks_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startTimeMeta = const VerificationMeta(
    'startTime',
  );
  @override
  late final GeneratedColumn<String> startTime = GeneratedColumn<String>(
    'start_time',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _endTimeMeta = const VerificationMeta(
    'endTime',
  );
  @override
  late final GeneratedColumn<String> endTime = GeneratedColumn<String>(
    'end_time',
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
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _colorKeyMeta = const VerificationMeta(
    'colorKey',
  );
  @override
  late final GeneratedColumn<int> colorKey = GeneratedColumn<int>(
    'color_key',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    schoolId,
    semesterId,
    source,
    name,
    teacher,
    classroom,
    weekday,
    startSection,
    endSection,
    weeksJson,
    startTime,
    endTime,
    note,
    colorKey,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'course_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<CourseEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('school_id')) {
      context.handle(
        _schoolIdMeta,
        schoolId.isAcceptableOrUnknown(data['school_id']!, _schoolIdMeta),
      );
    } else if (isInserting) {
      context.missing(_schoolIdMeta);
    }
    if (data.containsKey('semester_id')) {
      context.handle(
        _semesterIdMeta,
        semesterId.isAcceptableOrUnknown(data['semester_id']!, _semesterIdMeta),
      );
    } else if (isInserting) {
      context.missing(_semesterIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('teacher')) {
      context.handle(
        _teacherMeta,
        teacher.isAcceptableOrUnknown(data['teacher']!, _teacherMeta),
      );
    }
    if (data.containsKey('classroom')) {
      context.handle(
        _classroomMeta,
        classroom.isAcceptableOrUnknown(data['classroom']!, _classroomMeta),
      );
    }
    if (data.containsKey('weekday')) {
      context.handle(
        _weekdayMeta,
        weekday.isAcceptableOrUnknown(data['weekday']!, _weekdayMeta),
      );
    } else if (isInserting) {
      context.missing(_weekdayMeta);
    }
    if (data.containsKey('start_section')) {
      context.handle(
        _startSectionMeta,
        startSection.isAcceptableOrUnknown(
          data['start_section']!,
          _startSectionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_startSectionMeta);
    }
    if (data.containsKey('end_section')) {
      context.handle(
        _endSectionMeta,
        endSection.isAcceptableOrUnknown(data['end_section']!, _endSectionMeta),
      );
    } else if (isInserting) {
      context.missing(_endSectionMeta);
    }
    if (data.containsKey('weeks_json')) {
      context.handle(
        _weeksJsonMeta,
        weeksJson.isAcceptableOrUnknown(data['weeks_json']!, _weeksJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_weeksJsonMeta);
    }
    if (data.containsKey('start_time')) {
      context.handle(
        _startTimeMeta,
        startTime.isAcceptableOrUnknown(data['start_time']!, _startTimeMeta),
      );
    }
    if (data.containsKey('end_time')) {
      context.handle(
        _endTimeMeta,
        endTime.isAcceptableOrUnknown(data['end_time']!, _endTimeMeta),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('color_key')) {
      context.handle(
        _colorKeyMeta,
        colorKey.isAcceptableOrUnknown(data['color_key']!, _colorKeyMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CourseEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CourseEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      schoolId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}school_id'],
      )!,
      semesterId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}semester_id'],
      )!,
      source: $CourseEntriesTable.$convertersource.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}source'],
        )!,
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      teacher: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}teacher'],
      )!,
      classroom: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}classroom'],
      )!,
      weekday: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}weekday'],
      )!,
      startSection: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}start_section'],
      )!,
      endSection: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}end_section'],
      )!,
      weeksJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}weeks_json'],
      )!,
      startTime: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}start_time'],
      ),
      endTime: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}end_time'],
      ),
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      )!,
      colorKey: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}color_key'],
      )!,
    );
  }

  @override
  $CourseEntriesTable createAlias(String alias) {
    return $CourseEntriesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<CourseSource, String, String> $convertersource =
      const EnumNameConverter<CourseSource>(CourseSource.values);
}

class CourseEntry extends DataClass implements Insertable<CourseEntry> {
  final String id;
  final String schoolId;
  final String semesterId;
  final CourseSource source;
  final String name;
  final String teacher;
  final String classroom;
  final int weekday;
  final int startSection;
  final int endSection;
  final String weeksJson;
  final String? startTime;
  final String? endTime;
  final String note;
  final int colorKey;
  const CourseEntry({
    required this.id,
    required this.schoolId,
    required this.semesterId,
    required this.source,
    required this.name,
    required this.teacher,
    required this.classroom,
    required this.weekday,
    required this.startSection,
    required this.endSection,
    required this.weeksJson,
    this.startTime,
    this.endTime,
    required this.note,
    required this.colorKey,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['school_id'] = Variable<String>(schoolId);
    map['semester_id'] = Variable<String>(semesterId);
    {
      map['source'] = Variable<String>(
        $CourseEntriesTable.$convertersource.toSql(source),
      );
    }
    map['name'] = Variable<String>(name);
    map['teacher'] = Variable<String>(teacher);
    map['classroom'] = Variable<String>(classroom);
    map['weekday'] = Variable<int>(weekday);
    map['start_section'] = Variable<int>(startSection);
    map['end_section'] = Variable<int>(endSection);
    map['weeks_json'] = Variable<String>(weeksJson);
    if (!nullToAbsent || startTime != null) {
      map['start_time'] = Variable<String>(startTime);
    }
    if (!nullToAbsent || endTime != null) {
      map['end_time'] = Variable<String>(endTime);
    }
    map['note'] = Variable<String>(note);
    map['color_key'] = Variable<int>(colorKey);
    return map;
  }

  CourseEntriesCompanion toCompanion(bool nullToAbsent) {
    return CourseEntriesCompanion(
      id: Value(id),
      schoolId: Value(schoolId),
      semesterId: Value(semesterId),
      source: Value(source),
      name: Value(name),
      teacher: Value(teacher),
      classroom: Value(classroom),
      weekday: Value(weekday),
      startSection: Value(startSection),
      endSection: Value(endSection),
      weeksJson: Value(weeksJson),
      startTime: startTime == null && nullToAbsent
          ? const Value.absent()
          : Value(startTime),
      endTime: endTime == null && nullToAbsent
          ? const Value.absent()
          : Value(endTime),
      note: Value(note),
      colorKey: Value(colorKey),
    );
  }

  factory CourseEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CourseEntry(
      id: serializer.fromJson<String>(json['id']),
      schoolId: serializer.fromJson<String>(json['schoolId']),
      semesterId: serializer.fromJson<String>(json['semesterId']),
      source: $CourseEntriesTable.$convertersource.fromJson(
        serializer.fromJson<String>(json['source']),
      ),
      name: serializer.fromJson<String>(json['name']),
      teacher: serializer.fromJson<String>(json['teacher']),
      classroom: serializer.fromJson<String>(json['classroom']),
      weekday: serializer.fromJson<int>(json['weekday']),
      startSection: serializer.fromJson<int>(json['startSection']),
      endSection: serializer.fromJson<int>(json['endSection']),
      weeksJson: serializer.fromJson<String>(json['weeksJson']),
      startTime: serializer.fromJson<String?>(json['startTime']),
      endTime: serializer.fromJson<String?>(json['endTime']),
      note: serializer.fromJson<String>(json['note']),
      colorKey: serializer.fromJson<int>(json['colorKey']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'schoolId': serializer.toJson<String>(schoolId),
      'semesterId': serializer.toJson<String>(semesterId),
      'source': serializer.toJson<String>(
        $CourseEntriesTable.$convertersource.toJson(source),
      ),
      'name': serializer.toJson<String>(name),
      'teacher': serializer.toJson<String>(teacher),
      'classroom': serializer.toJson<String>(classroom),
      'weekday': serializer.toJson<int>(weekday),
      'startSection': serializer.toJson<int>(startSection),
      'endSection': serializer.toJson<int>(endSection),
      'weeksJson': serializer.toJson<String>(weeksJson),
      'startTime': serializer.toJson<String?>(startTime),
      'endTime': serializer.toJson<String?>(endTime),
      'note': serializer.toJson<String>(note),
      'colorKey': serializer.toJson<int>(colorKey),
    };
  }

  CourseEntry copyWith({
    String? id,
    String? schoolId,
    String? semesterId,
    CourseSource? source,
    String? name,
    String? teacher,
    String? classroom,
    int? weekday,
    int? startSection,
    int? endSection,
    String? weeksJson,
    Value<String?> startTime = const Value.absent(),
    Value<String?> endTime = const Value.absent(),
    String? note,
    int? colorKey,
  }) => CourseEntry(
    id: id ?? this.id,
    schoolId: schoolId ?? this.schoolId,
    semesterId: semesterId ?? this.semesterId,
    source: source ?? this.source,
    name: name ?? this.name,
    teacher: teacher ?? this.teacher,
    classroom: classroom ?? this.classroom,
    weekday: weekday ?? this.weekday,
    startSection: startSection ?? this.startSection,
    endSection: endSection ?? this.endSection,
    weeksJson: weeksJson ?? this.weeksJson,
    startTime: startTime.present ? startTime.value : this.startTime,
    endTime: endTime.present ? endTime.value : this.endTime,
    note: note ?? this.note,
    colorKey: colorKey ?? this.colorKey,
  );
  CourseEntry copyWithCompanion(CourseEntriesCompanion data) {
    return CourseEntry(
      id: data.id.present ? data.id.value : this.id,
      schoolId: data.schoolId.present ? data.schoolId.value : this.schoolId,
      semesterId: data.semesterId.present
          ? data.semesterId.value
          : this.semesterId,
      source: data.source.present ? data.source.value : this.source,
      name: data.name.present ? data.name.value : this.name,
      teacher: data.teacher.present ? data.teacher.value : this.teacher,
      classroom: data.classroom.present ? data.classroom.value : this.classroom,
      weekday: data.weekday.present ? data.weekday.value : this.weekday,
      startSection: data.startSection.present
          ? data.startSection.value
          : this.startSection,
      endSection: data.endSection.present
          ? data.endSection.value
          : this.endSection,
      weeksJson: data.weeksJson.present ? data.weeksJson.value : this.weeksJson,
      startTime: data.startTime.present ? data.startTime.value : this.startTime,
      endTime: data.endTime.present ? data.endTime.value : this.endTime,
      note: data.note.present ? data.note.value : this.note,
      colorKey: data.colorKey.present ? data.colorKey.value : this.colorKey,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CourseEntry(')
          ..write('id: $id, ')
          ..write('schoolId: $schoolId, ')
          ..write('semesterId: $semesterId, ')
          ..write('source: $source, ')
          ..write('name: $name, ')
          ..write('teacher: $teacher, ')
          ..write('classroom: $classroom, ')
          ..write('weekday: $weekday, ')
          ..write('startSection: $startSection, ')
          ..write('endSection: $endSection, ')
          ..write('weeksJson: $weeksJson, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('note: $note, ')
          ..write('colorKey: $colorKey')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    schoolId,
    semesterId,
    source,
    name,
    teacher,
    classroom,
    weekday,
    startSection,
    endSection,
    weeksJson,
    startTime,
    endTime,
    note,
    colorKey,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CourseEntry &&
          other.id == this.id &&
          other.schoolId == this.schoolId &&
          other.semesterId == this.semesterId &&
          other.source == this.source &&
          other.name == this.name &&
          other.teacher == this.teacher &&
          other.classroom == this.classroom &&
          other.weekday == this.weekday &&
          other.startSection == this.startSection &&
          other.endSection == this.endSection &&
          other.weeksJson == this.weeksJson &&
          other.startTime == this.startTime &&
          other.endTime == this.endTime &&
          other.note == this.note &&
          other.colorKey == this.colorKey);
}

class CourseEntriesCompanion extends UpdateCompanion<CourseEntry> {
  final Value<String> id;
  final Value<String> schoolId;
  final Value<String> semesterId;
  final Value<CourseSource> source;
  final Value<String> name;
  final Value<String> teacher;
  final Value<String> classroom;
  final Value<int> weekday;
  final Value<int> startSection;
  final Value<int> endSection;
  final Value<String> weeksJson;
  final Value<String?> startTime;
  final Value<String?> endTime;
  final Value<String> note;
  final Value<int> colorKey;
  final Value<int> rowid;
  const CourseEntriesCompanion({
    this.id = const Value.absent(),
    this.schoolId = const Value.absent(),
    this.semesterId = const Value.absent(),
    this.source = const Value.absent(),
    this.name = const Value.absent(),
    this.teacher = const Value.absent(),
    this.classroom = const Value.absent(),
    this.weekday = const Value.absent(),
    this.startSection = const Value.absent(),
    this.endSection = const Value.absent(),
    this.weeksJson = const Value.absent(),
    this.startTime = const Value.absent(),
    this.endTime = const Value.absent(),
    this.note = const Value.absent(),
    this.colorKey = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CourseEntriesCompanion.insert({
    required String id,
    required String schoolId,
    required String semesterId,
    required CourseSource source,
    required String name,
    this.teacher = const Value.absent(),
    this.classroom = const Value.absent(),
    required int weekday,
    required int startSection,
    required int endSection,
    required String weeksJson,
    this.startTime = const Value.absent(),
    this.endTime = const Value.absent(),
    this.note = const Value.absent(),
    this.colorKey = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       schoolId = Value(schoolId),
       semesterId = Value(semesterId),
       source = Value(source),
       name = Value(name),
       weekday = Value(weekday),
       startSection = Value(startSection),
       endSection = Value(endSection),
       weeksJson = Value(weeksJson);
  static Insertable<CourseEntry> custom({
    Expression<String>? id,
    Expression<String>? schoolId,
    Expression<String>? semesterId,
    Expression<String>? source,
    Expression<String>? name,
    Expression<String>? teacher,
    Expression<String>? classroom,
    Expression<int>? weekday,
    Expression<int>? startSection,
    Expression<int>? endSection,
    Expression<String>? weeksJson,
    Expression<String>? startTime,
    Expression<String>? endTime,
    Expression<String>? note,
    Expression<int>? colorKey,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (schoolId != null) 'school_id': schoolId,
      if (semesterId != null) 'semester_id': semesterId,
      if (source != null) 'source': source,
      if (name != null) 'name': name,
      if (teacher != null) 'teacher': teacher,
      if (classroom != null) 'classroom': classroom,
      if (weekday != null) 'weekday': weekday,
      if (startSection != null) 'start_section': startSection,
      if (endSection != null) 'end_section': endSection,
      if (weeksJson != null) 'weeks_json': weeksJson,
      if (startTime != null) 'start_time': startTime,
      if (endTime != null) 'end_time': endTime,
      if (note != null) 'note': note,
      if (colorKey != null) 'color_key': colorKey,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CourseEntriesCompanion copyWith({
    Value<String>? id,
    Value<String>? schoolId,
    Value<String>? semesterId,
    Value<CourseSource>? source,
    Value<String>? name,
    Value<String>? teacher,
    Value<String>? classroom,
    Value<int>? weekday,
    Value<int>? startSection,
    Value<int>? endSection,
    Value<String>? weeksJson,
    Value<String?>? startTime,
    Value<String?>? endTime,
    Value<String>? note,
    Value<int>? colorKey,
    Value<int>? rowid,
  }) {
    return CourseEntriesCompanion(
      id: id ?? this.id,
      schoolId: schoolId ?? this.schoolId,
      semesterId: semesterId ?? this.semesterId,
      source: source ?? this.source,
      name: name ?? this.name,
      teacher: teacher ?? this.teacher,
      classroom: classroom ?? this.classroom,
      weekday: weekday ?? this.weekday,
      startSection: startSection ?? this.startSection,
      endSection: endSection ?? this.endSection,
      weeksJson: weeksJson ?? this.weeksJson,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      note: note ?? this.note,
      colorKey: colorKey ?? this.colorKey,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (schoolId.present) {
      map['school_id'] = Variable<String>(schoolId.value);
    }
    if (semesterId.present) {
      map['semester_id'] = Variable<String>(semesterId.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(
        $CourseEntriesTable.$convertersource.toSql(source.value),
      );
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (teacher.present) {
      map['teacher'] = Variable<String>(teacher.value);
    }
    if (classroom.present) {
      map['classroom'] = Variable<String>(classroom.value);
    }
    if (weekday.present) {
      map['weekday'] = Variable<int>(weekday.value);
    }
    if (startSection.present) {
      map['start_section'] = Variable<int>(startSection.value);
    }
    if (endSection.present) {
      map['end_section'] = Variable<int>(endSection.value);
    }
    if (weeksJson.present) {
      map['weeks_json'] = Variable<String>(weeksJson.value);
    }
    if (startTime.present) {
      map['start_time'] = Variable<String>(startTime.value);
    }
    if (endTime.present) {
      map['end_time'] = Variable<String>(endTime.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (colorKey.present) {
      map['color_key'] = Variable<int>(colorKey.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CourseEntriesCompanion(')
          ..write('id: $id, ')
          ..write('schoolId: $schoolId, ')
          ..write('semesterId: $semesterId, ')
          ..write('source: $source, ')
          ..write('name: $name, ')
          ..write('teacher: $teacher, ')
          ..write('classroom: $classroom, ')
          ..write('weekday: $weekday, ')
          ..write('startSection: $startSection, ')
          ..write('endSection: $endSection, ')
          ..write('weeksJson: $weeksJson, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('note: $note, ')
          ..write('colorKey: $colorKey, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SectionTimeEntriesTable extends SectionTimeEntries
    with TableInfo<$SectionTimeEntriesTable, SectionTimeEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SectionTimeEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _schoolIdMeta = const VerificationMeta(
    'schoolId',
  );
  @override
  late final GeneratedColumn<String> schoolId = GeneratedColumn<String>(
    'school_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sectionIndexMeta = const VerificationMeta(
    'sectionIndex',
  );
  @override
  late final GeneratedColumn<int> sectionIndex = GeneratedColumn<int>(
    'section_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startMeta = const VerificationMeta('start');
  @override
  late final GeneratedColumn<String> start = GeneratedColumn<String>(
    'start',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endMeta = const VerificationMeta('end');
  @override
  late final GeneratedColumn<String> end = GeneratedColumn<String>(
    'end',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<SectionGroup, String>
  periodGroup = GeneratedColumn<String>(
    'period_group',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<SectionGroup>($SectionTimeEntriesTable.$converterperiodGroup);
  @override
  List<GeneratedColumn> get $columns => [
    schoolId,
    sectionIndex,
    start,
    end,
    periodGroup,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'section_time_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<SectionTimeEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('school_id')) {
      context.handle(
        _schoolIdMeta,
        schoolId.isAcceptableOrUnknown(data['school_id']!, _schoolIdMeta),
      );
    } else if (isInserting) {
      context.missing(_schoolIdMeta);
    }
    if (data.containsKey('section_index')) {
      context.handle(
        _sectionIndexMeta,
        sectionIndex.isAcceptableOrUnknown(
          data['section_index']!,
          _sectionIndexMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sectionIndexMeta);
    }
    if (data.containsKey('start')) {
      context.handle(
        _startMeta,
        start.isAcceptableOrUnknown(data['start']!, _startMeta),
      );
    } else if (isInserting) {
      context.missing(_startMeta);
    }
    if (data.containsKey('end')) {
      context.handle(
        _endMeta,
        end.isAcceptableOrUnknown(data['end']!, _endMeta),
      );
    } else if (isInserting) {
      context.missing(_endMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {schoolId, sectionIndex};
  @override
  SectionTimeEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SectionTimeEntry(
      schoolId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}school_id'],
      )!,
      sectionIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}section_index'],
      )!,
      start: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}start'],
      )!,
      end: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}end'],
      )!,
      periodGroup: $SectionTimeEntriesTable.$converterperiodGroup.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}period_group'],
        )!,
      ),
    );
  }

  @override
  $SectionTimeEntriesTable createAlias(String alias) {
    return $SectionTimeEntriesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<SectionGroup, String, String>
  $converterperiodGroup = const EnumNameConverter<SectionGroup>(
    SectionGroup.values,
  );
}

class SectionTimeEntry extends DataClass
    implements Insertable<SectionTimeEntry> {
  final String schoolId;
  final int sectionIndex;
  final String start;
  final String end;
  final SectionGroup periodGroup;
  const SectionTimeEntry({
    required this.schoolId,
    required this.sectionIndex,
    required this.start,
    required this.end,
    required this.periodGroup,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['school_id'] = Variable<String>(schoolId);
    map['section_index'] = Variable<int>(sectionIndex);
    map['start'] = Variable<String>(start);
    map['end'] = Variable<String>(end);
    {
      map['period_group'] = Variable<String>(
        $SectionTimeEntriesTable.$converterperiodGroup.toSql(periodGroup),
      );
    }
    return map;
  }

  SectionTimeEntriesCompanion toCompanion(bool nullToAbsent) {
    return SectionTimeEntriesCompanion(
      schoolId: Value(schoolId),
      sectionIndex: Value(sectionIndex),
      start: Value(start),
      end: Value(end),
      periodGroup: Value(periodGroup),
    );
  }

  factory SectionTimeEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SectionTimeEntry(
      schoolId: serializer.fromJson<String>(json['schoolId']),
      sectionIndex: serializer.fromJson<int>(json['sectionIndex']),
      start: serializer.fromJson<String>(json['start']),
      end: serializer.fromJson<String>(json['end']),
      periodGroup: $SectionTimeEntriesTable.$converterperiodGroup.fromJson(
        serializer.fromJson<String>(json['periodGroup']),
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'schoolId': serializer.toJson<String>(schoolId),
      'sectionIndex': serializer.toJson<int>(sectionIndex),
      'start': serializer.toJson<String>(start),
      'end': serializer.toJson<String>(end),
      'periodGroup': serializer.toJson<String>(
        $SectionTimeEntriesTable.$converterperiodGroup.toJson(periodGroup),
      ),
    };
  }

  SectionTimeEntry copyWith({
    String? schoolId,
    int? sectionIndex,
    String? start,
    String? end,
    SectionGroup? periodGroup,
  }) => SectionTimeEntry(
    schoolId: schoolId ?? this.schoolId,
    sectionIndex: sectionIndex ?? this.sectionIndex,
    start: start ?? this.start,
    end: end ?? this.end,
    periodGroup: periodGroup ?? this.periodGroup,
  );
  SectionTimeEntry copyWithCompanion(SectionTimeEntriesCompanion data) {
    return SectionTimeEntry(
      schoolId: data.schoolId.present ? data.schoolId.value : this.schoolId,
      sectionIndex: data.sectionIndex.present
          ? data.sectionIndex.value
          : this.sectionIndex,
      start: data.start.present ? data.start.value : this.start,
      end: data.end.present ? data.end.value : this.end,
      periodGroup: data.periodGroup.present
          ? data.periodGroup.value
          : this.periodGroup,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SectionTimeEntry(')
          ..write('schoolId: $schoolId, ')
          ..write('sectionIndex: $sectionIndex, ')
          ..write('start: $start, ')
          ..write('end: $end, ')
          ..write('periodGroup: $periodGroup')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(schoolId, sectionIndex, start, end, periodGroup);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SectionTimeEntry &&
          other.schoolId == this.schoolId &&
          other.sectionIndex == this.sectionIndex &&
          other.start == this.start &&
          other.end == this.end &&
          other.periodGroup == this.periodGroup);
}

class SectionTimeEntriesCompanion extends UpdateCompanion<SectionTimeEntry> {
  final Value<String> schoolId;
  final Value<int> sectionIndex;
  final Value<String> start;
  final Value<String> end;
  final Value<SectionGroup> periodGroup;
  final Value<int> rowid;
  const SectionTimeEntriesCompanion({
    this.schoolId = const Value.absent(),
    this.sectionIndex = const Value.absent(),
    this.start = const Value.absent(),
    this.end = const Value.absent(),
    this.periodGroup = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SectionTimeEntriesCompanion.insert({
    required String schoolId,
    required int sectionIndex,
    required String start,
    required String end,
    required SectionGroup periodGroup,
    this.rowid = const Value.absent(),
  }) : schoolId = Value(schoolId),
       sectionIndex = Value(sectionIndex),
       start = Value(start),
       end = Value(end),
       periodGroup = Value(periodGroup);
  static Insertable<SectionTimeEntry> custom({
    Expression<String>? schoolId,
    Expression<int>? sectionIndex,
    Expression<String>? start,
    Expression<String>? end,
    Expression<String>? periodGroup,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (schoolId != null) 'school_id': schoolId,
      if (sectionIndex != null) 'section_index': sectionIndex,
      if (start != null) 'start': start,
      if (end != null) 'end': end,
      if (periodGroup != null) 'period_group': periodGroup,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SectionTimeEntriesCompanion copyWith({
    Value<String>? schoolId,
    Value<int>? sectionIndex,
    Value<String>? start,
    Value<String>? end,
    Value<SectionGroup>? periodGroup,
    Value<int>? rowid,
  }) {
    return SectionTimeEntriesCompanion(
      schoolId: schoolId ?? this.schoolId,
      sectionIndex: sectionIndex ?? this.sectionIndex,
      start: start ?? this.start,
      end: end ?? this.end,
      periodGroup: periodGroup ?? this.periodGroup,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (schoolId.present) {
      map['school_id'] = Variable<String>(schoolId.value);
    }
    if (sectionIndex.present) {
      map['section_index'] = Variable<int>(sectionIndex.value);
    }
    if (start.present) {
      map['start'] = Variable<String>(start.value);
    }
    if (end.present) {
      map['end'] = Variable<String>(end.value);
    }
    if (periodGroup.present) {
      map['period_group'] = Variable<String>(
        $SectionTimeEntriesTable.$converterperiodGroup.toSql(periodGroup.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SectionTimeEntriesCompanion(')
          ..write('schoolId: $schoolId, ')
          ..write('sectionIndex: $sectionIndex, ')
          ..write('start: $start, ')
          ..write('end: $end, ')
          ..write('periodGroup: $periodGroup, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SettingsTable extends Settings with TableInfo<$SettingsTable, Setting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<Setting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  Setting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Setting(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $SettingsTable createAlias(String alias) {
    return $SettingsTable(attachedDatabase, alias);
  }
}

class Setting extends DataClass implements Insertable<Setting> {
  final String key;
  final String value;
  const Setting({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  SettingsCompanion toCompanion(bool nullToAbsent) {
    return SettingsCompanion(key: Value(key), value: Value(value));
  }

  factory Setting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Setting(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  Setting copyWith({String? key, String? value}) =>
      Setting(key: key ?? this.key, value: value ?? this.value);
  Setting copyWithCompanion(SettingsCompanion data) {
    return Setting(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Setting(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Setting && other.key == this.key && other.value == this.value);
}

class SettingsCompanion extends UpdateCompanion<Setting> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const SettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SettingsCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<Setting> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SettingsCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return SettingsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $SchoolsTable schools = $SchoolsTable(this);
  late final $SemestersTable semesters = $SemestersTable(this);
  late final $CourseEntriesTable courseEntries = $CourseEntriesTable(this);
  late final $SectionTimeEntriesTable sectionTimeEntries =
      $SectionTimeEntriesTable(this);
  late final $SettingsTable settings = $SettingsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    schools,
    semesters,
    courseEntries,
    sectionTimeEntries,
    settings,
  ];
}

typedef $$SchoolsTableCreateCompanionBuilder = SchoolsCompanion Function({
  required String id,
  required String displayName,
  Value<String> adapterId,
  Value<String> presetId,
  Value<String> loginUrl,
  Value<String> acceptedHostsJson,
  Value<String> scheduleVariantsJson,
  required DateTime createdAt,
  Value<int> rowid,
});
typedef $$SchoolsTableUpdateCompanionBuilder = SchoolsCompanion Function({
  Value<String> id,
  Value<String> displayName,
  Value<String> adapterId,
  Value<String> presetId,
  Value<String> loginUrl,
  Value<String> acceptedHostsJson,
  Value<String> scheduleVariantsJson,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

class $$SchoolsTableFilterComposer
    extends Composer<_$AppDatabase, $SchoolsTable> {
  $$SchoolsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get adapterId => $composableBuilder(
    column: $table.adapterId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get presetId => $composableBuilder(
    column: $table.presetId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get loginUrl => $composableBuilder(
    column: $table.loginUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get acceptedHostsJson => $composableBuilder(
    column: $table.acceptedHostsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get scheduleVariantsJson => $composableBuilder(
    column: $table.scheduleVariantsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SchoolsTableOrderingComposer
    extends Composer<_$AppDatabase, $SchoolsTable> {
  $$SchoolsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get adapterId => $composableBuilder(
    column: $table.adapterId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get presetId => $composableBuilder(
    column: $table.presetId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get loginUrl => $composableBuilder(
    column: $table.loginUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get acceptedHostsJson => $composableBuilder(
    column: $table.acceptedHostsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get scheduleVariantsJson => $composableBuilder(
    column: $table.scheduleVariantsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SchoolsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SchoolsTable> {
  $$SchoolsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get adapterId =>
      $composableBuilder(column: $table.adapterId, builder: (column) => column);

  GeneratedColumn<String> get presetId =>
      $composableBuilder(column: $table.presetId, builder: (column) => column);

  GeneratedColumn<String> get loginUrl =>
      $composableBuilder(column: $table.loginUrl, builder: (column) => column);

  GeneratedColumn<String> get acceptedHostsJson => $composableBuilder(
    column: $table.acceptedHostsJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get scheduleVariantsJson => $composableBuilder(
    column: $table.scheduleVariantsJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$SchoolsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SchoolsTable,
          School,
          $$SchoolsTableFilterComposer,
          $$SchoolsTableOrderingComposer,
          $$SchoolsTableAnnotationComposer,
          $$SchoolsTableCreateCompanionBuilder,
          $$SchoolsTableUpdateCompanionBuilder,
          (School, BaseReferences<_$AppDatabase, $SchoolsTable, School>),
          School,
          PrefetchHooks Function()
        > {
  $$SchoolsTableTableManager(_$AppDatabase db, $SchoolsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SchoolsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SchoolsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SchoolsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> displayName = const Value.absent(),
                Value<String> adapterId = const Value.absent(),
                Value<String> presetId = const Value.absent(),
                Value<String> loginUrl = const Value.absent(),
                Value<String> acceptedHostsJson = const Value.absent(),
                Value<String> scheduleVariantsJson = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SchoolsCompanion(
                id: id,
                displayName: displayName,
                adapterId: adapterId,
                presetId: presetId,
                loginUrl: loginUrl,
                acceptedHostsJson: acceptedHostsJson,
                scheduleVariantsJson: scheduleVariantsJson,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String displayName,
                Value<String> adapterId = const Value.absent(),
                Value<String> presetId = const Value.absent(),
                Value<String> loginUrl = const Value.absent(),
                Value<String> acceptedHostsJson = const Value.absent(),
                Value<String> scheduleVariantsJson = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => SchoolsCompanion.insert(
                id: id,
                displayName: displayName,
                adapterId: adapterId,
                presetId: presetId,
                loginUrl: loginUrl,
                acceptedHostsJson: acceptedHostsJson,
                scheduleVariantsJson: scheduleVariantsJson,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SchoolsTable, School>(table),
                  BaseReferences<_$AppDatabase, $SchoolsTable, School>(
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

typedef $$SchoolsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SchoolsTable,
      School,
      $$SchoolsTableFilterComposer,
      $$SchoolsTableOrderingComposer,
      $$SchoolsTableAnnotationComposer,
      $$SchoolsTableCreateCompanionBuilder,
      $$SchoolsTableUpdateCompanionBuilder,
      (School, BaseReferences<_$AppDatabase, $SchoolsTable, School>),
      School,
      PrefetchHooks Function()
    >;
typedef $$SemestersTableCreateCompanionBuilder = SemestersCompanion Function({
  required String id,
  required String schoolId,
  required String firstWeekMondayIso,
  required int totalWeeks,
  Value<int> rowid,
});
typedef $$SemestersTableUpdateCompanionBuilder = SemestersCompanion Function({
  Value<String> id,
  Value<String> schoolId,
  Value<String> firstWeekMondayIso,
  Value<int> totalWeeks,
  Value<int> rowid,
});

class $$SemestersTableFilterComposer
    extends Composer<_$AppDatabase, $SemestersTable> {
  $$SemestersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get schoolId => $composableBuilder(
    column: $table.schoolId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get firstWeekMondayIso => $composableBuilder(
    column: $table.firstWeekMondayIso,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalWeeks => $composableBuilder(
    column: $table.totalWeeks,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SemestersTableOrderingComposer
    extends Composer<_$AppDatabase, $SemestersTable> {
  $$SemestersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get schoolId => $composableBuilder(
    column: $table.schoolId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get firstWeekMondayIso => $composableBuilder(
    column: $table.firstWeekMondayIso,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalWeeks => $composableBuilder(
    column: $table.totalWeeks,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SemestersTableAnnotationComposer
    extends Composer<_$AppDatabase, $SemestersTable> {
  $$SemestersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get schoolId =>
      $composableBuilder(column: $table.schoolId, builder: (column) => column);

  GeneratedColumn<String> get firstWeekMondayIso => $composableBuilder(
    column: $table.firstWeekMondayIso,
    builder: (column) => column,
  );

  GeneratedColumn<int> get totalWeeks => $composableBuilder(
    column: $table.totalWeeks,
    builder: (column) => column,
  );
}

class $$SemestersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SemestersTable,
          SemesterRow,
          $$SemestersTableFilterComposer,
          $$SemestersTableOrderingComposer,
          $$SemestersTableAnnotationComposer,
          $$SemestersTableCreateCompanionBuilder,
          $$SemestersTableUpdateCompanionBuilder,
          (
            SemesterRow,
            BaseReferences<_$AppDatabase, $SemestersTable, SemesterRow>,
          ),
          SemesterRow,
          PrefetchHooks Function()
        > {
  $$SemestersTableTableManager(_$AppDatabase db, $SemestersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SemestersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SemestersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SemestersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> schoolId = const Value.absent(),
                Value<String> firstWeekMondayIso = const Value.absent(),
                Value<int> totalWeeks = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SemestersCompanion(
                id: id,
                schoolId: schoolId,
                firstWeekMondayIso: firstWeekMondayIso,
                totalWeeks: totalWeeks,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String schoolId,
                required String firstWeekMondayIso,
                required int totalWeeks,
                Value<int> rowid = const Value.absent(),
              }) => SemestersCompanion.insert(
                id: id,
                schoolId: schoolId,
                firstWeekMondayIso: firstWeekMondayIso,
                totalWeeks: totalWeeks,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SemestersTable, SemesterRow>(table),
                  BaseReferences<_$AppDatabase, $SemestersTable, SemesterRow>(
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

typedef $$SemestersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SemestersTable,
      SemesterRow,
      $$SemestersTableFilterComposer,
      $$SemestersTableOrderingComposer,
      $$SemestersTableAnnotationComposer,
      $$SemestersTableCreateCompanionBuilder,
      $$SemestersTableUpdateCompanionBuilder,
      (
        SemesterRow,
        BaseReferences<_$AppDatabase, $SemestersTable, SemesterRow>,
      ),
      SemesterRow,
      PrefetchHooks Function()
    >;
typedef $$CourseEntriesTableCreateCompanionBuilder =
    CourseEntriesCompanion Function({
      required String id,
      required String schoolId,
      required String semesterId,
      required CourseSource source,
      required String name,
      Value<String> teacher,
      Value<String> classroom,
      required int weekday,
      required int startSection,
      required int endSection,
      required String weeksJson,
      Value<String?> startTime,
      Value<String?> endTime,
      Value<String> note,
      Value<int> colorKey,
      Value<int> rowid,
    });
typedef $$CourseEntriesTableUpdateCompanionBuilder =
    CourseEntriesCompanion Function({
      Value<String> id,
      Value<String> schoolId,
      Value<String> semesterId,
      Value<CourseSource> source,
      Value<String> name,
      Value<String> teacher,
      Value<String> classroom,
      Value<int> weekday,
      Value<int> startSection,
      Value<int> endSection,
      Value<String> weeksJson,
      Value<String?> startTime,
      Value<String?> endTime,
      Value<String> note,
      Value<int> colorKey,
      Value<int> rowid,
    });

class $$CourseEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $CourseEntriesTable> {
  $$CourseEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get schoolId => $composableBuilder(
    column: $table.schoolId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get semesterId => $composableBuilder(
    column: $table.semesterId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<CourseSource, CourseSource, String>
  get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get teacher => $composableBuilder(
    column: $table.teacher,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get classroom => $composableBuilder(
    column: $table.classroom,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get weekday => $composableBuilder(
    column: $table.weekday,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startSection => $composableBuilder(
    column: $table.startSection,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get endSection => $composableBuilder(
    column: $table.endSection,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get weeksJson => $composableBuilder(
    column: $table.weeksJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get startTime => $composableBuilder(
    column: $table.startTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get endTime => $composableBuilder(
    column: $table.endTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get colorKey => $composableBuilder(
    column: $table.colorKey,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CourseEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $CourseEntriesTable> {
  $$CourseEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get schoolId => $composableBuilder(
    column: $table.schoolId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get semesterId => $composableBuilder(
    column: $table.semesterId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get teacher => $composableBuilder(
    column: $table.teacher,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get classroom => $composableBuilder(
    column: $table.classroom,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get weekday => $composableBuilder(
    column: $table.weekday,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startSection => $composableBuilder(
    column: $table.startSection,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get endSection => $composableBuilder(
    column: $table.endSection,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get weeksJson => $composableBuilder(
    column: $table.weeksJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get startTime => $composableBuilder(
    column: $table.startTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get endTime => $composableBuilder(
    column: $table.endTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get colorKey => $composableBuilder(
    column: $table.colorKey,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CourseEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CourseEntriesTable> {
  $$CourseEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get schoolId =>
      $composableBuilder(column: $table.schoolId, builder: (column) => column);

  GeneratedColumn<String> get semesterId => $composableBuilder(
    column: $table.semesterId,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<CourseSource, String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get teacher =>
      $composableBuilder(column: $table.teacher, builder: (column) => column);

  GeneratedColumn<String> get classroom =>
      $composableBuilder(column: $table.classroom, builder: (column) => column);

  GeneratedColumn<int> get weekday =>
      $composableBuilder(column: $table.weekday, builder: (column) => column);

  GeneratedColumn<int> get startSection => $composableBuilder(
    column: $table.startSection,
    builder: (column) => column,
  );

  GeneratedColumn<int> get endSection => $composableBuilder(
    column: $table.endSection,
    builder: (column) => column,
  );

  GeneratedColumn<String> get weeksJson =>
      $composableBuilder(column: $table.weeksJson, builder: (column) => column);

  GeneratedColumn<String> get startTime =>
      $composableBuilder(column: $table.startTime, builder: (column) => column);

  GeneratedColumn<String> get endTime =>
      $composableBuilder(column: $table.endTime, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<int> get colorKey =>
      $composableBuilder(column: $table.colorKey, builder: (column) => column);
}

class $$CourseEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CourseEntriesTable,
          CourseEntry,
          $$CourseEntriesTableFilterComposer,
          $$CourseEntriesTableOrderingComposer,
          $$CourseEntriesTableAnnotationComposer,
          $$CourseEntriesTableCreateCompanionBuilder,
          $$CourseEntriesTableUpdateCompanionBuilder,
          (
            CourseEntry,
            BaseReferences<_$AppDatabase, $CourseEntriesTable, CourseEntry>,
          ),
          CourseEntry,
          PrefetchHooks Function()
        > {
  $$CourseEntriesTableTableManager(_$AppDatabase db, $CourseEntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CourseEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CourseEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CourseEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> schoolId = const Value.absent(),
                Value<String> semesterId = const Value.absent(),
                Value<CourseSource> source = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> teacher = const Value.absent(),
                Value<String> classroom = const Value.absent(),
                Value<int> weekday = const Value.absent(),
                Value<int> startSection = const Value.absent(),
                Value<int> endSection = const Value.absent(),
                Value<String> weeksJson = const Value.absent(),
                Value<String?> startTime = const Value.absent(),
                Value<String?> endTime = const Value.absent(),
                Value<String> note = const Value.absent(),
                Value<int> colorKey = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CourseEntriesCompanion(
                id: id,
                schoolId: schoolId,
                semesterId: semesterId,
                source: source,
                name: name,
                teacher: teacher,
                classroom: classroom,
                weekday: weekday,
                startSection: startSection,
                endSection: endSection,
                weeksJson: weeksJson,
                startTime: startTime,
                endTime: endTime,
                note: note,
                colorKey: colorKey,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String schoolId,
                required String semesterId,
                required CourseSource source,
                required String name,
                Value<String> teacher = const Value.absent(),
                Value<String> classroom = const Value.absent(),
                required int weekday,
                required int startSection,
                required int endSection,
                required String weeksJson,
                Value<String?> startTime = const Value.absent(),
                Value<String?> endTime = const Value.absent(),
                Value<String> note = const Value.absent(),
                Value<int> colorKey = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CourseEntriesCompanion.insert(
                id: id,
                schoolId: schoolId,
                semesterId: semesterId,
                source: source,
                name: name,
                teacher: teacher,
                classroom: classroom,
                weekday: weekday,
                startSection: startSection,
                endSection: endSection,
                weeksJson: weeksJson,
                startTime: startTime,
                endTime: endTime,
                note: note,
                colorKey: colorKey,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CourseEntriesTable, CourseEntry>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $CourseEntriesTable,
                    CourseEntry
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CourseEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CourseEntriesTable,
      CourseEntry,
      $$CourseEntriesTableFilterComposer,
      $$CourseEntriesTableOrderingComposer,
      $$CourseEntriesTableAnnotationComposer,
      $$CourseEntriesTableCreateCompanionBuilder,
      $$CourseEntriesTableUpdateCompanionBuilder,
      (
        CourseEntry,
        BaseReferences<_$AppDatabase, $CourseEntriesTable, CourseEntry>,
      ),
      CourseEntry,
      PrefetchHooks Function()
    >;
typedef $$SectionTimeEntriesTableCreateCompanionBuilder =
    SectionTimeEntriesCompanion Function({
      required String schoolId,
      required int sectionIndex,
      required String start,
      required String end,
      required SectionGroup periodGroup,
      Value<int> rowid,
    });
typedef $$SectionTimeEntriesTableUpdateCompanionBuilder =
    SectionTimeEntriesCompanion Function({
      Value<String> schoolId,
      Value<int> sectionIndex,
      Value<String> start,
      Value<String> end,
      Value<SectionGroup> periodGroup,
      Value<int> rowid,
    });

class $$SectionTimeEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $SectionTimeEntriesTable> {
  $$SectionTimeEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get schoolId => $composableBuilder(
    column: $table.schoolId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sectionIndex => $composableBuilder(
    column: $table.sectionIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get start => $composableBuilder(
    column: $table.start,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get end => $composableBuilder(
    column: $table.end,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<SectionGroup, SectionGroup, String>
  get periodGroup => $composableBuilder(
    column: $table.periodGroup,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );
}

class $$SectionTimeEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $SectionTimeEntriesTable> {
  $$SectionTimeEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get schoolId => $composableBuilder(
    column: $table.schoolId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sectionIndex => $composableBuilder(
    column: $table.sectionIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get start => $composableBuilder(
    column: $table.start,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get end => $composableBuilder(
    column: $table.end,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get periodGroup => $composableBuilder(
    column: $table.periodGroup,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SectionTimeEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SectionTimeEntriesTable> {
  $$SectionTimeEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get schoolId =>
      $composableBuilder(column: $table.schoolId, builder: (column) => column);

  GeneratedColumn<int> get sectionIndex => $composableBuilder(
    column: $table.sectionIndex,
    builder: (column) => column,
  );

  GeneratedColumn<String> get start =>
      $composableBuilder(column: $table.start, builder: (column) => column);

  GeneratedColumn<String> get end =>
      $composableBuilder(column: $table.end, builder: (column) => column);

  GeneratedColumnWithTypeConverter<SectionGroup, String> get periodGroup =>
      $composableBuilder(
        column: $table.periodGroup,
        builder: (column) => column,
      );
}

class $$SectionTimeEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SectionTimeEntriesTable,
          SectionTimeEntry,
          $$SectionTimeEntriesTableFilterComposer,
          $$SectionTimeEntriesTableOrderingComposer,
          $$SectionTimeEntriesTableAnnotationComposer,
          $$SectionTimeEntriesTableCreateCompanionBuilder,
          $$SectionTimeEntriesTableUpdateCompanionBuilder,
          (
            SectionTimeEntry,
            BaseReferences<
              _$AppDatabase,
              $SectionTimeEntriesTable,
              SectionTimeEntry
            >,
          ),
          SectionTimeEntry,
          PrefetchHooks Function()
        > {
  $$SectionTimeEntriesTableTableManager(
    _$AppDatabase db,
    $SectionTimeEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SectionTimeEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SectionTimeEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SectionTimeEntriesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> schoolId = const Value.absent(),
                Value<int> sectionIndex = const Value.absent(),
                Value<String> start = const Value.absent(),
                Value<String> end = const Value.absent(),
                Value<SectionGroup> periodGroup = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SectionTimeEntriesCompanion(
                schoolId: schoolId,
                sectionIndex: sectionIndex,
                start: start,
                end: end,
                periodGroup: periodGroup,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String schoolId,
                required int sectionIndex,
                required String start,
                required String end,
                required SectionGroup periodGroup,
                Value<int> rowid = const Value.absent(),
              }) => SectionTimeEntriesCompanion.insert(
                schoolId: schoolId,
                sectionIndex: sectionIndex,
                start: start,
                end: end,
                periodGroup: periodGroup,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SectionTimeEntriesTable, SectionTimeEntry>(
                    table,
                  ),
                  BaseReferences<
                    _$AppDatabase,
                    $SectionTimeEntriesTable,
                    SectionTimeEntry
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SectionTimeEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SectionTimeEntriesTable,
      SectionTimeEntry,
      $$SectionTimeEntriesTableFilterComposer,
      $$SectionTimeEntriesTableOrderingComposer,
      $$SectionTimeEntriesTableAnnotationComposer,
      $$SectionTimeEntriesTableCreateCompanionBuilder,
      $$SectionTimeEntriesTableUpdateCompanionBuilder,
      (
        SectionTimeEntry,
        BaseReferences<
          _$AppDatabase,
          $SectionTimeEntriesTable,
          SectionTimeEntry
        >,
      ),
      SectionTimeEntry,
      PrefetchHooks Function()
    >;
typedef $$SettingsTableCreateCompanionBuilder = SettingsCompanion Function({
  required String key,
  required String value,
  Value<int> rowid,
});
typedef $$SettingsTableUpdateCompanionBuilder = SettingsCompanion Function({
  Value<String> key,
  Value<String> value,
  Value<int> rowid,
});

class $$SettingsTableFilterComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$SettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SettingsTable,
          Setting,
          $$SettingsTableFilterComposer,
          $$SettingsTableOrderingComposer,
          $$SettingsTableAnnotationComposer,
          $$SettingsTableCreateCompanionBuilder,
          $$SettingsTableUpdateCompanionBuilder,
          (Setting, BaseReferences<_$AppDatabase, $SettingsTable, Setting>),
          Setting,
          PrefetchHooks Function()
        > {
  $$SettingsTableTableManager(_$AppDatabase db, $SettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => SettingsCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback: ({
            required String key,
            required String value,
            Value<int> rowid = const Value.absent(),
          }) => SettingsCompanion.insert(key: key, value: value, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SettingsTable, Setting>(table),
                  BaseReferences<_$AppDatabase, $SettingsTable, Setting>(
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

typedef $$SettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SettingsTable,
      Setting,
      $$SettingsTableFilterComposer,
      $$SettingsTableOrderingComposer,
      $$SettingsTableAnnotationComposer,
      $$SettingsTableCreateCompanionBuilder,
      $$SettingsTableUpdateCompanionBuilder,
      (Setting, BaseReferences<_$AppDatabase, $SettingsTable, Setting>),
      Setting,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$SchoolsTableTableManager get schools =>
      $$SchoolsTableTableManager(_db, _db.schools);
  $$SemestersTableTableManager get semesters =>
      $$SemestersTableTableManager(_db, _db.semesters);
  $$CourseEntriesTableTableManager get courseEntries =>
      $$CourseEntriesTableTableManager(_db, _db.courseEntries);
  $$SectionTimeEntriesTableTableManager get sectionTimeEntries =>
      $$SectionTimeEntriesTableTableManager(_db, _db.sectionTimeEntries);
  $$SettingsTableTableManager get settings =>
      $$SettingsTableTableManager(_db, _db.settings);
}
