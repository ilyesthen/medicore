// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $UsersTable extends Users with TableInfo<$UsersTable, UserEntity> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UsersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
      'role', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _passwordHashMeta =
      const VerificationMeta('passwordHash');
  @override
  late final GeneratedColumn<String> passwordHash = GeneratedColumn<String>(
      'password_hash', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _percentageMeta =
      const VerificationMeta('percentage');
  @override
  late final GeneratedColumn<double> percentage = GeneratedColumn<double>(
      'percentage', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _isTemplateUserMeta =
      const VerificationMeta('isTemplateUser');
  @override
  late final GeneratedColumn<bool> isTemplateUser = GeneratedColumn<bool>(
      'is_template_user', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_template_user" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _deletedAtMeta =
      const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
      'deleted_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _lastSyncedAtMeta =
      const VerificationMeta('lastSyncedAt');
  @override
  late final GeneratedColumn<DateTime> lastSyncedAt = GeneratedColumn<DateTime>(
      'last_synced_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _syncVersionMeta =
      const VerificationMeta('syncVersion');
  @override
  late final GeneratedColumn<int> syncVersion = GeneratedColumn<int>(
      'sync_version', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _needsSyncMeta =
      const VerificationMeta('needsSync');
  @override
  late final GeneratedColumn<bool> needsSync = GeneratedColumn<bool>(
      'needs_sync', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("needs_sync" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        name,
        role,
        passwordHash,
        percentage,
        isTemplateUser,
        createdAt,
        updatedAt,
        deletedAt,
        lastSyncedAt,
        syncVersion,
        needsSync
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'users';
  @override
  VerificationContext validateIntegrity(Insertable<UserEntity> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('role')) {
      context.handle(
          _roleMeta, role.isAcceptableOrUnknown(data['role']!, _roleMeta));
    } else if (isInserting) {
      context.missing(_roleMeta);
    }
    if (data.containsKey('password_hash')) {
      context.handle(
          _passwordHashMeta,
          passwordHash.isAcceptableOrUnknown(
              data['password_hash']!, _passwordHashMeta));
    } else if (isInserting) {
      context.missing(_passwordHashMeta);
    }
    if (data.containsKey('percentage')) {
      context.handle(
          _percentageMeta,
          percentage.isAcceptableOrUnknown(
              data['percentage']!, _percentageMeta));
    }
    if (data.containsKey('is_template_user')) {
      context.handle(
          _isTemplateUserMeta,
          isTemplateUser.isAcceptableOrUnknown(
              data['is_template_user']!, _isTemplateUserMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta,
          deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    if (data.containsKey('last_synced_at')) {
      context.handle(
          _lastSyncedAtMeta,
          lastSyncedAt.isAcceptableOrUnknown(
              data['last_synced_at']!, _lastSyncedAtMeta));
    }
    if (data.containsKey('sync_version')) {
      context.handle(
          _syncVersionMeta,
          syncVersion.isAcceptableOrUnknown(
              data['sync_version']!, _syncVersionMeta));
    }
    if (data.containsKey('needs_sync')) {
      context.handle(_needsSyncMeta,
          needsSync.isAcceptableOrUnknown(data['needs_sync']!, _needsSyncMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  UserEntity map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserEntity(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      role: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}role'])!,
      passwordHash: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}password_hash'])!,
      percentage: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}percentage']),
      isTemplateUser: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_template_user'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      deletedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}deleted_at']),
      lastSyncedAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}last_synced_at']),
      syncVersion: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sync_version'])!,
      needsSync: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}needs_sync'])!,
    );
  }

  @override
  $UsersTable createAlias(String alias) {
    return $UsersTable(attachedDatabase, alias);
  }
}

class UserEntity extends DataClass implements Insertable<UserEntity> {
  final String id;
  final String name;
  final String role;
  final String passwordHash;
  final double? percentage;
  final bool isTemplateUser;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final DateTime? lastSyncedAt;
  final int syncVersion;
  final bool needsSync;
  const UserEntity(
      {required this.id,
      required this.name,
      required this.role,
      required this.passwordHash,
      this.percentage,
      required this.isTemplateUser,
      required this.createdAt,
      required this.updatedAt,
      this.deletedAt,
      this.lastSyncedAt,
      required this.syncVersion,
      required this.needsSync});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['role'] = Variable<String>(role);
    map['password_hash'] = Variable<String>(passwordHash);
    if (!nullToAbsent || percentage != null) {
      map['percentage'] = Variable<double>(percentage);
    }
    map['is_template_user'] = Variable<bool>(isTemplateUser);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    if (!nullToAbsent || lastSyncedAt != null) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt);
    }
    map['sync_version'] = Variable<int>(syncVersion);
    map['needs_sync'] = Variable<bool>(needsSync);
    return map;
  }

  UsersCompanion toCompanion(bool nullToAbsent) {
    return UsersCompanion(
      id: Value(id),
      name: Value(name),
      role: Value(role),
      passwordHash: Value(passwordHash),
      percentage: percentage == null && nullToAbsent
          ? const Value.absent()
          : Value(percentage),
      isTemplateUser: Value(isTemplateUser),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      lastSyncedAt: lastSyncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncedAt),
      syncVersion: Value(syncVersion),
      needsSync: Value(needsSync),
    );
  }

  factory UserEntity.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserEntity(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      role: serializer.fromJson<String>(json['role']),
      passwordHash: serializer.fromJson<String>(json['passwordHash']),
      percentage: serializer.fromJson<double?>(json['percentage']),
      isTemplateUser: serializer.fromJson<bool>(json['isTemplateUser']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      lastSyncedAt: serializer.fromJson<DateTime?>(json['lastSyncedAt']),
      syncVersion: serializer.fromJson<int>(json['syncVersion']),
      needsSync: serializer.fromJson<bool>(json['needsSync']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'role': serializer.toJson<String>(role),
      'passwordHash': serializer.toJson<String>(passwordHash),
      'percentage': serializer.toJson<double?>(percentage),
      'isTemplateUser': serializer.toJson<bool>(isTemplateUser),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'lastSyncedAt': serializer.toJson<DateTime?>(lastSyncedAt),
      'syncVersion': serializer.toJson<int>(syncVersion),
      'needsSync': serializer.toJson<bool>(needsSync),
    };
  }

  UserEntity copyWith(
          {String? id,
          String? name,
          String? role,
          String? passwordHash,
          Value<double?> percentage = const Value.absent(),
          bool? isTemplateUser,
          DateTime? createdAt,
          DateTime? updatedAt,
          Value<DateTime?> deletedAt = const Value.absent(),
          Value<DateTime?> lastSyncedAt = const Value.absent(),
          int? syncVersion,
          bool? needsSync}) =>
      UserEntity(
        id: id ?? this.id,
        name: name ?? this.name,
        role: role ?? this.role,
        passwordHash: passwordHash ?? this.passwordHash,
        percentage: percentage.present ? percentage.value : this.percentage,
        isTemplateUser: isTemplateUser ?? this.isTemplateUser,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
        lastSyncedAt:
            lastSyncedAt.present ? lastSyncedAt.value : this.lastSyncedAt,
        syncVersion: syncVersion ?? this.syncVersion,
        needsSync: needsSync ?? this.needsSync,
      );
  UserEntity copyWithCompanion(UsersCompanion data) {
    return UserEntity(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      role: data.role.present ? data.role.value : this.role,
      passwordHash: data.passwordHash.present
          ? data.passwordHash.value
          : this.passwordHash,
      percentage:
          data.percentage.present ? data.percentage.value : this.percentage,
      isTemplateUser: data.isTemplateUser.present
          ? data.isTemplateUser.value
          : this.isTemplateUser,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      lastSyncedAt: data.lastSyncedAt.present
          ? data.lastSyncedAt.value
          : this.lastSyncedAt,
      syncVersion:
          data.syncVersion.present ? data.syncVersion.value : this.syncVersion,
      needsSync: data.needsSync.present ? data.needsSync.value : this.needsSync,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserEntity(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('role: $role, ')
          ..write('passwordHash: $passwordHash, ')
          ..write('percentage: $percentage, ')
          ..write('isTemplateUser: $isTemplateUser, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('syncVersion: $syncVersion, ')
          ..write('needsSync: $needsSync')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      name,
      role,
      passwordHash,
      percentage,
      isTemplateUser,
      createdAt,
      updatedAt,
      deletedAt,
      lastSyncedAt,
      syncVersion,
      needsSync);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserEntity &&
          other.id == this.id &&
          other.name == this.name &&
          other.role == this.role &&
          other.passwordHash == this.passwordHash &&
          other.percentage == this.percentage &&
          other.isTemplateUser == this.isTemplateUser &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.lastSyncedAt == this.lastSyncedAt &&
          other.syncVersion == this.syncVersion &&
          other.needsSync == this.needsSync);
}

class UsersCompanion extends UpdateCompanion<UserEntity> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> role;
  final Value<String> passwordHash;
  final Value<double?> percentage;
  final Value<bool> isTemplateUser;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<DateTime?> lastSyncedAt;
  final Value<int> syncVersion;
  final Value<bool> needsSync;
  final Value<int> rowid;
  const UsersCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.role = const Value.absent(),
    this.passwordHash = const Value.absent(),
    this.percentage = const Value.absent(),
    this.isTemplateUser = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.syncVersion = const Value.absent(),
    this.needsSync = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UsersCompanion.insert({
    required String id,
    required String name,
    required String role,
    required String passwordHash,
    this.percentage = const Value.absent(),
    this.isTemplateUser = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.syncVersion = const Value.absent(),
    this.needsSync = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name),
        role = Value(role),
        passwordHash = Value(passwordHash);
  static Insertable<UserEntity> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? role,
    Expression<String>? passwordHash,
    Expression<double>? percentage,
    Expression<bool>? isTemplateUser,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<DateTime>? lastSyncedAt,
    Expression<int>? syncVersion,
    Expression<bool>? needsSync,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (role != null) 'role': role,
      if (passwordHash != null) 'password_hash': passwordHash,
      if (percentage != null) 'percentage': percentage,
      if (isTemplateUser != null) 'is_template_user': isTemplateUser,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (lastSyncedAt != null) 'last_synced_at': lastSyncedAt,
      if (syncVersion != null) 'sync_version': syncVersion,
      if (needsSync != null) 'needs_sync': needsSync,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UsersCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<String>? role,
      Value<String>? passwordHash,
      Value<double?>? percentage,
      Value<bool>? isTemplateUser,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<DateTime?>? deletedAt,
      Value<DateTime?>? lastSyncedAt,
      Value<int>? syncVersion,
      Value<bool>? needsSync,
      Value<int>? rowid}) {
    return UsersCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      role: role ?? this.role,
      passwordHash: passwordHash ?? this.passwordHash,
      percentage: percentage ?? this.percentage,
      isTemplateUser: isTemplateUser ?? this.isTemplateUser,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      syncVersion: syncVersion ?? this.syncVersion,
      needsSync: needsSync ?? this.needsSync,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (passwordHash.present) {
      map['password_hash'] = Variable<String>(passwordHash.value);
    }
    if (percentage.present) {
      map['percentage'] = Variable<double>(percentage.value);
    }
    if (isTemplateUser.present) {
      map['is_template_user'] = Variable<bool>(isTemplateUser.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (lastSyncedAt.present) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt.value);
    }
    if (syncVersion.present) {
      map['sync_version'] = Variable<int>(syncVersion.value);
    }
    if (needsSync.present) {
      map['needs_sync'] = Variable<bool>(needsSync.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UsersCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('role: $role, ')
          ..write('passwordHash: $passwordHash, ')
          ..write('percentage: $percentage, ')
          ..write('isTemplateUser: $isTemplateUser, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('syncVersion: $syncVersion, ')
          ..write('needsSync: $needsSync, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TemplatesTable extends Templates
    with TableInfo<$TemplatesTable, TemplateEntity> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TemplatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
      'role', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _passwordHashMeta =
      const VerificationMeta('passwordHash');
  @override
  late final GeneratedColumn<String> passwordHash = GeneratedColumn<String>(
      'password_hash', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _percentageMeta =
      const VerificationMeta('percentage');
  @override
  late final GeneratedColumn<double> percentage = GeneratedColumn<double>(
      'percentage', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _deletedAtMeta =
      const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
      'deleted_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _lastSyncedAtMeta =
      const VerificationMeta('lastSyncedAt');
  @override
  late final GeneratedColumn<DateTime> lastSyncedAt = GeneratedColumn<DateTime>(
      'last_synced_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _syncVersionMeta =
      const VerificationMeta('syncVersion');
  @override
  late final GeneratedColumn<int> syncVersion = GeneratedColumn<int>(
      'sync_version', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _needsSyncMeta =
      const VerificationMeta('needsSync');
  @override
  late final GeneratedColumn<bool> needsSync = GeneratedColumn<bool>(
      'needs_sync', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("needs_sync" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        role,
        passwordHash,
        percentage,
        createdAt,
        updatedAt,
        deletedAt,
        lastSyncedAt,
        syncVersion,
        needsSync
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'templates';
  @override
  VerificationContext validateIntegrity(Insertable<TemplateEntity> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('role')) {
      context.handle(
          _roleMeta, role.isAcceptableOrUnknown(data['role']!, _roleMeta));
    } else if (isInserting) {
      context.missing(_roleMeta);
    }
    if (data.containsKey('password_hash')) {
      context.handle(
          _passwordHashMeta,
          passwordHash.isAcceptableOrUnknown(
              data['password_hash']!, _passwordHashMeta));
    } else if (isInserting) {
      context.missing(_passwordHashMeta);
    }
    if (data.containsKey('percentage')) {
      context.handle(
          _percentageMeta,
          percentage.isAcceptableOrUnknown(
              data['percentage']!, _percentageMeta));
    } else if (isInserting) {
      context.missing(_percentageMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta,
          deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    if (data.containsKey('last_synced_at')) {
      context.handle(
          _lastSyncedAtMeta,
          lastSyncedAt.isAcceptableOrUnknown(
              data['last_synced_at']!, _lastSyncedAtMeta));
    }
    if (data.containsKey('sync_version')) {
      context.handle(
          _syncVersionMeta,
          syncVersion.isAcceptableOrUnknown(
              data['sync_version']!, _syncVersionMeta));
    }
    if (data.containsKey('needs_sync')) {
      context.handle(_needsSyncMeta,
          needsSync.isAcceptableOrUnknown(data['needs_sync']!, _needsSyncMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TemplateEntity map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TemplateEntity(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      role: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}role'])!,
      passwordHash: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}password_hash'])!,
      percentage: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}percentage'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      deletedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}deleted_at']),
      lastSyncedAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}last_synced_at']),
      syncVersion: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sync_version'])!,
      needsSync: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}needs_sync'])!,
    );
  }

  @override
  $TemplatesTable createAlias(String alias) {
    return $TemplatesTable(attachedDatabase, alias);
  }
}

class TemplateEntity extends DataClass implements Insertable<TemplateEntity> {
  final String id;
  final String role;
  final String passwordHash;
  final double percentage;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final DateTime? lastSyncedAt;
  final int syncVersion;
  final bool needsSync;
  const TemplateEntity(
      {required this.id,
      required this.role,
      required this.passwordHash,
      required this.percentage,
      required this.createdAt,
      required this.updatedAt,
      this.deletedAt,
      this.lastSyncedAt,
      required this.syncVersion,
      required this.needsSync});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['role'] = Variable<String>(role);
    map['password_hash'] = Variable<String>(passwordHash);
    map['percentage'] = Variable<double>(percentage);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    if (!nullToAbsent || lastSyncedAt != null) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt);
    }
    map['sync_version'] = Variable<int>(syncVersion);
    map['needs_sync'] = Variable<bool>(needsSync);
    return map;
  }

  TemplatesCompanion toCompanion(bool nullToAbsent) {
    return TemplatesCompanion(
      id: Value(id),
      role: Value(role),
      passwordHash: Value(passwordHash),
      percentage: Value(percentage),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      lastSyncedAt: lastSyncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncedAt),
      syncVersion: Value(syncVersion),
      needsSync: Value(needsSync),
    );
  }

  factory TemplateEntity.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TemplateEntity(
      id: serializer.fromJson<String>(json['id']),
      role: serializer.fromJson<String>(json['role']),
      passwordHash: serializer.fromJson<String>(json['passwordHash']),
      percentage: serializer.fromJson<double>(json['percentage']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      lastSyncedAt: serializer.fromJson<DateTime?>(json['lastSyncedAt']),
      syncVersion: serializer.fromJson<int>(json['syncVersion']),
      needsSync: serializer.fromJson<bool>(json['needsSync']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'role': serializer.toJson<String>(role),
      'passwordHash': serializer.toJson<String>(passwordHash),
      'percentage': serializer.toJson<double>(percentage),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'lastSyncedAt': serializer.toJson<DateTime?>(lastSyncedAt),
      'syncVersion': serializer.toJson<int>(syncVersion),
      'needsSync': serializer.toJson<bool>(needsSync),
    };
  }

  TemplateEntity copyWith(
          {String? id,
          String? role,
          String? passwordHash,
          double? percentage,
          DateTime? createdAt,
          DateTime? updatedAt,
          Value<DateTime?> deletedAt = const Value.absent(),
          Value<DateTime?> lastSyncedAt = const Value.absent(),
          int? syncVersion,
          bool? needsSync}) =>
      TemplateEntity(
        id: id ?? this.id,
        role: role ?? this.role,
        passwordHash: passwordHash ?? this.passwordHash,
        percentage: percentage ?? this.percentage,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
        lastSyncedAt:
            lastSyncedAt.present ? lastSyncedAt.value : this.lastSyncedAt,
        syncVersion: syncVersion ?? this.syncVersion,
        needsSync: needsSync ?? this.needsSync,
      );
  TemplateEntity copyWithCompanion(TemplatesCompanion data) {
    return TemplateEntity(
      id: data.id.present ? data.id.value : this.id,
      role: data.role.present ? data.role.value : this.role,
      passwordHash: data.passwordHash.present
          ? data.passwordHash.value
          : this.passwordHash,
      percentage:
          data.percentage.present ? data.percentage.value : this.percentage,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      lastSyncedAt: data.lastSyncedAt.present
          ? data.lastSyncedAt.value
          : this.lastSyncedAt,
      syncVersion:
          data.syncVersion.present ? data.syncVersion.value : this.syncVersion,
      needsSync: data.needsSync.present ? data.needsSync.value : this.needsSync,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TemplateEntity(')
          ..write('id: $id, ')
          ..write('role: $role, ')
          ..write('passwordHash: $passwordHash, ')
          ..write('percentage: $percentage, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('syncVersion: $syncVersion, ')
          ..write('needsSync: $needsSync')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, role, passwordHash, percentage, createdAt,
      updatedAt, deletedAt, lastSyncedAt, syncVersion, needsSync);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TemplateEntity &&
          other.id == this.id &&
          other.role == this.role &&
          other.passwordHash == this.passwordHash &&
          other.percentage == this.percentage &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.lastSyncedAt == this.lastSyncedAt &&
          other.syncVersion == this.syncVersion &&
          other.needsSync == this.needsSync);
}

class TemplatesCompanion extends UpdateCompanion<TemplateEntity> {
  final Value<String> id;
  final Value<String> role;
  final Value<String> passwordHash;
  final Value<double> percentage;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<DateTime?> lastSyncedAt;
  final Value<int> syncVersion;
  final Value<bool> needsSync;
  final Value<int> rowid;
  const TemplatesCompanion({
    this.id = const Value.absent(),
    this.role = const Value.absent(),
    this.passwordHash = const Value.absent(),
    this.percentage = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.syncVersion = const Value.absent(),
    this.needsSync = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TemplatesCompanion.insert({
    required String id,
    required String role,
    required String passwordHash,
    required double percentage,
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.syncVersion = const Value.absent(),
    this.needsSync = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        role = Value(role),
        passwordHash = Value(passwordHash),
        percentage = Value(percentage);
  static Insertable<TemplateEntity> custom({
    Expression<String>? id,
    Expression<String>? role,
    Expression<String>? passwordHash,
    Expression<double>? percentage,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<DateTime>? lastSyncedAt,
    Expression<int>? syncVersion,
    Expression<bool>? needsSync,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (role != null) 'role': role,
      if (passwordHash != null) 'password_hash': passwordHash,
      if (percentage != null) 'percentage': percentage,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (lastSyncedAt != null) 'last_synced_at': lastSyncedAt,
      if (syncVersion != null) 'sync_version': syncVersion,
      if (needsSync != null) 'needs_sync': needsSync,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TemplatesCompanion copyWith(
      {Value<String>? id,
      Value<String>? role,
      Value<String>? passwordHash,
      Value<double>? percentage,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<DateTime?>? deletedAt,
      Value<DateTime?>? lastSyncedAt,
      Value<int>? syncVersion,
      Value<bool>? needsSync,
      Value<int>? rowid}) {
    return TemplatesCompanion(
      id: id ?? this.id,
      role: role ?? this.role,
      passwordHash: passwordHash ?? this.passwordHash,
      percentage: percentage ?? this.percentage,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      syncVersion: syncVersion ?? this.syncVersion,
      needsSync: needsSync ?? this.needsSync,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (passwordHash.present) {
      map['password_hash'] = Variable<String>(passwordHash.value);
    }
    if (percentage.present) {
      map['percentage'] = Variable<double>(percentage.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (lastSyncedAt.present) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt.value);
    }
    if (syncVersion.present) {
      map['sync_version'] = Variable<int>(syncVersion.value);
    }
    if (needsSync.present) {
      map['needs_sync'] = Variable<bool>(needsSync.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TemplatesCompanion(')
          ..write('id: $id, ')
          ..write('role: $role, ')
          ..write('passwordHash: $passwordHash, ')
          ..write('percentage: $percentage, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('syncVersion: $syncVersion, ')
          ..write('needsSync: $needsSync, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RoomsTable extends Rooms with TableInfo<$RoomsTable, Room> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RoomsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _needsSyncMeta =
      const VerificationMeta('needsSync');
  @override
  late final GeneratedColumn<bool> needsSync = GeneratedColumn<bool>(
      'needs_sync', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("needs_sync" IN (0, 1))'),
      defaultValue: const Constant(true));
  @override
  List<GeneratedColumn> get $columns =>
      [id, name, createdAt, updatedAt, needsSync];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'rooms';
  @override
  VerificationContext validateIntegrity(Insertable<Room> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    if (data.containsKey('needs_sync')) {
      context.handle(_needsSyncMeta,
          needsSync.isAcceptableOrUnknown(data['needs_sync']!, _needsSyncMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Room map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Room(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      needsSync: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}needs_sync'])!,
    );
  }

  @override
  $RoomsTable createAlias(String alias) {
    return $RoomsTable(attachedDatabase, alias);
  }
}

class Room extends DataClass implements Insertable<Room> {
  final String id;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool needsSync;
  const Room(
      {required this.id,
      required this.name,
      required this.createdAt,
      required this.updatedAt,
      required this.needsSync});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['needs_sync'] = Variable<bool>(needsSync);
    return map;
  }

  RoomsCompanion toCompanion(bool nullToAbsent) {
    return RoomsCompanion(
      id: Value(id),
      name: Value(name),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      needsSync: Value(needsSync),
    );
  }

  factory Room.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Room(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      needsSync: serializer.fromJson<bool>(json['needsSync']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'needsSync': serializer.toJson<bool>(needsSync),
    };
  }

  Room copyWith(
          {String? id,
          String? name,
          DateTime? createdAt,
          DateTime? updatedAt,
          bool? needsSync}) =>
      Room(
        id: id ?? this.id,
        name: name ?? this.name,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        needsSync: needsSync ?? this.needsSync,
      );
  Room copyWithCompanion(RoomsCompanion data) {
    return Room(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      needsSync: data.needsSync.present ? data.needsSync.value : this.needsSync,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Room(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('needsSync: $needsSync')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, createdAt, updatedAt, needsSync);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Room &&
          other.id == this.id &&
          other.name == this.name &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.needsSync == this.needsSync);
}

class RoomsCompanion extends UpdateCompanion<Room> {
  final Value<String> id;
  final Value<String> name;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<bool> needsSync;
  final Value<int> rowid;
  const RoomsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.needsSync = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RoomsCompanion.insert({
    required String id,
    required String name,
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.needsSync = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name);
  static Insertable<Room> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<bool>? needsSync,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (needsSync != null) 'needs_sync': needsSync,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RoomsCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<bool>? needsSync,
      Value<int>? rowid}) {
    return RoomsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      needsSync: needsSync ?? this.needsSync,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (needsSync.present) {
      map['needs_sync'] = Variable<bool>(needsSync.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RoomsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('needsSync: $needsSync, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PatientsTable extends Patients with TableInfo<$PatientsTable, Patient> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PatientsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _codeMeta = const VerificationMeta('code');
  @override
  late final GeneratedColumn<int> code = GeneratedColumn<int>(
      'code', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _barcodeMeta =
      const VerificationMeta('barcode');
  @override
  late final GeneratedColumn<String> barcode = GeneratedColumn<String>(
      'barcode', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 8, maxTextLength: 8),
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _firstNameMeta =
      const VerificationMeta('firstName');
  @override
  late final GeneratedColumn<String> firstName = GeneratedColumn<String>(
      'first_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _lastNameMeta =
      const VerificationMeta('lastName');
  @override
  late final GeneratedColumn<String> lastName = GeneratedColumn<String>(
      'last_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _ageMeta = const VerificationMeta('age');
  @override
  late final GeneratedColumn<int> age = GeneratedColumn<int>(
      'age', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _dateOfBirthMeta =
      const VerificationMeta('dateOfBirth');
  @override
  late final GeneratedColumn<DateTime> dateOfBirth = GeneratedColumn<DateTime>(
      'date_of_birth', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _addressMeta =
      const VerificationMeta('address');
  @override
  late final GeneratedColumn<String> address = GeneratedColumn<String>(
      'address', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _phoneNumberMeta =
      const VerificationMeta('phoneNumber');
  @override
  late final GeneratedColumn<String> phoneNumber = GeneratedColumn<String>(
      'phone_number', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _otherInfoMeta =
      const VerificationMeta('otherInfo');
  @override
  late final GeneratedColumn<String> otherInfo = GeneratedColumn<String>(
      'other_info', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _needsSyncMeta =
      const VerificationMeta('needsSync');
  @override
  late final GeneratedColumn<bool> needsSync = GeneratedColumn<bool>(
      'needs_sync', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("needs_sync" IN (0, 1))'),
      defaultValue: const Constant(true));
  @override
  List<GeneratedColumn> get $columns => [
        code,
        barcode,
        createdAt,
        firstName,
        lastName,
        age,
        dateOfBirth,
        address,
        phoneNumber,
        otherInfo,
        updatedAt,
        needsSync
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'patients';
  @override
  VerificationContext validateIntegrity(Insertable<Patient> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('code')) {
      context.handle(
          _codeMeta, code.isAcceptableOrUnknown(data['code']!, _codeMeta));
    }
    if (data.containsKey('barcode')) {
      context.handle(_barcodeMeta,
          barcode.isAcceptableOrUnknown(data['barcode']!, _barcodeMeta));
    } else if (isInserting) {
      context.missing(_barcodeMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('first_name')) {
      context.handle(_firstNameMeta,
          firstName.isAcceptableOrUnknown(data['first_name']!, _firstNameMeta));
    } else if (isInserting) {
      context.missing(_firstNameMeta);
    }
    if (data.containsKey('last_name')) {
      context.handle(_lastNameMeta,
          lastName.isAcceptableOrUnknown(data['last_name']!, _lastNameMeta));
    } else if (isInserting) {
      context.missing(_lastNameMeta);
    }
    if (data.containsKey('age')) {
      context.handle(
          _ageMeta, age.isAcceptableOrUnknown(data['age']!, _ageMeta));
    }
    if (data.containsKey('date_of_birth')) {
      context.handle(
          _dateOfBirthMeta,
          dateOfBirth.isAcceptableOrUnknown(
              data['date_of_birth']!, _dateOfBirthMeta));
    }
    if (data.containsKey('address')) {
      context.handle(_addressMeta,
          address.isAcceptableOrUnknown(data['address']!, _addressMeta));
    }
    if (data.containsKey('phone_number')) {
      context.handle(
          _phoneNumberMeta,
          phoneNumber.isAcceptableOrUnknown(
              data['phone_number']!, _phoneNumberMeta));
    }
    if (data.containsKey('other_info')) {
      context.handle(_otherInfoMeta,
          otherInfo.isAcceptableOrUnknown(data['other_info']!, _otherInfoMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('needs_sync')) {
      context.handle(_needsSyncMeta,
          needsSync.isAcceptableOrUnknown(data['needs_sync']!, _needsSyncMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {code};
  @override
  Patient map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Patient(
      code: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}code'])!,
      barcode: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}barcode'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      firstName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}first_name'])!,
      lastName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}last_name'])!,
      age: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}age']),
      dateOfBirth: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}date_of_birth']),
      address: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}address']),
      phoneNumber: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}phone_number']),
      otherInfo: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}other_info']),
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      needsSync: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}needs_sync'])!,
    );
  }

  @override
  $PatientsTable createAlias(String alias) {
    return $PatientsTable(attachedDatabase, alias);
  }
}

class Patient extends DataClass implements Insertable<Patient> {
  /// Patient code (sequential number, shown in N° column)
  final int code;

  /// Unique barcode (8 characters like "0v4c+wLj")
  final String barcode;

  /// Date of creation
  final DateTime createdAt;

  /// First name (required)
  final String firstName;

  /// Last name (required)
  final String lastName;

  /// Age (optional)
  final int? age;

  /// Date of birth (optional, for age calculation)
  final DateTime? dateOfBirth;

  /// Address (optional)
  final String? address;

  /// Phone number (optional)
  final String? phoneNumber;

  /// Other info (optional)
  final String? otherInfo;

  /// Last update timestamp
  final DateTime updatedAt;

  /// Sync flag for cloud/LAN sync
  final bool needsSync;
  const Patient(
      {required this.code,
      required this.barcode,
      required this.createdAt,
      required this.firstName,
      required this.lastName,
      this.age,
      this.dateOfBirth,
      this.address,
      this.phoneNumber,
      this.otherInfo,
      required this.updatedAt,
      required this.needsSync});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['code'] = Variable<int>(code);
    map['barcode'] = Variable<String>(barcode);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['first_name'] = Variable<String>(firstName);
    map['last_name'] = Variable<String>(lastName);
    if (!nullToAbsent || age != null) {
      map['age'] = Variable<int>(age);
    }
    if (!nullToAbsent || dateOfBirth != null) {
      map['date_of_birth'] = Variable<DateTime>(dateOfBirth);
    }
    if (!nullToAbsent || address != null) {
      map['address'] = Variable<String>(address);
    }
    if (!nullToAbsent || phoneNumber != null) {
      map['phone_number'] = Variable<String>(phoneNumber);
    }
    if (!nullToAbsent || otherInfo != null) {
      map['other_info'] = Variable<String>(otherInfo);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['needs_sync'] = Variable<bool>(needsSync);
    return map;
  }

  PatientsCompanion toCompanion(bool nullToAbsent) {
    return PatientsCompanion(
      code: Value(code),
      barcode: Value(barcode),
      createdAt: Value(createdAt),
      firstName: Value(firstName),
      lastName: Value(lastName),
      age: age == null && nullToAbsent ? const Value.absent() : Value(age),
      dateOfBirth: dateOfBirth == null && nullToAbsent
          ? const Value.absent()
          : Value(dateOfBirth),
      address: address == null && nullToAbsent
          ? const Value.absent()
          : Value(address),
      phoneNumber: phoneNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(phoneNumber),
      otherInfo: otherInfo == null && nullToAbsent
          ? const Value.absent()
          : Value(otherInfo),
      updatedAt: Value(updatedAt),
      needsSync: Value(needsSync),
    );
  }

  factory Patient.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Patient(
      code: serializer.fromJson<int>(json['code']),
      barcode: serializer.fromJson<String>(json['barcode']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      firstName: serializer.fromJson<String>(json['firstName']),
      lastName: serializer.fromJson<String>(json['lastName']),
      age: serializer.fromJson<int?>(json['age']),
      dateOfBirth: serializer.fromJson<DateTime?>(json['dateOfBirth']),
      address: serializer.fromJson<String?>(json['address']),
      phoneNumber: serializer.fromJson<String?>(json['phoneNumber']),
      otherInfo: serializer.fromJson<String?>(json['otherInfo']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      needsSync: serializer.fromJson<bool>(json['needsSync']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'code': serializer.toJson<int>(code),
      'barcode': serializer.toJson<String>(barcode),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'firstName': serializer.toJson<String>(firstName),
      'lastName': serializer.toJson<String>(lastName),
      'age': serializer.toJson<int?>(age),
      'dateOfBirth': serializer.toJson<DateTime?>(dateOfBirth),
      'address': serializer.toJson<String?>(address),
      'phoneNumber': serializer.toJson<String?>(phoneNumber),
      'otherInfo': serializer.toJson<String?>(otherInfo),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'needsSync': serializer.toJson<bool>(needsSync),
    };
  }

  Patient copyWith(
          {int? code,
          String? barcode,
          DateTime? createdAt,
          String? firstName,
          String? lastName,
          Value<int?> age = const Value.absent(),
          Value<DateTime?> dateOfBirth = const Value.absent(),
          Value<String?> address = const Value.absent(),
          Value<String?> phoneNumber = const Value.absent(),
          Value<String?> otherInfo = const Value.absent(),
          DateTime? updatedAt,
          bool? needsSync}) =>
      Patient(
        code: code ?? this.code,
        barcode: barcode ?? this.barcode,
        createdAt: createdAt ?? this.createdAt,
        firstName: firstName ?? this.firstName,
        lastName: lastName ?? this.lastName,
        age: age.present ? age.value : this.age,
        dateOfBirth: dateOfBirth.present ? dateOfBirth.value : this.dateOfBirth,
        address: address.present ? address.value : this.address,
        phoneNumber: phoneNumber.present ? phoneNumber.value : this.phoneNumber,
        otherInfo: otherInfo.present ? otherInfo.value : this.otherInfo,
        updatedAt: updatedAt ?? this.updatedAt,
        needsSync: needsSync ?? this.needsSync,
      );
  Patient copyWithCompanion(PatientsCompanion data) {
    return Patient(
      code: data.code.present ? data.code.value : this.code,
      barcode: data.barcode.present ? data.barcode.value : this.barcode,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      firstName: data.firstName.present ? data.firstName.value : this.firstName,
      lastName: data.lastName.present ? data.lastName.value : this.lastName,
      age: data.age.present ? data.age.value : this.age,
      dateOfBirth:
          data.dateOfBirth.present ? data.dateOfBirth.value : this.dateOfBirth,
      address: data.address.present ? data.address.value : this.address,
      phoneNumber:
          data.phoneNumber.present ? data.phoneNumber.value : this.phoneNumber,
      otherInfo: data.otherInfo.present ? data.otherInfo.value : this.otherInfo,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      needsSync: data.needsSync.present ? data.needsSync.value : this.needsSync,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Patient(')
          ..write('code: $code, ')
          ..write('barcode: $barcode, ')
          ..write('createdAt: $createdAt, ')
          ..write('firstName: $firstName, ')
          ..write('lastName: $lastName, ')
          ..write('age: $age, ')
          ..write('dateOfBirth: $dateOfBirth, ')
          ..write('address: $address, ')
          ..write('phoneNumber: $phoneNumber, ')
          ..write('otherInfo: $otherInfo, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('needsSync: $needsSync')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(code, barcode, createdAt, firstName, lastName,
      age, dateOfBirth, address, phoneNumber, otherInfo, updatedAt, needsSync);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Patient &&
          other.code == this.code &&
          other.barcode == this.barcode &&
          other.createdAt == this.createdAt &&
          other.firstName == this.firstName &&
          other.lastName == this.lastName &&
          other.age == this.age &&
          other.dateOfBirth == this.dateOfBirth &&
          other.address == this.address &&
          other.phoneNumber == this.phoneNumber &&
          other.otherInfo == this.otherInfo &&
          other.updatedAt == this.updatedAt &&
          other.needsSync == this.needsSync);
}

class PatientsCompanion extends UpdateCompanion<Patient> {
  final Value<int> code;
  final Value<String> barcode;
  final Value<DateTime> createdAt;
  final Value<String> firstName;
  final Value<String> lastName;
  final Value<int?> age;
  final Value<DateTime?> dateOfBirth;
  final Value<String?> address;
  final Value<String?> phoneNumber;
  final Value<String?> otherInfo;
  final Value<DateTime> updatedAt;
  final Value<bool> needsSync;
  const PatientsCompanion({
    this.code = const Value.absent(),
    this.barcode = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.firstName = const Value.absent(),
    this.lastName = const Value.absent(),
    this.age = const Value.absent(),
    this.dateOfBirth = const Value.absent(),
    this.address = const Value.absent(),
    this.phoneNumber = const Value.absent(),
    this.otherInfo = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.needsSync = const Value.absent(),
  });
  PatientsCompanion.insert({
    this.code = const Value.absent(),
    required String barcode,
    required DateTime createdAt,
    required String firstName,
    required String lastName,
    this.age = const Value.absent(),
    this.dateOfBirth = const Value.absent(),
    this.address = const Value.absent(),
    this.phoneNumber = const Value.absent(),
    this.otherInfo = const Value.absent(),
    required DateTime updatedAt,
    this.needsSync = const Value.absent(),
  })  : barcode = Value(barcode),
        createdAt = Value(createdAt),
        firstName = Value(firstName),
        lastName = Value(lastName),
        updatedAt = Value(updatedAt);
  static Insertable<Patient> custom({
    Expression<int>? code,
    Expression<String>? barcode,
    Expression<DateTime>? createdAt,
    Expression<String>? firstName,
    Expression<String>? lastName,
    Expression<int>? age,
    Expression<DateTime>? dateOfBirth,
    Expression<String>? address,
    Expression<String>? phoneNumber,
    Expression<String>? otherInfo,
    Expression<DateTime>? updatedAt,
    Expression<bool>? needsSync,
  }) {
    return RawValuesInsertable({
      if (code != null) 'code': code,
      if (barcode != null) 'barcode': barcode,
      if (createdAt != null) 'created_at': createdAt,
      if (firstName != null) 'first_name': firstName,
      if (lastName != null) 'last_name': lastName,
      if (age != null) 'age': age,
      if (dateOfBirth != null) 'date_of_birth': dateOfBirth,
      if (address != null) 'address': address,
      if (phoneNumber != null) 'phone_number': phoneNumber,
      if (otherInfo != null) 'other_info': otherInfo,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (needsSync != null) 'needs_sync': needsSync,
    });
  }

  PatientsCompanion copyWith(
      {Value<int>? code,
      Value<String>? barcode,
      Value<DateTime>? createdAt,
      Value<String>? firstName,
      Value<String>? lastName,
      Value<int?>? age,
      Value<DateTime?>? dateOfBirth,
      Value<String?>? address,
      Value<String?>? phoneNumber,
      Value<String?>? otherInfo,
      Value<DateTime>? updatedAt,
      Value<bool>? needsSync}) {
    return PatientsCompanion(
      code: code ?? this.code,
      barcode: barcode ?? this.barcode,
      createdAt: createdAt ?? this.createdAt,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      age: age ?? this.age,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      address: address ?? this.address,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      otherInfo: otherInfo ?? this.otherInfo,
      updatedAt: updatedAt ?? this.updatedAt,
      needsSync: needsSync ?? this.needsSync,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (code.present) {
      map['code'] = Variable<int>(code.value);
    }
    if (barcode.present) {
      map['barcode'] = Variable<String>(barcode.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (firstName.present) {
      map['first_name'] = Variable<String>(firstName.value);
    }
    if (lastName.present) {
      map['last_name'] = Variable<String>(lastName.value);
    }
    if (age.present) {
      map['age'] = Variable<int>(age.value);
    }
    if (dateOfBirth.present) {
      map['date_of_birth'] = Variable<DateTime>(dateOfBirth.value);
    }
    if (address.present) {
      map['address'] = Variable<String>(address.value);
    }
    if (phoneNumber.present) {
      map['phone_number'] = Variable<String>(phoneNumber.value);
    }
    if (otherInfo.present) {
      map['other_info'] = Variable<String>(otherInfo.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (needsSync.present) {
      map['needs_sync'] = Variable<bool>(needsSync.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PatientsCompanion(')
          ..write('code: $code, ')
          ..write('barcode: $barcode, ')
          ..write('createdAt: $createdAt, ')
          ..write('firstName: $firstName, ')
          ..write('lastName: $lastName, ')
          ..write('age: $age, ')
          ..write('dateOfBirth: $dateOfBirth, ')
          ..write('address: $address, ')
          ..write('phoneNumber: $phoneNumber, ')
          ..write('otherInfo: $otherInfo, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('needsSync: $needsSync')
          ..write(')'))
        .toString();
  }
}

class $MessageTemplatesTable extends MessageTemplates
    with TableInfo<$MessageTemplatesTable, MessageTemplate> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MessageTemplatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _contentMeta =
      const VerificationMeta('content');
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
      'content', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _displayOrderMeta =
      const VerificationMeta('displayOrder');
  @override
  late final GeneratedColumn<int> displayOrder = GeneratedColumn<int>(
      'display_order', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _createdByMeta =
      const VerificationMeta('createdBy');
  @override
  late final GeneratedColumn<String> createdBy = GeneratedColumn<String>(
      'created_by', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [id, content, displayOrder, createdAt, createdBy];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'message_templates';
  @override
  VerificationContext validateIntegrity(Insertable<MessageTemplate> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('content')) {
      context.handle(_contentMeta,
          content.isAcceptableOrUnknown(data['content']!, _contentMeta));
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('display_order')) {
      context.handle(
          _displayOrderMeta,
          displayOrder.isAcceptableOrUnknown(
              data['display_order']!, _displayOrderMeta));
    } else if (isInserting) {
      context.missing(_displayOrderMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('created_by')) {
      context.handle(_createdByMeta,
          createdBy.isAcceptableOrUnknown(data['created_by']!, _createdByMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MessageTemplate map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MessageTemplate(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      content: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}content'])!,
      displayOrder: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}display_order'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      createdBy: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}created_by']),
    );
  }

  @override
  $MessageTemplatesTable createAlias(String alias) {
    return $MessageTemplatesTable(attachedDatabase, alias);
  }
}

class MessageTemplate extends DataClass implements Insertable<MessageTemplate> {
  /// Unique ID
  final int id;

  /// Template text content
  final String content;

  /// Display order
  final int displayOrder;

  /// Creation timestamp
  final DateTime createdAt;

  /// User who created it (null = system default)
  final String? createdBy;
  const MessageTemplate(
      {required this.id,
      required this.content,
      required this.displayOrder,
      required this.createdAt,
      this.createdBy});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['content'] = Variable<String>(content);
    map['display_order'] = Variable<int>(displayOrder);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || createdBy != null) {
      map['created_by'] = Variable<String>(createdBy);
    }
    return map;
  }

  MessageTemplatesCompanion toCompanion(bool nullToAbsent) {
    return MessageTemplatesCompanion(
      id: Value(id),
      content: Value(content),
      displayOrder: Value(displayOrder),
      createdAt: Value(createdAt),
      createdBy: createdBy == null && nullToAbsent
          ? const Value.absent()
          : Value(createdBy),
    );
  }

  factory MessageTemplate.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MessageTemplate(
      id: serializer.fromJson<int>(json['id']),
      content: serializer.fromJson<String>(json['content']),
      displayOrder: serializer.fromJson<int>(json['displayOrder']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      createdBy: serializer.fromJson<String?>(json['createdBy']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'content': serializer.toJson<String>(content),
      'displayOrder': serializer.toJson<int>(displayOrder),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'createdBy': serializer.toJson<String?>(createdBy),
    };
  }

  MessageTemplate copyWith(
          {int? id,
          String? content,
          int? displayOrder,
          DateTime? createdAt,
          Value<String?> createdBy = const Value.absent()}) =>
      MessageTemplate(
        id: id ?? this.id,
        content: content ?? this.content,
        displayOrder: displayOrder ?? this.displayOrder,
        createdAt: createdAt ?? this.createdAt,
        createdBy: createdBy.present ? createdBy.value : this.createdBy,
      );
  MessageTemplate copyWithCompanion(MessageTemplatesCompanion data) {
    return MessageTemplate(
      id: data.id.present ? data.id.value : this.id,
      content: data.content.present ? data.content.value : this.content,
      displayOrder: data.displayOrder.present
          ? data.displayOrder.value
          : this.displayOrder,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      createdBy: data.createdBy.present ? data.createdBy.value : this.createdBy,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MessageTemplate(')
          ..write('id: $id, ')
          ..write('content: $content, ')
          ..write('displayOrder: $displayOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('createdBy: $createdBy')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, content, displayOrder, createdAt, createdBy);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MessageTemplate &&
          other.id == this.id &&
          other.content == this.content &&
          other.displayOrder == this.displayOrder &&
          other.createdAt == this.createdAt &&
          other.createdBy == this.createdBy);
}

class MessageTemplatesCompanion extends UpdateCompanion<MessageTemplate> {
  final Value<int> id;
  final Value<String> content;
  final Value<int> displayOrder;
  final Value<DateTime> createdAt;
  final Value<String?> createdBy;
  const MessageTemplatesCompanion({
    this.id = const Value.absent(),
    this.content = const Value.absent(),
    this.displayOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.createdBy = const Value.absent(),
  });
  MessageTemplatesCompanion.insert({
    this.id = const Value.absent(),
    required String content,
    required int displayOrder,
    required DateTime createdAt,
    this.createdBy = const Value.absent(),
  })  : content = Value(content),
        displayOrder = Value(displayOrder),
        createdAt = Value(createdAt);
  static Insertable<MessageTemplate> custom({
    Expression<int>? id,
    Expression<String>? content,
    Expression<int>? displayOrder,
    Expression<DateTime>? createdAt,
    Expression<String>? createdBy,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (content != null) 'content': content,
      if (displayOrder != null) 'display_order': displayOrder,
      if (createdAt != null) 'created_at': createdAt,
      if (createdBy != null) 'created_by': createdBy,
    });
  }

  MessageTemplatesCompanion copyWith(
      {Value<int>? id,
      Value<String>? content,
      Value<int>? displayOrder,
      Value<DateTime>? createdAt,
      Value<String?>? createdBy}) {
    return MessageTemplatesCompanion(
      id: id ?? this.id,
      content: content ?? this.content,
      displayOrder: displayOrder ?? this.displayOrder,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (displayOrder.present) {
      map['display_order'] = Variable<int>(displayOrder.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (createdBy.present) {
      map['created_by'] = Variable<String>(createdBy.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MessageTemplatesCompanion(')
          ..write('id: $id, ')
          ..write('content: $content, ')
          ..write('displayOrder: $displayOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('createdBy: $createdBy')
          ..write(')'))
        .toString();
  }
}

class $MessagesTable extends Messages with TableInfo<$MessagesTable, Message> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MessagesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _roomIdMeta = const VerificationMeta('roomId');
  @override
  late final GeneratedColumn<String> roomId = GeneratedColumn<String>(
      'room_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _senderIdMeta =
      const VerificationMeta('senderId');
  @override
  late final GeneratedColumn<String> senderId = GeneratedColumn<String>(
      'sender_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _senderNameMeta =
      const VerificationMeta('senderName');
  @override
  late final GeneratedColumn<String> senderName = GeneratedColumn<String>(
      'sender_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _senderRoleMeta =
      const VerificationMeta('senderRole');
  @override
  late final GeneratedColumn<String> senderRole = GeneratedColumn<String>(
      'sender_role', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _contentMeta =
      const VerificationMeta('content');
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
      'content', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _directionMeta =
      const VerificationMeta('direction');
  @override
  late final GeneratedColumn<String> direction = GeneratedColumn<String>(
      'direction', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _isReadMeta = const VerificationMeta('isRead');
  @override
  late final GeneratedColumn<bool> isRead = GeneratedColumn<bool>(
      'is_read', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_read" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _sentAtMeta = const VerificationMeta('sentAt');
  @override
  late final GeneratedColumn<DateTime> sentAt = GeneratedColumn<DateTime>(
      'sent_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _readAtMeta = const VerificationMeta('readAt');
  @override
  late final GeneratedColumn<DateTime> readAt = GeneratedColumn<DateTime>(
      'read_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _patientCodeMeta =
      const VerificationMeta('patientCode');
  @override
  late final GeneratedColumn<int> patientCode = GeneratedColumn<int>(
      'patient_code', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _patientNameMeta =
      const VerificationMeta('patientName');
  @override
  late final GeneratedColumn<String> patientName = GeneratedColumn<String>(
      'patient_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        roomId,
        senderId,
        senderName,
        senderRole,
        content,
        direction,
        isRead,
        sentAt,
        readAt,
        patientCode,
        patientName
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'messages';
  @override
  VerificationContext validateIntegrity(Insertable<Message> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('room_id')) {
      context.handle(_roomIdMeta,
          roomId.isAcceptableOrUnknown(data['room_id']!, _roomIdMeta));
    } else if (isInserting) {
      context.missing(_roomIdMeta);
    }
    if (data.containsKey('sender_id')) {
      context.handle(_senderIdMeta,
          senderId.isAcceptableOrUnknown(data['sender_id']!, _senderIdMeta));
    } else if (isInserting) {
      context.missing(_senderIdMeta);
    }
    if (data.containsKey('sender_name')) {
      context.handle(
          _senderNameMeta,
          senderName.isAcceptableOrUnknown(
              data['sender_name']!, _senderNameMeta));
    } else if (isInserting) {
      context.missing(_senderNameMeta);
    }
    if (data.containsKey('sender_role')) {
      context.handle(
          _senderRoleMeta,
          senderRole.isAcceptableOrUnknown(
              data['sender_role']!, _senderRoleMeta));
    } else if (isInserting) {
      context.missing(_senderRoleMeta);
    }
    if (data.containsKey('content')) {
      context.handle(_contentMeta,
          content.isAcceptableOrUnknown(data['content']!, _contentMeta));
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('direction')) {
      context.handle(_directionMeta,
          direction.isAcceptableOrUnknown(data['direction']!, _directionMeta));
    } else if (isInserting) {
      context.missing(_directionMeta);
    }
    if (data.containsKey('is_read')) {
      context.handle(_isReadMeta,
          isRead.isAcceptableOrUnknown(data['is_read']!, _isReadMeta));
    }
    if (data.containsKey('sent_at')) {
      context.handle(_sentAtMeta,
          sentAt.isAcceptableOrUnknown(data['sent_at']!, _sentAtMeta));
    } else if (isInserting) {
      context.missing(_sentAtMeta);
    }
    if (data.containsKey('read_at')) {
      context.handle(_readAtMeta,
          readAt.isAcceptableOrUnknown(data['read_at']!, _readAtMeta));
    }
    if (data.containsKey('patient_code')) {
      context.handle(
          _patientCodeMeta,
          patientCode.isAcceptableOrUnknown(
              data['patient_code']!, _patientCodeMeta));
    }
    if (data.containsKey('patient_name')) {
      context.handle(
          _patientNameMeta,
          patientName.isAcceptableOrUnknown(
              data['patient_name']!, _patientNameMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Message map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Message(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      roomId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}room_id'])!,
      senderId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sender_id'])!,
      senderName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sender_name'])!,
      senderRole: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sender_role'])!,
      content: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}content'])!,
      direction: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}direction'])!,
      isRead: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_read'])!,
      sentAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}sent_at'])!,
      readAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}read_at']),
      patientCode: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}patient_code']),
      patientName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}patient_name']),
    );
  }

  @override
  $MessagesTable createAlias(String alias) {
    return $MessagesTable(attachedDatabase, alias);
  }
}

class Message extends DataClass implements Insertable<Message> {
  /// Unique message ID
  final int id;

  /// Room ID where message is sent from/to
  final String roomId;

  /// Sender user ID
  final String senderId;

  /// Sender name (for display)
  final String senderName;

  /// Sender role (for display)
  final String senderRole;

  /// Message content
  final String content;

  /// Message direction: 'to_nurse' or 'to_doctor'
  final String direction;

  /// Whether message has been read
  final bool isRead;

  /// When message was sent
  final DateTime sentAt;

  /// When message was read (null if unread)
  final DateTime? readAt;

  /// Patient code (optional - set when message sent from consultation page)
  final int? patientCode;

  /// Patient name for display (optional - "FirstName LastName")
  final String? patientName;
  const Message(
      {required this.id,
      required this.roomId,
      required this.senderId,
      required this.senderName,
      required this.senderRole,
      required this.content,
      required this.direction,
      required this.isRead,
      required this.sentAt,
      this.readAt,
      this.patientCode,
      this.patientName});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['room_id'] = Variable<String>(roomId);
    map['sender_id'] = Variable<String>(senderId);
    map['sender_name'] = Variable<String>(senderName);
    map['sender_role'] = Variable<String>(senderRole);
    map['content'] = Variable<String>(content);
    map['direction'] = Variable<String>(direction);
    map['is_read'] = Variable<bool>(isRead);
    map['sent_at'] = Variable<DateTime>(sentAt);
    if (!nullToAbsent || readAt != null) {
      map['read_at'] = Variable<DateTime>(readAt);
    }
    if (!nullToAbsent || patientCode != null) {
      map['patient_code'] = Variable<int>(patientCode);
    }
    if (!nullToAbsent || patientName != null) {
      map['patient_name'] = Variable<String>(patientName);
    }
    return map;
  }

  MessagesCompanion toCompanion(bool nullToAbsent) {
    return MessagesCompanion(
      id: Value(id),
      roomId: Value(roomId),
      senderId: Value(senderId),
      senderName: Value(senderName),
      senderRole: Value(senderRole),
      content: Value(content),
      direction: Value(direction),
      isRead: Value(isRead),
      sentAt: Value(sentAt),
      readAt:
          readAt == null && nullToAbsent ? const Value.absent() : Value(readAt),
      patientCode: patientCode == null && nullToAbsent
          ? const Value.absent()
          : Value(patientCode),
      patientName: patientName == null && nullToAbsent
          ? const Value.absent()
          : Value(patientName),
    );
  }

  factory Message.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Message(
      id: serializer.fromJson<int>(json['id']),
      roomId: serializer.fromJson<String>(json['roomId']),
      senderId: serializer.fromJson<String>(json['senderId']),
      senderName: serializer.fromJson<String>(json['senderName']),
      senderRole: serializer.fromJson<String>(json['senderRole']),
      content: serializer.fromJson<String>(json['content']),
      direction: serializer.fromJson<String>(json['direction']),
      isRead: serializer.fromJson<bool>(json['isRead']),
      sentAt: serializer.fromJson<DateTime>(json['sentAt']),
      readAt: serializer.fromJson<DateTime?>(json['readAt']),
      patientCode: serializer.fromJson<int?>(json['patientCode']),
      patientName: serializer.fromJson<String?>(json['patientName']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'roomId': serializer.toJson<String>(roomId),
      'senderId': serializer.toJson<String>(senderId),
      'senderName': serializer.toJson<String>(senderName),
      'senderRole': serializer.toJson<String>(senderRole),
      'content': serializer.toJson<String>(content),
      'direction': serializer.toJson<String>(direction),
      'isRead': serializer.toJson<bool>(isRead),
      'sentAt': serializer.toJson<DateTime>(sentAt),
      'readAt': serializer.toJson<DateTime?>(readAt),
      'patientCode': serializer.toJson<int?>(patientCode),
      'patientName': serializer.toJson<String?>(patientName),
    };
  }

  Message copyWith(
          {int? id,
          String? roomId,
          String? senderId,
          String? senderName,
          String? senderRole,
          String? content,
          String? direction,
          bool? isRead,
          DateTime? sentAt,
          Value<DateTime?> readAt = const Value.absent(),
          Value<int?> patientCode = const Value.absent(),
          Value<String?> patientName = const Value.absent()}) =>
      Message(
        id: id ?? this.id,
        roomId: roomId ?? this.roomId,
        senderId: senderId ?? this.senderId,
        senderName: senderName ?? this.senderName,
        senderRole: senderRole ?? this.senderRole,
        content: content ?? this.content,
        direction: direction ?? this.direction,
        isRead: isRead ?? this.isRead,
        sentAt: sentAt ?? this.sentAt,
        readAt: readAt.present ? readAt.value : this.readAt,
        patientCode: patientCode.present ? patientCode.value : this.patientCode,
        patientName: patientName.present ? patientName.value : this.patientName,
      );
  Message copyWithCompanion(MessagesCompanion data) {
    return Message(
      id: data.id.present ? data.id.value : this.id,
      roomId: data.roomId.present ? data.roomId.value : this.roomId,
      senderId: data.senderId.present ? data.senderId.value : this.senderId,
      senderName:
          data.senderName.present ? data.senderName.value : this.senderName,
      senderRole:
          data.senderRole.present ? data.senderRole.value : this.senderRole,
      content: data.content.present ? data.content.value : this.content,
      direction: data.direction.present ? data.direction.value : this.direction,
      isRead: data.isRead.present ? data.isRead.value : this.isRead,
      sentAt: data.sentAt.present ? data.sentAt.value : this.sentAt,
      readAt: data.readAt.present ? data.readAt.value : this.readAt,
      patientCode:
          data.patientCode.present ? data.patientCode.value : this.patientCode,
      patientName:
          data.patientName.present ? data.patientName.value : this.patientName,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Message(')
          ..write('id: $id, ')
          ..write('roomId: $roomId, ')
          ..write('senderId: $senderId, ')
          ..write('senderName: $senderName, ')
          ..write('senderRole: $senderRole, ')
          ..write('content: $content, ')
          ..write('direction: $direction, ')
          ..write('isRead: $isRead, ')
          ..write('sentAt: $sentAt, ')
          ..write('readAt: $readAt, ')
          ..write('patientCode: $patientCode, ')
          ..write('patientName: $patientName')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, roomId, senderId, senderName, senderRole,
      content, direction, isRead, sentAt, readAt, patientCode, patientName);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Message &&
          other.id == this.id &&
          other.roomId == this.roomId &&
          other.senderId == this.senderId &&
          other.senderName == this.senderName &&
          other.senderRole == this.senderRole &&
          other.content == this.content &&
          other.direction == this.direction &&
          other.isRead == this.isRead &&
          other.sentAt == this.sentAt &&
          other.readAt == this.readAt &&
          other.patientCode == this.patientCode &&
          other.patientName == this.patientName);
}

class MessagesCompanion extends UpdateCompanion<Message> {
  final Value<int> id;
  final Value<String> roomId;
  final Value<String> senderId;
  final Value<String> senderName;
  final Value<String> senderRole;
  final Value<String> content;
  final Value<String> direction;
  final Value<bool> isRead;
  final Value<DateTime> sentAt;
  final Value<DateTime?> readAt;
  final Value<int?> patientCode;
  final Value<String?> patientName;
  const MessagesCompanion({
    this.id = const Value.absent(),
    this.roomId = const Value.absent(),
    this.senderId = const Value.absent(),
    this.senderName = const Value.absent(),
    this.senderRole = const Value.absent(),
    this.content = const Value.absent(),
    this.direction = const Value.absent(),
    this.isRead = const Value.absent(),
    this.sentAt = const Value.absent(),
    this.readAt = const Value.absent(),
    this.patientCode = const Value.absent(),
    this.patientName = const Value.absent(),
  });
  MessagesCompanion.insert({
    this.id = const Value.absent(),
    required String roomId,
    required String senderId,
    required String senderName,
    required String senderRole,
    required String content,
    required String direction,
    this.isRead = const Value.absent(),
    required DateTime sentAt,
    this.readAt = const Value.absent(),
    this.patientCode = const Value.absent(),
    this.patientName = const Value.absent(),
  })  : roomId = Value(roomId),
        senderId = Value(senderId),
        senderName = Value(senderName),
        senderRole = Value(senderRole),
        content = Value(content),
        direction = Value(direction),
        sentAt = Value(sentAt);
  static Insertable<Message> custom({
    Expression<int>? id,
    Expression<String>? roomId,
    Expression<String>? senderId,
    Expression<String>? senderName,
    Expression<String>? senderRole,
    Expression<String>? content,
    Expression<String>? direction,
    Expression<bool>? isRead,
    Expression<DateTime>? sentAt,
    Expression<DateTime>? readAt,
    Expression<int>? patientCode,
    Expression<String>? patientName,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (roomId != null) 'room_id': roomId,
      if (senderId != null) 'sender_id': senderId,
      if (senderName != null) 'sender_name': senderName,
      if (senderRole != null) 'sender_role': senderRole,
      if (content != null) 'content': content,
      if (direction != null) 'direction': direction,
      if (isRead != null) 'is_read': isRead,
      if (sentAt != null) 'sent_at': sentAt,
      if (readAt != null) 'read_at': readAt,
      if (patientCode != null) 'patient_code': patientCode,
      if (patientName != null) 'patient_name': patientName,
    });
  }

  MessagesCompanion copyWith(
      {Value<int>? id,
      Value<String>? roomId,
      Value<String>? senderId,
      Value<String>? senderName,
      Value<String>? senderRole,
      Value<String>? content,
      Value<String>? direction,
      Value<bool>? isRead,
      Value<DateTime>? sentAt,
      Value<DateTime?>? readAt,
      Value<int?>? patientCode,
      Value<String?>? patientName}) {
    return MessagesCompanion(
      id: id ?? this.id,
      roomId: roomId ?? this.roomId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderRole: senderRole ?? this.senderRole,
      content: content ?? this.content,
      direction: direction ?? this.direction,
      isRead: isRead ?? this.isRead,
      sentAt: sentAt ?? this.sentAt,
      readAt: readAt ?? this.readAt,
      patientCode: patientCode ?? this.patientCode,
      patientName: patientName ?? this.patientName,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (roomId.present) {
      map['room_id'] = Variable<String>(roomId.value);
    }
    if (senderId.present) {
      map['sender_id'] = Variable<String>(senderId.value);
    }
    if (senderName.present) {
      map['sender_name'] = Variable<String>(senderName.value);
    }
    if (senderRole.present) {
      map['sender_role'] = Variable<String>(senderRole.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (direction.present) {
      map['direction'] = Variable<String>(direction.value);
    }
    if (isRead.present) {
      map['is_read'] = Variable<bool>(isRead.value);
    }
    if (sentAt.present) {
      map['sent_at'] = Variable<DateTime>(sentAt.value);
    }
    if (readAt.present) {
      map['read_at'] = Variable<DateTime>(readAt.value);
    }
    if (patientCode.present) {
      map['patient_code'] = Variable<int>(patientCode.value);
    }
    if (patientName.present) {
      map['patient_name'] = Variable<String>(patientName.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MessagesCompanion(')
          ..write('id: $id, ')
          ..write('roomId: $roomId, ')
          ..write('senderId: $senderId, ')
          ..write('senderName: $senderName, ')
          ..write('senderRole: $senderRole, ')
          ..write('content: $content, ')
          ..write('direction: $direction, ')
          ..write('isRead: $isRead, ')
          ..write('sentAt: $sentAt, ')
          ..write('readAt: $readAt, ')
          ..write('patientCode: $patientCode, ')
          ..write('patientName: $patientName')
          ..write(')'))
        .toString();
  }
}

class $MedicalActsTable extends MedicalActs
    with TableInfo<$MedicalActsTable, MedicalAct> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MedicalActsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _feeAmountMeta =
      const VerificationMeta('feeAmount');
  @override
  late final GeneratedColumn<int> feeAmount = GeneratedColumn<int>(
      'fee_amount', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _displayOrderMeta =
      const VerificationMeta('displayOrder');
  @override
  late final GeneratedColumn<int> displayOrder = GeneratedColumn<int>(
      'display_order', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _isActiveMeta =
      const VerificationMeta('isActive');
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
      'is_active', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_active" IN (0, 1))'),
      defaultValue: const Constant(true));
  @override
  List<GeneratedColumn> get $columns =>
      [id, name, feeAmount, displayOrder, createdAt, updatedAt, isActive];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'medical_acts';
  @override
  VerificationContext validateIntegrity(Insertable<MedicalAct> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('fee_amount')) {
      context.handle(_feeAmountMeta,
          feeAmount.isAcceptableOrUnknown(data['fee_amount']!, _feeAmountMeta));
    } else if (isInserting) {
      context.missing(_feeAmountMeta);
    }
    if (data.containsKey('display_order')) {
      context.handle(
          _displayOrderMeta,
          displayOrder.isAcceptableOrUnknown(
              data['display_order']!, _displayOrderMeta));
    } else if (isInserting) {
      context.missing(_displayOrderMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('is_active')) {
      context.handle(_isActiveMeta,
          isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MedicalAct map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MedicalAct(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      feeAmount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}fee_amount'])!,
      displayOrder: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}display_order'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      isActive: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_active'])!,
    );
  }

  @override
  $MedicalActsTable createAlias(String alias) {
    return $MedicalActsTable(attachedDatabase, alias);
  }
}

class MedicalAct extends DataClass implements Insertable<MedicalAct> {
  /// Unique act ID (sequential, important for other features)
  final int id;

  /// Act name/description (e.g., "CONSULTATION +FO", "OCT", etc.)
  final String name;

  /// Fee amount in DA (Dinar Algérien)
  final int feeAmount;

  /// Display order for the list
  final int displayOrder;

  /// When the act was created
  final DateTime createdAt;

  /// When the act was last modified
  final DateTime updatedAt;

  /// Whether this act is active (soft delete)
  final bool isActive;
  const MedicalAct(
      {required this.id,
      required this.name,
      required this.feeAmount,
      required this.displayOrder,
      required this.createdAt,
      required this.updatedAt,
      required this.isActive});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['fee_amount'] = Variable<int>(feeAmount);
    map['display_order'] = Variable<int>(displayOrder);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['is_active'] = Variable<bool>(isActive);
    return map;
  }

  MedicalActsCompanion toCompanion(bool nullToAbsent) {
    return MedicalActsCompanion(
      id: Value(id),
      name: Value(name),
      feeAmount: Value(feeAmount),
      displayOrder: Value(displayOrder),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      isActive: Value(isActive),
    );
  }

  factory MedicalAct.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MedicalAct(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      feeAmount: serializer.fromJson<int>(json['feeAmount']),
      displayOrder: serializer.fromJson<int>(json['displayOrder']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      isActive: serializer.fromJson<bool>(json['isActive']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'feeAmount': serializer.toJson<int>(feeAmount),
      'displayOrder': serializer.toJson<int>(displayOrder),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'isActive': serializer.toJson<bool>(isActive),
    };
  }

  MedicalAct copyWith(
          {int? id,
          String? name,
          int? feeAmount,
          int? displayOrder,
          DateTime? createdAt,
          DateTime? updatedAt,
          bool? isActive}) =>
      MedicalAct(
        id: id ?? this.id,
        name: name ?? this.name,
        feeAmount: feeAmount ?? this.feeAmount,
        displayOrder: displayOrder ?? this.displayOrder,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        isActive: isActive ?? this.isActive,
      );
  MedicalAct copyWithCompanion(MedicalActsCompanion data) {
    return MedicalAct(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      feeAmount: data.feeAmount.present ? data.feeAmount.value : this.feeAmount,
      displayOrder: data.displayOrder.present
          ? data.displayOrder.value
          : this.displayOrder,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MedicalAct(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('feeAmount: $feeAmount, ')
          ..write('displayOrder: $displayOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isActive: $isActive')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, name, feeAmount, displayOrder, createdAt, updatedAt, isActive);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MedicalAct &&
          other.id == this.id &&
          other.name == this.name &&
          other.feeAmount == this.feeAmount &&
          other.displayOrder == this.displayOrder &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.isActive == this.isActive);
}

class MedicalActsCompanion extends UpdateCompanion<MedicalAct> {
  final Value<int> id;
  final Value<String> name;
  final Value<int> feeAmount;
  final Value<int> displayOrder;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<bool> isActive;
  const MedicalActsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.feeAmount = const Value.absent(),
    this.displayOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.isActive = const Value.absent(),
  });
  MedicalActsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required int feeAmount,
    required int displayOrder,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.isActive = const Value.absent(),
  })  : name = Value(name),
        feeAmount = Value(feeAmount),
        displayOrder = Value(displayOrder),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<MedicalAct> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<int>? feeAmount,
    Expression<int>? displayOrder,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<bool>? isActive,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (feeAmount != null) 'fee_amount': feeAmount,
      if (displayOrder != null) 'display_order': displayOrder,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (isActive != null) 'is_active': isActive,
    });
  }

  MedicalActsCompanion copyWith(
      {Value<int>? id,
      Value<String>? name,
      Value<int>? feeAmount,
      Value<int>? displayOrder,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<bool>? isActive}) {
    return MedicalActsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      feeAmount: feeAmount ?? this.feeAmount,
      displayOrder: displayOrder ?? this.displayOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (feeAmount.present) {
      map['fee_amount'] = Variable<int>(feeAmount.value);
    }
    if (displayOrder.present) {
      map['display_order'] = Variable<int>(displayOrder.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MedicalActsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('feeAmount: $feeAmount, ')
          ..write('displayOrder: $displayOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isActive: $isActive')
          ..write(')'))
        .toString();
  }
}

class $PaymentsTable extends Payments with TableInfo<$PaymentsTable, Payment> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PaymentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _medicalActIdMeta =
      const VerificationMeta('medicalActId');
  @override
  late final GeneratedColumn<int> medicalActId = GeneratedColumn<int>(
      'medical_act_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _medicalActNameMeta =
      const VerificationMeta('medicalActName');
  @override
  late final GeneratedColumn<String> medicalActName = GeneratedColumn<String>(
      'medical_act_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<int> amount = GeneratedColumn<int>(
      'amount', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _userNameMeta =
      const VerificationMeta('userName');
  @override
  late final GeneratedColumn<String> userName = GeneratedColumn<String>(
      'user_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _patientCodeMeta =
      const VerificationMeta('patientCode');
  @override
  late final GeneratedColumn<int> patientCode = GeneratedColumn<int>(
      'patient_code', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _patientFirstNameMeta =
      const VerificationMeta('patientFirstName');
  @override
  late final GeneratedColumn<String> patientFirstName = GeneratedColumn<String>(
      'patient_first_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _patientLastNameMeta =
      const VerificationMeta('patientLastName');
  @override
  late final GeneratedColumn<String> patientLastName = GeneratedColumn<String>(
      'patient_last_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _paymentTimeMeta =
      const VerificationMeta('paymentTime');
  @override
  late final GeneratedColumn<DateTime> paymentTime = GeneratedColumn<DateTime>(
      'payment_time', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _needsSyncMeta =
      const VerificationMeta('needsSync');
  @override
  late final GeneratedColumn<bool> needsSync = GeneratedColumn<bool>(
      'needs_sync', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("needs_sync" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _isActiveMeta =
      const VerificationMeta('isActive');
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
      'is_active', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_active" IN (0, 1))'),
      defaultValue: const Constant(true));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        medicalActId,
        medicalActName,
        amount,
        userId,
        userName,
        patientCode,
        patientFirstName,
        patientLastName,
        paymentTime,
        createdAt,
        updatedAt,
        needsSync,
        isActive
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'payments';
  @override
  VerificationContext validateIntegrity(Insertable<Payment> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('medical_act_id')) {
      context.handle(
          _medicalActIdMeta,
          medicalActId.isAcceptableOrUnknown(
              data['medical_act_id']!, _medicalActIdMeta));
    } else if (isInserting) {
      context.missing(_medicalActIdMeta);
    }
    if (data.containsKey('medical_act_name')) {
      context.handle(
          _medicalActNameMeta,
          medicalActName.isAcceptableOrUnknown(
              data['medical_act_name']!, _medicalActNameMeta));
    } else if (isInserting) {
      context.missing(_medicalActNameMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(_amountMeta,
          amount.isAcceptableOrUnknown(data['amount']!, _amountMeta));
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('user_name')) {
      context.handle(_userNameMeta,
          userName.isAcceptableOrUnknown(data['user_name']!, _userNameMeta));
    } else if (isInserting) {
      context.missing(_userNameMeta);
    }
    if (data.containsKey('patient_code')) {
      context.handle(
          _patientCodeMeta,
          patientCode.isAcceptableOrUnknown(
              data['patient_code']!, _patientCodeMeta));
    } else if (isInserting) {
      context.missing(_patientCodeMeta);
    }
    if (data.containsKey('patient_first_name')) {
      context.handle(
          _patientFirstNameMeta,
          patientFirstName.isAcceptableOrUnknown(
              data['patient_first_name']!, _patientFirstNameMeta));
    } else if (isInserting) {
      context.missing(_patientFirstNameMeta);
    }
    if (data.containsKey('patient_last_name')) {
      context.handle(
          _patientLastNameMeta,
          patientLastName.isAcceptableOrUnknown(
              data['patient_last_name']!, _patientLastNameMeta));
    } else if (isInserting) {
      context.missing(_patientLastNameMeta);
    }
    if (data.containsKey('payment_time')) {
      context.handle(
          _paymentTimeMeta,
          paymentTime.isAcceptableOrUnknown(
              data['payment_time']!, _paymentTimeMeta));
    } else if (isInserting) {
      context.missing(_paymentTimeMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('needs_sync')) {
      context.handle(_needsSyncMeta,
          needsSync.isAcceptableOrUnknown(data['needs_sync']!, _needsSyncMeta));
    }
    if (data.containsKey('is_active')) {
      context.handle(_isActiveMeta,
          isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Payment map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Payment(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      medicalActId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}medical_act_id'])!,
      medicalActName: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}medical_act_name'])!,
      amount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}amount'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      userName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_name'])!,
      patientCode: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}patient_code'])!,
      patientFirstName: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}patient_first_name'])!,
      patientLastName: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}patient_last_name'])!,
      paymentTime: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}payment_time'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      needsSync: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}needs_sync'])!,
      isActive: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_active'])!,
    );
  }

  @override
  $PaymentsTable createAlias(String alias) {
    return $PaymentsTable(attachedDatabase, alias);
  }
}

class Payment extends DataClass implements Insertable<Payment> {
  /// Unique payment ID (sequential, auto-increment)
  final int id;

  /// Medical act ID from medical_acts table
  final int medicalActId;

  /// Medical act name (stored for data integrity and performance)
  /// Even if the act is modified later, this preserves historical data
  final String medicalActName;

  /// Amount charged in DA (stored from medical_acts at time of payment)
  final int amount;

  /// User ID who performed/recorded the payment
  final String userId;

  /// User name (stored for reporting, even if user is deleted later)
  final String userName;

  /// Patient code (foreign key to patients table)
  final int patientCode;

  /// Patient first name (stored for reporting)
  final String patientFirstName;

  /// Patient last name (stored for reporting)
  final String patientLastName;

  /// Payment date and time (with hours for morning/afternoon filtering)
  /// Morning: before 13:00 (1 PM)
  /// Afternoon: 13:00 (1 PM) and later
  final DateTime paymentTime;

  /// When this payment record was created
  final DateTime createdAt;

  /// When this payment record was last modified
  final DateTime updatedAt;

  /// Sync flag for multi-PC synchronization
  final bool needsSync;

  /// Soft delete flag (preserves data integrity for accounting)
  final bool isActive;
  const Payment(
      {required this.id,
      required this.medicalActId,
      required this.medicalActName,
      required this.amount,
      required this.userId,
      required this.userName,
      required this.patientCode,
      required this.patientFirstName,
      required this.patientLastName,
      required this.paymentTime,
      required this.createdAt,
      required this.updatedAt,
      required this.needsSync,
      required this.isActive});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['medical_act_id'] = Variable<int>(medicalActId);
    map['medical_act_name'] = Variable<String>(medicalActName);
    map['amount'] = Variable<int>(amount);
    map['user_id'] = Variable<String>(userId);
    map['user_name'] = Variable<String>(userName);
    map['patient_code'] = Variable<int>(patientCode);
    map['patient_first_name'] = Variable<String>(patientFirstName);
    map['patient_last_name'] = Variable<String>(patientLastName);
    map['payment_time'] = Variable<DateTime>(paymentTime);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['needs_sync'] = Variable<bool>(needsSync);
    map['is_active'] = Variable<bool>(isActive);
    return map;
  }

  PaymentsCompanion toCompanion(bool nullToAbsent) {
    return PaymentsCompanion(
      id: Value(id),
      medicalActId: Value(medicalActId),
      medicalActName: Value(medicalActName),
      amount: Value(amount),
      userId: Value(userId),
      userName: Value(userName),
      patientCode: Value(patientCode),
      patientFirstName: Value(patientFirstName),
      patientLastName: Value(patientLastName),
      paymentTime: Value(paymentTime),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      needsSync: Value(needsSync),
      isActive: Value(isActive),
    );
  }

  factory Payment.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Payment(
      id: serializer.fromJson<int>(json['id']),
      medicalActId: serializer.fromJson<int>(json['medicalActId']),
      medicalActName: serializer.fromJson<String>(json['medicalActName']),
      amount: serializer.fromJson<int>(json['amount']),
      userId: serializer.fromJson<String>(json['userId']),
      userName: serializer.fromJson<String>(json['userName']),
      patientCode: serializer.fromJson<int>(json['patientCode']),
      patientFirstName: serializer.fromJson<String>(json['patientFirstName']),
      patientLastName: serializer.fromJson<String>(json['patientLastName']),
      paymentTime: serializer.fromJson<DateTime>(json['paymentTime']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      needsSync: serializer.fromJson<bool>(json['needsSync']),
      isActive: serializer.fromJson<bool>(json['isActive']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'medicalActId': serializer.toJson<int>(medicalActId),
      'medicalActName': serializer.toJson<String>(medicalActName),
      'amount': serializer.toJson<int>(amount),
      'userId': serializer.toJson<String>(userId),
      'userName': serializer.toJson<String>(userName),
      'patientCode': serializer.toJson<int>(patientCode),
      'patientFirstName': serializer.toJson<String>(patientFirstName),
      'patientLastName': serializer.toJson<String>(patientLastName),
      'paymentTime': serializer.toJson<DateTime>(paymentTime),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'needsSync': serializer.toJson<bool>(needsSync),
      'isActive': serializer.toJson<bool>(isActive),
    };
  }

  Payment copyWith(
          {int? id,
          int? medicalActId,
          String? medicalActName,
          int? amount,
          String? userId,
          String? userName,
          int? patientCode,
          String? patientFirstName,
          String? patientLastName,
          DateTime? paymentTime,
          DateTime? createdAt,
          DateTime? updatedAt,
          bool? needsSync,
          bool? isActive}) =>
      Payment(
        id: id ?? this.id,
        medicalActId: medicalActId ?? this.medicalActId,
        medicalActName: medicalActName ?? this.medicalActName,
        amount: amount ?? this.amount,
        userId: userId ?? this.userId,
        userName: userName ?? this.userName,
        patientCode: patientCode ?? this.patientCode,
        patientFirstName: patientFirstName ?? this.patientFirstName,
        patientLastName: patientLastName ?? this.patientLastName,
        paymentTime: paymentTime ?? this.paymentTime,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        needsSync: needsSync ?? this.needsSync,
        isActive: isActive ?? this.isActive,
      );
  Payment copyWithCompanion(PaymentsCompanion data) {
    return Payment(
      id: data.id.present ? data.id.value : this.id,
      medicalActId: data.medicalActId.present
          ? data.medicalActId.value
          : this.medicalActId,
      medicalActName: data.medicalActName.present
          ? data.medicalActName.value
          : this.medicalActName,
      amount: data.amount.present ? data.amount.value : this.amount,
      userId: data.userId.present ? data.userId.value : this.userId,
      userName: data.userName.present ? data.userName.value : this.userName,
      patientCode:
          data.patientCode.present ? data.patientCode.value : this.patientCode,
      patientFirstName: data.patientFirstName.present
          ? data.patientFirstName.value
          : this.patientFirstName,
      patientLastName: data.patientLastName.present
          ? data.patientLastName.value
          : this.patientLastName,
      paymentTime:
          data.paymentTime.present ? data.paymentTime.value : this.paymentTime,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      needsSync: data.needsSync.present ? data.needsSync.value : this.needsSync,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Payment(')
          ..write('id: $id, ')
          ..write('medicalActId: $medicalActId, ')
          ..write('medicalActName: $medicalActName, ')
          ..write('amount: $amount, ')
          ..write('userId: $userId, ')
          ..write('userName: $userName, ')
          ..write('patientCode: $patientCode, ')
          ..write('patientFirstName: $patientFirstName, ')
          ..write('patientLastName: $patientLastName, ')
          ..write('paymentTime: $paymentTime, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('needsSync: $needsSync, ')
          ..write('isActive: $isActive')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      medicalActId,
      medicalActName,
      amount,
      userId,
      userName,
      patientCode,
      patientFirstName,
      patientLastName,
      paymentTime,
      createdAt,
      updatedAt,
      needsSync,
      isActive);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Payment &&
          other.id == this.id &&
          other.medicalActId == this.medicalActId &&
          other.medicalActName == this.medicalActName &&
          other.amount == this.amount &&
          other.userId == this.userId &&
          other.userName == this.userName &&
          other.patientCode == this.patientCode &&
          other.patientFirstName == this.patientFirstName &&
          other.patientLastName == this.patientLastName &&
          other.paymentTime == this.paymentTime &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.needsSync == this.needsSync &&
          other.isActive == this.isActive);
}

class PaymentsCompanion extends UpdateCompanion<Payment> {
  final Value<int> id;
  final Value<int> medicalActId;
  final Value<String> medicalActName;
  final Value<int> amount;
  final Value<String> userId;
  final Value<String> userName;
  final Value<int> patientCode;
  final Value<String> patientFirstName;
  final Value<String> patientLastName;
  final Value<DateTime> paymentTime;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<bool> needsSync;
  final Value<bool> isActive;
  const PaymentsCompanion({
    this.id = const Value.absent(),
    this.medicalActId = const Value.absent(),
    this.medicalActName = const Value.absent(),
    this.amount = const Value.absent(),
    this.userId = const Value.absent(),
    this.userName = const Value.absent(),
    this.patientCode = const Value.absent(),
    this.patientFirstName = const Value.absent(),
    this.patientLastName = const Value.absent(),
    this.paymentTime = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.needsSync = const Value.absent(),
    this.isActive = const Value.absent(),
  });
  PaymentsCompanion.insert({
    this.id = const Value.absent(),
    required int medicalActId,
    required String medicalActName,
    required int amount,
    required String userId,
    required String userName,
    required int patientCode,
    required String patientFirstName,
    required String patientLastName,
    required DateTime paymentTime,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.needsSync = const Value.absent(),
    this.isActive = const Value.absent(),
  })  : medicalActId = Value(medicalActId),
        medicalActName = Value(medicalActName),
        amount = Value(amount),
        userId = Value(userId),
        userName = Value(userName),
        patientCode = Value(patientCode),
        patientFirstName = Value(patientFirstName),
        patientLastName = Value(patientLastName),
        paymentTime = Value(paymentTime),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<Payment> custom({
    Expression<int>? id,
    Expression<int>? medicalActId,
    Expression<String>? medicalActName,
    Expression<int>? amount,
    Expression<String>? userId,
    Expression<String>? userName,
    Expression<int>? patientCode,
    Expression<String>? patientFirstName,
    Expression<String>? patientLastName,
    Expression<DateTime>? paymentTime,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<bool>? needsSync,
    Expression<bool>? isActive,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (medicalActId != null) 'medical_act_id': medicalActId,
      if (medicalActName != null) 'medical_act_name': medicalActName,
      if (amount != null) 'amount': amount,
      if (userId != null) 'user_id': userId,
      if (userName != null) 'user_name': userName,
      if (patientCode != null) 'patient_code': patientCode,
      if (patientFirstName != null) 'patient_first_name': patientFirstName,
      if (patientLastName != null) 'patient_last_name': patientLastName,
      if (paymentTime != null) 'payment_time': paymentTime,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (needsSync != null) 'needs_sync': needsSync,
      if (isActive != null) 'is_active': isActive,
    });
  }

  PaymentsCompanion copyWith(
      {Value<int>? id,
      Value<int>? medicalActId,
      Value<String>? medicalActName,
      Value<int>? amount,
      Value<String>? userId,
      Value<String>? userName,
      Value<int>? patientCode,
      Value<String>? patientFirstName,
      Value<String>? patientLastName,
      Value<DateTime>? paymentTime,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<bool>? needsSync,
      Value<bool>? isActive}) {
    return PaymentsCompanion(
      id: id ?? this.id,
      medicalActId: medicalActId ?? this.medicalActId,
      medicalActName: medicalActName ?? this.medicalActName,
      amount: amount ?? this.amount,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      patientCode: patientCode ?? this.patientCode,
      patientFirstName: patientFirstName ?? this.patientFirstName,
      patientLastName: patientLastName ?? this.patientLastName,
      paymentTime: paymentTime ?? this.paymentTime,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      needsSync: needsSync ?? this.needsSync,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (medicalActId.present) {
      map['medical_act_id'] = Variable<int>(medicalActId.value);
    }
    if (medicalActName.present) {
      map['medical_act_name'] = Variable<String>(medicalActName.value);
    }
    if (amount.present) {
      map['amount'] = Variable<int>(amount.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (userName.present) {
      map['user_name'] = Variable<String>(userName.value);
    }
    if (patientCode.present) {
      map['patient_code'] = Variable<int>(patientCode.value);
    }
    if (patientFirstName.present) {
      map['patient_first_name'] = Variable<String>(patientFirstName.value);
    }
    if (patientLastName.present) {
      map['patient_last_name'] = Variable<String>(patientLastName.value);
    }
    if (paymentTime.present) {
      map['payment_time'] = Variable<DateTime>(paymentTime.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (needsSync.present) {
      map['needs_sync'] = Variable<bool>(needsSync.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PaymentsCompanion(')
          ..write('id: $id, ')
          ..write('medicalActId: $medicalActId, ')
          ..write('medicalActName: $medicalActName, ')
          ..write('amount: $amount, ')
          ..write('userId: $userId, ')
          ..write('userName: $userName, ')
          ..write('patientCode: $patientCode, ')
          ..write('patientFirstName: $patientFirstName, ')
          ..write('patientLastName: $patientLastName, ')
          ..write('paymentTime: $paymentTime, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('needsSync: $needsSync, ')
          ..write('isActive: $isActive')
          ..write(')'))
        .toString();
  }
}

class $VisitsTable extends Visits with TableInfo<$VisitsTable, Visit> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VisitsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _originalIdMeta =
      const VerificationMeta('originalId');
  @override
  late final GeneratedColumn<int> originalId = GeneratedColumn<int>(
      'original_id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _patientCodeMeta =
      const VerificationMeta('patientCode');
  @override
  late final GeneratedColumn<int> patientCode = GeneratedColumn<int>(
      'patient_code', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _visitSequenceMeta =
      const VerificationMeta('visitSequence');
  @override
  late final GeneratedColumn<int> visitSequence = GeneratedColumn<int>(
      'visit_sequence', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _visitDateMeta =
      const VerificationMeta('visitDate');
  @override
  late final GeneratedColumn<DateTime> visitDate = GeneratedColumn<DateTime>(
      'visit_date', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _doctorNameMeta =
      const VerificationMeta('doctorName');
  @override
  late final GeneratedColumn<String> doctorName = GeneratedColumn<String>(
      'doctor_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _motifMeta = const VerificationMeta('motif');
  @override
  late final GeneratedColumn<String> motif = GeneratedColumn<String>(
      'motif', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _diagnosisMeta =
      const VerificationMeta('diagnosis');
  @override
  late final GeneratedColumn<String> diagnosis = GeneratedColumn<String>(
      'diagnosis', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _conductMeta =
      const VerificationMeta('conduct');
  @override
  late final GeneratedColumn<String> conduct = GeneratedColumn<String>(
      'conduct', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _odSvMeta = const VerificationMeta('odSv');
  @override
  late final GeneratedColumn<String> odSv = GeneratedColumn<String>(
      'od_sv', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _odAvMeta = const VerificationMeta('odAv');
  @override
  late final GeneratedColumn<String> odAv = GeneratedColumn<String>(
      'od_av', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _odSphereMeta =
      const VerificationMeta('odSphere');
  @override
  late final GeneratedColumn<String> odSphere = GeneratedColumn<String>(
      'od_sphere', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _odCylinderMeta =
      const VerificationMeta('odCylinder');
  @override
  late final GeneratedColumn<String> odCylinder = GeneratedColumn<String>(
      'od_cylinder', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _odAxisMeta = const VerificationMeta('odAxis');
  @override
  late final GeneratedColumn<String> odAxis = GeneratedColumn<String>(
      'od_axis', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _odVlMeta = const VerificationMeta('odVl');
  @override
  late final GeneratedColumn<String> odVl = GeneratedColumn<String>(
      'od_vl', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _odK1Meta = const VerificationMeta('odK1');
  @override
  late final GeneratedColumn<String> odK1 = GeneratedColumn<String>(
      'od_k1', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _odK2Meta = const VerificationMeta('odK2');
  @override
  late final GeneratedColumn<String> odK2 = GeneratedColumn<String>(
      'od_k2', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _odR1Meta = const VerificationMeta('odR1');
  @override
  late final GeneratedColumn<String> odR1 = GeneratedColumn<String>(
      'od_r1', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _odR2Meta = const VerificationMeta('odR2');
  @override
  late final GeneratedColumn<String> odR2 = GeneratedColumn<String>(
      'od_r2', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _odR0Meta = const VerificationMeta('odR0');
  @override
  late final GeneratedColumn<String> odR0 = GeneratedColumn<String>(
      'od_r0', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _odPachyMeta =
      const VerificationMeta('odPachy');
  @override
  late final GeneratedColumn<String> odPachy = GeneratedColumn<String>(
      'od_pachy', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _odTocMeta = const VerificationMeta('odToc');
  @override
  late final GeneratedColumn<String> odToc = GeneratedColumn<String>(
      'od_toc', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _odNotesMeta =
      const VerificationMeta('odNotes');
  @override
  late final GeneratedColumn<String> odNotes = GeneratedColumn<String>(
      'od_notes', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _odGonioMeta =
      const VerificationMeta('odGonio');
  @override
  late final GeneratedColumn<String> odGonio = GeneratedColumn<String>(
      'od_gonio', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _odToMeta = const VerificationMeta('odTo');
  @override
  late final GeneratedColumn<String> odTo = GeneratedColumn<String>(
      'od_to', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _odLafMeta = const VerificationMeta('odLaf');
  @override
  late final GeneratedColumn<String> odLaf = GeneratedColumn<String>(
      'od_laf', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _odFoMeta = const VerificationMeta('odFo');
  @override
  late final GeneratedColumn<String> odFo = GeneratedColumn<String>(
      'od_fo', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _ogSvMeta = const VerificationMeta('ogSv');
  @override
  late final GeneratedColumn<String> ogSv = GeneratedColumn<String>(
      'og_sv', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _ogAvMeta = const VerificationMeta('ogAv');
  @override
  late final GeneratedColumn<String> ogAv = GeneratedColumn<String>(
      'og_av', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _ogSphereMeta =
      const VerificationMeta('ogSphere');
  @override
  late final GeneratedColumn<String> ogSphere = GeneratedColumn<String>(
      'og_sphere', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _ogCylinderMeta =
      const VerificationMeta('ogCylinder');
  @override
  late final GeneratedColumn<String> ogCylinder = GeneratedColumn<String>(
      'og_cylinder', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _ogAxisMeta = const VerificationMeta('ogAxis');
  @override
  late final GeneratedColumn<String> ogAxis = GeneratedColumn<String>(
      'og_axis', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _ogVlMeta = const VerificationMeta('ogVl');
  @override
  late final GeneratedColumn<String> ogVl = GeneratedColumn<String>(
      'og_vl', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _ogK1Meta = const VerificationMeta('ogK1');
  @override
  late final GeneratedColumn<String> ogK1 = GeneratedColumn<String>(
      'og_k1', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _ogK2Meta = const VerificationMeta('ogK2');
  @override
  late final GeneratedColumn<String> ogK2 = GeneratedColumn<String>(
      'og_k2', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _ogR1Meta = const VerificationMeta('ogR1');
  @override
  late final GeneratedColumn<String> ogR1 = GeneratedColumn<String>(
      'og_r1', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _ogR2Meta = const VerificationMeta('ogR2');
  @override
  late final GeneratedColumn<String> ogR2 = GeneratedColumn<String>(
      'og_r2', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _ogR0Meta = const VerificationMeta('ogR0');
  @override
  late final GeneratedColumn<String> ogR0 = GeneratedColumn<String>(
      'og_r0', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _ogPachyMeta =
      const VerificationMeta('ogPachy');
  @override
  late final GeneratedColumn<String> ogPachy = GeneratedColumn<String>(
      'og_pachy', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _ogTocMeta = const VerificationMeta('ogToc');
  @override
  late final GeneratedColumn<String> ogToc = GeneratedColumn<String>(
      'og_toc', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _ogNotesMeta =
      const VerificationMeta('ogNotes');
  @override
  late final GeneratedColumn<String> ogNotes = GeneratedColumn<String>(
      'og_notes', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _ogGonioMeta =
      const VerificationMeta('ogGonio');
  @override
  late final GeneratedColumn<String> ogGonio = GeneratedColumn<String>(
      'og_gonio', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _ogToMeta = const VerificationMeta('ogTo');
  @override
  late final GeneratedColumn<String> ogTo = GeneratedColumn<String>(
      'og_to', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _ogLafMeta = const VerificationMeta('ogLaf');
  @override
  late final GeneratedColumn<String> ogLaf = GeneratedColumn<String>(
      'og_laf', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _ogFoMeta = const VerificationMeta('ogFo');
  @override
  late final GeneratedColumn<String> ogFo = GeneratedColumn<String>(
      'og_fo', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _additionMeta =
      const VerificationMeta('addition');
  @override
  late final GeneratedColumn<String> addition = GeneratedColumn<String>(
      'addition', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _dipMeta = const VerificationMeta('dip');
  @override
  late final GeneratedColumn<String> dip = GeneratedColumn<String>(
      'dip', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _needsSyncMeta =
      const VerificationMeta('needsSync');
  @override
  late final GeneratedColumn<bool> needsSync = GeneratedColumn<bool>(
      'needs_sync', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("needs_sync" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _isActiveMeta =
      const VerificationMeta('isActive');
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
      'is_active', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_active" IN (0, 1))'),
      defaultValue: const Constant(true));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        originalId,
        patientCode,
        visitSequence,
        visitDate,
        doctorName,
        motif,
        diagnosis,
        conduct,
        odSv,
        odAv,
        odSphere,
        odCylinder,
        odAxis,
        odVl,
        odK1,
        odK2,
        odR1,
        odR2,
        odR0,
        odPachy,
        odToc,
        odNotes,
        odGonio,
        odTo,
        odLaf,
        odFo,
        ogSv,
        ogAv,
        ogSphere,
        ogCylinder,
        ogAxis,
        ogVl,
        ogK1,
        ogK2,
        ogR1,
        ogR2,
        ogR0,
        ogPachy,
        ogToc,
        ogNotes,
        ogGonio,
        ogTo,
        ogLaf,
        ogFo,
        addition,
        dip,
        createdAt,
        updatedAt,
        needsSync,
        isActive
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'visits';
  @override
  VerificationContext validateIntegrity(Insertable<Visit> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('original_id')) {
      context.handle(
          _originalIdMeta,
          originalId.isAcceptableOrUnknown(
              data['original_id']!, _originalIdMeta));
    }
    if (data.containsKey('patient_code')) {
      context.handle(
          _patientCodeMeta,
          patientCode.isAcceptableOrUnknown(
              data['patient_code']!, _patientCodeMeta));
    } else if (isInserting) {
      context.missing(_patientCodeMeta);
    }
    if (data.containsKey('visit_sequence')) {
      context.handle(
          _visitSequenceMeta,
          visitSequence.isAcceptableOrUnknown(
              data['visit_sequence']!, _visitSequenceMeta));
    }
    if (data.containsKey('visit_date')) {
      context.handle(_visitDateMeta,
          visitDate.isAcceptableOrUnknown(data['visit_date']!, _visitDateMeta));
    } else if (isInserting) {
      context.missing(_visitDateMeta);
    }
    if (data.containsKey('doctor_name')) {
      context.handle(
          _doctorNameMeta,
          doctorName.isAcceptableOrUnknown(
              data['doctor_name']!, _doctorNameMeta));
    } else if (isInserting) {
      context.missing(_doctorNameMeta);
    }
    if (data.containsKey('motif')) {
      context.handle(
          _motifMeta, motif.isAcceptableOrUnknown(data['motif']!, _motifMeta));
    }
    if (data.containsKey('diagnosis')) {
      context.handle(_diagnosisMeta,
          diagnosis.isAcceptableOrUnknown(data['diagnosis']!, _diagnosisMeta));
    }
    if (data.containsKey('conduct')) {
      context.handle(_conductMeta,
          conduct.isAcceptableOrUnknown(data['conduct']!, _conductMeta));
    }
    if (data.containsKey('od_sv')) {
      context.handle(
          _odSvMeta, odSv.isAcceptableOrUnknown(data['od_sv']!, _odSvMeta));
    }
    if (data.containsKey('od_av')) {
      context.handle(
          _odAvMeta, odAv.isAcceptableOrUnknown(data['od_av']!, _odAvMeta));
    }
    if (data.containsKey('od_sphere')) {
      context.handle(_odSphereMeta,
          odSphere.isAcceptableOrUnknown(data['od_sphere']!, _odSphereMeta));
    }
    if (data.containsKey('od_cylinder')) {
      context.handle(
          _odCylinderMeta,
          odCylinder.isAcceptableOrUnknown(
              data['od_cylinder']!, _odCylinderMeta));
    }
    if (data.containsKey('od_axis')) {
      context.handle(_odAxisMeta,
          odAxis.isAcceptableOrUnknown(data['od_axis']!, _odAxisMeta));
    }
    if (data.containsKey('od_vl')) {
      context.handle(
          _odVlMeta, odVl.isAcceptableOrUnknown(data['od_vl']!, _odVlMeta));
    }
    if (data.containsKey('od_k1')) {
      context.handle(
          _odK1Meta, odK1.isAcceptableOrUnknown(data['od_k1']!, _odK1Meta));
    }
    if (data.containsKey('od_k2')) {
      context.handle(
          _odK2Meta, odK2.isAcceptableOrUnknown(data['od_k2']!, _odK2Meta));
    }
    if (data.containsKey('od_r1')) {
      context.handle(
          _odR1Meta, odR1.isAcceptableOrUnknown(data['od_r1']!, _odR1Meta));
    }
    if (data.containsKey('od_r2')) {
      context.handle(
          _odR2Meta, odR2.isAcceptableOrUnknown(data['od_r2']!, _odR2Meta));
    }
    if (data.containsKey('od_r0')) {
      context.handle(
          _odR0Meta, odR0.isAcceptableOrUnknown(data['od_r0']!, _odR0Meta));
    }
    if (data.containsKey('od_pachy')) {
      context.handle(_odPachyMeta,
          odPachy.isAcceptableOrUnknown(data['od_pachy']!, _odPachyMeta));
    }
    if (data.containsKey('od_toc')) {
      context.handle(
          _odTocMeta, odToc.isAcceptableOrUnknown(data['od_toc']!, _odTocMeta));
    }
    if (data.containsKey('od_notes')) {
      context.handle(_odNotesMeta,
          odNotes.isAcceptableOrUnknown(data['od_notes']!, _odNotesMeta));
    }
    if (data.containsKey('od_gonio')) {
      context.handle(_odGonioMeta,
          odGonio.isAcceptableOrUnknown(data['od_gonio']!, _odGonioMeta));
    }
    if (data.containsKey('od_to')) {
      context.handle(
          _odToMeta, odTo.isAcceptableOrUnknown(data['od_to']!, _odToMeta));
    }
    if (data.containsKey('od_laf')) {
      context.handle(
          _odLafMeta, odLaf.isAcceptableOrUnknown(data['od_laf']!, _odLafMeta));
    }
    if (data.containsKey('od_fo')) {
      context.handle(
          _odFoMeta, odFo.isAcceptableOrUnknown(data['od_fo']!, _odFoMeta));
    }
    if (data.containsKey('og_sv')) {
      context.handle(
          _ogSvMeta, ogSv.isAcceptableOrUnknown(data['og_sv']!, _ogSvMeta));
    }
    if (data.containsKey('og_av')) {
      context.handle(
          _ogAvMeta, ogAv.isAcceptableOrUnknown(data['og_av']!, _ogAvMeta));
    }
    if (data.containsKey('og_sphere')) {
      context.handle(_ogSphereMeta,
          ogSphere.isAcceptableOrUnknown(data['og_sphere']!, _ogSphereMeta));
    }
    if (data.containsKey('og_cylinder')) {
      context.handle(
          _ogCylinderMeta,
          ogCylinder.isAcceptableOrUnknown(
              data['og_cylinder']!, _ogCylinderMeta));
    }
    if (data.containsKey('og_axis')) {
      context.handle(_ogAxisMeta,
          ogAxis.isAcceptableOrUnknown(data['og_axis']!, _ogAxisMeta));
    }
    if (data.containsKey('og_vl')) {
      context.handle(
          _ogVlMeta, ogVl.isAcceptableOrUnknown(data['og_vl']!, _ogVlMeta));
    }
    if (data.containsKey('og_k1')) {
      context.handle(
          _ogK1Meta, ogK1.isAcceptableOrUnknown(data['og_k1']!, _ogK1Meta));
    }
    if (data.containsKey('og_k2')) {
      context.handle(
          _ogK2Meta, ogK2.isAcceptableOrUnknown(data['og_k2']!, _ogK2Meta));
    }
    if (data.containsKey('og_r1')) {
      context.handle(
          _ogR1Meta, ogR1.isAcceptableOrUnknown(data['og_r1']!, _ogR1Meta));
    }
    if (data.containsKey('og_r2')) {
      context.handle(
          _ogR2Meta, ogR2.isAcceptableOrUnknown(data['og_r2']!, _ogR2Meta));
    }
    if (data.containsKey('og_r0')) {
      context.handle(
          _ogR0Meta, ogR0.isAcceptableOrUnknown(data['og_r0']!, _ogR0Meta));
    }
    if (data.containsKey('og_pachy')) {
      context.handle(_ogPachyMeta,
          ogPachy.isAcceptableOrUnknown(data['og_pachy']!, _ogPachyMeta));
    }
    if (data.containsKey('og_toc')) {
      context.handle(
          _ogTocMeta, ogToc.isAcceptableOrUnknown(data['og_toc']!, _ogTocMeta));
    }
    if (data.containsKey('og_notes')) {
      context.handle(_ogNotesMeta,
          ogNotes.isAcceptableOrUnknown(data['og_notes']!, _ogNotesMeta));
    }
    if (data.containsKey('og_gonio')) {
      context.handle(_ogGonioMeta,
          ogGonio.isAcceptableOrUnknown(data['og_gonio']!, _ogGonioMeta));
    }
    if (data.containsKey('og_to')) {
      context.handle(
          _ogToMeta, ogTo.isAcceptableOrUnknown(data['og_to']!, _ogToMeta));
    }
    if (data.containsKey('og_laf')) {
      context.handle(
          _ogLafMeta, ogLaf.isAcceptableOrUnknown(data['og_laf']!, _ogLafMeta));
    }
    if (data.containsKey('og_fo')) {
      context.handle(
          _ogFoMeta, ogFo.isAcceptableOrUnknown(data['og_fo']!, _ogFoMeta));
    }
    if (data.containsKey('addition')) {
      context.handle(_additionMeta,
          addition.isAcceptableOrUnknown(data['addition']!, _additionMeta));
    }
    if (data.containsKey('dip')) {
      context.handle(
          _dipMeta, dip.isAcceptableOrUnknown(data['dip']!, _dipMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('needs_sync')) {
      context.handle(_needsSyncMeta,
          needsSync.isAcceptableOrUnknown(data['needs_sync']!, _needsSyncMeta));
    }
    if (data.containsKey('is_active')) {
      context.handle(_isActiveMeta,
          isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Visit map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Visit(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      originalId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}original_id']),
      patientCode: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}patient_code'])!,
      visitSequence: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}visit_sequence'])!,
      visitDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}visit_date'])!,
      doctorName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}doctor_name'])!,
      motif: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}motif']),
      diagnosis: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}diagnosis']),
      conduct: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}conduct']),
      odSv: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}od_sv']),
      odAv: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}od_av']),
      odSphere: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}od_sphere']),
      odCylinder: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}od_cylinder']),
      odAxis: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}od_axis']),
      odVl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}od_vl']),
      odK1: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}od_k1']),
      odK2: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}od_k2']),
      odR1: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}od_r1']),
      odR2: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}od_r2']),
      odR0: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}od_r0']),
      odPachy: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}od_pachy']),
      odToc: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}od_toc']),
      odNotes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}od_notes']),
      odGonio: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}od_gonio']),
      odTo: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}od_to']),
      odLaf: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}od_laf']),
      odFo: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}od_fo']),
      ogSv: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}og_sv']),
      ogAv: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}og_av']),
      ogSphere: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}og_sphere']),
      ogCylinder: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}og_cylinder']),
      ogAxis: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}og_axis']),
      ogVl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}og_vl']),
      ogK1: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}og_k1']),
      ogK2: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}og_k2']),
      ogR1: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}og_r1']),
      ogR2: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}og_r2']),
      ogR0: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}og_r0']),
      ogPachy: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}og_pachy']),
      ogToc: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}og_toc']),
      ogNotes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}og_notes']),
      ogGonio: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}og_gonio']),
      ogTo: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}og_to']),
      ogLaf: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}og_laf']),
      ogFo: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}og_fo']),
      addition: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}addition']),
      dip: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}dip']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      needsSync: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}needs_sync'])!,
      isActive: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_active'])!,
    );
  }

  @override
  $VisitsTable createAlias(String alias) {
    return $VisitsTable(attachedDatabase, alias);
  }
}

class Visit extends DataClass implements Insertable<Visit> {
  /// Unique visit ID (auto-increment)
  final int id;

  /// Original record number from XML (N__Enr.)
  final int? originalId;

  /// Patient code (CDEP) - links to patients table
  final int patientCode;

  /// Visit sequence number (SEQC)
  final int visitSequence;

  /// Visit date (DATECLI)
  final DateTime visitDate;

  /// Doctor name (MEDCIN)
  final String doctorName;

  /// Reason for visit (MOTIF)
  final String? motif;

  /// Diagnosis (DIIAG)
  final String? diagnosis;

  /// Treatment/Conduct (CAT - Conduite à tenir)
  final String? conduct;

  /// S.V - Sans Correction (SCOD)
  final String? odSv;

  /// A.V - Avec Correction (AVOD)
  final String? odAv;

  /// Sphere (p1)
  final String? odSphere;

  /// Cylinder (p2)
  final String? odCylinder;

  /// Axis (AXD)
  final String? odAxis;

  /// VL - Vision de Loin
  final String? odVl;

  /// K1 (K1_D)
  final String? odK1;

  /// K2 (K2_D)
  final String? odK2;

  /// R1 (R1_d)
  final String? odR1;

  /// R2 (R2_d)
  final String? odR2;

  /// R0 / Rayon (RAYOND)
  final String? odR0;

  /// Pachymetry (pachy1_D)
  final String? odPachy;

  /// T.O.C - Tension Oculaire (TOOD)
  final String? odToc;

  /// Notes (comentaire_D)
  final String? odNotes;

  /// GONIO (VAD)
  final String? odGonio;

  /// T.O (TOOD - same as TOC for now)
  final String? odTo;

  /// L.A.F - Lampe à Fente (LAF)
  final String? odLaf;

  /// F.O - Fond d'Oeil (FO)
  final String? odFo;

  /// S.V - Sans Correction (SCOG)
  final String? ogSv;

  /// A.V - Avec Correction (AVOG)
  final String? ogAv;

  /// Sphere (p3)
  final String? ogSphere;

  /// Cylinder (p5)
  final String? ogCylinder;

  /// Axis (AXG)
  final String? ogAxis;

  /// VL - Vision de Loin
  final String? ogVl;

  /// K1 (K1_G)
  final String? ogK1;

  /// K2 (K2_G)
  final String? ogK2;

  /// R1 (R1_G)
  final String? ogR1;

  /// R2 (R2_G)
  final String? ogR2;

  /// R0 / Rayon (RAYONG)
  final String? ogR0;

  /// Pachymetry (pachy1_g)
  final String? ogPachy;

  /// T.O.C - Tension Oculaire (TOOG)
  final String? ogToc;

  /// Notes (commentaire_G)
  final String? ogNotes;

  /// GONIO (VAG)
  final String? ogGonio;

  /// T.O (TOOG - same as TOC for now)
  final String? ogTo;

  /// L.A.F - Lampe à Fente (LAF_G)
  final String? ogLaf;

  /// F.O - Fond d'Oeil (FO_G)
  final String? ogFo;

  /// Addition/EP (EP)
  final String? addition;

  /// D.I.P - Distance Inter-Pupillaire (EP as well, stored separately)
  final String? dip;

  /// Record creation timestamp
  final DateTime createdAt;

  /// Last update timestamp
  final DateTime updatedAt;

  /// Sync flag for multi-PC synchronization
  final bool needsSync;

  /// Soft delete flag
  final bool isActive;
  const Visit(
      {required this.id,
      this.originalId,
      required this.patientCode,
      required this.visitSequence,
      required this.visitDate,
      required this.doctorName,
      this.motif,
      this.diagnosis,
      this.conduct,
      this.odSv,
      this.odAv,
      this.odSphere,
      this.odCylinder,
      this.odAxis,
      this.odVl,
      this.odK1,
      this.odK2,
      this.odR1,
      this.odR2,
      this.odR0,
      this.odPachy,
      this.odToc,
      this.odNotes,
      this.odGonio,
      this.odTo,
      this.odLaf,
      this.odFo,
      this.ogSv,
      this.ogAv,
      this.ogSphere,
      this.ogCylinder,
      this.ogAxis,
      this.ogVl,
      this.ogK1,
      this.ogK2,
      this.ogR1,
      this.ogR2,
      this.ogR0,
      this.ogPachy,
      this.ogToc,
      this.ogNotes,
      this.ogGonio,
      this.ogTo,
      this.ogLaf,
      this.ogFo,
      this.addition,
      this.dip,
      required this.createdAt,
      required this.updatedAt,
      required this.needsSync,
      required this.isActive});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || originalId != null) {
      map['original_id'] = Variable<int>(originalId);
    }
    map['patient_code'] = Variable<int>(patientCode);
    map['visit_sequence'] = Variable<int>(visitSequence);
    map['visit_date'] = Variable<DateTime>(visitDate);
    map['doctor_name'] = Variable<String>(doctorName);
    if (!nullToAbsent || motif != null) {
      map['motif'] = Variable<String>(motif);
    }
    if (!nullToAbsent || diagnosis != null) {
      map['diagnosis'] = Variable<String>(diagnosis);
    }
    if (!nullToAbsent || conduct != null) {
      map['conduct'] = Variable<String>(conduct);
    }
    if (!nullToAbsent || odSv != null) {
      map['od_sv'] = Variable<String>(odSv);
    }
    if (!nullToAbsent || odAv != null) {
      map['od_av'] = Variable<String>(odAv);
    }
    if (!nullToAbsent || odSphere != null) {
      map['od_sphere'] = Variable<String>(odSphere);
    }
    if (!nullToAbsent || odCylinder != null) {
      map['od_cylinder'] = Variable<String>(odCylinder);
    }
    if (!nullToAbsent || odAxis != null) {
      map['od_axis'] = Variable<String>(odAxis);
    }
    if (!nullToAbsent || odVl != null) {
      map['od_vl'] = Variable<String>(odVl);
    }
    if (!nullToAbsent || odK1 != null) {
      map['od_k1'] = Variable<String>(odK1);
    }
    if (!nullToAbsent || odK2 != null) {
      map['od_k2'] = Variable<String>(odK2);
    }
    if (!nullToAbsent || odR1 != null) {
      map['od_r1'] = Variable<String>(odR1);
    }
    if (!nullToAbsent || odR2 != null) {
      map['od_r2'] = Variable<String>(odR2);
    }
    if (!nullToAbsent || odR0 != null) {
      map['od_r0'] = Variable<String>(odR0);
    }
    if (!nullToAbsent || odPachy != null) {
      map['od_pachy'] = Variable<String>(odPachy);
    }
    if (!nullToAbsent || odToc != null) {
      map['od_toc'] = Variable<String>(odToc);
    }
    if (!nullToAbsent || odNotes != null) {
      map['od_notes'] = Variable<String>(odNotes);
    }
    if (!nullToAbsent || odGonio != null) {
      map['od_gonio'] = Variable<String>(odGonio);
    }
    if (!nullToAbsent || odTo != null) {
      map['od_to'] = Variable<String>(odTo);
    }
    if (!nullToAbsent || odLaf != null) {
      map['od_laf'] = Variable<String>(odLaf);
    }
    if (!nullToAbsent || odFo != null) {
      map['od_fo'] = Variable<String>(odFo);
    }
    if (!nullToAbsent || ogSv != null) {
      map['og_sv'] = Variable<String>(ogSv);
    }
    if (!nullToAbsent || ogAv != null) {
      map['og_av'] = Variable<String>(ogAv);
    }
    if (!nullToAbsent || ogSphere != null) {
      map['og_sphere'] = Variable<String>(ogSphere);
    }
    if (!nullToAbsent || ogCylinder != null) {
      map['og_cylinder'] = Variable<String>(ogCylinder);
    }
    if (!nullToAbsent || ogAxis != null) {
      map['og_axis'] = Variable<String>(ogAxis);
    }
    if (!nullToAbsent || ogVl != null) {
      map['og_vl'] = Variable<String>(ogVl);
    }
    if (!nullToAbsent || ogK1 != null) {
      map['og_k1'] = Variable<String>(ogK1);
    }
    if (!nullToAbsent || ogK2 != null) {
      map['og_k2'] = Variable<String>(ogK2);
    }
    if (!nullToAbsent || ogR1 != null) {
      map['og_r1'] = Variable<String>(ogR1);
    }
    if (!nullToAbsent || ogR2 != null) {
      map['og_r2'] = Variable<String>(ogR2);
    }
    if (!nullToAbsent || ogR0 != null) {
      map['og_r0'] = Variable<String>(ogR0);
    }
    if (!nullToAbsent || ogPachy != null) {
      map['og_pachy'] = Variable<String>(ogPachy);
    }
    if (!nullToAbsent || ogToc != null) {
      map['og_toc'] = Variable<String>(ogToc);
    }
    if (!nullToAbsent || ogNotes != null) {
      map['og_notes'] = Variable<String>(ogNotes);
    }
    if (!nullToAbsent || ogGonio != null) {
      map['og_gonio'] = Variable<String>(ogGonio);
    }
    if (!nullToAbsent || ogTo != null) {
      map['og_to'] = Variable<String>(ogTo);
    }
    if (!nullToAbsent || ogLaf != null) {
      map['og_laf'] = Variable<String>(ogLaf);
    }
    if (!nullToAbsent || ogFo != null) {
      map['og_fo'] = Variable<String>(ogFo);
    }
    if (!nullToAbsent || addition != null) {
      map['addition'] = Variable<String>(addition);
    }
    if (!nullToAbsent || dip != null) {
      map['dip'] = Variable<String>(dip);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['needs_sync'] = Variable<bool>(needsSync);
    map['is_active'] = Variable<bool>(isActive);
    return map;
  }

  VisitsCompanion toCompanion(bool nullToAbsent) {
    return VisitsCompanion(
      id: Value(id),
      originalId: originalId == null && nullToAbsent
          ? const Value.absent()
          : Value(originalId),
      patientCode: Value(patientCode),
      visitSequence: Value(visitSequence),
      visitDate: Value(visitDate),
      doctorName: Value(doctorName),
      motif:
          motif == null && nullToAbsent ? const Value.absent() : Value(motif),
      diagnosis: diagnosis == null && nullToAbsent
          ? const Value.absent()
          : Value(diagnosis),
      conduct: conduct == null && nullToAbsent
          ? const Value.absent()
          : Value(conduct),
      odSv: odSv == null && nullToAbsent ? const Value.absent() : Value(odSv),
      odAv: odAv == null && nullToAbsent ? const Value.absent() : Value(odAv),
      odSphere: odSphere == null && nullToAbsent
          ? const Value.absent()
          : Value(odSphere),
      odCylinder: odCylinder == null && nullToAbsent
          ? const Value.absent()
          : Value(odCylinder),
      odAxis:
          odAxis == null && nullToAbsent ? const Value.absent() : Value(odAxis),
      odVl: odVl == null && nullToAbsent ? const Value.absent() : Value(odVl),
      odK1: odK1 == null && nullToAbsent ? const Value.absent() : Value(odK1),
      odK2: odK2 == null && nullToAbsent ? const Value.absent() : Value(odK2),
      odR1: odR1 == null && nullToAbsent ? const Value.absent() : Value(odR1),
      odR2: odR2 == null && nullToAbsent ? const Value.absent() : Value(odR2),
      odR0: odR0 == null && nullToAbsent ? const Value.absent() : Value(odR0),
      odPachy: odPachy == null && nullToAbsent
          ? const Value.absent()
          : Value(odPachy),
      odToc:
          odToc == null && nullToAbsent ? const Value.absent() : Value(odToc),
      odNotes: odNotes == null && nullToAbsent
          ? const Value.absent()
          : Value(odNotes),
      odGonio: odGonio == null && nullToAbsent
          ? const Value.absent()
          : Value(odGonio),
      odTo: odTo == null && nullToAbsent ? const Value.absent() : Value(odTo),
      odLaf:
          odLaf == null && nullToAbsent ? const Value.absent() : Value(odLaf),
      odFo: odFo == null && nullToAbsent ? const Value.absent() : Value(odFo),
      ogSv: ogSv == null && nullToAbsent ? const Value.absent() : Value(ogSv),
      ogAv: ogAv == null && nullToAbsent ? const Value.absent() : Value(ogAv),
      ogSphere: ogSphere == null && nullToAbsent
          ? const Value.absent()
          : Value(ogSphere),
      ogCylinder: ogCylinder == null && nullToAbsent
          ? const Value.absent()
          : Value(ogCylinder),
      ogAxis:
          ogAxis == null && nullToAbsent ? const Value.absent() : Value(ogAxis),
      ogVl: ogVl == null && nullToAbsent ? const Value.absent() : Value(ogVl),
      ogK1: ogK1 == null && nullToAbsent ? const Value.absent() : Value(ogK1),
      ogK2: ogK2 == null && nullToAbsent ? const Value.absent() : Value(ogK2),
      ogR1: ogR1 == null && nullToAbsent ? const Value.absent() : Value(ogR1),
      ogR2: ogR2 == null && nullToAbsent ? const Value.absent() : Value(ogR2),
      ogR0: ogR0 == null && nullToAbsent ? const Value.absent() : Value(ogR0),
      ogPachy: ogPachy == null && nullToAbsent
          ? const Value.absent()
          : Value(ogPachy),
      ogToc:
          ogToc == null && nullToAbsent ? const Value.absent() : Value(ogToc),
      ogNotes: ogNotes == null && nullToAbsent
          ? const Value.absent()
          : Value(ogNotes),
      ogGonio: ogGonio == null && nullToAbsent
          ? const Value.absent()
          : Value(ogGonio),
      ogTo: ogTo == null && nullToAbsent ? const Value.absent() : Value(ogTo),
      ogLaf:
          ogLaf == null && nullToAbsent ? const Value.absent() : Value(ogLaf),
      ogFo: ogFo == null && nullToAbsent ? const Value.absent() : Value(ogFo),
      addition: addition == null && nullToAbsent
          ? const Value.absent()
          : Value(addition),
      dip: dip == null && nullToAbsent ? const Value.absent() : Value(dip),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      needsSync: Value(needsSync),
      isActive: Value(isActive),
    );
  }

  factory Visit.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Visit(
      id: serializer.fromJson<int>(json['id']),
      originalId: serializer.fromJson<int?>(json['originalId']),
      patientCode: serializer.fromJson<int>(json['patientCode']),
      visitSequence: serializer.fromJson<int>(json['visitSequence']),
      visitDate: serializer.fromJson<DateTime>(json['visitDate']),
      doctorName: serializer.fromJson<String>(json['doctorName']),
      motif: serializer.fromJson<String?>(json['motif']),
      diagnosis: serializer.fromJson<String?>(json['diagnosis']),
      conduct: serializer.fromJson<String?>(json['conduct']),
      odSv: serializer.fromJson<String?>(json['odSv']),
      odAv: serializer.fromJson<String?>(json['odAv']),
      odSphere: serializer.fromJson<String?>(json['odSphere']),
      odCylinder: serializer.fromJson<String?>(json['odCylinder']),
      odAxis: serializer.fromJson<String?>(json['odAxis']),
      odVl: serializer.fromJson<String?>(json['odVl']),
      odK1: serializer.fromJson<String?>(json['odK1']),
      odK2: serializer.fromJson<String?>(json['odK2']),
      odR1: serializer.fromJson<String?>(json['odR1']),
      odR2: serializer.fromJson<String?>(json['odR2']),
      odR0: serializer.fromJson<String?>(json['odR0']),
      odPachy: serializer.fromJson<String?>(json['odPachy']),
      odToc: serializer.fromJson<String?>(json['odToc']),
      odNotes: serializer.fromJson<String?>(json['odNotes']),
      odGonio: serializer.fromJson<String?>(json['odGonio']),
      odTo: serializer.fromJson<String?>(json['odTo']),
      odLaf: serializer.fromJson<String?>(json['odLaf']),
      odFo: serializer.fromJson<String?>(json['odFo']),
      ogSv: serializer.fromJson<String?>(json['ogSv']),
      ogAv: serializer.fromJson<String?>(json['ogAv']),
      ogSphere: serializer.fromJson<String?>(json['ogSphere']),
      ogCylinder: serializer.fromJson<String?>(json['ogCylinder']),
      ogAxis: serializer.fromJson<String?>(json['ogAxis']),
      ogVl: serializer.fromJson<String?>(json['ogVl']),
      ogK1: serializer.fromJson<String?>(json['ogK1']),
      ogK2: serializer.fromJson<String?>(json['ogK2']),
      ogR1: serializer.fromJson<String?>(json['ogR1']),
      ogR2: serializer.fromJson<String?>(json['ogR2']),
      ogR0: serializer.fromJson<String?>(json['ogR0']),
      ogPachy: serializer.fromJson<String?>(json['ogPachy']),
      ogToc: serializer.fromJson<String?>(json['ogToc']),
      ogNotes: serializer.fromJson<String?>(json['ogNotes']),
      ogGonio: serializer.fromJson<String?>(json['ogGonio']),
      ogTo: serializer.fromJson<String?>(json['ogTo']),
      ogLaf: serializer.fromJson<String?>(json['ogLaf']),
      ogFo: serializer.fromJson<String?>(json['ogFo']),
      addition: serializer.fromJson<String?>(json['addition']),
      dip: serializer.fromJson<String?>(json['dip']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      needsSync: serializer.fromJson<bool>(json['needsSync']),
      isActive: serializer.fromJson<bool>(json['isActive']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'originalId': serializer.toJson<int?>(originalId),
      'patientCode': serializer.toJson<int>(patientCode),
      'visitSequence': serializer.toJson<int>(visitSequence),
      'visitDate': serializer.toJson<DateTime>(visitDate),
      'doctorName': serializer.toJson<String>(doctorName),
      'motif': serializer.toJson<String?>(motif),
      'diagnosis': serializer.toJson<String?>(diagnosis),
      'conduct': serializer.toJson<String?>(conduct),
      'odSv': serializer.toJson<String?>(odSv),
      'odAv': serializer.toJson<String?>(odAv),
      'odSphere': serializer.toJson<String?>(odSphere),
      'odCylinder': serializer.toJson<String?>(odCylinder),
      'odAxis': serializer.toJson<String?>(odAxis),
      'odVl': serializer.toJson<String?>(odVl),
      'odK1': serializer.toJson<String?>(odK1),
      'odK2': serializer.toJson<String?>(odK2),
      'odR1': serializer.toJson<String?>(odR1),
      'odR2': serializer.toJson<String?>(odR2),
      'odR0': serializer.toJson<String?>(odR0),
      'odPachy': serializer.toJson<String?>(odPachy),
      'odToc': serializer.toJson<String?>(odToc),
      'odNotes': serializer.toJson<String?>(odNotes),
      'odGonio': serializer.toJson<String?>(odGonio),
      'odTo': serializer.toJson<String?>(odTo),
      'odLaf': serializer.toJson<String?>(odLaf),
      'odFo': serializer.toJson<String?>(odFo),
      'ogSv': serializer.toJson<String?>(ogSv),
      'ogAv': serializer.toJson<String?>(ogAv),
      'ogSphere': serializer.toJson<String?>(ogSphere),
      'ogCylinder': serializer.toJson<String?>(ogCylinder),
      'ogAxis': serializer.toJson<String?>(ogAxis),
      'ogVl': serializer.toJson<String?>(ogVl),
      'ogK1': serializer.toJson<String?>(ogK1),
      'ogK2': serializer.toJson<String?>(ogK2),
      'ogR1': serializer.toJson<String?>(ogR1),
      'ogR2': serializer.toJson<String?>(ogR2),
      'ogR0': serializer.toJson<String?>(ogR0),
      'ogPachy': serializer.toJson<String?>(ogPachy),
      'ogToc': serializer.toJson<String?>(ogToc),
      'ogNotes': serializer.toJson<String?>(ogNotes),
      'ogGonio': serializer.toJson<String?>(ogGonio),
      'ogTo': serializer.toJson<String?>(ogTo),
      'ogLaf': serializer.toJson<String?>(ogLaf),
      'ogFo': serializer.toJson<String?>(ogFo),
      'addition': serializer.toJson<String?>(addition),
      'dip': serializer.toJson<String?>(dip),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'needsSync': serializer.toJson<bool>(needsSync),
      'isActive': serializer.toJson<bool>(isActive),
    };
  }

  Visit copyWith(
          {int? id,
          Value<int?> originalId = const Value.absent(),
          int? patientCode,
          int? visitSequence,
          DateTime? visitDate,
          String? doctorName,
          Value<String?> motif = const Value.absent(),
          Value<String?> diagnosis = const Value.absent(),
          Value<String?> conduct = const Value.absent(),
          Value<String?> odSv = const Value.absent(),
          Value<String?> odAv = const Value.absent(),
          Value<String?> odSphere = const Value.absent(),
          Value<String?> odCylinder = const Value.absent(),
          Value<String?> odAxis = const Value.absent(),
          Value<String?> odVl = const Value.absent(),
          Value<String?> odK1 = const Value.absent(),
          Value<String?> odK2 = const Value.absent(),
          Value<String?> odR1 = const Value.absent(),
          Value<String?> odR2 = const Value.absent(),
          Value<String?> odR0 = const Value.absent(),
          Value<String?> odPachy = const Value.absent(),
          Value<String?> odToc = const Value.absent(),
          Value<String?> odNotes = const Value.absent(),
          Value<String?> odGonio = const Value.absent(),
          Value<String?> odTo = const Value.absent(),
          Value<String?> odLaf = const Value.absent(),
          Value<String?> odFo = const Value.absent(),
          Value<String?> ogSv = const Value.absent(),
          Value<String?> ogAv = const Value.absent(),
          Value<String?> ogSphere = const Value.absent(),
          Value<String?> ogCylinder = const Value.absent(),
          Value<String?> ogAxis = const Value.absent(),
          Value<String?> ogVl = const Value.absent(),
          Value<String?> ogK1 = const Value.absent(),
          Value<String?> ogK2 = const Value.absent(),
          Value<String?> ogR1 = const Value.absent(),
          Value<String?> ogR2 = const Value.absent(),
          Value<String?> ogR0 = const Value.absent(),
          Value<String?> ogPachy = const Value.absent(),
          Value<String?> ogToc = const Value.absent(),
          Value<String?> ogNotes = const Value.absent(),
          Value<String?> ogGonio = const Value.absent(),
          Value<String?> ogTo = const Value.absent(),
          Value<String?> ogLaf = const Value.absent(),
          Value<String?> ogFo = const Value.absent(),
          Value<String?> addition = const Value.absent(),
          Value<String?> dip = const Value.absent(),
          DateTime? createdAt,
          DateTime? updatedAt,
          bool? needsSync,
          bool? isActive}) =>
      Visit(
        id: id ?? this.id,
        originalId: originalId.present ? originalId.value : this.originalId,
        patientCode: patientCode ?? this.patientCode,
        visitSequence: visitSequence ?? this.visitSequence,
        visitDate: visitDate ?? this.visitDate,
        doctorName: doctorName ?? this.doctorName,
        motif: motif.present ? motif.value : this.motif,
        diagnosis: diagnosis.present ? diagnosis.value : this.diagnosis,
        conduct: conduct.present ? conduct.value : this.conduct,
        odSv: odSv.present ? odSv.value : this.odSv,
        odAv: odAv.present ? odAv.value : this.odAv,
        odSphere: odSphere.present ? odSphere.value : this.odSphere,
        odCylinder: odCylinder.present ? odCylinder.value : this.odCylinder,
        odAxis: odAxis.present ? odAxis.value : this.odAxis,
        odVl: odVl.present ? odVl.value : this.odVl,
        odK1: odK1.present ? odK1.value : this.odK1,
        odK2: odK2.present ? odK2.value : this.odK2,
        odR1: odR1.present ? odR1.value : this.odR1,
        odR2: odR2.present ? odR2.value : this.odR2,
        odR0: odR0.present ? odR0.value : this.odR0,
        odPachy: odPachy.present ? odPachy.value : this.odPachy,
        odToc: odToc.present ? odToc.value : this.odToc,
        odNotes: odNotes.present ? odNotes.value : this.odNotes,
        odGonio: odGonio.present ? odGonio.value : this.odGonio,
        odTo: odTo.present ? odTo.value : this.odTo,
        odLaf: odLaf.present ? odLaf.value : this.odLaf,
        odFo: odFo.present ? odFo.value : this.odFo,
        ogSv: ogSv.present ? ogSv.value : this.ogSv,
        ogAv: ogAv.present ? ogAv.value : this.ogAv,
        ogSphere: ogSphere.present ? ogSphere.value : this.ogSphere,
        ogCylinder: ogCylinder.present ? ogCylinder.value : this.ogCylinder,
        ogAxis: ogAxis.present ? ogAxis.value : this.ogAxis,
        ogVl: ogVl.present ? ogVl.value : this.ogVl,
        ogK1: ogK1.present ? ogK1.value : this.ogK1,
        ogK2: ogK2.present ? ogK2.value : this.ogK2,
        ogR1: ogR1.present ? ogR1.value : this.ogR1,
        ogR2: ogR2.present ? ogR2.value : this.ogR2,
        ogR0: ogR0.present ? ogR0.value : this.ogR0,
        ogPachy: ogPachy.present ? ogPachy.value : this.ogPachy,
        ogToc: ogToc.present ? ogToc.value : this.ogToc,
        ogNotes: ogNotes.present ? ogNotes.value : this.ogNotes,
        ogGonio: ogGonio.present ? ogGonio.value : this.ogGonio,
        ogTo: ogTo.present ? ogTo.value : this.ogTo,
        ogLaf: ogLaf.present ? ogLaf.value : this.ogLaf,
        ogFo: ogFo.present ? ogFo.value : this.ogFo,
        addition: addition.present ? addition.value : this.addition,
        dip: dip.present ? dip.value : this.dip,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        needsSync: needsSync ?? this.needsSync,
        isActive: isActive ?? this.isActive,
      );
  Visit copyWithCompanion(VisitsCompanion data) {
    return Visit(
      id: data.id.present ? data.id.value : this.id,
      originalId:
          data.originalId.present ? data.originalId.value : this.originalId,
      patientCode:
          data.patientCode.present ? data.patientCode.value : this.patientCode,
      visitSequence: data.visitSequence.present
          ? data.visitSequence.value
          : this.visitSequence,
      visitDate: data.visitDate.present ? data.visitDate.value : this.visitDate,
      doctorName:
          data.doctorName.present ? data.doctorName.value : this.doctorName,
      motif: data.motif.present ? data.motif.value : this.motif,
      diagnosis: data.diagnosis.present ? data.diagnosis.value : this.diagnosis,
      conduct: data.conduct.present ? data.conduct.value : this.conduct,
      odSv: data.odSv.present ? data.odSv.value : this.odSv,
      odAv: data.odAv.present ? data.odAv.value : this.odAv,
      odSphere: data.odSphere.present ? data.odSphere.value : this.odSphere,
      odCylinder:
          data.odCylinder.present ? data.odCylinder.value : this.odCylinder,
      odAxis: data.odAxis.present ? data.odAxis.value : this.odAxis,
      odVl: data.odVl.present ? data.odVl.value : this.odVl,
      odK1: data.odK1.present ? data.odK1.value : this.odK1,
      odK2: data.odK2.present ? data.odK2.value : this.odK2,
      odR1: data.odR1.present ? data.odR1.value : this.odR1,
      odR2: data.odR2.present ? data.odR2.value : this.odR2,
      odR0: data.odR0.present ? data.odR0.value : this.odR0,
      odPachy: data.odPachy.present ? data.odPachy.value : this.odPachy,
      odToc: data.odToc.present ? data.odToc.value : this.odToc,
      odNotes: data.odNotes.present ? data.odNotes.value : this.odNotes,
      odGonio: data.odGonio.present ? data.odGonio.value : this.odGonio,
      odTo: data.odTo.present ? data.odTo.value : this.odTo,
      odLaf: data.odLaf.present ? data.odLaf.value : this.odLaf,
      odFo: data.odFo.present ? data.odFo.value : this.odFo,
      ogSv: data.ogSv.present ? data.ogSv.value : this.ogSv,
      ogAv: data.ogAv.present ? data.ogAv.value : this.ogAv,
      ogSphere: data.ogSphere.present ? data.ogSphere.value : this.ogSphere,
      ogCylinder:
          data.ogCylinder.present ? data.ogCylinder.value : this.ogCylinder,
      ogAxis: data.ogAxis.present ? data.ogAxis.value : this.ogAxis,
      ogVl: data.ogVl.present ? data.ogVl.value : this.ogVl,
      ogK1: data.ogK1.present ? data.ogK1.value : this.ogK1,
      ogK2: data.ogK2.present ? data.ogK2.value : this.ogK2,
      ogR1: data.ogR1.present ? data.ogR1.value : this.ogR1,
      ogR2: data.ogR2.present ? data.ogR2.value : this.ogR2,
      ogR0: data.ogR0.present ? data.ogR0.value : this.ogR0,
      ogPachy: data.ogPachy.present ? data.ogPachy.value : this.ogPachy,
      ogToc: data.ogToc.present ? data.ogToc.value : this.ogToc,
      ogNotes: data.ogNotes.present ? data.ogNotes.value : this.ogNotes,
      ogGonio: data.ogGonio.present ? data.ogGonio.value : this.ogGonio,
      ogTo: data.ogTo.present ? data.ogTo.value : this.ogTo,
      ogLaf: data.ogLaf.present ? data.ogLaf.value : this.ogLaf,
      ogFo: data.ogFo.present ? data.ogFo.value : this.ogFo,
      addition: data.addition.present ? data.addition.value : this.addition,
      dip: data.dip.present ? data.dip.value : this.dip,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      needsSync: data.needsSync.present ? data.needsSync.value : this.needsSync,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Visit(')
          ..write('id: $id, ')
          ..write('originalId: $originalId, ')
          ..write('patientCode: $patientCode, ')
          ..write('visitSequence: $visitSequence, ')
          ..write('visitDate: $visitDate, ')
          ..write('doctorName: $doctorName, ')
          ..write('motif: $motif, ')
          ..write('diagnosis: $diagnosis, ')
          ..write('conduct: $conduct, ')
          ..write('odSv: $odSv, ')
          ..write('odAv: $odAv, ')
          ..write('odSphere: $odSphere, ')
          ..write('odCylinder: $odCylinder, ')
          ..write('odAxis: $odAxis, ')
          ..write('odVl: $odVl, ')
          ..write('odK1: $odK1, ')
          ..write('odK2: $odK2, ')
          ..write('odR1: $odR1, ')
          ..write('odR2: $odR2, ')
          ..write('odR0: $odR0, ')
          ..write('odPachy: $odPachy, ')
          ..write('odToc: $odToc, ')
          ..write('odNotes: $odNotes, ')
          ..write('odGonio: $odGonio, ')
          ..write('odTo: $odTo, ')
          ..write('odLaf: $odLaf, ')
          ..write('odFo: $odFo, ')
          ..write('ogSv: $ogSv, ')
          ..write('ogAv: $ogAv, ')
          ..write('ogSphere: $ogSphere, ')
          ..write('ogCylinder: $ogCylinder, ')
          ..write('ogAxis: $ogAxis, ')
          ..write('ogVl: $ogVl, ')
          ..write('ogK1: $ogK1, ')
          ..write('ogK2: $ogK2, ')
          ..write('ogR1: $ogR1, ')
          ..write('ogR2: $ogR2, ')
          ..write('ogR0: $ogR0, ')
          ..write('ogPachy: $ogPachy, ')
          ..write('ogToc: $ogToc, ')
          ..write('ogNotes: $ogNotes, ')
          ..write('ogGonio: $ogGonio, ')
          ..write('ogTo: $ogTo, ')
          ..write('ogLaf: $ogLaf, ')
          ..write('ogFo: $ogFo, ')
          ..write('addition: $addition, ')
          ..write('dip: $dip, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('needsSync: $needsSync, ')
          ..write('isActive: $isActive')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
        id,
        originalId,
        patientCode,
        visitSequence,
        visitDate,
        doctorName,
        motif,
        diagnosis,
        conduct,
        odSv,
        odAv,
        odSphere,
        odCylinder,
        odAxis,
        odVl,
        odK1,
        odK2,
        odR1,
        odR2,
        odR0,
        odPachy,
        odToc,
        odNotes,
        odGonio,
        odTo,
        odLaf,
        odFo,
        ogSv,
        ogAv,
        ogSphere,
        ogCylinder,
        ogAxis,
        ogVl,
        ogK1,
        ogK2,
        ogR1,
        ogR2,
        ogR0,
        ogPachy,
        ogToc,
        ogNotes,
        ogGonio,
        ogTo,
        ogLaf,
        ogFo,
        addition,
        dip,
        createdAt,
        updatedAt,
        needsSync,
        isActive
      ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Visit &&
          other.id == this.id &&
          other.originalId == this.originalId &&
          other.patientCode == this.patientCode &&
          other.visitSequence == this.visitSequence &&
          other.visitDate == this.visitDate &&
          other.doctorName == this.doctorName &&
          other.motif == this.motif &&
          other.diagnosis == this.diagnosis &&
          other.conduct == this.conduct &&
          other.odSv == this.odSv &&
          other.odAv == this.odAv &&
          other.odSphere == this.odSphere &&
          other.odCylinder == this.odCylinder &&
          other.odAxis == this.odAxis &&
          other.odVl == this.odVl &&
          other.odK1 == this.odK1 &&
          other.odK2 == this.odK2 &&
          other.odR1 == this.odR1 &&
          other.odR2 == this.odR2 &&
          other.odR0 == this.odR0 &&
          other.odPachy == this.odPachy &&
          other.odToc == this.odToc &&
          other.odNotes == this.odNotes &&
          other.odGonio == this.odGonio &&
          other.odTo == this.odTo &&
          other.odLaf == this.odLaf &&
          other.odFo == this.odFo &&
          other.ogSv == this.ogSv &&
          other.ogAv == this.ogAv &&
          other.ogSphere == this.ogSphere &&
          other.ogCylinder == this.ogCylinder &&
          other.ogAxis == this.ogAxis &&
          other.ogVl == this.ogVl &&
          other.ogK1 == this.ogK1 &&
          other.ogK2 == this.ogK2 &&
          other.ogR1 == this.ogR1 &&
          other.ogR2 == this.ogR2 &&
          other.ogR0 == this.ogR0 &&
          other.ogPachy == this.ogPachy &&
          other.ogToc == this.ogToc &&
          other.ogNotes == this.ogNotes &&
          other.ogGonio == this.ogGonio &&
          other.ogTo == this.ogTo &&
          other.ogLaf == this.ogLaf &&
          other.ogFo == this.ogFo &&
          other.addition == this.addition &&
          other.dip == this.dip &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.needsSync == this.needsSync &&
          other.isActive == this.isActive);
}

class VisitsCompanion extends UpdateCompanion<Visit> {
  final Value<int> id;
  final Value<int?> originalId;
  final Value<int> patientCode;
  final Value<int> visitSequence;
  final Value<DateTime> visitDate;
  final Value<String> doctorName;
  final Value<String?> motif;
  final Value<String?> diagnosis;
  final Value<String?> conduct;
  final Value<String?> odSv;
  final Value<String?> odAv;
  final Value<String?> odSphere;
  final Value<String?> odCylinder;
  final Value<String?> odAxis;
  final Value<String?> odVl;
  final Value<String?> odK1;
  final Value<String?> odK2;
  final Value<String?> odR1;
  final Value<String?> odR2;
  final Value<String?> odR0;
  final Value<String?> odPachy;
  final Value<String?> odToc;
  final Value<String?> odNotes;
  final Value<String?> odGonio;
  final Value<String?> odTo;
  final Value<String?> odLaf;
  final Value<String?> odFo;
  final Value<String?> ogSv;
  final Value<String?> ogAv;
  final Value<String?> ogSphere;
  final Value<String?> ogCylinder;
  final Value<String?> ogAxis;
  final Value<String?> ogVl;
  final Value<String?> ogK1;
  final Value<String?> ogK2;
  final Value<String?> ogR1;
  final Value<String?> ogR2;
  final Value<String?> ogR0;
  final Value<String?> ogPachy;
  final Value<String?> ogToc;
  final Value<String?> ogNotes;
  final Value<String?> ogGonio;
  final Value<String?> ogTo;
  final Value<String?> ogLaf;
  final Value<String?> ogFo;
  final Value<String?> addition;
  final Value<String?> dip;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<bool> needsSync;
  final Value<bool> isActive;
  const VisitsCompanion({
    this.id = const Value.absent(),
    this.originalId = const Value.absent(),
    this.patientCode = const Value.absent(),
    this.visitSequence = const Value.absent(),
    this.visitDate = const Value.absent(),
    this.doctorName = const Value.absent(),
    this.motif = const Value.absent(),
    this.diagnosis = const Value.absent(),
    this.conduct = const Value.absent(),
    this.odSv = const Value.absent(),
    this.odAv = const Value.absent(),
    this.odSphere = const Value.absent(),
    this.odCylinder = const Value.absent(),
    this.odAxis = const Value.absent(),
    this.odVl = const Value.absent(),
    this.odK1 = const Value.absent(),
    this.odK2 = const Value.absent(),
    this.odR1 = const Value.absent(),
    this.odR2 = const Value.absent(),
    this.odR0 = const Value.absent(),
    this.odPachy = const Value.absent(),
    this.odToc = const Value.absent(),
    this.odNotes = const Value.absent(),
    this.odGonio = const Value.absent(),
    this.odTo = const Value.absent(),
    this.odLaf = const Value.absent(),
    this.odFo = const Value.absent(),
    this.ogSv = const Value.absent(),
    this.ogAv = const Value.absent(),
    this.ogSphere = const Value.absent(),
    this.ogCylinder = const Value.absent(),
    this.ogAxis = const Value.absent(),
    this.ogVl = const Value.absent(),
    this.ogK1 = const Value.absent(),
    this.ogK2 = const Value.absent(),
    this.ogR1 = const Value.absent(),
    this.ogR2 = const Value.absent(),
    this.ogR0 = const Value.absent(),
    this.ogPachy = const Value.absent(),
    this.ogToc = const Value.absent(),
    this.ogNotes = const Value.absent(),
    this.ogGonio = const Value.absent(),
    this.ogTo = const Value.absent(),
    this.ogLaf = const Value.absent(),
    this.ogFo = const Value.absent(),
    this.addition = const Value.absent(),
    this.dip = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.needsSync = const Value.absent(),
    this.isActive = const Value.absent(),
  });
  VisitsCompanion.insert({
    this.id = const Value.absent(),
    this.originalId = const Value.absent(),
    required int patientCode,
    this.visitSequence = const Value.absent(),
    required DateTime visitDate,
    required String doctorName,
    this.motif = const Value.absent(),
    this.diagnosis = const Value.absent(),
    this.conduct = const Value.absent(),
    this.odSv = const Value.absent(),
    this.odAv = const Value.absent(),
    this.odSphere = const Value.absent(),
    this.odCylinder = const Value.absent(),
    this.odAxis = const Value.absent(),
    this.odVl = const Value.absent(),
    this.odK1 = const Value.absent(),
    this.odK2 = const Value.absent(),
    this.odR1 = const Value.absent(),
    this.odR2 = const Value.absent(),
    this.odR0 = const Value.absent(),
    this.odPachy = const Value.absent(),
    this.odToc = const Value.absent(),
    this.odNotes = const Value.absent(),
    this.odGonio = const Value.absent(),
    this.odTo = const Value.absent(),
    this.odLaf = const Value.absent(),
    this.odFo = const Value.absent(),
    this.ogSv = const Value.absent(),
    this.ogAv = const Value.absent(),
    this.ogSphere = const Value.absent(),
    this.ogCylinder = const Value.absent(),
    this.ogAxis = const Value.absent(),
    this.ogVl = const Value.absent(),
    this.ogK1 = const Value.absent(),
    this.ogK2 = const Value.absent(),
    this.ogR1 = const Value.absent(),
    this.ogR2 = const Value.absent(),
    this.ogR0 = const Value.absent(),
    this.ogPachy = const Value.absent(),
    this.ogToc = const Value.absent(),
    this.ogNotes = const Value.absent(),
    this.ogGonio = const Value.absent(),
    this.ogTo = const Value.absent(),
    this.ogLaf = const Value.absent(),
    this.ogFo = const Value.absent(),
    this.addition = const Value.absent(),
    this.dip = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.needsSync = const Value.absent(),
    this.isActive = const Value.absent(),
  })  : patientCode = Value(patientCode),
        visitDate = Value(visitDate),
        doctorName = Value(doctorName),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<Visit> custom({
    Expression<int>? id,
    Expression<int>? originalId,
    Expression<int>? patientCode,
    Expression<int>? visitSequence,
    Expression<DateTime>? visitDate,
    Expression<String>? doctorName,
    Expression<String>? motif,
    Expression<String>? diagnosis,
    Expression<String>? conduct,
    Expression<String>? odSv,
    Expression<String>? odAv,
    Expression<String>? odSphere,
    Expression<String>? odCylinder,
    Expression<String>? odAxis,
    Expression<String>? odVl,
    Expression<String>? odK1,
    Expression<String>? odK2,
    Expression<String>? odR1,
    Expression<String>? odR2,
    Expression<String>? odR0,
    Expression<String>? odPachy,
    Expression<String>? odToc,
    Expression<String>? odNotes,
    Expression<String>? odGonio,
    Expression<String>? odTo,
    Expression<String>? odLaf,
    Expression<String>? odFo,
    Expression<String>? ogSv,
    Expression<String>? ogAv,
    Expression<String>? ogSphere,
    Expression<String>? ogCylinder,
    Expression<String>? ogAxis,
    Expression<String>? ogVl,
    Expression<String>? ogK1,
    Expression<String>? ogK2,
    Expression<String>? ogR1,
    Expression<String>? ogR2,
    Expression<String>? ogR0,
    Expression<String>? ogPachy,
    Expression<String>? ogToc,
    Expression<String>? ogNotes,
    Expression<String>? ogGonio,
    Expression<String>? ogTo,
    Expression<String>? ogLaf,
    Expression<String>? ogFo,
    Expression<String>? addition,
    Expression<String>? dip,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<bool>? needsSync,
    Expression<bool>? isActive,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (originalId != null) 'original_id': originalId,
      if (patientCode != null) 'patient_code': patientCode,
      if (visitSequence != null) 'visit_sequence': visitSequence,
      if (visitDate != null) 'visit_date': visitDate,
      if (doctorName != null) 'doctor_name': doctorName,
      if (motif != null) 'motif': motif,
      if (diagnosis != null) 'diagnosis': diagnosis,
      if (conduct != null) 'conduct': conduct,
      if (odSv != null) 'od_sv': odSv,
      if (odAv != null) 'od_av': odAv,
      if (odSphere != null) 'od_sphere': odSphere,
      if (odCylinder != null) 'od_cylinder': odCylinder,
      if (odAxis != null) 'od_axis': odAxis,
      if (odVl != null) 'od_vl': odVl,
      if (odK1 != null) 'od_k1': odK1,
      if (odK2 != null) 'od_k2': odK2,
      if (odR1 != null) 'od_r1': odR1,
      if (odR2 != null) 'od_r2': odR2,
      if (odR0 != null) 'od_r0': odR0,
      if (odPachy != null) 'od_pachy': odPachy,
      if (odToc != null) 'od_toc': odToc,
      if (odNotes != null) 'od_notes': odNotes,
      if (odGonio != null) 'od_gonio': odGonio,
      if (odTo != null) 'od_to': odTo,
      if (odLaf != null) 'od_laf': odLaf,
      if (odFo != null) 'od_fo': odFo,
      if (ogSv != null) 'og_sv': ogSv,
      if (ogAv != null) 'og_av': ogAv,
      if (ogSphere != null) 'og_sphere': ogSphere,
      if (ogCylinder != null) 'og_cylinder': ogCylinder,
      if (ogAxis != null) 'og_axis': ogAxis,
      if (ogVl != null) 'og_vl': ogVl,
      if (ogK1 != null) 'og_k1': ogK1,
      if (ogK2 != null) 'og_k2': ogK2,
      if (ogR1 != null) 'og_r1': ogR1,
      if (ogR2 != null) 'og_r2': ogR2,
      if (ogR0 != null) 'og_r0': ogR0,
      if (ogPachy != null) 'og_pachy': ogPachy,
      if (ogToc != null) 'og_toc': ogToc,
      if (ogNotes != null) 'og_notes': ogNotes,
      if (ogGonio != null) 'og_gonio': ogGonio,
      if (ogTo != null) 'og_to': ogTo,
      if (ogLaf != null) 'og_laf': ogLaf,
      if (ogFo != null) 'og_fo': ogFo,
      if (addition != null) 'addition': addition,
      if (dip != null) 'dip': dip,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (needsSync != null) 'needs_sync': needsSync,
      if (isActive != null) 'is_active': isActive,
    });
  }

  VisitsCompanion copyWith(
      {Value<int>? id,
      Value<int?>? originalId,
      Value<int>? patientCode,
      Value<int>? visitSequence,
      Value<DateTime>? visitDate,
      Value<String>? doctorName,
      Value<String?>? motif,
      Value<String?>? diagnosis,
      Value<String?>? conduct,
      Value<String?>? odSv,
      Value<String?>? odAv,
      Value<String?>? odSphere,
      Value<String?>? odCylinder,
      Value<String?>? odAxis,
      Value<String?>? odVl,
      Value<String?>? odK1,
      Value<String?>? odK2,
      Value<String?>? odR1,
      Value<String?>? odR2,
      Value<String?>? odR0,
      Value<String?>? odPachy,
      Value<String?>? odToc,
      Value<String?>? odNotes,
      Value<String?>? odGonio,
      Value<String?>? odTo,
      Value<String?>? odLaf,
      Value<String?>? odFo,
      Value<String?>? ogSv,
      Value<String?>? ogAv,
      Value<String?>? ogSphere,
      Value<String?>? ogCylinder,
      Value<String?>? ogAxis,
      Value<String?>? ogVl,
      Value<String?>? ogK1,
      Value<String?>? ogK2,
      Value<String?>? ogR1,
      Value<String?>? ogR2,
      Value<String?>? ogR0,
      Value<String?>? ogPachy,
      Value<String?>? ogToc,
      Value<String?>? ogNotes,
      Value<String?>? ogGonio,
      Value<String?>? ogTo,
      Value<String?>? ogLaf,
      Value<String?>? ogFo,
      Value<String?>? addition,
      Value<String?>? dip,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<bool>? needsSync,
      Value<bool>? isActive}) {
    return VisitsCompanion(
      id: id ?? this.id,
      originalId: originalId ?? this.originalId,
      patientCode: patientCode ?? this.patientCode,
      visitSequence: visitSequence ?? this.visitSequence,
      visitDate: visitDate ?? this.visitDate,
      doctorName: doctorName ?? this.doctorName,
      motif: motif ?? this.motif,
      diagnosis: diagnosis ?? this.diagnosis,
      conduct: conduct ?? this.conduct,
      odSv: odSv ?? this.odSv,
      odAv: odAv ?? this.odAv,
      odSphere: odSphere ?? this.odSphere,
      odCylinder: odCylinder ?? this.odCylinder,
      odAxis: odAxis ?? this.odAxis,
      odVl: odVl ?? this.odVl,
      odK1: odK1 ?? this.odK1,
      odK2: odK2 ?? this.odK2,
      odR1: odR1 ?? this.odR1,
      odR2: odR2 ?? this.odR2,
      odR0: odR0 ?? this.odR0,
      odPachy: odPachy ?? this.odPachy,
      odToc: odToc ?? this.odToc,
      odNotes: odNotes ?? this.odNotes,
      odGonio: odGonio ?? this.odGonio,
      odTo: odTo ?? this.odTo,
      odLaf: odLaf ?? this.odLaf,
      odFo: odFo ?? this.odFo,
      ogSv: ogSv ?? this.ogSv,
      ogAv: ogAv ?? this.ogAv,
      ogSphere: ogSphere ?? this.ogSphere,
      ogCylinder: ogCylinder ?? this.ogCylinder,
      ogAxis: ogAxis ?? this.ogAxis,
      ogVl: ogVl ?? this.ogVl,
      ogK1: ogK1 ?? this.ogK1,
      ogK2: ogK2 ?? this.ogK2,
      ogR1: ogR1 ?? this.ogR1,
      ogR2: ogR2 ?? this.ogR2,
      ogR0: ogR0 ?? this.ogR0,
      ogPachy: ogPachy ?? this.ogPachy,
      ogToc: ogToc ?? this.ogToc,
      ogNotes: ogNotes ?? this.ogNotes,
      ogGonio: ogGonio ?? this.ogGonio,
      ogTo: ogTo ?? this.ogTo,
      ogLaf: ogLaf ?? this.ogLaf,
      ogFo: ogFo ?? this.ogFo,
      addition: addition ?? this.addition,
      dip: dip ?? this.dip,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      needsSync: needsSync ?? this.needsSync,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (originalId.present) {
      map['original_id'] = Variable<int>(originalId.value);
    }
    if (patientCode.present) {
      map['patient_code'] = Variable<int>(patientCode.value);
    }
    if (visitSequence.present) {
      map['visit_sequence'] = Variable<int>(visitSequence.value);
    }
    if (visitDate.present) {
      map['visit_date'] = Variable<DateTime>(visitDate.value);
    }
    if (doctorName.present) {
      map['doctor_name'] = Variable<String>(doctorName.value);
    }
    if (motif.present) {
      map['motif'] = Variable<String>(motif.value);
    }
    if (diagnosis.present) {
      map['diagnosis'] = Variable<String>(diagnosis.value);
    }
    if (conduct.present) {
      map['conduct'] = Variable<String>(conduct.value);
    }
    if (odSv.present) {
      map['od_sv'] = Variable<String>(odSv.value);
    }
    if (odAv.present) {
      map['od_av'] = Variable<String>(odAv.value);
    }
    if (odSphere.present) {
      map['od_sphere'] = Variable<String>(odSphere.value);
    }
    if (odCylinder.present) {
      map['od_cylinder'] = Variable<String>(odCylinder.value);
    }
    if (odAxis.present) {
      map['od_axis'] = Variable<String>(odAxis.value);
    }
    if (odVl.present) {
      map['od_vl'] = Variable<String>(odVl.value);
    }
    if (odK1.present) {
      map['od_k1'] = Variable<String>(odK1.value);
    }
    if (odK2.present) {
      map['od_k2'] = Variable<String>(odK2.value);
    }
    if (odR1.present) {
      map['od_r1'] = Variable<String>(odR1.value);
    }
    if (odR2.present) {
      map['od_r2'] = Variable<String>(odR2.value);
    }
    if (odR0.present) {
      map['od_r0'] = Variable<String>(odR0.value);
    }
    if (odPachy.present) {
      map['od_pachy'] = Variable<String>(odPachy.value);
    }
    if (odToc.present) {
      map['od_toc'] = Variable<String>(odToc.value);
    }
    if (odNotes.present) {
      map['od_notes'] = Variable<String>(odNotes.value);
    }
    if (odGonio.present) {
      map['od_gonio'] = Variable<String>(odGonio.value);
    }
    if (odTo.present) {
      map['od_to'] = Variable<String>(odTo.value);
    }
    if (odLaf.present) {
      map['od_laf'] = Variable<String>(odLaf.value);
    }
    if (odFo.present) {
      map['od_fo'] = Variable<String>(odFo.value);
    }
    if (ogSv.present) {
      map['og_sv'] = Variable<String>(ogSv.value);
    }
    if (ogAv.present) {
      map['og_av'] = Variable<String>(ogAv.value);
    }
    if (ogSphere.present) {
      map['og_sphere'] = Variable<String>(ogSphere.value);
    }
    if (ogCylinder.present) {
      map['og_cylinder'] = Variable<String>(ogCylinder.value);
    }
    if (ogAxis.present) {
      map['og_axis'] = Variable<String>(ogAxis.value);
    }
    if (ogVl.present) {
      map['og_vl'] = Variable<String>(ogVl.value);
    }
    if (ogK1.present) {
      map['og_k1'] = Variable<String>(ogK1.value);
    }
    if (ogK2.present) {
      map['og_k2'] = Variable<String>(ogK2.value);
    }
    if (ogR1.present) {
      map['og_r1'] = Variable<String>(ogR1.value);
    }
    if (ogR2.present) {
      map['og_r2'] = Variable<String>(ogR2.value);
    }
    if (ogR0.present) {
      map['og_r0'] = Variable<String>(ogR0.value);
    }
    if (ogPachy.present) {
      map['og_pachy'] = Variable<String>(ogPachy.value);
    }
    if (ogToc.present) {
      map['og_toc'] = Variable<String>(ogToc.value);
    }
    if (ogNotes.present) {
      map['og_notes'] = Variable<String>(ogNotes.value);
    }
    if (ogGonio.present) {
      map['og_gonio'] = Variable<String>(ogGonio.value);
    }
    if (ogTo.present) {
      map['og_to'] = Variable<String>(ogTo.value);
    }
    if (ogLaf.present) {
      map['og_laf'] = Variable<String>(ogLaf.value);
    }
    if (ogFo.present) {
      map['og_fo'] = Variable<String>(ogFo.value);
    }
    if (addition.present) {
      map['addition'] = Variable<String>(addition.value);
    }
    if (dip.present) {
      map['dip'] = Variable<String>(dip.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (needsSync.present) {
      map['needs_sync'] = Variable<bool>(needsSync.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VisitsCompanion(')
          ..write('id: $id, ')
          ..write('originalId: $originalId, ')
          ..write('patientCode: $patientCode, ')
          ..write('visitSequence: $visitSequence, ')
          ..write('visitDate: $visitDate, ')
          ..write('doctorName: $doctorName, ')
          ..write('motif: $motif, ')
          ..write('diagnosis: $diagnosis, ')
          ..write('conduct: $conduct, ')
          ..write('odSv: $odSv, ')
          ..write('odAv: $odAv, ')
          ..write('odSphere: $odSphere, ')
          ..write('odCylinder: $odCylinder, ')
          ..write('odAxis: $odAxis, ')
          ..write('odVl: $odVl, ')
          ..write('odK1: $odK1, ')
          ..write('odK2: $odK2, ')
          ..write('odR1: $odR1, ')
          ..write('odR2: $odR2, ')
          ..write('odR0: $odR0, ')
          ..write('odPachy: $odPachy, ')
          ..write('odToc: $odToc, ')
          ..write('odNotes: $odNotes, ')
          ..write('odGonio: $odGonio, ')
          ..write('odTo: $odTo, ')
          ..write('odLaf: $odLaf, ')
          ..write('odFo: $odFo, ')
          ..write('ogSv: $ogSv, ')
          ..write('ogAv: $ogAv, ')
          ..write('ogSphere: $ogSphere, ')
          ..write('ogCylinder: $ogCylinder, ')
          ..write('ogAxis: $ogAxis, ')
          ..write('ogVl: $ogVl, ')
          ..write('ogK1: $ogK1, ')
          ..write('ogK2: $ogK2, ')
          ..write('ogR1: $ogR1, ')
          ..write('ogR2: $ogR2, ')
          ..write('ogR0: $ogR0, ')
          ..write('ogPachy: $ogPachy, ')
          ..write('ogToc: $ogToc, ')
          ..write('ogNotes: $ogNotes, ')
          ..write('ogGonio: $ogGonio, ')
          ..write('ogTo: $ogTo, ')
          ..write('ogLaf: $ogLaf, ')
          ..write('ogFo: $ogFo, ')
          ..write('addition: $addition, ')
          ..write('dip: $dip, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('needsSync: $needsSync, ')
          ..write('isActive: $isActive')
          ..write(')'))
        .toString();
  }
}

class $WaitingPatientsTable extends WaitingPatients
    with TableInfo<$WaitingPatientsTable, WaitingPatient> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WaitingPatientsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _patientCodeMeta =
      const VerificationMeta('patientCode');
  @override
  late final GeneratedColumn<int> patientCode = GeneratedColumn<int>(
      'patient_code', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _patientFirstNameMeta =
      const VerificationMeta('patientFirstName');
  @override
  late final GeneratedColumn<String> patientFirstName = GeneratedColumn<String>(
      'patient_first_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _patientLastNameMeta =
      const VerificationMeta('patientLastName');
  @override
  late final GeneratedColumn<String> patientLastName = GeneratedColumn<String>(
      'patient_last_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _patientBirthDateMeta =
      const VerificationMeta('patientBirthDate');
  @override
  late final GeneratedColumn<DateTime> patientBirthDate =
      GeneratedColumn<DateTime>('patient_birth_date', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _patientAgeMeta =
      const VerificationMeta('patientAge');
  @override
  late final GeneratedColumn<int> patientAge = GeneratedColumn<int>(
      'patient_age', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _isUrgentMeta =
      const VerificationMeta('isUrgent');
  @override
  late final GeneratedColumn<bool> isUrgent = GeneratedColumn<bool>(
      'is_urgent', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_urgent" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _isDilatationMeta =
      const VerificationMeta('isDilatation');
  @override
  late final GeneratedColumn<bool> isDilatation = GeneratedColumn<bool>(
      'is_dilatation', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_dilatation" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _dilatationTypeMeta =
      const VerificationMeta('dilatationType');
  @override
  late final GeneratedColumn<String> dilatationType = GeneratedColumn<String>(
      'dilatation_type', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _roomIdMeta = const VerificationMeta('roomId');
  @override
  late final GeneratedColumn<String> roomId = GeneratedColumn<String>(
      'room_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _roomNameMeta =
      const VerificationMeta('roomName');
  @override
  late final GeneratedColumn<String> roomName = GeneratedColumn<String>(
      'room_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _motifMeta = const VerificationMeta('motif');
  @override
  late final GeneratedColumn<String> motif = GeneratedColumn<String>(
      'motif', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sentByUserIdMeta =
      const VerificationMeta('sentByUserId');
  @override
  late final GeneratedColumn<String> sentByUserId = GeneratedColumn<String>(
      'sent_by_user_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sentByUserNameMeta =
      const VerificationMeta('sentByUserName');
  @override
  late final GeneratedColumn<String> sentByUserName = GeneratedColumn<String>(
      'sent_by_user_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sentAtMeta = const VerificationMeta('sentAt');
  @override
  late final GeneratedColumn<DateTime> sentAt = GeneratedColumn<DateTime>(
      'sent_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _isCheckedMeta =
      const VerificationMeta('isChecked');
  @override
  late final GeneratedColumn<bool> isChecked = GeneratedColumn<bool>(
      'is_checked', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_checked" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _isActiveMeta =
      const VerificationMeta('isActive');
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
      'is_active', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_active" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _isNotifiedMeta =
      const VerificationMeta('isNotified');
  @override
  late final GeneratedColumn<bool> isNotified = GeneratedColumn<bool>(
      'is_notified', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_notified" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        patientCode,
        patientFirstName,
        patientLastName,
        patientBirthDate,
        patientAge,
        isUrgent,
        isDilatation,
        dilatationType,
        roomId,
        roomName,
        motif,
        sentByUserId,
        sentByUserName,
        sentAt,
        isChecked,
        isActive,
        isNotified
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'waiting_patients';
  @override
  VerificationContext validateIntegrity(Insertable<WaitingPatient> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('patient_code')) {
      context.handle(
          _patientCodeMeta,
          patientCode.isAcceptableOrUnknown(
              data['patient_code']!, _patientCodeMeta));
    } else if (isInserting) {
      context.missing(_patientCodeMeta);
    }
    if (data.containsKey('patient_first_name')) {
      context.handle(
          _patientFirstNameMeta,
          patientFirstName.isAcceptableOrUnknown(
              data['patient_first_name']!, _patientFirstNameMeta));
    } else if (isInserting) {
      context.missing(_patientFirstNameMeta);
    }
    if (data.containsKey('patient_last_name')) {
      context.handle(
          _patientLastNameMeta,
          patientLastName.isAcceptableOrUnknown(
              data['patient_last_name']!, _patientLastNameMeta));
    } else if (isInserting) {
      context.missing(_patientLastNameMeta);
    }
    if (data.containsKey('patient_birth_date')) {
      context.handle(
          _patientBirthDateMeta,
          patientBirthDate.isAcceptableOrUnknown(
              data['patient_birth_date']!, _patientBirthDateMeta));
    }
    if (data.containsKey('patient_age')) {
      context.handle(
          _patientAgeMeta,
          patientAge.isAcceptableOrUnknown(
              data['patient_age']!, _patientAgeMeta));
    }
    if (data.containsKey('is_urgent')) {
      context.handle(_isUrgentMeta,
          isUrgent.isAcceptableOrUnknown(data['is_urgent']!, _isUrgentMeta));
    }
    if (data.containsKey('is_dilatation')) {
      context.handle(
          _isDilatationMeta,
          isDilatation.isAcceptableOrUnknown(
              data['is_dilatation']!, _isDilatationMeta));
    }
    if (data.containsKey('dilatation_type')) {
      context.handle(
          _dilatationTypeMeta,
          dilatationType.isAcceptableOrUnknown(
              data['dilatation_type']!, _dilatationTypeMeta));
    }
    if (data.containsKey('room_id')) {
      context.handle(_roomIdMeta,
          roomId.isAcceptableOrUnknown(data['room_id']!, _roomIdMeta));
    } else if (isInserting) {
      context.missing(_roomIdMeta);
    }
    if (data.containsKey('room_name')) {
      context.handle(_roomNameMeta,
          roomName.isAcceptableOrUnknown(data['room_name']!, _roomNameMeta));
    } else if (isInserting) {
      context.missing(_roomNameMeta);
    }
    if (data.containsKey('motif')) {
      context.handle(
          _motifMeta, motif.isAcceptableOrUnknown(data['motif']!, _motifMeta));
    } else if (isInserting) {
      context.missing(_motifMeta);
    }
    if (data.containsKey('sent_by_user_id')) {
      context.handle(
          _sentByUserIdMeta,
          sentByUserId.isAcceptableOrUnknown(
              data['sent_by_user_id']!, _sentByUserIdMeta));
    } else if (isInserting) {
      context.missing(_sentByUserIdMeta);
    }
    if (data.containsKey('sent_by_user_name')) {
      context.handle(
          _sentByUserNameMeta,
          sentByUserName.isAcceptableOrUnknown(
              data['sent_by_user_name']!, _sentByUserNameMeta));
    } else if (isInserting) {
      context.missing(_sentByUserNameMeta);
    }
    if (data.containsKey('sent_at')) {
      context.handle(_sentAtMeta,
          sentAt.isAcceptableOrUnknown(data['sent_at']!, _sentAtMeta));
    } else if (isInserting) {
      context.missing(_sentAtMeta);
    }
    if (data.containsKey('is_checked')) {
      context.handle(_isCheckedMeta,
          isChecked.isAcceptableOrUnknown(data['is_checked']!, _isCheckedMeta));
    }
    if (data.containsKey('is_active')) {
      context.handle(_isActiveMeta,
          isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta));
    }
    if (data.containsKey('is_notified')) {
      context.handle(
          _isNotifiedMeta,
          isNotified.isAcceptableOrUnknown(
              data['is_notified']!, _isNotifiedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WaitingPatient map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WaitingPatient(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      patientCode: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}patient_code'])!,
      patientFirstName: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}patient_first_name'])!,
      patientLastName: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}patient_last_name'])!,
      patientBirthDate: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}patient_birth_date']),
      patientAge: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}patient_age']),
      isUrgent: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_urgent'])!,
      isDilatation: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_dilatation'])!,
      dilatationType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}dilatation_type']),
      roomId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}room_id'])!,
      roomName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}room_name'])!,
      motif: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}motif'])!,
      sentByUserId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}sent_by_user_id'])!,
      sentByUserName: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}sent_by_user_name'])!,
      sentAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}sent_at'])!,
      isChecked: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_checked'])!,
      isActive: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_active'])!,
      isNotified: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_notified'])!,
    );
  }

  @override
  $WaitingPatientsTable createAlias(String alias) {
    return $WaitingPatientsTable(attachedDatabase, alias);
  }
}

class WaitingPatient extends DataClass implements Insertable<WaitingPatient> {
  /// Unique queue entry ID
  final int id;

  /// Patient code (FK to patients table)
  final int patientCode;

  /// Patient first name (cached for performance)
  final String patientFirstName;

  /// Patient last name (cached for performance)
  final String patientLastName;

  /// Patient birth date (cached for age calculation)
  final DateTime? patientBirthDate;

  /// Patient age (used when birthDate is not available)
  final int? patientAge;

  /// Whether this is an urgent case
  final bool isUrgent;

  /// Whether this is a dilatation request (doctor → nurse)
  final bool isDilatation;

  /// Dilatation type: 'skiacol', 'od', 'og', 'odg'
  final String? dilatationType;

  /// Room ID where patient is waiting
  final String roomId;

  /// Room name (cached)
  final String roomName;

  /// Motif de consultation (reason for visit)
  final String motif;

  /// User ID who sent the patient (nurse)
  final String sentByUserId;

  /// User name who sent (cached)
  final String sentByUserName;

  /// Timestamp when patient was sent to queue
  final DateTime sentAt;

  /// Whether doctor has checked/starred this patient
  final bool isChecked;

  /// Active flag (false when patient consultation started or removed)
  final bool isActive;

  /// Whether nurse has been notified (for badge/sound)
  final bool isNotified;
  const WaitingPatient(
      {required this.id,
      required this.patientCode,
      required this.patientFirstName,
      required this.patientLastName,
      this.patientBirthDate,
      this.patientAge,
      required this.isUrgent,
      required this.isDilatation,
      this.dilatationType,
      required this.roomId,
      required this.roomName,
      required this.motif,
      required this.sentByUserId,
      required this.sentByUserName,
      required this.sentAt,
      required this.isChecked,
      required this.isActive,
      required this.isNotified});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['patient_code'] = Variable<int>(patientCode);
    map['patient_first_name'] = Variable<String>(patientFirstName);
    map['patient_last_name'] = Variable<String>(patientLastName);
    if (!nullToAbsent || patientBirthDate != null) {
      map['patient_birth_date'] = Variable<DateTime>(patientBirthDate);
    }
    if (!nullToAbsent || patientAge != null) {
      map['patient_age'] = Variable<int>(patientAge);
    }
    map['is_urgent'] = Variable<bool>(isUrgent);
    map['is_dilatation'] = Variable<bool>(isDilatation);
    if (!nullToAbsent || dilatationType != null) {
      map['dilatation_type'] = Variable<String>(dilatationType);
    }
    map['room_id'] = Variable<String>(roomId);
    map['room_name'] = Variable<String>(roomName);
    map['motif'] = Variable<String>(motif);
    map['sent_by_user_id'] = Variable<String>(sentByUserId);
    map['sent_by_user_name'] = Variable<String>(sentByUserName);
    map['sent_at'] = Variable<DateTime>(sentAt);
    map['is_checked'] = Variable<bool>(isChecked);
    map['is_active'] = Variable<bool>(isActive);
    map['is_notified'] = Variable<bool>(isNotified);
    return map;
  }

  WaitingPatientsCompanion toCompanion(bool nullToAbsent) {
    return WaitingPatientsCompanion(
      id: Value(id),
      patientCode: Value(patientCode),
      patientFirstName: Value(patientFirstName),
      patientLastName: Value(patientLastName),
      patientBirthDate: patientBirthDate == null && nullToAbsent
          ? const Value.absent()
          : Value(patientBirthDate),
      patientAge: patientAge == null && nullToAbsent
          ? const Value.absent()
          : Value(patientAge),
      isUrgent: Value(isUrgent),
      isDilatation: Value(isDilatation),
      dilatationType: dilatationType == null && nullToAbsent
          ? const Value.absent()
          : Value(dilatationType),
      roomId: Value(roomId),
      roomName: Value(roomName),
      motif: Value(motif),
      sentByUserId: Value(sentByUserId),
      sentByUserName: Value(sentByUserName),
      sentAt: Value(sentAt),
      isChecked: Value(isChecked),
      isActive: Value(isActive),
      isNotified: Value(isNotified),
    );
  }

  factory WaitingPatient.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WaitingPatient(
      id: serializer.fromJson<int>(json['id']),
      patientCode: serializer.fromJson<int>(json['patientCode']),
      patientFirstName: serializer.fromJson<String>(json['patientFirstName']),
      patientLastName: serializer.fromJson<String>(json['patientLastName']),
      patientBirthDate:
          serializer.fromJson<DateTime?>(json['patientBirthDate']),
      patientAge: serializer.fromJson<int?>(json['patientAge']),
      isUrgent: serializer.fromJson<bool>(json['isUrgent']),
      isDilatation: serializer.fromJson<bool>(json['isDilatation']),
      dilatationType: serializer.fromJson<String?>(json['dilatationType']),
      roomId: serializer.fromJson<String>(json['roomId']),
      roomName: serializer.fromJson<String>(json['roomName']),
      motif: serializer.fromJson<String>(json['motif']),
      sentByUserId: serializer.fromJson<String>(json['sentByUserId']),
      sentByUserName: serializer.fromJson<String>(json['sentByUserName']),
      sentAt: serializer.fromJson<DateTime>(json['sentAt']),
      isChecked: serializer.fromJson<bool>(json['isChecked']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      isNotified: serializer.fromJson<bool>(json['isNotified']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'patientCode': serializer.toJson<int>(patientCode),
      'patientFirstName': serializer.toJson<String>(patientFirstName),
      'patientLastName': serializer.toJson<String>(patientLastName),
      'patientBirthDate': serializer.toJson<DateTime?>(patientBirthDate),
      'patientAge': serializer.toJson<int?>(patientAge),
      'isUrgent': serializer.toJson<bool>(isUrgent),
      'isDilatation': serializer.toJson<bool>(isDilatation),
      'dilatationType': serializer.toJson<String?>(dilatationType),
      'roomId': serializer.toJson<String>(roomId),
      'roomName': serializer.toJson<String>(roomName),
      'motif': serializer.toJson<String>(motif),
      'sentByUserId': serializer.toJson<String>(sentByUserId),
      'sentByUserName': serializer.toJson<String>(sentByUserName),
      'sentAt': serializer.toJson<DateTime>(sentAt),
      'isChecked': serializer.toJson<bool>(isChecked),
      'isActive': serializer.toJson<bool>(isActive),
      'isNotified': serializer.toJson<bool>(isNotified),
    };
  }

  WaitingPatient copyWith(
          {int? id,
          int? patientCode,
          String? patientFirstName,
          String? patientLastName,
          Value<DateTime?> patientBirthDate = const Value.absent(),
          Value<int?> patientAge = const Value.absent(),
          bool? isUrgent,
          bool? isDilatation,
          Value<String?> dilatationType = const Value.absent(),
          String? roomId,
          String? roomName,
          String? motif,
          String? sentByUserId,
          String? sentByUserName,
          DateTime? sentAt,
          bool? isChecked,
          bool? isActive,
          bool? isNotified}) =>
      WaitingPatient(
        id: id ?? this.id,
        patientCode: patientCode ?? this.patientCode,
        patientFirstName: patientFirstName ?? this.patientFirstName,
        patientLastName: patientLastName ?? this.patientLastName,
        patientBirthDate: patientBirthDate.present
            ? patientBirthDate.value
            : this.patientBirthDate,
        patientAge: patientAge.present ? patientAge.value : this.patientAge,
        isUrgent: isUrgent ?? this.isUrgent,
        isDilatation: isDilatation ?? this.isDilatation,
        dilatationType:
            dilatationType.present ? dilatationType.value : this.dilatationType,
        roomId: roomId ?? this.roomId,
        roomName: roomName ?? this.roomName,
        motif: motif ?? this.motif,
        sentByUserId: sentByUserId ?? this.sentByUserId,
        sentByUserName: sentByUserName ?? this.sentByUserName,
        sentAt: sentAt ?? this.sentAt,
        isChecked: isChecked ?? this.isChecked,
        isActive: isActive ?? this.isActive,
        isNotified: isNotified ?? this.isNotified,
      );
  WaitingPatient copyWithCompanion(WaitingPatientsCompanion data) {
    return WaitingPatient(
      id: data.id.present ? data.id.value : this.id,
      patientCode:
          data.patientCode.present ? data.patientCode.value : this.patientCode,
      patientFirstName: data.patientFirstName.present
          ? data.patientFirstName.value
          : this.patientFirstName,
      patientLastName: data.patientLastName.present
          ? data.patientLastName.value
          : this.patientLastName,
      patientBirthDate: data.patientBirthDate.present
          ? data.patientBirthDate.value
          : this.patientBirthDate,
      patientAge:
          data.patientAge.present ? data.patientAge.value : this.patientAge,
      isUrgent: data.isUrgent.present ? data.isUrgent.value : this.isUrgent,
      isDilatation: data.isDilatation.present
          ? data.isDilatation.value
          : this.isDilatation,
      dilatationType: data.dilatationType.present
          ? data.dilatationType.value
          : this.dilatationType,
      roomId: data.roomId.present ? data.roomId.value : this.roomId,
      roomName: data.roomName.present ? data.roomName.value : this.roomName,
      motif: data.motif.present ? data.motif.value : this.motif,
      sentByUserId: data.sentByUserId.present
          ? data.sentByUserId.value
          : this.sentByUserId,
      sentByUserName: data.sentByUserName.present
          ? data.sentByUserName.value
          : this.sentByUserName,
      sentAt: data.sentAt.present ? data.sentAt.value : this.sentAt,
      isChecked: data.isChecked.present ? data.isChecked.value : this.isChecked,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      isNotified:
          data.isNotified.present ? data.isNotified.value : this.isNotified,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WaitingPatient(')
          ..write('id: $id, ')
          ..write('patientCode: $patientCode, ')
          ..write('patientFirstName: $patientFirstName, ')
          ..write('patientLastName: $patientLastName, ')
          ..write('patientBirthDate: $patientBirthDate, ')
          ..write('patientAge: $patientAge, ')
          ..write('isUrgent: $isUrgent, ')
          ..write('isDilatation: $isDilatation, ')
          ..write('dilatationType: $dilatationType, ')
          ..write('roomId: $roomId, ')
          ..write('roomName: $roomName, ')
          ..write('motif: $motif, ')
          ..write('sentByUserId: $sentByUserId, ')
          ..write('sentByUserName: $sentByUserName, ')
          ..write('sentAt: $sentAt, ')
          ..write('isChecked: $isChecked, ')
          ..write('isActive: $isActive, ')
          ..write('isNotified: $isNotified')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      patientCode,
      patientFirstName,
      patientLastName,
      patientBirthDate,
      patientAge,
      isUrgent,
      isDilatation,
      dilatationType,
      roomId,
      roomName,
      motif,
      sentByUserId,
      sentByUserName,
      sentAt,
      isChecked,
      isActive,
      isNotified);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WaitingPatient &&
          other.id == this.id &&
          other.patientCode == this.patientCode &&
          other.patientFirstName == this.patientFirstName &&
          other.patientLastName == this.patientLastName &&
          other.patientBirthDate == this.patientBirthDate &&
          other.patientAge == this.patientAge &&
          other.isUrgent == this.isUrgent &&
          other.isDilatation == this.isDilatation &&
          other.dilatationType == this.dilatationType &&
          other.roomId == this.roomId &&
          other.roomName == this.roomName &&
          other.motif == this.motif &&
          other.sentByUserId == this.sentByUserId &&
          other.sentByUserName == this.sentByUserName &&
          other.sentAt == this.sentAt &&
          other.isChecked == this.isChecked &&
          other.isActive == this.isActive &&
          other.isNotified == this.isNotified);
}

class WaitingPatientsCompanion extends UpdateCompanion<WaitingPatient> {
  final Value<int> id;
  final Value<int> patientCode;
  final Value<String> patientFirstName;
  final Value<String> patientLastName;
  final Value<DateTime?> patientBirthDate;
  final Value<int?> patientAge;
  final Value<bool> isUrgent;
  final Value<bool> isDilatation;
  final Value<String?> dilatationType;
  final Value<String> roomId;
  final Value<String> roomName;
  final Value<String> motif;
  final Value<String> sentByUserId;
  final Value<String> sentByUserName;
  final Value<DateTime> sentAt;
  final Value<bool> isChecked;
  final Value<bool> isActive;
  final Value<bool> isNotified;
  const WaitingPatientsCompanion({
    this.id = const Value.absent(),
    this.patientCode = const Value.absent(),
    this.patientFirstName = const Value.absent(),
    this.patientLastName = const Value.absent(),
    this.patientBirthDate = const Value.absent(),
    this.patientAge = const Value.absent(),
    this.isUrgent = const Value.absent(),
    this.isDilatation = const Value.absent(),
    this.dilatationType = const Value.absent(),
    this.roomId = const Value.absent(),
    this.roomName = const Value.absent(),
    this.motif = const Value.absent(),
    this.sentByUserId = const Value.absent(),
    this.sentByUserName = const Value.absent(),
    this.sentAt = const Value.absent(),
    this.isChecked = const Value.absent(),
    this.isActive = const Value.absent(),
    this.isNotified = const Value.absent(),
  });
  WaitingPatientsCompanion.insert({
    this.id = const Value.absent(),
    required int patientCode,
    required String patientFirstName,
    required String patientLastName,
    this.patientBirthDate = const Value.absent(),
    this.patientAge = const Value.absent(),
    this.isUrgent = const Value.absent(),
    this.isDilatation = const Value.absent(),
    this.dilatationType = const Value.absent(),
    required String roomId,
    required String roomName,
    required String motif,
    required String sentByUserId,
    required String sentByUserName,
    required DateTime sentAt,
    this.isChecked = const Value.absent(),
    this.isActive = const Value.absent(),
    this.isNotified = const Value.absent(),
  })  : patientCode = Value(patientCode),
        patientFirstName = Value(patientFirstName),
        patientLastName = Value(patientLastName),
        roomId = Value(roomId),
        roomName = Value(roomName),
        motif = Value(motif),
        sentByUserId = Value(sentByUserId),
        sentByUserName = Value(sentByUserName),
        sentAt = Value(sentAt);
  static Insertable<WaitingPatient> custom({
    Expression<int>? id,
    Expression<int>? patientCode,
    Expression<String>? patientFirstName,
    Expression<String>? patientLastName,
    Expression<DateTime>? patientBirthDate,
    Expression<int>? patientAge,
    Expression<bool>? isUrgent,
    Expression<bool>? isDilatation,
    Expression<String>? dilatationType,
    Expression<String>? roomId,
    Expression<String>? roomName,
    Expression<String>? motif,
    Expression<String>? sentByUserId,
    Expression<String>? sentByUserName,
    Expression<DateTime>? sentAt,
    Expression<bool>? isChecked,
    Expression<bool>? isActive,
    Expression<bool>? isNotified,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (patientCode != null) 'patient_code': patientCode,
      if (patientFirstName != null) 'patient_first_name': patientFirstName,
      if (patientLastName != null) 'patient_last_name': patientLastName,
      if (patientBirthDate != null) 'patient_birth_date': patientBirthDate,
      if (patientAge != null) 'patient_age': patientAge,
      if (isUrgent != null) 'is_urgent': isUrgent,
      if (isDilatation != null) 'is_dilatation': isDilatation,
      if (dilatationType != null) 'dilatation_type': dilatationType,
      if (roomId != null) 'room_id': roomId,
      if (roomName != null) 'room_name': roomName,
      if (motif != null) 'motif': motif,
      if (sentByUserId != null) 'sent_by_user_id': sentByUserId,
      if (sentByUserName != null) 'sent_by_user_name': sentByUserName,
      if (sentAt != null) 'sent_at': sentAt,
      if (isChecked != null) 'is_checked': isChecked,
      if (isActive != null) 'is_active': isActive,
      if (isNotified != null) 'is_notified': isNotified,
    });
  }

  WaitingPatientsCompanion copyWith(
      {Value<int>? id,
      Value<int>? patientCode,
      Value<String>? patientFirstName,
      Value<String>? patientLastName,
      Value<DateTime?>? patientBirthDate,
      Value<int?>? patientAge,
      Value<bool>? isUrgent,
      Value<bool>? isDilatation,
      Value<String?>? dilatationType,
      Value<String>? roomId,
      Value<String>? roomName,
      Value<String>? motif,
      Value<String>? sentByUserId,
      Value<String>? sentByUserName,
      Value<DateTime>? sentAt,
      Value<bool>? isChecked,
      Value<bool>? isActive,
      Value<bool>? isNotified}) {
    return WaitingPatientsCompanion(
      id: id ?? this.id,
      patientCode: patientCode ?? this.patientCode,
      patientFirstName: patientFirstName ?? this.patientFirstName,
      patientLastName: patientLastName ?? this.patientLastName,
      patientBirthDate: patientBirthDate ?? this.patientBirthDate,
      patientAge: patientAge ?? this.patientAge,
      isUrgent: isUrgent ?? this.isUrgent,
      isDilatation: isDilatation ?? this.isDilatation,
      dilatationType: dilatationType ?? this.dilatationType,
      roomId: roomId ?? this.roomId,
      roomName: roomName ?? this.roomName,
      motif: motif ?? this.motif,
      sentByUserId: sentByUserId ?? this.sentByUserId,
      sentByUserName: sentByUserName ?? this.sentByUserName,
      sentAt: sentAt ?? this.sentAt,
      isChecked: isChecked ?? this.isChecked,
      isActive: isActive ?? this.isActive,
      isNotified: isNotified ?? this.isNotified,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (patientCode.present) {
      map['patient_code'] = Variable<int>(patientCode.value);
    }
    if (patientFirstName.present) {
      map['patient_first_name'] = Variable<String>(patientFirstName.value);
    }
    if (patientLastName.present) {
      map['patient_last_name'] = Variable<String>(patientLastName.value);
    }
    if (patientBirthDate.present) {
      map['patient_birth_date'] = Variable<DateTime>(patientBirthDate.value);
    }
    if (patientAge.present) {
      map['patient_age'] = Variable<int>(patientAge.value);
    }
    if (isUrgent.present) {
      map['is_urgent'] = Variable<bool>(isUrgent.value);
    }
    if (isDilatation.present) {
      map['is_dilatation'] = Variable<bool>(isDilatation.value);
    }
    if (dilatationType.present) {
      map['dilatation_type'] = Variable<String>(dilatationType.value);
    }
    if (roomId.present) {
      map['room_id'] = Variable<String>(roomId.value);
    }
    if (roomName.present) {
      map['room_name'] = Variable<String>(roomName.value);
    }
    if (motif.present) {
      map['motif'] = Variable<String>(motif.value);
    }
    if (sentByUserId.present) {
      map['sent_by_user_id'] = Variable<String>(sentByUserId.value);
    }
    if (sentByUserName.present) {
      map['sent_by_user_name'] = Variable<String>(sentByUserName.value);
    }
    if (sentAt.present) {
      map['sent_at'] = Variable<DateTime>(sentAt.value);
    }
    if (isChecked.present) {
      map['is_checked'] = Variable<bool>(isChecked.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (isNotified.present) {
      map['is_notified'] = Variable<bool>(isNotified.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WaitingPatientsCompanion(')
          ..write('id: $id, ')
          ..write('patientCode: $patientCode, ')
          ..write('patientFirstName: $patientFirstName, ')
          ..write('patientLastName: $patientLastName, ')
          ..write('patientBirthDate: $patientBirthDate, ')
          ..write('patientAge: $patientAge, ')
          ..write('isUrgent: $isUrgent, ')
          ..write('isDilatation: $isDilatation, ')
          ..write('dilatationType: $dilatationType, ')
          ..write('roomId: $roomId, ')
          ..write('roomName: $roomName, ')
          ..write('motif: $motif, ')
          ..write('sentByUserId: $sentByUserId, ')
          ..write('sentByUserName: $sentByUserName, ')
          ..write('sentAt: $sentAt, ')
          ..write('isChecked: $isChecked, ')
          ..write('isActive: $isActive, ')
          ..write('isNotified: $isNotified')
          ..write(')'))
        .toString();
  }
}

class $OrdonnancesTable extends Ordonnances
    with TableInfo<$OrdonnancesTable, Ordonnance> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OrdonnancesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _originalIdMeta =
      const VerificationMeta('originalId');
  @override
  late final GeneratedColumn<int> originalId = GeneratedColumn<int>(
      'original_id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _patientCodeMeta =
      const VerificationMeta('patientCode');
  @override
  late final GeneratedColumn<int> patientCode = GeneratedColumn<int>(
      'patient_code', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _documentDateMeta =
      const VerificationMeta('documentDate');
  @override
  late final GeneratedColumn<DateTime> documentDate = GeneratedColumn<DateTime>(
      'document_date', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _patientAgeMeta =
      const VerificationMeta('patientAge');
  @override
  late final GeneratedColumn<int> patientAge = GeneratedColumn<int>(
      'patient_age', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _sequenceMeta =
      const VerificationMeta('sequence');
  @override
  late final GeneratedColumn<int> sequence = GeneratedColumn<int>(
      'sequence', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _seqPatMeta = const VerificationMeta('seqPat');
  @override
  late final GeneratedColumn<String> seqPat = GeneratedColumn<String>(
      'seq_pat', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _doctorNameMeta =
      const VerificationMeta('doctorName');
  @override
  late final GeneratedColumn<String> doctorName = GeneratedColumn<String>(
      'doctor_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
      'amount', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _content1Meta =
      const VerificationMeta('content1');
  @override
  late final GeneratedColumn<String> content1 = GeneratedColumn<String>(
      'content1', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _type1Meta = const VerificationMeta('type1');
  @override
  late final GeneratedColumn<String> type1 = GeneratedColumn<String>(
      'type1', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('ORDONNANCE'));
  static const VerificationMeta _content2Meta =
      const VerificationMeta('content2');
  @override
  late final GeneratedColumn<String> content2 = GeneratedColumn<String>(
      'content2', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _type2Meta = const VerificationMeta('type2');
  @override
  late final GeneratedColumn<String> type2 = GeneratedColumn<String>(
      'type2', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _content3Meta =
      const VerificationMeta('content3');
  @override
  late final GeneratedColumn<String> content3 = GeneratedColumn<String>(
      'content3', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _type3Meta = const VerificationMeta('type3');
  @override
  late final GeneratedColumn<String> type3 = GeneratedColumn<String>(
      'type3', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _additionalNotesMeta =
      const VerificationMeta('additionalNotes');
  @override
  late final GeneratedColumn<String> additionalNotes = GeneratedColumn<String>(
      'additional_notes', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _reportTitleMeta =
      const VerificationMeta('reportTitle');
  @override
  late final GeneratedColumn<String> reportTitle = GeneratedColumn<String>(
      'report_title', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _referredByMeta =
      const VerificationMeta('referredBy');
  @override
  late final GeneratedColumn<String> referredBy = GeneratedColumn<String>(
      'referred_by', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _rdvFlagMeta =
      const VerificationMeta('rdvFlag');
  @override
  late final GeneratedColumn<int> rdvFlag = GeneratedColumn<int>(
      'rdv_flag', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _rdvDateMeta =
      const VerificationMeta('rdvDate');
  @override
  late final GeneratedColumn<String> rdvDate = GeneratedColumn<String>(
      'rdv_date', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _rdvDayMeta = const VerificationMeta('rdvDay');
  @override
  late final GeneratedColumn<String> rdvDay = GeneratedColumn<String>(
      'rdv_day', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        originalId,
        patientCode,
        documentDate,
        patientAge,
        sequence,
        seqPat,
        doctorName,
        amount,
        content1,
        type1,
        content2,
        type2,
        content3,
        type3,
        additionalNotes,
        reportTitle,
        referredBy,
        rdvFlag,
        rdvDate,
        rdvDay,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ordonnances';
  @override
  VerificationContext validateIntegrity(Insertable<Ordonnance> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('original_id')) {
      context.handle(
          _originalIdMeta,
          originalId.isAcceptableOrUnknown(
              data['original_id']!, _originalIdMeta));
    }
    if (data.containsKey('patient_code')) {
      context.handle(
          _patientCodeMeta,
          patientCode.isAcceptableOrUnknown(
              data['patient_code']!, _patientCodeMeta));
    } else if (isInserting) {
      context.missing(_patientCodeMeta);
    }
    if (data.containsKey('document_date')) {
      context.handle(
          _documentDateMeta,
          documentDate.isAcceptableOrUnknown(
              data['document_date']!, _documentDateMeta));
    }
    if (data.containsKey('patient_age')) {
      context.handle(
          _patientAgeMeta,
          patientAge.isAcceptableOrUnknown(
              data['patient_age']!, _patientAgeMeta));
    }
    if (data.containsKey('sequence')) {
      context.handle(_sequenceMeta,
          sequence.isAcceptableOrUnknown(data['sequence']!, _sequenceMeta));
    }
    if (data.containsKey('seq_pat')) {
      context.handle(_seqPatMeta,
          seqPat.isAcceptableOrUnknown(data['seq_pat']!, _seqPatMeta));
    }
    if (data.containsKey('doctor_name')) {
      context.handle(
          _doctorNameMeta,
          doctorName.isAcceptableOrUnknown(
              data['doctor_name']!, _doctorNameMeta));
    }
    if (data.containsKey('amount')) {
      context.handle(_amountMeta,
          amount.isAcceptableOrUnknown(data['amount']!, _amountMeta));
    }
    if (data.containsKey('content1')) {
      context.handle(_content1Meta,
          content1.isAcceptableOrUnknown(data['content1']!, _content1Meta));
    }
    if (data.containsKey('type1')) {
      context.handle(
          _type1Meta, type1.isAcceptableOrUnknown(data['type1']!, _type1Meta));
    }
    if (data.containsKey('content2')) {
      context.handle(_content2Meta,
          content2.isAcceptableOrUnknown(data['content2']!, _content2Meta));
    }
    if (data.containsKey('type2')) {
      context.handle(
          _type2Meta, type2.isAcceptableOrUnknown(data['type2']!, _type2Meta));
    }
    if (data.containsKey('content3')) {
      context.handle(_content3Meta,
          content3.isAcceptableOrUnknown(data['content3']!, _content3Meta));
    }
    if (data.containsKey('type3')) {
      context.handle(
          _type3Meta, type3.isAcceptableOrUnknown(data['type3']!, _type3Meta));
    }
    if (data.containsKey('additional_notes')) {
      context.handle(
          _additionalNotesMeta,
          additionalNotes.isAcceptableOrUnknown(
              data['additional_notes']!, _additionalNotesMeta));
    }
    if (data.containsKey('report_title')) {
      context.handle(
          _reportTitleMeta,
          reportTitle.isAcceptableOrUnknown(
              data['report_title']!, _reportTitleMeta));
    }
    if (data.containsKey('referred_by')) {
      context.handle(
          _referredByMeta,
          referredBy.isAcceptableOrUnknown(
              data['referred_by']!, _referredByMeta));
    }
    if (data.containsKey('rdv_flag')) {
      context.handle(_rdvFlagMeta,
          rdvFlag.isAcceptableOrUnknown(data['rdv_flag']!, _rdvFlagMeta));
    }
    if (data.containsKey('rdv_date')) {
      context.handle(_rdvDateMeta,
          rdvDate.isAcceptableOrUnknown(data['rdv_date']!, _rdvDateMeta));
    }
    if (data.containsKey('rdv_day')) {
      context.handle(_rdvDayMeta,
          rdvDay.isAcceptableOrUnknown(data['rdv_day']!, _rdvDayMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Ordonnance map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Ordonnance(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      originalId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}original_id']),
      patientCode: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}patient_code'])!,
      documentDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}document_date']),
      patientAge: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}patient_age']),
      sequence: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sequence'])!,
      seqPat: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}seq_pat']),
      doctorName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}doctor_name']),
      amount: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}amount'])!,
      content1: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}content1']),
      type1: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type1'])!,
      content2: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}content2']),
      type2: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type2']),
      content3: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}content3']),
      type3: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type3']),
      additionalNotes: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}additional_notes']),
      reportTitle: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}report_title']),
      referredBy: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}referred_by']),
      rdvFlag: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}rdv_flag'])!,
      rdvDate: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}rdv_date']),
      rdvDay: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}rdv_day']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $OrdonnancesTable createAlias(String alias) {
    return $OrdonnancesTable(attachedDatabase, alias);
  }
}

class Ordonnance extends DataClass implements Insertable<Ordonnance> {
  /// Unique record ID from XML (N__Enr.)
  final int id;

  /// Original record number from import
  final int? originalId;

  /// Patient code (CDEP)
  final int patientCode;

  /// Document date (DATEORD)
  final DateTime? documentDate;

  /// Patient age at time of document (AG2)
  final int? patientAge;

  /// Sequence/visit number (SEQ)
  final int sequence;

  /// Combined sequence + patient code (SEQPAT)
  final String? seqPat;

  /// Doctor name (MEDCIN)
  final String? doctorName;

  /// Amount (SMONT)
  final double amount;

  /// Primary document content (STRAIT) - preserves formatting
  final String? content1;

  /// Primary document type (ACTEX) - e.g., ORDONNANCE, CERTIFICAT MEDICAL
  final String type1;

  /// Secondary document content (strait1) - preserves formatting
  final String? content2;

  /// Secondary document type (ACTEX1)
  final String? type2;

  /// Third document content (strait2) - preserves formatting
  final String? content3;

  /// Third document type (ACTEX2)
  final String? type3;

  /// Additional notes (strait3)
  final String? additionalNotes;

  /// Report title (titre_cr) - e.g., COMPTE RENDU D'OCT
  final String? reportTitle;

  /// Referred by (ADressé_par)
  final String? referredBy;

  /// RDV flag (rdvle)
  final int rdvFlag;

  /// RDV date (datele)
  final String? rdvDate;

  /// RDV day (jourle)
  final String? rdvDay;

  /// Timestamps
  final DateTime createdAt;
  final DateTime updatedAt;
  const Ordonnance(
      {required this.id,
      this.originalId,
      required this.patientCode,
      this.documentDate,
      this.patientAge,
      required this.sequence,
      this.seqPat,
      this.doctorName,
      required this.amount,
      this.content1,
      required this.type1,
      this.content2,
      this.type2,
      this.content3,
      this.type3,
      this.additionalNotes,
      this.reportTitle,
      this.referredBy,
      required this.rdvFlag,
      this.rdvDate,
      this.rdvDay,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || originalId != null) {
      map['original_id'] = Variable<int>(originalId);
    }
    map['patient_code'] = Variable<int>(patientCode);
    if (!nullToAbsent || documentDate != null) {
      map['document_date'] = Variable<DateTime>(documentDate);
    }
    if (!nullToAbsent || patientAge != null) {
      map['patient_age'] = Variable<int>(patientAge);
    }
    map['sequence'] = Variable<int>(sequence);
    if (!nullToAbsent || seqPat != null) {
      map['seq_pat'] = Variable<String>(seqPat);
    }
    if (!nullToAbsent || doctorName != null) {
      map['doctor_name'] = Variable<String>(doctorName);
    }
    map['amount'] = Variable<double>(amount);
    if (!nullToAbsent || content1 != null) {
      map['content1'] = Variable<String>(content1);
    }
    map['type1'] = Variable<String>(type1);
    if (!nullToAbsent || content2 != null) {
      map['content2'] = Variable<String>(content2);
    }
    if (!nullToAbsent || type2 != null) {
      map['type2'] = Variable<String>(type2);
    }
    if (!nullToAbsent || content3 != null) {
      map['content3'] = Variable<String>(content3);
    }
    if (!nullToAbsent || type3 != null) {
      map['type3'] = Variable<String>(type3);
    }
    if (!nullToAbsent || additionalNotes != null) {
      map['additional_notes'] = Variable<String>(additionalNotes);
    }
    if (!nullToAbsent || reportTitle != null) {
      map['report_title'] = Variable<String>(reportTitle);
    }
    if (!nullToAbsent || referredBy != null) {
      map['referred_by'] = Variable<String>(referredBy);
    }
    map['rdv_flag'] = Variable<int>(rdvFlag);
    if (!nullToAbsent || rdvDate != null) {
      map['rdv_date'] = Variable<String>(rdvDate);
    }
    if (!nullToAbsent || rdvDay != null) {
      map['rdv_day'] = Variable<String>(rdvDay);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  OrdonnancesCompanion toCompanion(bool nullToAbsent) {
    return OrdonnancesCompanion(
      id: Value(id),
      originalId: originalId == null && nullToAbsent
          ? const Value.absent()
          : Value(originalId),
      patientCode: Value(patientCode),
      documentDate: documentDate == null && nullToAbsent
          ? const Value.absent()
          : Value(documentDate),
      patientAge: patientAge == null && nullToAbsent
          ? const Value.absent()
          : Value(patientAge),
      sequence: Value(sequence),
      seqPat:
          seqPat == null && nullToAbsent ? const Value.absent() : Value(seqPat),
      doctorName: doctorName == null && nullToAbsent
          ? const Value.absent()
          : Value(doctorName),
      amount: Value(amount),
      content1: content1 == null && nullToAbsent
          ? const Value.absent()
          : Value(content1),
      type1: Value(type1),
      content2: content2 == null && nullToAbsent
          ? const Value.absent()
          : Value(content2),
      type2:
          type2 == null && nullToAbsent ? const Value.absent() : Value(type2),
      content3: content3 == null && nullToAbsent
          ? const Value.absent()
          : Value(content3),
      type3:
          type3 == null && nullToAbsent ? const Value.absent() : Value(type3),
      additionalNotes: additionalNotes == null && nullToAbsent
          ? const Value.absent()
          : Value(additionalNotes),
      reportTitle: reportTitle == null && nullToAbsent
          ? const Value.absent()
          : Value(reportTitle),
      referredBy: referredBy == null && nullToAbsent
          ? const Value.absent()
          : Value(referredBy),
      rdvFlag: Value(rdvFlag),
      rdvDate: rdvDate == null && nullToAbsent
          ? const Value.absent()
          : Value(rdvDate),
      rdvDay:
          rdvDay == null && nullToAbsent ? const Value.absent() : Value(rdvDay),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Ordonnance.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Ordonnance(
      id: serializer.fromJson<int>(json['id']),
      originalId: serializer.fromJson<int?>(json['originalId']),
      patientCode: serializer.fromJson<int>(json['patientCode']),
      documentDate: serializer.fromJson<DateTime?>(json['documentDate']),
      patientAge: serializer.fromJson<int?>(json['patientAge']),
      sequence: serializer.fromJson<int>(json['sequence']),
      seqPat: serializer.fromJson<String?>(json['seqPat']),
      doctorName: serializer.fromJson<String?>(json['doctorName']),
      amount: serializer.fromJson<double>(json['amount']),
      content1: serializer.fromJson<String?>(json['content1']),
      type1: serializer.fromJson<String>(json['type1']),
      content2: serializer.fromJson<String?>(json['content2']),
      type2: serializer.fromJson<String?>(json['type2']),
      content3: serializer.fromJson<String?>(json['content3']),
      type3: serializer.fromJson<String?>(json['type3']),
      additionalNotes: serializer.fromJson<String?>(json['additionalNotes']),
      reportTitle: serializer.fromJson<String?>(json['reportTitle']),
      referredBy: serializer.fromJson<String?>(json['referredBy']),
      rdvFlag: serializer.fromJson<int>(json['rdvFlag']),
      rdvDate: serializer.fromJson<String?>(json['rdvDate']),
      rdvDay: serializer.fromJson<String?>(json['rdvDay']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'originalId': serializer.toJson<int?>(originalId),
      'patientCode': serializer.toJson<int>(patientCode),
      'documentDate': serializer.toJson<DateTime?>(documentDate),
      'patientAge': serializer.toJson<int?>(patientAge),
      'sequence': serializer.toJson<int>(sequence),
      'seqPat': serializer.toJson<String?>(seqPat),
      'doctorName': serializer.toJson<String?>(doctorName),
      'amount': serializer.toJson<double>(amount),
      'content1': serializer.toJson<String?>(content1),
      'type1': serializer.toJson<String>(type1),
      'content2': serializer.toJson<String?>(content2),
      'type2': serializer.toJson<String?>(type2),
      'content3': serializer.toJson<String?>(content3),
      'type3': serializer.toJson<String?>(type3),
      'additionalNotes': serializer.toJson<String?>(additionalNotes),
      'reportTitle': serializer.toJson<String?>(reportTitle),
      'referredBy': serializer.toJson<String?>(referredBy),
      'rdvFlag': serializer.toJson<int>(rdvFlag),
      'rdvDate': serializer.toJson<String?>(rdvDate),
      'rdvDay': serializer.toJson<String?>(rdvDay),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Ordonnance copyWith(
          {int? id,
          Value<int?> originalId = const Value.absent(),
          int? patientCode,
          Value<DateTime?> documentDate = const Value.absent(),
          Value<int?> patientAge = const Value.absent(),
          int? sequence,
          Value<String?> seqPat = const Value.absent(),
          Value<String?> doctorName = const Value.absent(),
          double? amount,
          Value<String?> content1 = const Value.absent(),
          String? type1,
          Value<String?> content2 = const Value.absent(),
          Value<String?> type2 = const Value.absent(),
          Value<String?> content3 = const Value.absent(),
          Value<String?> type3 = const Value.absent(),
          Value<String?> additionalNotes = const Value.absent(),
          Value<String?> reportTitle = const Value.absent(),
          Value<String?> referredBy = const Value.absent(),
          int? rdvFlag,
          Value<String?> rdvDate = const Value.absent(),
          Value<String?> rdvDay = const Value.absent(),
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      Ordonnance(
        id: id ?? this.id,
        originalId: originalId.present ? originalId.value : this.originalId,
        patientCode: patientCode ?? this.patientCode,
        documentDate:
            documentDate.present ? documentDate.value : this.documentDate,
        patientAge: patientAge.present ? patientAge.value : this.patientAge,
        sequence: sequence ?? this.sequence,
        seqPat: seqPat.present ? seqPat.value : this.seqPat,
        doctorName: doctorName.present ? doctorName.value : this.doctorName,
        amount: amount ?? this.amount,
        content1: content1.present ? content1.value : this.content1,
        type1: type1 ?? this.type1,
        content2: content2.present ? content2.value : this.content2,
        type2: type2.present ? type2.value : this.type2,
        content3: content3.present ? content3.value : this.content3,
        type3: type3.present ? type3.value : this.type3,
        additionalNotes: additionalNotes.present
            ? additionalNotes.value
            : this.additionalNotes,
        reportTitle: reportTitle.present ? reportTitle.value : this.reportTitle,
        referredBy: referredBy.present ? referredBy.value : this.referredBy,
        rdvFlag: rdvFlag ?? this.rdvFlag,
        rdvDate: rdvDate.present ? rdvDate.value : this.rdvDate,
        rdvDay: rdvDay.present ? rdvDay.value : this.rdvDay,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  Ordonnance copyWithCompanion(OrdonnancesCompanion data) {
    return Ordonnance(
      id: data.id.present ? data.id.value : this.id,
      originalId:
          data.originalId.present ? data.originalId.value : this.originalId,
      patientCode:
          data.patientCode.present ? data.patientCode.value : this.patientCode,
      documentDate: data.documentDate.present
          ? data.documentDate.value
          : this.documentDate,
      patientAge:
          data.patientAge.present ? data.patientAge.value : this.patientAge,
      sequence: data.sequence.present ? data.sequence.value : this.sequence,
      seqPat: data.seqPat.present ? data.seqPat.value : this.seqPat,
      doctorName:
          data.doctorName.present ? data.doctorName.value : this.doctorName,
      amount: data.amount.present ? data.amount.value : this.amount,
      content1: data.content1.present ? data.content1.value : this.content1,
      type1: data.type1.present ? data.type1.value : this.type1,
      content2: data.content2.present ? data.content2.value : this.content2,
      type2: data.type2.present ? data.type2.value : this.type2,
      content3: data.content3.present ? data.content3.value : this.content3,
      type3: data.type3.present ? data.type3.value : this.type3,
      additionalNotes: data.additionalNotes.present
          ? data.additionalNotes.value
          : this.additionalNotes,
      reportTitle:
          data.reportTitle.present ? data.reportTitle.value : this.reportTitle,
      referredBy:
          data.referredBy.present ? data.referredBy.value : this.referredBy,
      rdvFlag: data.rdvFlag.present ? data.rdvFlag.value : this.rdvFlag,
      rdvDate: data.rdvDate.present ? data.rdvDate.value : this.rdvDate,
      rdvDay: data.rdvDay.present ? data.rdvDay.value : this.rdvDay,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Ordonnance(')
          ..write('id: $id, ')
          ..write('originalId: $originalId, ')
          ..write('patientCode: $patientCode, ')
          ..write('documentDate: $documentDate, ')
          ..write('patientAge: $patientAge, ')
          ..write('sequence: $sequence, ')
          ..write('seqPat: $seqPat, ')
          ..write('doctorName: $doctorName, ')
          ..write('amount: $amount, ')
          ..write('content1: $content1, ')
          ..write('type1: $type1, ')
          ..write('content2: $content2, ')
          ..write('type2: $type2, ')
          ..write('content3: $content3, ')
          ..write('type3: $type3, ')
          ..write('additionalNotes: $additionalNotes, ')
          ..write('reportTitle: $reportTitle, ')
          ..write('referredBy: $referredBy, ')
          ..write('rdvFlag: $rdvFlag, ')
          ..write('rdvDate: $rdvDate, ')
          ..write('rdvDay: $rdvDay, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
        id,
        originalId,
        patientCode,
        documentDate,
        patientAge,
        sequence,
        seqPat,
        doctorName,
        amount,
        content1,
        type1,
        content2,
        type2,
        content3,
        type3,
        additionalNotes,
        reportTitle,
        referredBy,
        rdvFlag,
        rdvDate,
        rdvDay,
        createdAt,
        updatedAt
      ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Ordonnance &&
          other.id == this.id &&
          other.originalId == this.originalId &&
          other.patientCode == this.patientCode &&
          other.documentDate == this.documentDate &&
          other.patientAge == this.patientAge &&
          other.sequence == this.sequence &&
          other.seqPat == this.seqPat &&
          other.doctorName == this.doctorName &&
          other.amount == this.amount &&
          other.content1 == this.content1 &&
          other.type1 == this.type1 &&
          other.content2 == this.content2 &&
          other.type2 == this.type2 &&
          other.content3 == this.content3 &&
          other.type3 == this.type3 &&
          other.additionalNotes == this.additionalNotes &&
          other.reportTitle == this.reportTitle &&
          other.referredBy == this.referredBy &&
          other.rdvFlag == this.rdvFlag &&
          other.rdvDate == this.rdvDate &&
          other.rdvDay == this.rdvDay &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class OrdonnancesCompanion extends UpdateCompanion<Ordonnance> {
  final Value<int> id;
  final Value<int?> originalId;
  final Value<int> patientCode;
  final Value<DateTime?> documentDate;
  final Value<int?> patientAge;
  final Value<int> sequence;
  final Value<String?> seqPat;
  final Value<String?> doctorName;
  final Value<double> amount;
  final Value<String?> content1;
  final Value<String> type1;
  final Value<String?> content2;
  final Value<String?> type2;
  final Value<String?> content3;
  final Value<String?> type3;
  final Value<String?> additionalNotes;
  final Value<String?> reportTitle;
  final Value<String?> referredBy;
  final Value<int> rdvFlag;
  final Value<String?> rdvDate;
  final Value<String?> rdvDay;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const OrdonnancesCompanion({
    this.id = const Value.absent(),
    this.originalId = const Value.absent(),
    this.patientCode = const Value.absent(),
    this.documentDate = const Value.absent(),
    this.patientAge = const Value.absent(),
    this.sequence = const Value.absent(),
    this.seqPat = const Value.absent(),
    this.doctorName = const Value.absent(),
    this.amount = const Value.absent(),
    this.content1 = const Value.absent(),
    this.type1 = const Value.absent(),
    this.content2 = const Value.absent(),
    this.type2 = const Value.absent(),
    this.content3 = const Value.absent(),
    this.type3 = const Value.absent(),
    this.additionalNotes = const Value.absent(),
    this.reportTitle = const Value.absent(),
    this.referredBy = const Value.absent(),
    this.rdvFlag = const Value.absent(),
    this.rdvDate = const Value.absent(),
    this.rdvDay = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  OrdonnancesCompanion.insert({
    this.id = const Value.absent(),
    this.originalId = const Value.absent(),
    required int patientCode,
    this.documentDate = const Value.absent(),
    this.patientAge = const Value.absent(),
    this.sequence = const Value.absent(),
    this.seqPat = const Value.absent(),
    this.doctorName = const Value.absent(),
    this.amount = const Value.absent(),
    this.content1 = const Value.absent(),
    this.type1 = const Value.absent(),
    this.content2 = const Value.absent(),
    this.type2 = const Value.absent(),
    this.content3 = const Value.absent(),
    this.type3 = const Value.absent(),
    this.additionalNotes = const Value.absent(),
    this.reportTitle = const Value.absent(),
    this.referredBy = const Value.absent(),
    this.rdvFlag = const Value.absent(),
    this.rdvDate = const Value.absent(),
    this.rdvDay = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : patientCode = Value(patientCode);
  static Insertable<Ordonnance> custom({
    Expression<int>? id,
    Expression<int>? originalId,
    Expression<int>? patientCode,
    Expression<DateTime>? documentDate,
    Expression<int>? patientAge,
    Expression<int>? sequence,
    Expression<String>? seqPat,
    Expression<String>? doctorName,
    Expression<double>? amount,
    Expression<String>? content1,
    Expression<String>? type1,
    Expression<String>? content2,
    Expression<String>? type2,
    Expression<String>? content3,
    Expression<String>? type3,
    Expression<String>? additionalNotes,
    Expression<String>? reportTitle,
    Expression<String>? referredBy,
    Expression<int>? rdvFlag,
    Expression<String>? rdvDate,
    Expression<String>? rdvDay,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (originalId != null) 'original_id': originalId,
      if (patientCode != null) 'patient_code': patientCode,
      if (documentDate != null) 'document_date': documentDate,
      if (patientAge != null) 'patient_age': patientAge,
      if (sequence != null) 'sequence': sequence,
      if (seqPat != null) 'seq_pat': seqPat,
      if (doctorName != null) 'doctor_name': doctorName,
      if (amount != null) 'amount': amount,
      if (content1 != null) 'content1': content1,
      if (type1 != null) 'type1': type1,
      if (content2 != null) 'content2': content2,
      if (type2 != null) 'type2': type2,
      if (content3 != null) 'content3': content3,
      if (type3 != null) 'type3': type3,
      if (additionalNotes != null) 'additional_notes': additionalNotes,
      if (reportTitle != null) 'report_title': reportTitle,
      if (referredBy != null) 'referred_by': referredBy,
      if (rdvFlag != null) 'rdv_flag': rdvFlag,
      if (rdvDate != null) 'rdv_date': rdvDate,
      if (rdvDay != null) 'rdv_day': rdvDay,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  OrdonnancesCompanion copyWith(
      {Value<int>? id,
      Value<int?>? originalId,
      Value<int>? patientCode,
      Value<DateTime?>? documentDate,
      Value<int?>? patientAge,
      Value<int>? sequence,
      Value<String?>? seqPat,
      Value<String?>? doctorName,
      Value<double>? amount,
      Value<String?>? content1,
      Value<String>? type1,
      Value<String?>? content2,
      Value<String?>? type2,
      Value<String?>? content3,
      Value<String?>? type3,
      Value<String?>? additionalNotes,
      Value<String?>? reportTitle,
      Value<String?>? referredBy,
      Value<int>? rdvFlag,
      Value<String?>? rdvDate,
      Value<String?>? rdvDay,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt}) {
    return OrdonnancesCompanion(
      id: id ?? this.id,
      originalId: originalId ?? this.originalId,
      patientCode: patientCode ?? this.patientCode,
      documentDate: documentDate ?? this.documentDate,
      patientAge: patientAge ?? this.patientAge,
      sequence: sequence ?? this.sequence,
      seqPat: seqPat ?? this.seqPat,
      doctorName: doctorName ?? this.doctorName,
      amount: amount ?? this.amount,
      content1: content1 ?? this.content1,
      type1: type1 ?? this.type1,
      content2: content2 ?? this.content2,
      type2: type2 ?? this.type2,
      content3: content3 ?? this.content3,
      type3: type3 ?? this.type3,
      additionalNotes: additionalNotes ?? this.additionalNotes,
      reportTitle: reportTitle ?? this.reportTitle,
      referredBy: referredBy ?? this.referredBy,
      rdvFlag: rdvFlag ?? this.rdvFlag,
      rdvDate: rdvDate ?? this.rdvDate,
      rdvDay: rdvDay ?? this.rdvDay,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (originalId.present) {
      map['original_id'] = Variable<int>(originalId.value);
    }
    if (patientCode.present) {
      map['patient_code'] = Variable<int>(patientCode.value);
    }
    if (documentDate.present) {
      map['document_date'] = Variable<DateTime>(documentDate.value);
    }
    if (patientAge.present) {
      map['patient_age'] = Variable<int>(patientAge.value);
    }
    if (sequence.present) {
      map['sequence'] = Variable<int>(sequence.value);
    }
    if (seqPat.present) {
      map['seq_pat'] = Variable<String>(seqPat.value);
    }
    if (doctorName.present) {
      map['doctor_name'] = Variable<String>(doctorName.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (content1.present) {
      map['content1'] = Variable<String>(content1.value);
    }
    if (type1.present) {
      map['type1'] = Variable<String>(type1.value);
    }
    if (content2.present) {
      map['content2'] = Variable<String>(content2.value);
    }
    if (type2.present) {
      map['type2'] = Variable<String>(type2.value);
    }
    if (content3.present) {
      map['content3'] = Variable<String>(content3.value);
    }
    if (type3.present) {
      map['type3'] = Variable<String>(type3.value);
    }
    if (additionalNotes.present) {
      map['additional_notes'] = Variable<String>(additionalNotes.value);
    }
    if (reportTitle.present) {
      map['report_title'] = Variable<String>(reportTitle.value);
    }
    if (referredBy.present) {
      map['referred_by'] = Variable<String>(referredBy.value);
    }
    if (rdvFlag.present) {
      map['rdv_flag'] = Variable<int>(rdvFlag.value);
    }
    if (rdvDate.present) {
      map['rdv_date'] = Variable<String>(rdvDate.value);
    }
    if (rdvDay.present) {
      map['rdv_day'] = Variable<String>(rdvDay.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OrdonnancesCompanion(')
          ..write('id: $id, ')
          ..write('originalId: $originalId, ')
          ..write('patientCode: $patientCode, ')
          ..write('documentDate: $documentDate, ')
          ..write('patientAge: $patientAge, ')
          ..write('sequence: $sequence, ')
          ..write('seqPat: $seqPat, ')
          ..write('doctorName: $doctorName, ')
          ..write('amount: $amount, ')
          ..write('content1: $content1, ')
          ..write('type1: $type1, ')
          ..write('content2: $content2, ')
          ..write('type2: $type2, ')
          ..write('content3: $content3, ')
          ..write('type3: $type3, ')
          ..write('additionalNotes: $additionalNotes, ')
          ..write('reportTitle: $reportTitle, ')
          ..write('referredBy: $referredBy, ')
          ..write('rdvFlag: $rdvFlag, ')
          ..write('rdvDate: $rdvDate, ')
          ..write('rdvDay: $rdvDay, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $MedicationsTable extends Medications
    with TableInfo<$MedicationsTable, Medication> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MedicationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _originalIdMeta =
      const VerificationMeta('originalId');
  @override
  late final GeneratedColumn<int> originalId = GeneratedColumn<int>(
      'original_id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _codeMeta = const VerificationMeta('code');
  @override
  late final GeneratedColumn<String> code = GeneratedColumn<String>(
      'code', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _prescriptionMeta =
      const VerificationMeta('prescription');
  @override
  late final GeneratedColumn<String> prescription = GeneratedColumn<String>(
      'prescription', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _usageCountMeta =
      const VerificationMeta('usageCount');
  @override
  late final GeneratedColumn<int> usageCount = GeneratedColumn<int>(
      'usage_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _natureMeta = const VerificationMeta('nature');
  @override
  late final GeneratedColumn<String> nature = GeneratedColumn<String>(
      'nature', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('O'));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        originalId,
        code,
        prescription,
        usageCount,
        nature,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'medications';
  @override
  VerificationContext validateIntegrity(Insertable<Medication> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('original_id')) {
      context.handle(
          _originalIdMeta,
          originalId.isAcceptableOrUnknown(
              data['original_id']!, _originalIdMeta));
    }
    if (data.containsKey('code')) {
      context.handle(
          _codeMeta, code.isAcceptableOrUnknown(data['code']!, _codeMeta));
    } else if (isInserting) {
      context.missing(_codeMeta);
    }
    if (data.containsKey('prescription')) {
      context.handle(
          _prescriptionMeta,
          prescription.isAcceptableOrUnknown(
              data['prescription']!, _prescriptionMeta));
    } else if (isInserting) {
      context.missing(_prescriptionMeta);
    }
    if (data.containsKey('usage_count')) {
      context.handle(
          _usageCountMeta,
          usageCount.isAcceptableOrUnknown(
              data['usage_count']!, _usageCountMeta));
    }
    if (data.containsKey('nature')) {
      context.handle(_natureMeta,
          nature.isAcceptableOrUnknown(data['nature']!, _natureMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Medication map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Medication(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      originalId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}original_id']),
      code: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}code'])!,
      prescription: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}prescription'])!,
      usageCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}usage_count'])!,
      nature: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}nature'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $MedicationsTable createAlias(String alias) {
    return $MedicationsTable(attachedDatabase, alias);
  }
}

class Medication extends DataClass implements Insertable<Medication> {
  /// Unique ID
  final int id;

  /// Original ID from import (IDPREPA)
  final int? originalId;

  /// Code/Name for search (CODELIB)
  final String code;

  /// Full prescription text with formatting (LIBPREP)
  final String prescription;

  /// Usage count - editable by user (NBPRES)
  final int usageCount;

  /// Nature: O = Ordonnance, N = Other (bilan, etc)
  final String nature;

  /// Timestamps
  final DateTime createdAt;
  final DateTime updatedAt;
  const Medication(
      {required this.id,
      this.originalId,
      required this.code,
      required this.prescription,
      required this.usageCount,
      required this.nature,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || originalId != null) {
      map['original_id'] = Variable<int>(originalId);
    }
    map['code'] = Variable<String>(code);
    map['prescription'] = Variable<String>(prescription);
    map['usage_count'] = Variable<int>(usageCount);
    map['nature'] = Variable<String>(nature);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  MedicationsCompanion toCompanion(bool nullToAbsent) {
    return MedicationsCompanion(
      id: Value(id),
      originalId: originalId == null && nullToAbsent
          ? const Value.absent()
          : Value(originalId),
      code: Value(code),
      prescription: Value(prescription),
      usageCount: Value(usageCount),
      nature: Value(nature),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Medication.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Medication(
      id: serializer.fromJson<int>(json['id']),
      originalId: serializer.fromJson<int?>(json['originalId']),
      code: serializer.fromJson<String>(json['code']),
      prescription: serializer.fromJson<String>(json['prescription']),
      usageCount: serializer.fromJson<int>(json['usageCount']),
      nature: serializer.fromJson<String>(json['nature']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'originalId': serializer.toJson<int?>(originalId),
      'code': serializer.toJson<String>(code),
      'prescription': serializer.toJson<String>(prescription),
      'usageCount': serializer.toJson<int>(usageCount),
      'nature': serializer.toJson<String>(nature),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Medication copyWith(
          {int? id,
          Value<int?> originalId = const Value.absent(),
          String? code,
          String? prescription,
          int? usageCount,
          String? nature,
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      Medication(
        id: id ?? this.id,
        originalId: originalId.present ? originalId.value : this.originalId,
        code: code ?? this.code,
        prescription: prescription ?? this.prescription,
        usageCount: usageCount ?? this.usageCount,
        nature: nature ?? this.nature,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  Medication copyWithCompanion(MedicationsCompanion data) {
    return Medication(
      id: data.id.present ? data.id.value : this.id,
      originalId:
          data.originalId.present ? data.originalId.value : this.originalId,
      code: data.code.present ? data.code.value : this.code,
      prescription: data.prescription.present
          ? data.prescription.value
          : this.prescription,
      usageCount:
          data.usageCount.present ? data.usageCount.value : this.usageCount,
      nature: data.nature.present ? data.nature.value : this.nature,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Medication(')
          ..write('id: $id, ')
          ..write('originalId: $originalId, ')
          ..write('code: $code, ')
          ..write('prescription: $prescription, ')
          ..write('usageCount: $usageCount, ')
          ..write('nature: $nature, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, originalId, code, prescription,
      usageCount, nature, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Medication &&
          other.id == this.id &&
          other.originalId == this.originalId &&
          other.code == this.code &&
          other.prescription == this.prescription &&
          other.usageCount == this.usageCount &&
          other.nature == this.nature &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class MedicationsCompanion extends UpdateCompanion<Medication> {
  final Value<int> id;
  final Value<int?> originalId;
  final Value<String> code;
  final Value<String> prescription;
  final Value<int> usageCount;
  final Value<String> nature;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const MedicationsCompanion({
    this.id = const Value.absent(),
    this.originalId = const Value.absent(),
    this.code = const Value.absent(),
    this.prescription = const Value.absent(),
    this.usageCount = const Value.absent(),
    this.nature = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  MedicationsCompanion.insert({
    this.id = const Value.absent(),
    this.originalId = const Value.absent(),
    required String code,
    required String prescription,
    this.usageCount = const Value.absent(),
    this.nature = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  })  : code = Value(code),
        prescription = Value(prescription);
  static Insertable<Medication> custom({
    Expression<int>? id,
    Expression<int>? originalId,
    Expression<String>? code,
    Expression<String>? prescription,
    Expression<int>? usageCount,
    Expression<String>? nature,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (originalId != null) 'original_id': originalId,
      if (code != null) 'code': code,
      if (prescription != null) 'prescription': prescription,
      if (usageCount != null) 'usage_count': usageCount,
      if (nature != null) 'nature': nature,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  MedicationsCompanion copyWith(
      {Value<int>? id,
      Value<int?>? originalId,
      Value<String>? code,
      Value<String>? prescription,
      Value<int>? usageCount,
      Value<String>? nature,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt}) {
    return MedicationsCompanion(
      id: id ?? this.id,
      originalId: originalId ?? this.originalId,
      code: code ?? this.code,
      prescription: prescription ?? this.prescription,
      usageCount: usageCount ?? this.usageCount,
      nature: nature ?? this.nature,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (originalId.present) {
      map['original_id'] = Variable<int>(originalId.value);
    }
    if (code.present) {
      map['code'] = Variable<String>(code.value);
    }
    if (prescription.present) {
      map['prescription'] = Variable<String>(prescription.value);
    }
    if (usageCount.present) {
      map['usage_count'] = Variable<int>(usageCount.value);
    }
    if (nature.present) {
      map['nature'] = Variable<String>(nature.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MedicationsCompanion(')
          ..write('id: $id, ')
          ..write('originalId: $originalId, ')
          ..write('code: $code, ')
          ..write('prescription: $prescription, ')
          ..write('usageCount: $usageCount, ')
          ..write('nature: $nature, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $UsersTable users = $UsersTable(this);
  late final $TemplatesTable templates = $TemplatesTable(this);
  late final $RoomsTable rooms = $RoomsTable(this);
  late final $PatientsTable patients = $PatientsTable(this);
  late final $MessageTemplatesTable messageTemplates =
      $MessageTemplatesTable(this);
  late final $MessagesTable messages = $MessagesTable(this);
  late final $MedicalActsTable medicalActs = $MedicalActsTable(this);
  late final $PaymentsTable payments = $PaymentsTable(this);
  late final $VisitsTable visits = $VisitsTable(this);
  late final $WaitingPatientsTable waitingPatients =
      $WaitingPatientsTable(this);
  late final $OrdonnancesTable ordonnances = $OrdonnancesTable(this);
  late final $MedicationsTable medications = $MedicationsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        users,
        templates,
        rooms,
        patients,
        messageTemplates,
        messages,
        medicalActs,
        payments,
        visits,
        waitingPatients,
        ordonnances,
        medications
      ];
  @override
  DriftDatabaseOptions get options =>
      const DriftDatabaseOptions(storeDateTimeAsText: true);
}

typedef $$UsersTableCreateCompanionBuilder = UsersCompanion Function({
  required String id,
  required String name,
  required String role,
  required String passwordHash,
  Value<double?> percentage,
  Value<bool> isTemplateUser,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<DateTime?> lastSyncedAt,
  Value<int> syncVersion,
  Value<bool> needsSync,
  Value<int> rowid,
});
typedef $$UsersTableUpdateCompanionBuilder = UsersCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String> role,
  Value<String> passwordHash,
  Value<double?> percentage,
  Value<bool> isTemplateUser,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<DateTime?> lastSyncedAt,
  Value<int> syncVersion,
  Value<bool> needsSync,
  Value<int> rowid,
});

class $$UsersTableFilterComposer extends Composer<_$AppDatabase, $UsersTable> {
  $$UsersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get role => $composableBuilder(
      column: $table.role, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get passwordHash => $composableBuilder(
      column: $table.passwordHash, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get percentage => $composableBuilder(
      column: $table.percentage, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isTemplateUser => $composableBuilder(
      column: $table.isTemplateUser,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastSyncedAt => $composableBuilder(
      column: $table.lastSyncedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get syncVersion => $composableBuilder(
      column: $table.syncVersion, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get needsSync => $composableBuilder(
      column: $table.needsSync, builder: (column) => ColumnFilters(column));
}

class $$UsersTableOrderingComposer
    extends Composer<_$AppDatabase, $UsersTable> {
  $$UsersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get role => $composableBuilder(
      column: $table.role, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get passwordHash => $composableBuilder(
      column: $table.passwordHash,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get percentage => $composableBuilder(
      column: $table.percentage, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isTemplateUser => $composableBuilder(
      column: $table.isTemplateUser,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastSyncedAt => $composableBuilder(
      column: $table.lastSyncedAt,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get syncVersion => $composableBuilder(
      column: $table.syncVersion, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get needsSync => $composableBuilder(
      column: $table.needsSync, builder: (column) => ColumnOrderings(column));
}

class $$UsersTableAnnotationComposer
    extends Composer<_$AppDatabase, $UsersTable> {
  $$UsersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<String> get passwordHash => $composableBuilder(
      column: $table.passwordHash, builder: (column) => column);

  GeneratedColumn<double> get percentage => $composableBuilder(
      column: $table.percentage, builder: (column) => column);

  GeneratedColumn<bool> get isTemplateUser => $composableBuilder(
      column: $table.isTemplateUser, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastSyncedAt => $composableBuilder(
      column: $table.lastSyncedAt, builder: (column) => column);

  GeneratedColumn<int> get syncVersion => $composableBuilder(
      column: $table.syncVersion, builder: (column) => column);

  GeneratedColumn<bool> get needsSync =>
      $composableBuilder(column: $table.needsSync, builder: (column) => column);
}

class $$UsersTableTableManager extends RootTableManager<
    _$AppDatabase,
    $UsersTable,
    UserEntity,
    $$UsersTableFilterComposer,
    $$UsersTableOrderingComposer,
    $$UsersTableAnnotationComposer,
    $$UsersTableCreateCompanionBuilder,
    $$UsersTableUpdateCompanionBuilder,
    (UserEntity, BaseReferences<_$AppDatabase, $UsersTable, UserEntity>),
    UserEntity,
    PrefetchHooks Function()> {
  $$UsersTableTableManager(_$AppDatabase db, $UsersTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UsersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UsersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UsersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> role = const Value.absent(),
            Value<String> passwordHash = const Value.absent(),
            Value<double?> percentage = const Value.absent(),
            Value<bool> isTemplateUser = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<DateTime?> lastSyncedAt = const Value.absent(),
            Value<int> syncVersion = const Value.absent(),
            Value<bool> needsSync = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              UsersCompanion(
            id: id,
            name: name,
            role: role,
            passwordHash: passwordHash,
            percentage: percentage,
            isTemplateUser: isTemplateUser,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            lastSyncedAt: lastSyncedAt,
            syncVersion: syncVersion,
            needsSync: needsSync,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            required String role,
            required String passwordHash,
            Value<double?> percentage = const Value.absent(),
            Value<bool> isTemplateUser = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<DateTime?> lastSyncedAt = const Value.absent(),
            Value<int> syncVersion = const Value.absent(),
            Value<bool> needsSync = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              UsersCompanion.insert(
            id: id,
            name: name,
            role: role,
            passwordHash: passwordHash,
            percentage: percentage,
            isTemplateUser: isTemplateUser,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            lastSyncedAt: lastSyncedAt,
            syncVersion: syncVersion,
            needsSync: needsSync,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$UsersTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $UsersTable,
    UserEntity,
    $$UsersTableFilterComposer,
    $$UsersTableOrderingComposer,
    $$UsersTableAnnotationComposer,
    $$UsersTableCreateCompanionBuilder,
    $$UsersTableUpdateCompanionBuilder,
    (UserEntity, BaseReferences<_$AppDatabase, $UsersTable, UserEntity>),
    UserEntity,
    PrefetchHooks Function()>;
typedef $$TemplatesTableCreateCompanionBuilder = TemplatesCompanion Function({
  required String id,
  required String role,
  required String passwordHash,
  required double percentage,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<DateTime?> lastSyncedAt,
  Value<int> syncVersion,
  Value<bool> needsSync,
  Value<int> rowid,
});
typedef $$TemplatesTableUpdateCompanionBuilder = TemplatesCompanion Function({
  Value<String> id,
  Value<String> role,
  Value<String> passwordHash,
  Value<double> percentage,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<DateTime?> lastSyncedAt,
  Value<int> syncVersion,
  Value<bool> needsSync,
  Value<int> rowid,
});

class $$TemplatesTableFilterComposer
    extends Composer<_$AppDatabase, $TemplatesTable> {
  $$TemplatesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get role => $composableBuilder(
      column: $table.role, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get passwordHash => $composableBuilder(
      column: $table.passwordHash, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get percentage => $composableBuilder(
      column: $table.percentage, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastSyncedAt => $composableBuilder(
      column: $table.lastSyncedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get syncVersion => $composableBuilder(
      column: $table.syncVersion, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get needsSync => $composableBuilder(
      column: $table.needsSync, builder: (column) => ColumnFilters(column));
}

class $$TemplatesTableOrderingComposer
    extends Composer<_$AppDatabase, $TemplatesTable> {
  $$TemplatesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get role => $composableBuilder(
      column: $table.role, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get passwordHash => $composableBuilder(
      column: $table.passwordHash,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get percentage => $composableBuilder(
      column: $table.percentage, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastSyncedAt => $composableBuilder(
      column: $table.lastSyncedAt,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get syncVersion => $composableBuilder(
      column: $table.syncVersion, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get needsSync => $composableBuilder(
      column: $table.needsSync, builder: (column) => ColumnOrderings(column));
}

class $$TemplatesTableAnnotationComposer
    extends Composer<_$AppDatabase, $TemplatesTable> {
  $$TemplatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<String> get passwordHash => $composableBuilder(
      column: $table.passwordHash, builder: (column) => column);

  GeneratedColumn<double> get percentage => $composableBuilder(
      column: $table.percentage, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastSyncedAt => $composableBuilder(
      column: $table.lastSyncedAt, builder: (column) => column);

  GeneratedColumn<int> get syncVersion => $composableBuilder(
      column: $table.syncVersion, builder: (column) => column);

  GeneratedColumn<bool> get needsSync =>
      $composableBuilder(column: $table.needsSync, builder: (column) => column);
}

class $$TemplatesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $TemplatesTable,
    TemplateEntity,
    $$TemplatesTableFilterComposer,
    $$TemplatesTableOrderingComposer,
    $$TemplatesTableAnnotationComposer,
    $$TemplatesTableCreateCompanionBuilder,
    $$TemplatesTableUpdateCompanionBuilder,
    (
      TemplateEntity,
      BaseReferences<_$AppDatabase, $TemplatesTable, TemplateEntity>
    ),
    TemplateEntity,
    PrefetchHooks Function()> {
  $$TemplatesTableTableManager(_$AppDatabase db, $TemplatesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TemplatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TemplatesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TemplatesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> role = const Value.absent(),
            Value<String> passwordHash = const Value.absent(),
            Value<double> percentage = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<DateTime?> lastSyncedAt = const Value.absent(),
            Value<int> syncVersion = const Value.absent(),
            Value<bool> needsSync = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              TemplatesCompanion(
            id: id,
            role: role,
            passwordHash: passwordHash,
            percentage: percentage,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            lastSyncedAt: lastSyncedAt,
            syncVersion: syncVersion,
            needsSync: needsSync,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String role,
            required String passwordHash,
            required double percentage,
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<DateTime?> lastSyncedAt = const Value.absent(),
            Value<int> syncVersion = const Value.absent(),
            Value<bool> needsSync = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              TemplatesCompanion.insert(
            id: id,
            role: role,
            passwordHash: passwordHash,
            percentage: percentage,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            lastSyncedAt: lastSyncedAt,
            syncVersion: syncVersion,
            needsSync: needsSync,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$TemplatesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $TemplatesTable,
    TemplateEntity,
    $$TemplatesTableFilterComposer,
    $$TemplatesTableOrderingComposer,
    $$TemplatesTableAnnotationComposer,
    $$TemplatesTableCreateCompanionBuilder,
    $$TemplatesTableUpdateCompanionBuilder,
    (
      TemplateEntity,
      BaseReferences<_$AppDatabase, $TemplatesTable, TemplateEntity>
    ),
    TemplateEntity,
    PrefetchHooks Function()>;
typedef $$RoomsTableCreateCompanionBuilder = RoomsCompanion Function({
  required String id,
  required String name,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<bool> needsSync,
  Value<int> rowid,
});
typedef $$RoomsTableUpdateCompanionBuilder = RoomsCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<bool> needsSync,
  Value<int> rowid,
});

class $$RoomsTableFilterComposer extends Composer<_$AppDatabase, $RoomsTable> {
  $$RoomsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get needsSync => $composableBuilder(
      column: $table.needsSync, builder: (column) => ColumnFilters(column));
}

class $$RoomsTableOrderingComposer
    extends Composer<_$AppDatabase, $RoomsTable> {
  $$RoomsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get needsSync => $composableBuilder(
      column: $table.needsSync, builder: (column) => ColumnOrderings(column));
}

class $$RoomsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RoomsTable> {
  $$RoomsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get needsSync =>
      $composableBuilder(column: $table.needsSync, builder: (column) => column);
}

class $$RoomsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $RoomsTable,
    Room,
    $$RoomsTableFilterComposer,
    $$RoomsTableOrderingComposer,
    $$RoomsTableAnnotationComposer,
    $$RoomsTableCreateCompanionBuilder,
    $$RoomsTableUpdateCompanionBuilder,
    (Room, BaseReferences<_$AppDatabase, $RoomsTable, Room>),
    Room,
    PrefetchHooks Function()> {
  $$RoomsTableTableManager(_$AppDatabase db, $RoomsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RoomsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RoomsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RoomsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<bool> needsSync = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              RoomsCompanion(
            id: id,
            name: name,
            createdAt: createdAt,
            updatedAt: updatedAt,
            needsSync: needsSync,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<bool> needsSync = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              RoomsCompanion.insert(
            id: id,
            name: name,
            createdAt: createdAt,
            updatedAt: updatedAt,
            needsSync: needsSync,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$RoomsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $RoomsTable,
    Room,
    $$RoomsTableFilterComposer,
    $$RoomsTableOrderingComposer,
    $$RoomsTableAnnotationComposer,
    $$RoomsTableCreateCompanionBuilder,
    $$RoomsTableUpdateCompanionBuilder,
    (Room, BaseReferences<_$AppDatabase, $RoomsTable, Room>),
    Room,
    PrefetchHooks Function()>;
typedef $$PatientsTableCreateCompanionBuilder = PatientsCompanion Function({
  Value<int> code,
  required String barcode,
  required DateTime createdAt,
  required String firstName,
  required String lastName,
  Value<int?> age,
  Value<DateTime?> dateOfBirth,
  Value<String?> address,
  Value<String?> phoneNumber,
  Value<String?> otherInfo,
  required DateTime updatedAt,
  Value<bool> needsSync,
});
typedef $$PatientsTableUpdateCompanionBuilder = PatientsCompanion Function({
  Value<int> code,
  Value<String> barcode,
  Value<DateTime> createdAt,
  Value<String> firstName,
  Value<String> lastName,
  Value<int?> age,
  Value<DateTime?> dateOfBirth,
  Value<String?> address,
  Value<String?> phoneNumber,
  Value<String?> otherInfo,
  Value<DateTime> updatedAt,
  Value<bool> needsSync,
});

class $$PatientsTableFilterComposer
    extends Composer<_$AppDatabase, $PatientsTable> {
  $$PatientsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get code => $composableBuilder(
      column: $table.code, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get barcode => $composableBuilder(
      column: $table.barcode, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get firstName => $composableBuilder(
      column: $table.firstName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get lastName => $composableBuilder(
      column: $table.lastName, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get age => $composableBuilder(
      column: $table.age, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get dateOfBirth => $composableBuilder(
      column: $table.dateOfBirth, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get address => $composableBuilder(
      column: $table.address, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get phoneNumber => $composableBuilder(
      column: $table.phoneNumber, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get otherInfo => $composableBuilder(
      column: $table.otherInfo, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get needsSync => $composableBuilder(
      column: $table.needsSync, builder: (column) => ColumnFilters(column));
}

class $$PatientsTableOrderingComposer
    extends Composer<_$AppDatabase, $PatientsTable> {
  $$PatientsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get code => $composableBuilder(
      column: $table.code, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get barcode => $composableBuilder(
      column: $table.barcode, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get firstName => $composableBuilder(
      column: $table.firstName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get lastName => $composableBuilder(
      column: $table.lastName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get age => $composableBuilder(
      column: $table.age, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get dateOfBirth => $composableBuilder(
      column: $table.dateOfBirth, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get address => $composableBuilder(
      column: $table.address, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get phoneNumber => $composableBuilder(
      column: $table.phoneNumber, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get otherInfo => $composableBuilder(
      column: $table.otherInfo, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get needsSync => $composableBuilder(
      column: $table.needsSync, builder: (column) => ColumnOrderings(column));
}

class $$PatientsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PatientsTable> {
  $$PatientsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get code =>
      $composableBuilder(column: $table.code, builder: (column) => column);

  GeneratedColumn<String> get barcode =>
      $composableBuilder(column: $table.barcode, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get firstName =>
      $composableBuilder(column: $table.firstName, builder: (column) => column);

  GeneratedColumn<String> get lastName =>
      $composableBuilder(column: $table.lastName, builder: (column) => column);

  GeneratedColumn<int> get age =>
      $composableBuilder(column: $table.age, builder: (column) => column);

  GeneratedColumn<DateTime> get dateOfBirth => $composableBuilder(
      column: $table.dateOfBirth, builder: (column) => column);

  GeneratedColumn<String> get address =>
      $composableBuilder(column: $table.address, builder: (column) => column);

  GeneratedColumn<String> get phoneNumber => $composableBuilder(
      column: $table.phoneNumber, builder: (column) => column);

  GeneratedColumn<String> get otherInfo =>
      $composableBuilder(column: $table.otherInfo, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get needsSync =>
      $composableBuilder(column: $table.needsSync, builder: (column) => column);
}

class $$PatientsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $PatientsTable,
    Patient,
    $$PatientsTableFilterComposer,
    $$PatientsTableOrderingComposer,
    $$PatientsTableAnnotationComposer,
    $$PatientsTableCreateCompanionBuilder,
    $$PatientsTableUpdateCompanionBuilder,
    (Patient, BaseReferences<_$AppDatabase, $PatientsTable, Patient>),
    Patient,
    PrefetchHooks Function()> {
  $$PatientsTableTableManager(_$AppDatabase db, $PatientsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PatientsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PatientsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PatientsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> code = const Value.absent(),
            Value<String> barcode = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<String> firstName = const Value.absent(),
            Value<String> lastName = const Value.absent(),
            Value<int?> age = const Value.absent(),
            Value<DateTime?> dateOfBirth = const Value.absent(),
            Value<String?> address = const Value.absent(),
            Value<String?> phoneNumber = const Value.absent(),
            Value<String?> otherInfo = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<bool> needsSync = const Value.absent(),
          }) =>
              PatientsCompanion(
            code: code,
            barcode: barcode,
            createdAt: createdAt,
            firstName: firstName,
            lastName: lastName,
            age: age,
            dateOfBirth: dateOfBirth,
            address: address,
            phoneNumber: phoneNumber,
            otherInfo: otherInfo,
            updatedAt: updatedAt,
            needsSync: needsSync,
          ),
          createCompanionCallback: ({
            Value<int> code = const Value.absent(),
            required String barcode,
            required DateTime createdAt,
            required String firstName,
            required String lastName,
            Value<int?> age = const Value.absent(),
            Value<DateTime?> dateOfBirth = const Value.absent(),
            Value<String?> address = const Value.absent(),
            Value<String?> phoneNumber = const Value.absent(),
            Value<String?> otherInfo = const Value.absent(),
            required DateTime updatedAt,
            Value<bool> needsSync = const Value.absent(),
          }) =>
              PatientsCompanion.insert(
            code: code,
            barcode: barcode,
            createdAt: createdAt,
            firstName: firstName,
            lastName: lastName,
            age: age,
            dateOfBirth: dateOfBirth,
            address: address,
            phoneNumber: phoneNumber,
            otherInfo: otherInfo,
            updatedAt: updatedAt,
            needsSync: needsSync,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$PatientsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $PatientsTable,
    Patient,
    $$PatientsTableFilterComposer,
    $$PatientsTableOrderingComposer,
    $$PatientsTableAnnotationComposer,
    $$PatientsTableCreateCompanionBuilder,
    $$PatientsTableUpdateCompanionBuilder,
    (Patient, BaseReferences<_$AppDatabase, $PatientsTable, Patient>),
    Patient,
    PrefetchHooks Function()>;
typedef $$MessageTemplatesTableCreateCompanionBuilder
    = MessageTemplatesCompanion Function({
  Value<int> id,
  required String content,
  required int displayOrder,
  required DateTime createdAt,
  Value<String?> createdBy,
});
typedef $$MessageTemplatesTableUpdateCompanionBuilder
    = MessageTemplatesCompanion Function({
  Value<int> id,
  Value<String> content,
  Value<int> displayOrder,
  Value<DateTime> createdAt,
  Value<String?> createdBy,
});

class $$MessageTemplatesTableFilterComposer
    extends Composer<_$AppDatabase, $MessageTemplatesTable> {
  $$MessageTemplatesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get content => $composableBuilder(
      column: $table.content, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get displayOrder => $composableBuilder(
      column: $table.displayOrder, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get createdBy => $composableBuilder(
      column: $table.createdBy, builder: (column) => ColumnFilters(column));
}

class $$MessageTemplatesTableOrderingComposer
    extends Composer<_$AppDatabase, $MessageTemplatesTable> {
  $$MessageTemplatesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get content => $composableBuilder(
      column: $table.content, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get displayOrder => $composableBuilder(
      column: $table.displayOrder,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get createdBy => $composableBuilder(
      column: $table.createdBy, builder: (column) => ColumnOrderings(column));
}

class $$MessageTemplatesTableAnnotationComposer
    extends Composer<_$AppDatabase, $MessageTemplatesTable> {
  $$MessageTemplatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<int> get displayOrder => $composableBuilder(
      column: $table.displayOrder, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get createdBy =>
      $composableBuilder(column: $table.createdBy, builder: (column) => column);
}

class $$MessageTemplatesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $MessageTemplatesTable,
    MessageTemplate,
    $$MessageTemplatesTableFilterComposer,
    $$MessageTemplatesTableOrderingComposer,
    $$MessageTemplatesTableAnnotationComposer,
    $$MessageTemplatesTableCreateCompanionBuilder,
    $$MessageTemplatesTableUpdateCompanionBuilder,
    (
      MessageTemplate,
      BaseReferences<_$AppDatabase, $MessageTemplatesTable, MessageTemplate>
    ),
    MessageTemplate,
    PrefetchHooks Function()> {
  $$MessageTemplatesTableTableManager(
      _$AppDatabase db, $MessageTemplatesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MessageTemplatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MessageTemplatesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MessageTemplatesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> content = const Value.absent(),
            Value<int> displayOrder = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<String?> createdBy = const Value.absent(),
          }) =>
              MessageTemplatesCompanion(
            id: id,
            content: content,
            displayOrder: displayOrder,
            createdAt: createdAt,
            createdBy: createdBy,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String content,
            required int displayOrder,
            required DateTime createdAt,
            Value<String?> createdBy = const Value.absent(),
          }) =>
              MessageTemplatesCompanion.insert(
            id: id,
            content: content,
            displayOrder: displayOrder,
            createdAt: createdAt,
            createdBy: createdBy,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$MessageTemplatesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $MessageTemplatesTable,
    MessageTemplate,
    $$MessageTemplatesTableFilterComposer,
    $$MessageTemplatesTableOrderingComposer,
    $$MessageTemplatesTableAnnotationComposer,
    $$MessageTemplatesTableCreateCompanionBuilder,
    $$MessageTemplatesTableUpdateCompanionBuilder,
    (
      MessageTemplate,
      BaseReferences<_$AppDatabase, $MessageTemplatesTable, MessageTemplate>
    ),
    MessageTemplate,
    PrefetchHooks Function()>;
typedef $$MessagesTableCreateCompanionBuilder = MessagesCompanion Function({
  Value<int> id,
  required String roomId,
  required String senderId,
  required String senderName,
  required String senderRole,
  required String content,
  required String direction,
  Value<bool> isRead,
  required DateTime sentAt,
  Value<DateTime?> readAt,
  Value<int?> patientCode,
  Value<String?> patientName,
});
typedef $$MessagesTableUpdateCompanionBuilder = MessagesCompanion Function({
  Value<int> id,
  Value<String> roomId,
  Value<String> senderId,
  Value<String> senderName,
  Value<String> senderRole,
  Value<String> content,
  Value<String> direction,
  Value<bool> isRead,
  Value<DateTime> sentAt,
  Value<DateTime?> readAt,
  Value<int?> patientCode,
  Value<String?> patientName,
});

class $$MessagesTableFilterComposer
    extends Composer<_$AppDatabase, $MessagesTable> {
  $$MessagesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get roomId => $composableBuilder(
      column: $table.roomId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get senderId => $composableBuilder(
      column: $table.senderId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get senderName => $composableBuilder(
      column: $table.senderName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get senderRole => $composableBuilder(
      column: $table.senderRole, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get content => $composableBuilder(
      column: $table.content, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get direction => $composableBuilder(
      column: $table.direction, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isRead => $composableBuilder(
      column: $table.isRead, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get sentAt => $composableBuilder(
      column: $table.sentAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get readAt => $composableBuilder(
      column: $table.readAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get patientCode => $composableBuilder(
      column: $table.patientCode, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get patientName => $composableBuilder(
      column: $table.patientName, builder: (column) => ColumnFilters(column));
}

class $$MessagesTableOrderingComposer
    extends Composer<_$AppDatabase, $MessagesTable> {
  $$MessagesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get roomId => $composableBuilder(
      column: $table.roomId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get senderId => $composableBuilder(
      column: $table.senderId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get senderName => $composableBuilder(
      column: $table.senderName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get senderRole => $composableBuilder(
      column: $table.senderRole, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get content => $composableBuilder(
      column: $table.content, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get direction => $composableBuilder(
      column: $table.direction, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isRead => $composableBuilder(
      column: $table.isRead, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get sentAt => $composableBuilder(
      column: $table.sentAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get readAt => $composableBuilder(
      column: $table.readAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get patientCode => $composableBuilder(
      column: $table.patientCode, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get patientName => $composableBuilder(
      column: $table.patientName, builder: (column) => ColumnOrderings(column));
}

class $$MessagesTableAnnotationComposer
    extends Composer<_$AppDatabase, $MessagesTable> {
  $$MessagesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get roomId =>
      $composableBuilder(column: $table.roomId, builder: (column) => column);

  GeneratedColumn<String> get senderId =>
      $composableBuilder(column: $table.senderId, builder: (column) => column);

  GeneratedColumn<String> get senderName => $composableBuilder(
      column: $table.senderName, builder: (column) => column);

  GeneratedColumn<String> get senderRole => $composableBuilder(
      column: $table.senderRole, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<String> get direction =>
      $composableBuilder(column: $table.direction, builder: (column) => column);

  GeneratedColumn<bool> get isRead =>
      $composableBuilder(column: $table.isRead, builder: (column) => column);

  GeneratedColumn<DateTime> get sentAt =>
      $composableBuilder(column: $table.sentAt, builder: (column) => column);

  GeneratedColumn<DateTime> get readAt =>
      $composableBuilder(column: $table.readAt, builder: (column) => column);

  GeneratedColumn<int> get patientCode => $composableBuilder(
      column: $table.patientCode, builder: (column) => column);

  GeneratedColumn<String> get patientName => $composableBuilder(
      column: $table.patientName, builder: (column) => column);
}

class $$MessagesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $MessagesTable,
    Message,
    $$MessagesTableFilterComposer,
    $$MessagesTableOrderingComposer,
    $$MessagesTableAnnotationComposer,
    $$MessagesTableCreateCompanionBuilder,
    $$MessagesTableUpdateCompanionBuilder,
    (Message, BaseReferences<_$AppDatabase, $MessagesTable, Message>),
    Message,
    PrefetchHooks Function()> {
  $$MessagesTableTableManager(_$AppDatabase db, $MessagesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MessagesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MessagesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MessagesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> roomId = const Value.absent(),
            Value<String> senderId = const Value.absent(),
            Value<String> senderName = const Value.absent(),
            Value<String> senderRole = const Value.absent(),
            Value<String> content = const Value.absent(),
            Value<String> direction = const Value.absent(),
            Value<bool> isRead = const Value.absent(),
            Value<DateTime> sentAt = const Value.absent(),
            Value<DateTime?> readAt = const Value.absent(),
            Value<int?> patientCode = const Value.absent(),
            Value<String?> patientName = const Value.absent(),
          }) =>
              MessagesCompanion(
            id: id,
            roomId: roomId,
            senderId: senderId,
            senderName: senderName,
            senderRole: senderRole,
            content: content,
            direction: direction,
            isRead: isRead,
            sentAt: sentAt,
            readAt: readAt,
            patientCode: patientCode,
            patientName: patientName,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String roomId,
            required String senderId,
            required String senderName,
            required String senderRole,
            required String content,
            required String direction,
            Value<bool> isRead = const Value.absent(),
            required DateTime sentAt,
            Value<DateTime?> readAt = const Value.absent(),
            Value<int?> patientCode = const Value.absent(),
            Value<String?> patientName = const Value.absent(),
          }) =>
              MessagesCompanion.insert(
            id: id,
            roomId: roomId,
            senderId: senderId,
            senderName: senderName,
            senderRole: senderRole,
            content: content,
            direction: direction,
            isRead: isRead,
            sentAt: sentAt,
            readAt: readAt,
            patientCode: patientCode,
            patientName: patientName,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$MessagesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $MessagesTable,
    Message,
    $$MessagesTableFilterComposer,
    $$MessagesTableOrderingComposer,
    $$MessagesTableAnnotationComposer,
    $$MessagesTableCreateCompanionBuilder,
    $$MessagesTableUpdateCompanionBuilder,
    (Message, BaseReferences<_$AppDatabase, $MessagesTable, Message>),
    Message,
    PrefetchHooks Function()>;
typedef $$MedicalActsTableCreateCompanionBuilder = MedicalActsCompanion
    Function({
  Value<int> id,
  required String name,
  required int feeAmount,
  required int displayOrder,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<bool> isActive,
});
typedef $$MedicalActsTableUpdateCompanionBuilder = MedicalActsCompanion
    Function({
  Value<int> id,
  Value<String> name,
  Value<int> feeAmount,
  Value<int> displayOrder,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<bool> isActive,
});

class $$MedicalActsTableFilterComposer
    extends Composer<_$AppDatabase, $MedicalActsTable> {
  $$MedicalActsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get feeAmount => $composableBuilder(
      column: $table.feeAmount, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get displayOrder => $composableBuilder(
      column: $table.displayOrder, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnFilters(column));
}

class $$MedicalActsTableOrderingComposer
    extends Composer<_$AppDatabase, $MedicalActsTable> {
  $$MedicalActsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get feeAmount => $composableBuilder(
      column: $table.feeAmount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get displayOrder => $composableBuilder(
      column: $table.displayOrder,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnOrderings(column));
}

class $$MedicalActsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MedicalActsTable> {
  $$MedicalActsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get feeAmount =>
      $composableBuilder(column: $table.feeAmount, builder: (column) => column);

  GeneratedColumn<int> get displayOrder => $composableBuilder(
      column: $table.displayOrder, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);
}

class $$MedicalActsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $MedicalActsTable,
    MedicalAct,
    $$MedicalActsTableFilterComposer,
    $$MedicalActsTableOrderingComposer,
    $$MedicalActsTableAnnotationComposer,
    $$MedicalActsTableCreateCompanionBuilder,
    $$MedicalActsTableUpdateCompanionBuilder,
    (MedicalAct, BaseReferences<_$AppDatabase, $MedicalActsTable, MedicalAct>),
    MedicalAct,
    PrefetchHooks Function()> {
  $$MedicalActsTableTableManager(_$AppDatabase db, $MedicalActsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MedicalActsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MedicalActsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MedicalActsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<int> feeAmount = const Value.absent(),
            Value<int> displayOrder = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
          }) =>
              MedicalActsCompanion(
            id: id,
            name: name,
            feeAmount: feeAmount,
            displayOrder: displayOrder,
            createdAt: createdAt,
            updatedAt: updatedAt,
            isActive: isActive,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String name,
            required int feeAmount,
            required int displayOrder,
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<bool> isActive = const Value.absent(),
          }) =>
              MedicalActsCompanion.insert(
            id: id,
            name: name,
            feeAmount: feeAmount,
            displayOrder: displayOrder,
            createdAt: createdAt,
            updatedAt: updatedAt,
            isActive: isActive,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$MedicalActsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $MedicalActsTable,
    MedicalAct,
    $$MedicalActsTableFilterComposer,
    $$MedicalActsTableOrderingComposer,
    $$MedicalActsTableAnnotationComposer,
    $$MedicalActsTableCreateCompanionBuilder,
    $$MedicalActsTableUpdateCompanionBuilder,
    (MedicalAct, BaseReferences<_$AppDatabase, $MedicalActsTable, MedicalAct>),
    MedicalAct,
    PrefetchHooks Function()>;
typedef $$PaymentsTableCreateCompanionBuilder = PaymentsCompanion Function({
  Value<int> id,
  required int medicalActId,
  required String medicalActName,
  required int amount,
  required String userId,
  required String userName,
  required int patientCode,
  required String patientFirstName,
  required String patientLastName,
  required DateTime paymentTime,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<bool> needsSync,
  Value<bool> isActive,
});
typedef $$PaymentsTableUpdateCompanionBuilder = PaymentsCompanion Function({
  Value<int> id,
  Value<int> medicalActId,
  Value<String> medicalActName,
  Value<int> amount,
  Value<String> userId,
  Value<String> userName,
  Value<int> patientCode,
  Value<String> patientFirstName,
  Value<String> patientLastName,
  Value<DateTime> paymentTime,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<bool> needsSync,
  Value<bool> isActive,
});

class $$PaymentsTableFilterComposer
    extends Composer<_$AppDatabase, $PaymentsTable> {
  $$PaymentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get medicalActId => $composableBuilder(
      column: $table.medicalActId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get medicalActName => $composableBuilder(
      column: $table.medicalActName,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userName => $composableBuilder(
      column: $table.userName, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get patientCode => $composableBuilder(
      column: $table.patientCode, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get patientFirstName => $composableBuilder(
      column: $table.patientFirstName,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get patientLastName => $composableBuilder(
      column: $table.patientLastName,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get paymentTime => $composableBuilder(
      column: $table.paymentTime, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get needsSync => $composableBuilder(
      column: $table.needsSync, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnFilters(column));
}

class $$PaymentsTableOrderingComposer
    extends Composer<_$AppDatabase, $PaymentsTable> {
  $$PaymentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get medicalActId => $composableBuilder(
      column: $table.medicalActId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get medicalActName => $composableBuilder(
      column: $table.medicalActName,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userName => $composableBuilder(
      column: $table.userName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get patientCode => $composableBuilder(
      column: $table.patientCode, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get patientFirstName => $composableBuilder(
      column: $table.patientFirstName,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get patientLastName => $composableBuilder(
      column: $table.patientLastName,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get paymentTime => $composableBuilder(
      column: $table.paymentTime, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get needsSync => $composableBuilder(
      column: $table.needsSync, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnOrderings(column));
}

class $$PaymentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PaymentsTable> {
  $$PaymentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get medicalActId => $composableBuilder(
      column: $table.medicalActId, builder: (column) => column);

  GeneratedColumn<String> get medicalActName => $composableBuilder(
      column: $table.medicalActName, builder: (column) => column);

  GeneratedColumn<int> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get userName =>
      $composableBuilder(column: $table.userName, builder: (column) => column);

  GeneratedColumn<int> get patientCode => $composableBuilder(
      column: $table.patientCode, builder: (column) => column);

  GeneratedColumn<String> get patientFirstName => $composableBuilder(
      column: $table.patientFirstName, builder: (column) => column);

  GeneratedColumn<String> get patientLastName => $composableBuilder(
      column: $table.patientLastName, builder: (column) => column);

  GeneratedColumn<DateTime> get paymentTime => $composableBuilder(
      column: $table.paymentTime, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get needsSync =>
      $composableBuilder(column: $table.needsSync, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);
}

class $$PaymentsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $PaymentsTable,
    Payment,
    $$PaymentsTableFilterComposer,
    $$PaymentsTableOrderingComposer,
    $$PaymentsTableAnnotationComposer,
    $$PaymentsTableCreateCompanionBuilder,
    $$PaymentsTableUpdateCompanionBuilder,
    (Payment, BaseReferences<_$AppDatabase, $PaymentsTable, Payment>),
    Payment,
    PrefetchHooks Function()> {
  $$PaymentsTableTableManager(_$AppDatabase db, $PaymentsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PaymentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PaymentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PaymentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> medicalActId = const Value.absent(),
            Value<String> medicalActName = const Value.absent(),
            Value<int> amount = const Value.absent(),
            Value<String> userId = const Value.absent(),
            Value<String> userName = const Value.absent(),
            Value<int> patientCode = const Value.absent(),
            Value<String> patientFirstName = const Value.absent(),
            Value<String> patientLastName = const Value.absent(),
            Value<DateTime> paymentTime = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<bool> needsSync = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
          }) =>
              PaymentsCompanion(
            id: id,
            medicalActId: medicalActId,
            medicalActName: medicalActName,
            amount: amount,
            userId: userId,
            userName: userName,
            patientCode: patientCode,
            patientFirstName: patientFirstName,
            patientLastName: patientLastName,
            paymentTime: paymentTime,
            createdAt: createdAt,
            updatedAt: updatedAt,
            needsSync: needsSync,
            isActive: isActive,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int medicalActId,
            required String medicalActName,
            required int amount,
            required String userId,
            required String userName,
            required int patientCode,
            required String patientFirstName,
            required String patientLastName,
            required DateTime paymentTime,
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<bool> needsSync = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
          }) =>
              PaymentsCompanion.insert(
            id: id,
            medicalActId: medicalActId,
            medicalActName: medicalActName,
            amount: amount,
            userId: userId,
            userName: userName,
            patientCode: patientCode,
            patientFirstName: patientFirstName,
            patientLastName: patientLastName,
            paymentTime: paymentTime,
            createdAt: createdAt,
            updatedAt: updatedAt,
            needsSync: needsSync,
            isActive: isActive,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$PaymentsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $PaymentsTable,
    Payment,
    $$PaymentsTableFilterComposer,
    $$PaymentsTableOrderingComposer,
    $$PaymentsTableAnnotationComposer,
    $$PaymentsTableCreateCompanionBuilder,
    $$PaymentsTableUpdateCompanionBuilder,
    (Payment, BaseReferences<_$AppDatabase, $PaymentsTable, Payment>),
    Payment,
    PrefetchHooks Function()>;
typedef $$VisitsTableCreateCompanionBuilder = VisitsCompanion Function({
  Value<int> id,
  Value<int?> originalId,
  required int patientCode,
  Value<int> visitSequence,
  required DateTime visitDate,
  required String doctorName,
  Value<String?> motif,
  Value<String?> diagnosis,
  Value<String?> conduct,
  Value<String?> odSv,
  Value<String?> odAv,
  Value<String?> odSphere,
  Value<String?> odCylinder,
  Value<String?> odAxis,
  Value<String?> odVl,
  Value<String?> odK1,
  Value<String?> odK2,
  Value<String?> odR1,
  Value<String?> odR2,
  Value<String?> odR0,
  Value<String?> odPachy,
  Value<String?> odToc,
  Value<String?> odNotes,
  Value<String?> odGonio,
  Value<String?> odTo,
  Value<String?> odLaf,
  Value<String?> odFo,
  Value<String?> ogSv,
  Value<String?> ogAv,
  Value<String?> ogSphere,
  Value<String?> ogCylinder,
  Value<String?> ogAxis,
  Value<String?> ogVl,
  Value<String?> ogK1,
  Value<String?> ogK2,
  Value<String?> ogR1,
  Value<String?> ogR2,
  Value<String?> ogR0,
  Value<String?> ogPachy,
  Value<String?> ogToc,
  Value<String?> ogNotes,
  Value<String?> ogGonio,
  Value<String?> ogTo,
  Value<String?> ogLaf,
  Value<String?> ogFo,
  Value<String?> addition,
  Value<String?> dip,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<bool> needsSync,
  Value<bool> isActive,
});
typedef $$VisitsTableUpdateCompanionBuilder = VisitsCompanion Function({
  Value<int> id,
  Value<int?> originalId,
  Value<int> patientCode,
  Value<int> visitSequence,
  Value<DateTime> visitDate,
  Value<String> doctorName,
  Value<String?> motif,
  Value<String?> diagnosis,
  Value<String?> conduct,
  Value<String?> odSv,
  Value<String?> odAv,
  Value<String?> odSphere,
  Value<String?> odCylinder,
  Value<String?> odAxis,
  Value<String?> odVl,
  Value<String?> odK1,
  Value<String?> odK2,
  Value<String?> odR1,
  Value<String?> odR2,
  Value<String?> odR0,
  Value<String?> odPachy,
  Value<String?> odToc,
  Value<String?> odNotes,
  Value<String?> odGonio,
  Value<String?> odTo,
  Value<String?> odLaf,
  Value<String?> odFo,
  Value<String?> ogSv,
  Value<String?> ogAv,
  Value<String?> ogSphere,
  Value<String?> ogCylinder,
  Value<String?> ogAxis,
  Value<String?> ogVl,
  Value<String?> ogK1,
  Value<String?> ogK2,
  Value<String?> ogR1,
  Value<String?> ogR2,
  Value<String?> ogR0,
  Value<String?> ogPachy,
  Value<String?> ogToc,
  Value<String?> ogNotes,
  Value<String?> ogGonio,
  Value<String?> ogTo,
  Value<String?> ogLaf,
  Value<String?> ogFo,
  Value<String?> addition,
  Value<String?> dip,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<bool> needsSync,
  Value<bool> isActive,
});

class $$VisitsTableFilterComposer
    extends Composer<_$AppDatabase, $VisitsTable> {
  $$VisitsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get originalId => $composableBuilder(
      column: $table.originalId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get patientCode => $composableBuilder(
      column: $table.patientCode, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get visitSequence => $composableBuilder(
      column: $table.visitSequence, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get visitDate => $composableBuilder(
      column: $table.visitDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get doctorName => $composableBuilder(
      column: $table.doctorName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get motif => $composableBuilder(
      column: $table.motif, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get diagnosis => $composableBuilder(
      column: $table.diagnosis, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get conduct => $composableBuilder(
      column: $table.conduct, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get odSv => $composableBuilder(
      column: $table.odSv, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get odAv => $composableBuilder(
      column: $table.odAv, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get odSphere => $composableBuilder(
      column: $table.odSphere, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get odCylinder => $composableBuilder(
      column: $table.odCylinder, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get odAxis => $composableBuilder(
      column: $table.odAxis, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get odVl => $composableBuilder(
      column: $table.odVl, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get odK1 => $composableBuilder(
      column: $table.odK1, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get odK2 => $composableBuilder(
      column: $table.odK2, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get odR1 => $composableBuilder(
      column: $table.odR1, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get odR2 => $composableBuilder(
      column: $table.odR2, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get odR0 => $composableBuilder(
      column: $table.odR0, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get odPachy => $composableBuilder(
      column: $table.odPachy, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get odToc => $composableBuilder(
      column: $table.odToc, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get odNotes => $composableBuilder(
      column: $table.odNotes, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get odGonio => $composableBuilder(
      column: $table.odGonio, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get odTo => $composableBuilder(
      column: $table.odTo, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get odLaf => $composableBuilder(
      column: $table.odLaf, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get odFo => $composableBuilder(
      column: $table.odFo, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get ogSv => $composableBuilder(
      column: $table.ogSv, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get ogAv => $composableBuilder(
      column: $table.ogAv, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get ogSphere => $composableBuilder(
      column: $table.ogSphere, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get ogCylinder => $composableBuilder(
      column: $table.ogCylinder, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get ogAxis => $composableBuilder(
      column: $table.ogAxis, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get ogVl => $composableBuilder(
      column: $table.ogVl, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get ogK1 => $composableBuilder(
      column: $table.ogK1, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get ogK2 => $composableBuilder(
      column: $table.ogK2, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get ogR1 => $composableBuilder(
      column: $table.ogR1, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get ogR2 => $composableBuilder(
      column: $table.ogR2, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get ogR0 => $composableBuilder(
      column: $table.ogR0, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get ogPachy => $composableBuilder(
      column: $table.ogPachy, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get ogToc => $composableBuilder(
      column: $table.ogToc, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get ogNotes => $composableBuilder(
      column: $table.ogNotes, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get ogGonio => $composableBuilder(
      column: $table.ogGonio, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get ogTo => $composableBuilder(
      column: $table.ogTo, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get ogLaf => $composableBuilder(
      column: $table.ogLaf, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get ogFo => $composableBuilder(
      column: $table.ogFo, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get addition => $composableBuilder(
      column: $table.addition, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get dip => $composableBuilder(
      column: $table.dip, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get needsSync => $composableBuilder(
      column: $table.needsSync, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnFilters(column));
}

class $$VisitsTableOrderingComposer
    extends Composer<_$AppDatabase, $VisitsTable> {
  $$VisitsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get originalId => $composableBuilder(
      column: $table.originalId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get patientCode => $composableBuilder(
      column: $table.patientCode, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get visitSequence => $composableBuilder(
      column: $table.visitSequence,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get visitDate => $composableBuilder(
      column: $table.visitDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get doctorName => $composableBuilder(
      column: $table.doctorName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get motif => $composableBuilder(
      column: $table.motif, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get diagnosis => $composableBuilder(
      column: $table.diagnosis, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get conduct => $composableBuilder(
      column: $table.conduct, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get odSv => $composableBuilder(
      column: $table.odSv, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get odAv => $composableBuilder(
      column: $table.odAv, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get odSphere => $composableBuilder(
      column: $table.odSphere, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get odCylinder => $composableBuilder(
      column: $table.odCylinder, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get odAxis => $composableBuilder(
      column: $table.odAxis, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get odVl => $composableBuilder(
      column: $table.odVl, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get odK1 => $composableBuilder(
      column: $table.odK1, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get odK2 => $composableBuilder(
      column: $table.odK2, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get odR1 => $composableBuilder(
      column: $table.odR1, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get odR2 => $composableBuilder(
      column: $table.odR2, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get odR0 => $composableBuilder(
      column: $table.odR0, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get odPachy => $composableBuilder(
      column: $table.odPachy, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get odToc => $composableBuilder(
      column: $table.odToc, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get odNotes => $composableBuilder(
      column: $table.odNotes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get odGonio => $composableBuilder(
      column: $table.odGonio, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get odTo => $composableBuilder(
      column: $table.odTo, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get odLaf => $composableBuilder(
      column: $table.odLaf, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get odFo => $composableBuilder(
      column: $table.odFo, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get ogSv => $composableBuilder(
      column: $table.ogSv, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get ogAv => $composableBuilder(
      column: $table.ogAv, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get ogSphere => $composableBuilder(
      column: $table.ogSphere, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get ogCylinder => $composableBuilder(
      column: $table.ogCylinder, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get ogAxis => $composableBuilder(
      column: $table.ogAxis, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get ogVl => $composableBuilder(
      column: $table.ogVl, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get ogK1 => $composableBuilder(
      column: $table.ogK1, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get ogK2 => $composableBuilder(
      column: $table.ogK2, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get ogR1 => $composableBuilder(
      column: $table.ogR1, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get ogR2 => $composableBuilder(
      column: $table.ogR2, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get ogR0 => $composableBuilder(
      column: $table.ogR0, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get ogPachy => $composableBuilder(
      column: $table.ogPachy, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get ogToc => $composableBuilder(
      column: $table.ogToc, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get ogNotes => $composableBuilder(
      column: $table.ogNotes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get ogGonio => $composableBuilder(
      column: $table.ogGonio, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get ogTo => $composableBuilder(
      column: $table.ogTo, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get ogLaf => $composableBuilder(
      column: $table.ogLaf, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get ogFo => $composableBuilder(
      column: $table.ogFo, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get addition => $composableBuilder(
      column: $table.addition, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get dip => $composableBuilder(
      column: $table.dip, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get needsSync => $composableBuilder(
      column: $table.needsSync, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnOrderings(column));
}

class $$VisitsTableAnnotationComposer
    extends Composer<_$AppDatabase, $VisitsTable> {
  $$VisitsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get originalId => $composableBuilder(
      column: $table.originalId, builder: (column) => column);

  GeneratedColumn<int> get patientCode => $composableBuilder(
      column: $table.patientCode, builder: (column) => column);

  GeneratedColumn<int> get visitSequence => $composableBuilder(
      column: $table.visitSequence, builder: (column) => column);

  GeneratedColumn<DateTime> get visitDate =>
      $composableBuilder(column: $table.visitDate, builder: (column) => column);

  GeneratedColumn<String> get doctorName => $composableBuilder(
      column: $table.doctorName, builder: (column) => column);

  GeneratedColumn<String> get motif =>
      $composableBuilder(column: $table.motif, builder: (column) => column);

  GeneratedColumn<String> get diagnosis =>
      $composableBuilder(column: $table.diagnosis, builder: (column) => column);

  GeneratedColumn<String> get conduct =>
      $composableBuilder(column: $table.conduct, builder: (column) => column);

  GeneratedColumn<String> get odSv =>
      $composableBuilder(column: $table.odSv, builder: (column) => column);

  GeneratedColumn<String> get odAv =>
      $composableBuilder(column: $table.odAv, builder: (column) => column);

  GeneratedColumn<String> get odSphere =>
      $composableBuilder(column: $table.odSphere, builder: (column) => column);

  GeneratedColumn<String> get odCylinder => $composableBuilder(
      column: $table.odCylinder, builder: (column) => column);

  GeneratedColumn<String> get odAxis =>
      $composableBuilder(column: $table.odAxis, builder: (column) => column);

  GeneratedColumn<String> get odVl =>
      $composableBuilder(column: $table.odVl, builder: (column) => column);

  GeneratedColumn<String> get odK1 =>
      $composableBuilder(column: $table.odK1, builder: (column) => column);

  GeneratedColumn<String> get odK2 =>
      $composableBuilder(column: $table.odK2, builder: (column) => column);

  GeneratedColumn<String> get odR1 =>
      $composableBuilder(column: $table.odR1, builder: (column) => column);

  GeneratedColumn<String> get odR2 =>
      $composableBuilder(column: $table.odR2, builder: (column) => column);

  GeneratedColumn<String> get odR0 =>
      $composableBuilder(column: $table.odR0, builder: (column) => column);

  GeneratedColumn<String> get odPachy =>
      $composableBuilder(column: $table.odPachy, builder: (column) => column);

  GeneratedColumn<String> get odToc =>
      $composableBuilder(column: $table.odToc, builder: (column) => column);

  GeneratedColumn<String> get odNotes =>
      $composableBuilder(column: $table.odNotes, builder: (column) => column);

  GeneratedColumn<String> get odGonio =>
      $composableBuilder(column: $table.odGonio, builder: (column) => column);

  GeneratedColumn<String> get odTo =>
      $composableBuilder(column: $table.odTo, builder: (column) => column);

  GeneratedColumn<String> get odLaf =>
      $composableBuilder(column: $table.odLaf, builder: (column) => column);

  GeneratedColumn<String> get odFo =>
      $composableBuilder(column: $table.odFo, builder: (column) => column);

  GeneratedColumn<String> get ogSv =>
      $composableBuilder(column: $table.ogSv, builder: (column) => column);

  GeneratedColumn<String> get ogAv =>
      $composableBuilder(column: $table.ogAv, builder: (column) => column);

  GeneratedColumn<String> get ogSphere =>
      $composableBuilder(column: $table.ogSphere, builder: (column) => column);

  GeneratedColumn<String> get ogCylinder => $composableBuilder(
      column: $table.ogCylinder, builder: (column) => column);

  GeneratedColumn<String> get ogAxis =>
      $composableBuilder(column: $table.ogAxis, builder: (column) => column);

  GeneratedColumn<String> get ogVl =>
      $composableBuilder(column: $table.ogVl, builder: (column) => column);

  GeneratedColumn<String> get ogK1 =>
      $composableBuilder(column: $table.ogK1, builder: (column) => column);

  GeneratedColumn<String> get ogK2 =>
      $composableBuilder(column: $table.ogK2, builder: (column) => column);

  GeneratedColumn<String> get ogR1 =>
      $composableBuilder(column: $table.ogR1, builder: (column) => column);

  GeneratedColumn<String> get ogR2 =>
      $composableBuilder(column: $table.ogR2, builder: (column) => column);

  GeneratedColumn<String> get ogR0 =>
      $composableBuilder(column: $table.ogR0, builder: (column) => column);

  GeneratedColumn<String> get ogPachy =>
      $composableBuilder(column: $table.ogPachy, builder: (column) => column);

  GeneratedColumn<String> get ogToc =>
      $composableBuilder(column: $table.ogToc, builder: (column) => column);

  GeneratedColumn<String> get ogNotes =>
      $composableBuilder(column: $table.ogNotes, builder: (column) => column);

  GeneratedColumn<String> get ogGonio =>
      $composableBuilder(column: $table.ogGonio, builder: (column) => column);

  GeneratedColumn<String> get ogTo =>
      $composableBuilder(column: $table.ogTo, builder: (column) => column);

  GeneratedColumn<String> get ogLaf =>
      $composableBuilder(column: $table.ogLaf, builder: (column) => column);

  GeneratedColumn<String> get ogFo =>
      $composableBuilder(column: $table.ogFo, builder: (column) => column);

  GeneratedColumn<String> get addition =>
      $composableBuilder(column: $table.addition, builder: (column) => column);

  GeneratedColumn<String> get dip =>
      $composableBuilder(column: $table.dip, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get needsSync =>
      $composableBuilder(column: $table.needsSync, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);
}

class $$VisitsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $VisitsTable,
    Visit,
    $$VisitsTableFilterComposer,
    $$VisitsTableOrderingComposer,
    $$VisitsTableAnnotationComposer,
    $$VisitsTableCreateCompanionBuilder,
    $$VisitsTableUpdateCompanionBuilder,
    (Visit, BaseReferences<_$AppDatabase, $VisitsTable, Visit>),
    Visit,
    PrefetchHooks Function()> {
  $$VisitsTableTableManager(_$AppDatabase db, $VisitsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VisitsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$VisitsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$VisitsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int?> originalId = const Value.absent(),
            Value<int> patientCode = const Value.absent(),
            Value<int> visitSequence = const Value.absent(),
            Value<DateTime> visitDate = const Value.absent(),
            Value<String> doctorName = const Value.absent(),
            Value<String?> motif = const Value.absent(),
            Value<String?> diagnosis = const Value.absent(),
            Value<String?> conduct = const Value.absent(),
            Value<String?> odSv = const Value.absent(),
            Value<String?> odAv = const Value.absent(),
            Value<String?> odSphere = const Value.absent(),
            Value<String?> odCylinder = const Value.absent(),
            Value<String?> odAxis = const Value.absent(),
            Value<String?> odVl = const Value.absent(),
            Value<String?> odK1 = const Value.absent(),
            Value<String?> odK2 = const Value.absent(),
            Value<String?> odR1 = const Value.absent(),
            Value<String?> odR2 = const Value.absent(),
            Value<String?> odR0 = const Value.absent(),
            Value<String?> odPachy = const Value.absent(),
            Value<String?> odToc = const Value.absent(),
            Value<String?> odNotes = const Value.absent(),
            Value<String?> odGonio = const Value.absent(),
            Value<String?> odTo = const Value.absent(),
            Value<String?> odLaf = const Value.absent(),
            Value<String?> odFo = const Value.absent(),
            Value<String?> ogSv = const Value.absent(),
            Value<String?> ogAv = const Value.absent(),
            Value<String?> ogSphere = const Value.absent(),
            Value<String?> ogCylinder = const Value.absent(),
            Value<String?> ogAxis = const Value.absent(),
            Value<String?> ogVl = const Value.absent(),
            Value<String?> ogK1 = const Value.absent(),
            Value<String?> ogK2 = const Value.absent(),
            Value<String?> ogR1 = const Value.absent(),
            Value<String?> ogR2 = const Value.absent(),
            Value<String?> ogR0 = const Value.absent(),
            Value<String?> ogPachy = const Value.absent(),
            Value<String?> ogToc = const Value.absent(),
            Value<String?> ogNotes = const Value.absent(),
            Value<String?> ogGonio = const Value.absent(),
            Value<String?> ogTo = const Value.absent(),
            Value<String?> ogLaf = const Value.absent(),
            Value<String?> ogFo = const Value.absent(),
            Value<String?> addition = const Value.absent(),
            Value<String?> dip = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<bool> needsSync = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
          }) =>
              VisitsCompanion(
            id: id,
            originalId: originalId,
            patientCode: patientCode,
            visitSequence: visitSequence,
            visitDate: visitDate,
            doctorName: doctorName,
            motif: motif,
            diagnosis: diagnosis,
            conduct: conduct,
            odSv: odSv,
            odAv: odAv,
            odSphere: odSphere,
            odCylinder: odCylinder,
            odAxis: odAxis,
            odVl: odVl,
            odK1: odK1,
            odK2: odK2,
            odR1: odR1,
            odR2: odR2,
            odR0: odR0,
            odPachy: odPachy,
            odToc: odToc,
            odNotes: odNotes,
            odGonio: odGonio,
            odTo: odTo,
            odLaf: odLaf,
            odFo: odFo,
            ogSv: ogSv,
            ogAv: ogAv,
            ogSphere: ogSphere,
            ogCylinder: ogCylinder,
            ogAxis: ogAxis,
            ogVl: ogVl,
            ogK1: ogK1,
            ogK2: ogK2,
            ogR1: ogR1,
            ogR2: ogR2,
            ogR0: ogR0,
            ogPachy: ogPachy,
            ogToc: ogToc,
            ogNotes: ogNotes,
            ogGonio: ogGonio,
            ogTo: ogTo,
            ogLaf: ogLaf,
            ogFo: ogFo,
            addition: addition,
            dip: dip,
            createdAt: createdAt,
            updatedAt: updatedAt,
            needsSync: needsSync,
            isActive: isActive,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int?> originalId = const Value.absent(),
            required int patientCode,
            Value<int> visitSequence = const Value.absent(),
            required DateTime visitDate,
            required String doctorName,
            Value<String?> motif = const Value.absent(),
            Value<String?> diagnosis = const Value.absent(),
            Value<String?> conduct = const Value.absent(),
            Value<String?> odSv = const Value.absent(),
            Value<String?> odAv = const Value.absent(),
            Value<String?> odSphere = const Value.absent(),
            Value<String?> odCylinder = const Value.absent(),
            Value<String?> odAxis = const Value.absent(),
            Value<String?> odVl = const Value.absent(),
            Value<String?> odK1 = const Value.absent(),
            Value<String?> odK2 = const Value.absent(),
            Value<String?> odR1 = const Value.absent(),
            Value<String?> odR2 = const Value.absent(),
            Value<String?> odR0 = const Value.absent(),
            Value<String?> odPachy = const Value.absent(),
            Value<String?> odToc = const Value.absent(),
            Value<String?> odNotes = const Value.absent(),
            Value<String?> odGonio = const Value.absent(),
            Value<String?> odTo = const Value.absent(),
            Value<String?> odLaf = const Value.absent(),
            Value<String?> odFo = const Value.absent(),
            Value<String?> ogSv = const Value.absent(),
            Value<String?> ogAv = const Value.absent(),
            Value<String?> ogSphere = const Value.absent(),
            Value<String?> ogCylinder = const Value.absent(),
            Value<String?> ogAxis = const Value.absent(),
            Value<String?> ogVl = const Value.absent(),
            Value<String?> ogK1 = const Value.absent(),
            Value<String?> ogK2 = const Value.absent(),
            Value<String?> ogR1 = const Value.absent(),
            Value<String?> ogR2 = const Value.absent(),
            Value<String?> ogR0 = const Value.absent(),
            Value<String?> ogPachy = const Value.absent(),
            Value<String?> ogToc = const Value.absent(),
            Value<String?> ogNotes = const Value.absent(),
            Value<String?> ogGonio = const Value.absent(),
            Value<String?> ogTo = const Value.absent(),
            Value<String?> ogLaf = const Value.absent(),
            Value<String?> ogFo = const Value.absent(),
            Value<String?> addition = const Value.absent(),
            Value<String?> dip = const Value.absent(),
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<bool> needsSync = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
          }) =>
              VisitsCompanion.insert(
            id: id,
            originalId: originalId,
            patientCode: patientCode,
            visitSequence: visitSequence,
            visitDate: visitDate,
            doctorName: doctorName,
            motif: motif,
            diagnosis: diagnosis,
            conduct: conduct,
            odSv: odSv,
            odAv: odAv,
            odSphere: odSphere,
            odCylinder: odCylinder,
            odAxis: odAxis,
            odVl: odVl,
            odK1: odK1,
            odK2: odK2,
            odR1: odR1,
            odR2: odR2,
            odR0: odR0,
            odPachy: odPachy,
            odToc: odToc,
            odNotes: odNotes,
            odGonio: odGonio,
            odTo: odTo,
            odLaf: odLaf,
            odFo: odFo,
            ogSv: ogSv,
            ogAv: ogAv,
            ogSphere: ogSphere,
            ogCylinder: ogCylinder,
            ogAxis: ogAxis,
            ogVl: ogVl,
            ogK1: ogK1,
            ogK2: ogK2,
            ogR1: ogR1,
            ogR2: ogR2,
            ogR0: ogR0,
            ogPachy: ogPachy,
            ogToc: ogToc,
            ogNotes: ogNotes,
            ogGonio: ogGonio,
            ogTo: ogTo,
            ogLaf: ogLaf,
            ogFo: ogFo,
            addition: addition,
            dip: dip,
            createdAt: createdAt,
            updatedAt: updatedAt,
            needsSync: needsSync,
            isActive: isActive,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$VisitsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $VisitsTable,
    Visit,
    $$VisitsTableFilterComposer,
    $$VisitsTableOrderingComposer,
    $$VisitsTableAnnotationComposer,
    $$VisitsTableCreateCompanionBuilder,
    $$VisitsTableUpdateCompanionBuilder,
    (Visit, BaseReferences<_$AppDatabase, $VisitsTable, Visit>),
    Visit,
    PrefetchHooks Function()>;
typedef $$WaitingPatientsTableCreateCompanionBuilder = WaitingPatientsCompanion
    Function({
  Value<int> id,
  required int patientCode,
  required String patientFirstName,
  required String patientLastName,
  Value<DateTime?> patientBirthDate,
  Value<int?> patientAge,
  Value<bool> isUrgent,
  Value<bool> isDilatation,
  Value<String?> dilatationType,
  required String roomId,
  required String roomName,
  required String motif,
  required String sentByUserId,
  required String sentByUserName,
  required DateTime sentAt,
  Value<bool> isChecked,
  Value<bool> isActive,
  Value<bool> isNotified,
});
typedef $$WaitingPatientsTableUpdateCompanionBuilder = WaitingPatientsCompanion
    Function({
  Value<int> id,
  Value<int> patientCode,
  Value<String> patientFirstName,
  Value<String> patientLastName,
  Value<DateTime?> patientBirthDate,
  Value<int?> patientAge,
  Value<bool> isUrgent,
  Value<bool> isDilatation,
  Value<String?> dilatationType,
  Value<String> roomId,
  Value<String> roomName,
  Value<String> motif,
  Value<String> sentByUserId,
  Value<String> sentByUserName,
  Value<DateTime> sentAt,
  Value<bool> isChecked,
  Value<bool> isActive,
  Value<bool> isNotified,
});

class $$WaitingPatientsTableFilterComposer
    extends Composer<_$AppDatabase, $WaitingPatientsTable> {
  $$WaitingPatientsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get patientCode => $composableBuilder(
      column: $table.patientCode, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get patientFirstName => $composableBuilder(
      column: $table.patientFirstName,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get patientLastName => $composableBuilder(
      column: $table.patientLastName,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get patientBirthDate => $composableBuilder(
      column: $table.patientBirthDate,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get patientAge => $composableBuilder(
      column: $table.patientAge, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isUrgent => $composableBuilder(
      column: $table.isUrgent, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isDilatation => $composableBuilder(
      column: $table.isDilatation, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get dilatationType => $composableBuilder(
      column: $table.dilatationType,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get roomId => $composableBuilder(
      column: $table.roomId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get roomName => $composableBuilder(
      column: $table.roomName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get motif => $composableBuilder(
      column: $table.motif, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sentByUserId => $composableBuilder(
      column: $table.sentByUserId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sentByUserName => $composableBuilder(
      column: $table.sentByUserName,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get sentAt => $composableBuilder(
      column: $table.sentAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isChecked => $composableBuilder(
      column: $table.isChecked, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isNotified => $composableBuilder(
      column: $table.isNotified, builder: (column) => ColumnFilters(column));
}

class $$WaitingPatientsTableOrderingComposer
    extends Composer<_$AppDatabase, $WaitingPatientsTable> {
  $$WaitingPatientsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get patientCode => $composableBuilder(
      column: $table.patientCode, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get patientFirstName => $composableBuilder(
      column: $table.patientFirstName,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get patientLastName => $composableBuilder(
      column: $table.patientLastName,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get patientBirthDate => $composableBuilder(
      column: $table.patientBirthDate,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get patientAge => $composableBuilder(
      column: $table.patientAge, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isUrgent => $composableBuilder(
      column: $table.isUrgent, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isDilatation => $composableBuilder(
      column: $table.isDilatation,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get dilatationType => $composableBuilder(
      column: $table.dilatationType,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get roomId => $composableBuilder(
      column: $table.roomId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get roomName => $composableBuilder(
      column: $table.roomName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get motif => $composableBuilder(
      column: $table.motif, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sentByUserId => $composableBuilder(
      column: $table.sentByUserId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sentByUserName => $composableBuilder(
      column: $table.sentByUserName,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get sentAt => $composableBuilder(
      column: $table.sentAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isChecked => $composableBuilder(
      column: $table.isChecked, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isNotified => $composableBuilder(
      column: $table.isNotified, builder: (column) => ColumnOrderings(column));
}

class $$WaitingPatientsTableAnnotationComposer
    extends Composer<_$AppDatabase, $WaitingPatientsTable> {
  $$WaitingPatientsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get patientCode => $composableBuilder(
      column: $table.patientCode, builder: (column) => column);

  GeneratedColumn<String> get patientFirstName => $composableBuilder(
      column: $table.patientFirstName, builder: (column) => column);

  GeneratedColumn<String> get patientLastName => $composableBuilder(
      column: $table.patientLastName, builder: (column) => column);

  GeneratedColumn<DateTime> get patientBirthDate => $composableBuilder(
      column: $table.patientBirthDate, builder: (column) => column);

  GeneratedColumn<int> get patientAge => $composableBuilder(
      column: $table.patientAge, builder: (column) => column);

  GeneratedColumn<bool> get isUrgent =>
      $composableBuilder(column: $table.isUrgent, builder: (column) => column);

  GeneratedColumn<bool> get isDilatation => $composableBuilder(
      column: $table.isDilatation, builder: (column) => column);

  GeneratedColumn<String> get dilatationType => $composableBuilder(
      column: $table.dilatationType, builder: (column) => column);

  GeneratedColumn<String> get roomId =>
      $composableBuilder(column: $table.roomId, builder: (column) => column);

  GeneratedColumn<String> get roomName =>
      $composableBuilder(column: $table.roomName, builder: (column) => column);

  GeneratedColumn<String> get motif =>
      $composableBuilder(column: $table.motif, builder: (column) => column);

  GeneratedColumn<String> get sentByUserId => $composableBuilder(
      column: $table.sentByUserId, builder: (column) => column);

  GeneratedColumn<String> get sentByUserName => $composableBuilder(
      column: $table.sentByUserName, builder: (column) => column);

  GeneratedColumn<DateTime> get sentAt =>
      $composableBuilder(column: $table.sentAt, builder: (column) => column);

  GeneratedColumn<bool> get isChecked =>
      $composableBuilder(column: $table.isChecked, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<bool> get isNotified => $composableBuilder(
      column: $table.isNotified, builder: (column) => column);
}

class $$WaitingPatientsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $WaitingPatientsTable,
    WaitingPatient,
    $$WaitingPatientsTableFilterComposer,
    $$WaitingPatientsTableOrderingComposer,
    $$WaitingPatientsTableAnnotationComposer,
    $$WaitingPatientsTableCreateCompanionBuilder,
    $$WaitingPatientsTableUpdateCompanionBuilder,
    (
      WaitingPatient,
      BaseReferences<_$AppDatabase, $WaitingPatientsTable, WaitingPatient>
    ),
    WaitingPatient,
    PrefetchHooks Function()> {
  $$WaitingPatientsTableTableManager(
      _$AppDatabase db, $WaitingPatientsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WaitingPatientsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WaitingPatientsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WaitingPatientsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> patientCode = const Value.absent(),
            Value<String> patientFirstName = const Value.absent(),
            Value<String> patientLastName = const Value.absent(),
            Value<DateTime?> patientBirthDate = const Value.absent(),
            Value<int?> patientAge = const Value.absent(),
            Value<bool> isUrgent = const Value.absent(),
            Value<bool> isDilatation = const Value.absent(),
            Value<String?> dilatationType = const Value.absent(),
            Value<String> roomId = const Value.absent(),
            Value<String> roomName = const Value.absent(),
            Value<String> motif = const Value.absent(),
            Value<String> sentByUserId = const Value.absent(),
            Value<String> sentByUserName = const Value.absent(),
            Value<DateTime> sentAt = const Value.absent(),
            Value<bool> isChecked = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
            Value<bool> isNotified = const Value.absent(),
          }) =>
              WaitingPatientsCompanion(
            id: id,
            patientCode: patientCode,
            patientFirstName: patientFirstName,
            patientLastName: patientLastName,
            patientBirthDate: patientBirthDate,
            patientAge: patientAge,
            isUrgent: isUrgent,
            isDilatation: isDilatation,
            dilatationType: dilatationType,
            roomId: roomId,
            roomName: roomName,
            motif: motif,
            sentByUserId: sentByUserId,
            sentByUserName: sentByUserName,
            sentAt: sentAt,
            isChecked: isChecked,
            isActive: isActive,
            isNotified: isNotified,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int patientCode,
            required String patientFirstName,
            required String patientLastName,
            Value<DateTime?> patientBirthDate = const Value.absent(),
            Value<int?> patientAge = const Value.absent(),
            Value<bool> isUrgent = const Value.absent(),
            Value<bool> isDilatation = const Value.absent(),
            Value<String?> dilatationType = const Value.absent(),
            required String roomId,
            required String roomName,
            required String motif,
            required String sentByUserId,
            required String sentByUserName,
            required DateTime sentAt,
            Value<bool> isChecked = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
            Value<bool> isNotified = const Value.absent(),
          }) =>
              WaitingPatientsCompanion.insert(
            id: id,
            patientCode: patientCode,
            patientFirstName: patientFirstName,
            patientLastName: patientLastName,
            patientBirthDate: patientBirthDate,
            patientAge: patientAge,
            isUrgent: isUrgent,
            isDilatation: isDilatation,
            dilatationType: dilatationType,
            roomId: roomId,
            roomName: roomName,
            motif: motif,
            sentByUserId: sentByUserId,
            sentByUserName: sentByUserName,
            sentAt: sentAt,
            isChecked: isChecked,
            isActive: isActive,
            isNotified: isNotified,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$WaitingPatientsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $WaitingPatientsTable,
    WaitingPatient,
    $$WaitingPatientsTableFilterComposer,
    $$WaitingPatientsTableOrderingComposer,
    $$WaitingPatientsTableAnnotationComposer,
    $$WaitingPatientsTableCreateCompanionBuilder,
    $$WaitingPatientsTableUpdateCompanionBuilder,
    (
      WaitingPatient,
      BaseReferences<_$AppDatabase, $WaitingPatientsTable, WaitingPatient>
    ),
    WaitingPatient,
    PrefetchHooks Function()>;
typedef $$OrdonnancesTableCreateCompanionBuilder = OrdonnancesCompanion
    Function({
  Value<int> id,
  Value<int?> originalId,
  required int patientCode,
  Value<DateTime?> documentDate,
  Value<int?> patientAge,
  Value<int> sequence,
  Value<String?> seqPat,
  Value<String?> doctorName,
  Value<double> amount,
  Value<String?> content1,
  Value<String> type1,
  Value<String?> content2,
  Value<String?> type2,
  Value<String?> content3,
  Value<String?> type3,
  Value<String?> additionalNotes,
  Value<String?> reportTitle,
  Value<String?> referredBy,
  Value<int> rdvFlag,
  Value<String?> rdvDate,
  Value<String?> rdvDay,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});
typedef $$OrdonnancesTableUpdateCompanionBuilder = OrdonnancesCompanion
    Function({
  Value<int> id,
  Value<int?> originalId,
  Value<int> patientCode,
  Value<DateTime?> documentDate,
  Value<int?> patientAge,
  Value<int> sequence,
  Value<String?> seqPat,
  Value<String?> doctorName,
  Value<double> amount,
  Value<String?> content1,
  Value<String> type1,
  Value<String?> content2,
  Value<String?> type2,
  Value<String?> content3,
  Value<String?> type3,
  Value<String?> additionalNotes,
  Value<String?> reportTitle,
  Value<String?> referredBy,
  Value<int> rdvFlag,
  Value<String?> rdvDate,
  Value<String?> rdvDay,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});

class $$OrdonnancesTableFilterComposer
    extends Composer<_$AppDatabase, $OrdonnancesTable> {
  $$OrdonnancesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get originalId => $composableBuilder(
      column: $table.originalId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get patientCode => $composableBuilder(
      column: $table.patientCode, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get documentDate => $composableBuilder(
      column: $table.documentDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get patientAge => $composableBuilder(
      column: $table.patientAge, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sequence => $composableBuilder(
      column: $table.sequence, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get seqPat => $composableBuilder(
      column: $table.seqPat, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get doctorName => $composableBuilder(
      column: $table.doctorName, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get content1 => $composableBuilder(
      column: $table.content1, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get type1 => $composableBuilder(
      column: $table.type1, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get content2 => $composableBuilder(
      column: $table.content2, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get type2 => $composableBuilder(
      column: $table.type2, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get content3 => $composableBuilder(
      column: $table.content3, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get type3 => $composableBuilder(
      column: $table.type3, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get additionalNotes => $composableBuilder(
      column: $table.additionalNotes,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get reportTitle => $composableBuilder(
      column: $table.reportTitle, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get referredBy => $composableBuilder(
      column: $table.referredBy, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get rdvFlag => $composableBuilder(
      column: $table.rdvFlag, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get rdvDate => $composableBuilder(
      column: $table.rdvDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get rdvDay => $composableBuilder(
      column: $table.rdvDay, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$OrdonnancesTableOrderingComposer
    extends Composer<_$AppDatabase, $OrdonnancesTable> {
  $$OrdonnancesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get originalId => $composableBuilder(
      column: $table.originalId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get patientCode => $composableBuilder(
      column: $table.patientCode, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get documentDate => $composableBuilder(
      column: $table.documentDate,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get patientAge => $composableBuilder(
      column: $table.patientAge, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sequence => $composableBuilder(
      column: $table.sequence, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get seqPat => $composableBuilder(
      column: $table.seqPat, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get doctorName => $composableBuilder(
      column: $table.doctorName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get content1 => $composableBuilder(
      column: $table.content1, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get type1 => $composableBuilder(
      column: $table.type1, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get content2 => $composableBuilder(
      column: $table.content2, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get type2 => $composableBuilder(
      column: $table.type2, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get content3 => $composableBuilder(
      column: $table.content3, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get type3 => $composableBuilder(
      column: $table.type3, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get additionalNotes => $composableBuilder(
      column: $table.additionalNotes,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get reportTitle => $composableBuilder(
      column: $table.reportTitle, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get referredBy => $composableBuilder(
      column: $table.referredBy, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get rdvFlag => $composableBuilder(
      column: $table.rdvFlag, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get rdvDate => $composableBuilder(
      column: $table.rdvDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get rdvDay => $composableBuilder(
      column: $table.rdvDay, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$OrdonnancesTableAnnotationComposer
    extends Composer<_$AppDatabase, $OrdonnancesTable> {
  $$OrdonnancesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get originalId => $composableBuilder(
      column: $table.originalId, builder: (column) => column);

  GeneratedColumn<int> get patientCode => $composableBuilder(
      column: $table.patientCode, builder: (column) => column);

  GeneratedColumn<DateTime> get documentDate => $composableBuilder(
      column: $table.documentDate, builder: (column) => column);

  GeneratedColumn<int> get patientAge => $composableBuilder(
      column: $table.patientAge, builder: (column) => column);

  GeneratedColumn<int> get sequence =>
      $composableBuilder(column: $table.sequence, builder: (column) => column);

  GeneratedColumn<String> get seqPat =>
      $composableBuilder(column: $table.seqPat, builder: (column) => column);

  GeneratedColumn<String> get doctorName => $composableBuilder(
      column: $table.doctorName, builder: (column) => column);

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get content1 =>
      $composableBuilder(column: $table.content1, builder: (column) => column);

  GeneratedColumn<String> get type1 =>
      $composableBuilder(column: $table.type1, builder: (column) => column);

  GeneratedColumn<String> get content2 =>
      $composableBuilder(column: $table.content2, builder: (column) => column);

  GeneratedColumn<String> get type2 =>
      $composableBuilder(column: $table.type2, builder: (column) => column);

  GeneratedColumn<String> get content3 =>
      $composableBuilder(column: $table.content3, builder: (column) => column);

  GeneratedColumn<String> get type3 =>
      $composableBuilder(column: $table.type3, builder: (column) => column);

  GeneratedColumn<String> get additionalNotes => $composableBuilder(
      column: $table.additionalNotes, builder: (column) => column);

  GeneratedColumn<String> get reportTitle => $composableBuilder(
      column: $table.reportTitle, builder: (column) => column);

  GeneratedColumn<String> get referredBy => $composableBuilder(
      column: $table.referredBy, builder: (column) => column);

  GeneratedColumn<int> get rdvFlag =>
      $composableBuilder(column: $table.rdvFlag, builder: (column) => column);

  GeneratedColumn<String> get rdvDate =>
      $composableBuilder(column: $table.rdvDate, builder: (column) => column);

  GeneratedColumn<String> get rdvDay =>
      $composableBuilder(column: $table.rdvDay, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$OrdonnancesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $OrdonnancesTable,
    Ordonnance,
    $$OrdonnancesTableFilterComposer,
    $$OrdonnancesTableOrderingComposer,
    $$OrdonnancesTableAnnotationComposer,
    $$OrdonnancesTableCreateCompanionBuilder,
    $$OrdonnancesTableUpdateCompanionBuilder,
    (Ordonnance, BaseReferences<_$AppDatabase, $OrdonnancesTable, Ordonnance>),
    Ordonnance,
    PrefetchHooks Function()> {
  $$OrdonnancesTableTableManager(_$AppDatabase db, $OrdonnancesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OrdonnancesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OrdonnancesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OrdonnancesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int?> originalId = const Value.absent(),
            Value<int> patientCode = const Value.absent(),
            Value<DateTime?> documentDate = const Value.absent(),
            Value<int?> patientAge = const Value.absent(),
            Value<int> sequence = const Value.absent(),
            Value<String?> seqPat = const Value.absent(),
            Value<String?> doctorName = const Value.absent(),
            Value<double> amount = const Value.absent(),
            Value<String?> content1 = const Value.absent(),
            Value<String> type1 = const Value.absent(),
            Value<String?> content2 = const Value.absent(),
            Value<String?> type2 = const Value.absent(),
            Value<String?> content3 = const Value.absent(),
            Value<String?> type3 = const Value.absent(),
            Value<String?> additionalNotes = const Value.absent(),
            Value<String?> reportTitle = const Value.absent(),
            Value<String?> referredBy = const Value.absent(),
            Value<int> rdvFlag = const Value.absent(),
            Value<String?> rdvDate = const Value.absent(),
            Value<String?> rdvDay = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              OrdonnancesCompanion(
            id: id,
            originalId: originalId,
            patientCode: patientCode,
            documentDate: documentDate,
            patientAge: patientAge,
            sequence: sequence,
            seqPat: seqPat,
            doctorName: doctorName,
            amount: amount,
            content1: content1,
            type1: type1,
            content2: content2,
            type2: type2,
            content3: content3,
            type3: type3,
            additionalNotes: additionalNotes,
            reportTitle: reportTitle,
            referredBy: referredBy,
            rdvFlag: rdvFlag,
            rdvDate: rdvDate,
            rdvDay: rdvDay,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int?> originalId = const Value.absent(),
            required int patientCode,
            Value<DateTime?> documentDate = const Value.absent(),
            Value<int?> patientAge = const Value.absent(),
            Value<int> sequence = const Value.absent(),
            Value<String?> seqPat = const Value.absent(),
            Value<String?> doctorName = const Value.absent(),
            Value<double> amount = const Value.absent(),
            Value<String?> content1 = const Value.absent(),
            Value<String> type1 = const Value.absent(),
            Value<String?> content2 = const Value.absent(),
            Value<String?> type2 = const Value.absent(),
            Value<String?> content3 = const Value.absent(),
            Value<String?> type3 = const Value.absent(),
            Value<String?> additionalNotes = const Value.absent(),
            Value<String?> reportTitle = const Value.absent(),
            Value<String?> referredBy = const Value.absent(),
            Value<int> rdvFlag = const Value.absent(),
            Value<String?> rdvDate = const Value.absent(),
            Value<String?> rdvDay = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              OrdonnancesCompanion.insert(
            id: id,
            originalId: originalId,
            patientCode: patientCode,
            documentDate: documentDate,
            patientAge: patientAge,
            sequence: sequence,
            seqPat: seqPat,
            doctorName: doctorName,
            amount: amount,
            content1: content1,
            type1: type1,
            content2: content2,
            type2: type2,
            content3: content3,
            type3: type3,
            additionalNotes: additionalNotes,
            reportTitle: reportTitle,
            referredBy: referredBy,
            rdvFlag: rdvFlag,
            rdvDate: rdvDate,
            rdvDay: rdvDay,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$OrdonnancesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $OrdonnancesTable,
    Ordonnance,
    $$OrdonnancesTableFilterComposer,
    $$OrdonnancesTableOrderingComposer,
    $$OrdonnancesTableAnnotationComposer,
    $$OrdonnancesTableCreateCompanionBuilder,
    $$OrdonnancesTableUpdateCompanionBuilder,
    (Ordonnance, BaseReferences<_$AppDatabase, $OrdonnancesTable, Ordonnance>),
    Ordonnance,
    PrefetchHooks Function()>;
typedef $$MedicationsTableCreateCompanionBuilder = MedicationsCompanion
    Function({
  Value<int> id,
  Value<int?> originalId,
  required String code,
  required String prescription,
  Value<int> usageCount,
  Value<String> nature,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});
typedef $$MedicationsTableUpdateCompanionBuilder = MedicationsCompanion
    Function({
  Value<int> id,
  Value<int?> originalId,
  Value<String> code,
  Value<String> prescription,
  Value<int> usageCount,
  Value<String> nature,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});

class $$MedicationsTableFilterComposer
    extends Composer<_$AppDatabase, $MedicationsTable> {
  $$MedicationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get originalId => $composableBuilder(
      column: $table.originalId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get code => $composableBuilder(
      column: $table.code, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get prescription => $composableBuilder(
      column: $table.prescription, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get usageCount => $composableBuilder(
      column: $table.usageCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get nature => $composableBuilder(
      column: $table.nature, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$MedicationsTableOrderingComposer
    extends Composer<_$AppDatabase, $MedicationsTable> {
  $$MedicationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get originalId => $composableBuilder(
      column: $table.originalId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get code => $composableBuilder(
      column: $table.code, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get prescription => $composableBuilder(
      column: $table.prescription,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get usageCount => $composableBuilder(
      column: $table.usageCount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get nature => $composableBuilder(
      column: $table.nature, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$MedicationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MedicationsTable> {
  $$MedicationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get originalId => $composableBuilder(
      column: $table.originalId, builder: (column) => column);

  GeneratedColumn<String> get code =>
      $composableBuilder(column: $table.code, builder: (column) => column);

  GeneratedColumn<String> get prescription => $composableBuilder(
      column: $table.prescription, builder: (column) => column);

  GeneratedColumn<int> get usageCount => $composableBuilder(
      column: $table.usageCount, builder: (column) => column);

  GeneratedColumn<String> get nature =>
      $composableBuilder(column: $table.nature, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$MedicationsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $MedicationsTable,
    Medication,
    $$MedicationsTableFilterComposer,
    $$MedicationsTableOrderingComposer,
    $$MedicationsTableAnnotationComposer,
    $$MedicationsTableCreateCompanionBuilder,
    $$MedicationsTableUpdateCompanionBuilder,
    (Medication, BaseReferences<_$AppDatabase, $MedicationsTable, Medication>),
    Medication,
    PrefetchHooks Function()> {
  $$MedicationsTableTableManager(_$AppDatabase db, $MedicationsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MedicationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MedicationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MedicationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int?> originalId = const Value.absent(),
            Value<String> code = const Value.absent(),
            Value<String> prescription = const Value.absent(),
            Value<int> usageCount = const Value.absent(),
            Value<String> nature = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              MedicationsCompanion(
            id: id,
            originalId: originalId,
            code: code,
            prescription: prescription,
            usageCount: usageCount,
            nature: nature,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int?> originalId = const Value.absent(),
            required String code,
            required String prescription,
            Value<int> usageCount = const Value.absent(),
            Value<String> nature = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              MedicationsCompanion.insert(
            id: id,
            originalId: originalId,
            code: code,
            prescription: prescription,
            usageCount: usageCount,
            nature: nature,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$MedicationsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $MedicationsTable,
    Medication,
    $$MedicationsTableFilterComposer,
    $$MedicationsTableOrderingComposer,
    $$MedicationsTableAnnotationComposer,
    $$MedicationsTableCreateCompanionBuilder,
    $$MedicationsTableUpdateCompanionBuilder,
    (Medication, BaseReferences<_$AppDatabase, $MedicationsTable, Medication>),
    Medication,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$UsersTableTableManager get users =>
      $$UsersTableTableManager(_db, _db.users);
  $$TemplatesTableTableManager get templates =>
      $$TemplatesTableTableManager(_db, _db.templates);
  $$RoomsTableTableManager get rooms =>
      $$RoomsTableTableManager(_db, _db.rooms);
  $$PatientsTableTableManager get patients =>
      $$PatientsTableTableManager(_db, _db.patients);
  $$MessageTemplatesTableTableManager get messageTemplates =>
      $$MessageTemplatesTableTableManager(_db, _db.messageTemplates);
  $$MessagesTableTableManager get messages =>
      $$MessagesTableTableManager(_db, _db.messages);
  $$MedicalActsTableTableManager get medicalActs =>
      $$MedicalActsTableTableManager(_db, _db.medicalActs);
  $$PaymentsTableTableManager get payments =>
      $$PaymentsTableTableManager(_db, _db.payments);
  $$VisitsTableTableManager get visits =>
      $$VisitsTableTableManager(_db, _db.visits);
  $$WaitingPatientsTableTableManager get waitingPatients =>
      $$WaitingPatientsTableTableManager(_db, _db.waitingPatients);
  $$OrdonnancesTableTableManager get ordonnances =>
      $$OrdonnancesTableTableManager(_db, _db.ordonnances);
  $$MedicationsTableTableManager get medications =>
      $$MedicationsTableTableManager(_db, _db.medications);
}
