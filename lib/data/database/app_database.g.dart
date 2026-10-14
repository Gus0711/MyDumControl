// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $FoldersTable extends Folders with TableInfo<$FoldersTable, Folder> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FoldersTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 100,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _iconMeta = const VerificationMeta('icon');
  @override
  late final GeneratedColumn<String> icon = GeneratedColumn<String>(
    'icon',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('folder'),
  );
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<String> color = GeneratedColumn<String>(
    'color',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('#2196F3'),
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    icon,
    color,
    sortOrder,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'folders';
  @override
  VerificationContext validateIntegrity(
    Insertable<Folder> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('icon')) {
      context.handle(
        _iconMeta,
        icon.isAcceptableOrUnknown(data['icon']!, _iconMeta),
      );
    }
    if (data.containsKey('color')) {
      context.handle(
        _colorMeta,
        color.isAcceptableOrUnknown(data['color']!, _colorMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Folder map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Folder(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      icon: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}icon'],
      )!,
      color: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}color'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $FoldersTable createAlias(String alias) {
    return $FoldersTable(attachedDatabase, alias);
  }
}

class Folder extends DataClass implements Insertable<Folder> {
  /// Identifiant unique
  final int id;

  /// Nom du dossier
  final String name;

  /// Icône du dossier (nom de l'icône Material)
  final String icon;

  /// Couleur du dossier (code hexadécimal)
  final String color;

  /// Ordre d'affichage
  final int sortOrder;

  /// Date de création
  final DateTime createdAt;
  const Folder({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.sortOrder,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['icon'] = Variable<String>(icon);
    map['color'] = Variable<String>(color);
    map['sort_order'] = Variable<int>(sortOrder);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  FoldersCompanion toCompanion(bool nullToAbsent) {
    return FoldersCompanion(
      id: Value(id),
      name: Value(name),
      icon: Value(icon),
      color: Value(color),
      sortOrder: Value(sortOrder),
      createdAt: Value(createdAt),
    );
  }

  factory Folder.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Folder(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      icon: serializer.fromJson<String>(json['icon']),
      color: serializer.fromJson<String>(json['color']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'icon': serializer.toJson<String>(icon),
      'color': serializer.toJson<String>(color),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Folder copyWith({
    int? id,
    String? name,
    String? icon,
    String? color,
    int? sortOrder,
    DateTime? createdAt,
  }) => Folder(
    id: id ?? this.id,
    name: name ?? this.name,
    icon: icon ?? this.icon,
    color: color ?? this.color,
    sortOrder: sortOrder ?? this.sortOrder,
    createdAt: createdAt ?? this.createdAt,
  );
  Folder copyWithCompanion(FoldersCompanion data) {
    return Folder(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      icon: data.icon.present ? data.icon.value : this.icon,
      color: data.color.present ? data.color.value : this.color,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Folder(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('icon: $icon, ')
          ..write('color: $color, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, icon, color, sortOrder, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Folder &&
          other.id == this.id &&
          other.name == this.name &&
          other.icon == this.icon &&
          other.color == this.color &&
          other.sortOrder == this.sortOrder &&
          other.createdAt == this.createdAt);
}

class FoldersCompanion extends UpdateCompanion<Folder> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> icon;
  final Value<String> color;
  final Value<int> sortOrder;
  final Value<DateTime> createdAt;
  const FoldersCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.icon = const Value.absent(),
    this.color = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  FoldersCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.icon = const Value.absent(),
    this.color = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : name = Value(name);
  static Insertable<Folder> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? icon,
    Expression<String>? color,
    Expression<int>? sortOrder,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (icon != null) 'icon': icon,
      if (color != null) 'color': color,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  FoldersCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String>? icon,
    Value<String>? color,
    Value<int>? sortOrder,
    Value<DateTime>? createdAt,
  }) {
    return FoldersCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
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
    if (icon.present) {
      map['icon'] = Variable<String>(icon.value);
    }
    if (color.present) {
      map['color'] = Variable<String>(color.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FoldersCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('icon: $icon, ')
          ..write('color: $color, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $ConnectionsTable extends Connections
    with TableInfo<$ConnectionsTable, Connection> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ConnectionsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _folderIdMeta = const VerificationMeta(
    'folderId',
  );
  @override
  late final GeneratedColumn<int> folderId = GeneratedColumn<int>(
    'folder_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES folders (id)',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 100,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hostMeta = const VerificationMeta('host');
  @override
  late final GeneratedColumn<String> host = GeneratedColumn<String>(
    'host',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 255,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _portMeta = const VerificationMeta('port');
  @override
  late final GeneratedColumn<int> port = GeneratedColumn<int>(
    'port',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(443),
  );
  static const VerificationMeta _useHttpsMeta = const VerificationMeta(
    'useHttps',
  );
  @override
  late final GeneratedColumn<bool> useHttps = GeneratedColumn<bool>(
    'use_https',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("use_https" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _usernameMeta = const VerificationMeta(
    'username',
  );
  @override
  late final GeneratedColumn<String> username = GeneratedColumn<String>(
    'username',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 100,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _passwordKeyMeta = const VerificationMeta(
    'passwordKey',
  );
  @override
  late final GeneratedColumn<String> passwordKey = GeneratedColumn<String>(
    'password_key',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 100,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _apiVersionMeta = const VerificationMeta(
    'apiVersion',
  );
  @override
  late final GeneratedColumn<String> apiVersion = GeneratedColumn<String>(
    'api_version',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _modelNameMeta = const VerificationMeta(
    'modelName',
  );
  @override
  late final GeneratedColumn<String> modelName = GeneratedColumn<String>(
    'model_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _certificateFingerprintMeta =
      const VerificationMeta('certificateFingerprint');
  @override
  late final GeneratedColumn<String> certificateFingerprint =
      GeneratedColumn<String>(
        'certificate_fingerprint',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _connectionTypeMeta = const VerificationMeta(
    'connectionType',
  );
  @override
  late final GeneratedColumn<String> connectionType = GeneratedColumn<String>(
    'connection_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('distech_api'),
  );
  static const VerificationMeta _bacnetDeviceIdMeta = const VerificationMeta(
    'bacnetDeviceId',
  );
  @override
  late final GeneratedColumn<int> bacnetDeviceId = GeneratedColumn<int>(
    'bacnet_device_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _lastConnectedAtMeta = const VerificationMeta(
    'lastConnectedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastConnectedAt =
      GeneratedColumn<DateTime>(
        'last_connected_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _designerUrlMeta = const VerificationMeta(
    'designerUrl',
  );
  @override
  late final GeneratedColumn<String> designerUrl = GeneratedColumn<String>(
    'designer_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    folderId,
    name,
    host,
    port,
    useHttps,
    username,
    passwordKey,
    apiVersion,
    modelName,
    certificateFingerprint,
    connectionType,
    bacnetDeviceId,
    createdAt,
    updatedAt,
    lastConnectedAt,
    designerUrl,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'connections';
  @override
  VerificationContext validateIntegrity(
    Insertable<Connection> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('folder_id')) {
      context.handle(
        _folderIdMeta,
        folderId.isAcceptableOrUnknown(data['folder_id']!, _folderIdMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('host')) {
      context.handle(
        _hostMeta,
        host.isAcceptableOrUnknown(data['host']!, _hostMeta),
      );
    } else if (isInserting) {
      context.missing(_hostMeta);
    }
    if (data.containsKey('port')) {
      context.handle(
        _portMeta,
        port.isAcceptableOrUnknown(data['port']!, _portMeta),
      );
    }
    if (data.containsKey('use_https')) {
      context.handle(
        _useHttpsMeta,
        useHttps.isAcceptableOrUnknown(data['use_https']!, _useHttpsMeta),
      );
    }
    if (data.containsKey('username')) {
      context.handle(
        _usernameMeta,
        username.isAcceptableOrUnknown(data['username']!, _usernameMeta),
      );
    } else if (isInserting) {
      context.missing(_usernameMeta);
    }
    if (data.containsKey('password_key')) {
      context.handle(
        _passwordKeyMeta,
        passwordKey.isAcceptableOrUnknown(
          data['password_key']!,
          _passwordKeyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_passwordKeyMeta);
    }
    if (data.containsKey('api_version')) {
      context.handle(
        _apiVersionMeta,
        apiVersion.isAcceptableOrUnknown(data['api_version']!, _apiVersionMeta),
      );
    }
    if (data.containsKey('model_name')) {
      context.handle(
        _modelNameMeta,
        modelName.isAcceptableOrUnknown(data['model_name']!, _modelNameMeta),
      );
    }
    if (data.containsKey('certificate_fingerprint')) {
      context.handle(
        _certificateFingerprintMeta,
        certificateFingerprint.isAcceptableOrUnknown(
          data['certificate_fingerprint']!,
          _certificateFingerprintMeta,
        ),
      );
    }
    if (data.containsKey('connection_type')) {
      context.handle(
        _connectionTypeMeta,
        connectionType.isAcceptableOrUnknown(
          data['connection_type']!,
          _connectionTypeMeta,
        ),
      );
    }
    if (data.containsKey('bacnet_device_id')) {
      context.handle(
        _bacnetDeviceIdMeta,
        bacnetDeviceId.isAcceptableOrUnknown(
          data['bacnet_device_id']!,
          _bacnetDeviceIdMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('last_connected_at')) {
      context.handle(
        _lastConnectedAtMeta,
        lastConnectedAt.isAcceptableOrUnknown(
          data['last_connected_at']!,
          _lastConnectedAtMeta,
        ),
      );
    }
    if (data.containsKey('designer_url')) {
      context.handle(
        _designerUrlMeta,
        designerUrl.isAcceptableOrUnknown(
          data['designer_url']!,
          _designerUrlMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Connection map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Connection(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      folderId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}folder_id'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      host: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}host'],
      )!,
      port: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}port'],
      )!,
      useHttps: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}use_https'],
      )!,
      username: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}username'],
      )!,
      passwordKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}password_key'],
      )!,
      apiVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}api_version'],
      ),
      modelName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}model_name'],
      ),
      certificateFingerprint: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}certificate_fingerprint'],
      ),
      connectionType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}connection_type'],
      )!,
      bacnetDeviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}bacnet_device_id'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      lastConnectedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_connected_at'],
      ),
      designerUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}designer_url'],
      ),
    );
  }

  @override
  $ConnectionsTable createAlias(String alias) {
    return $ConnectionsTable(attachedDatabase, alias);
  }
}

class Connection extends DataClass implements Insertable<Connection> {
  /// Identifiant unique
  final int id;

  /// Dossier parent (null = racine)
  final int? folderId;

  /// Nom de la connexion (affiché dans la liste)
  final String name;

  /// Hôte (IP ou hostname)
  final String host;

  /// Port
  final int port;

  /// Utiliser HTTPS (ignoré si connectionType = 'bacnet')
  final bool useHttps;

  /// Nom d'utilisateur (ignoré si connectionType = 'bacnet')
  final String username;

  /// Mot de passe (sera chiffré via flutter_secure_storage séparément)
  /// Ici on stocke juste une référence/clé (ignoré si connectionType = 'bacnet')
  final String passwordKey;

  /// Version de l'API détectée (v1, v2, ou null si pas encore testé)
  /// Pour BACnet, contiendra la version du protocole si disponible
  final String? apiVersion;

  /// Modèle de l'automate (ex: "ECY-S1000", "ECY-PS100")
  /// Détecté lors de la première connexion
  final String? modelName;

  /// Empreinte du certificat (pour TOFU) - API Distech uniquement
  final String? certificateFingerprint;

  /// Type de connexion : 'distech_api' (défaut) ou 'bacnet'
  final String connectionType;

  /// Device ID BACnet (instance number du device object)
  /// Utilisé pour adresser un device spécifique (ex: via routeur BACnet)
  /// Null = auto-détection ou device unique
  final int? bacnetDeviceId;

  /// Date de création
  final DateTime createdAt;

  /// Date de dernière modification
  final DateTime updatedAt;

  /// Dernière connexion réussie
  final DateTime? lastConnectedAt;

  /// URL du Designer Envysion (ex: /eclypse/envysion/viewer.html?proj=SST_NORD)
  /// Si renseignée, permet d'afficher le synoptique intégré via WebView
  final String? designerUrl;
  const Connection({
    required this.id,
    this.folderId,
    required this.name,
    required this.host,
    required this.port,
    required this.useHttps,
    required this.username,
    required this.passwordKey,
    this.apiVersion,
    this.modelName,
    this.certificateFingerprint,
    required this.connectionType,
    this.bacnetDeviceId,
    required this.createdAt,
    required this.updatedAt,
    this.lastConnectedAt,
    this.designerUrl,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || folderId != null) {
      map['folder_id'] = Variable<int>(folderId);
    }
    map['name'] = Variable<String>(name);
    map['host'] = Variable<String>(host);
    map['port'] = Variable<int>(port);
    map['use_https'] = Variable<bool>(useHttps);
    map['username'] = Variable<String>(username);
    map['password_key'] = Variable<String>(passwordKey);
    if (!nullToAbsent || apiVersion != null) {
      map['api_version'] = Variable<String>(apiVersion);
    }
    if (!nullToAbsent || modelName != null) {
      map['model_name'] = Variable<String>(modelName);
    }
    if (!nullToAbsent || certificateFingerprint != null) {
      map['certificate_fingerprint'] = Variable<String>(certificateFingerprint);
    }
    map['connection_type'] = Variable<String>(connectionType);
    if (!nullToAbsent || bacnetDeviceId != null) {
      map['bacnet_device_id'] = Variable<int>(bacnetDeviceId);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || lastConnectedAt != null) {
      map['last_connected_at'] = Variable<DateTime>(lastConnectedAt);
    }
    if (!nullToAbsent || designerUrl != null) {
      map['designer_url'] = Variable<String>(designerUrl);
    }
    return map;
  }

  ConnectionsCompanion toCompanion(bool nullToAbsent) {
    return ConnectionsCompanion(
      id: Value(id),
      folderId: folderId == null && nullToAbsent
          ? const Value.absent()
          : Value(folderId),
      name: Value(name),
      host: Value(host),
      port: Value(port),
      useHttps: Value(useHttps),
      username: Value(username),
      passwordKey: Value(passwordKey),
      apiVersion: apiVersion == null && nullToAbsent
          ? const Value.absent()
          : Value(apiVersion),
      modelName: modelName == null && nullToAbsent
          ? const Value.absent()
          : Value(modelName),
      certificateFingerprint: certificateFingerprint == null && nullToAbsent
          ? const Value.absent()
          : Value(certificateFingerprint),
      connectionType: Value(connectionType),
      bacnetDeviceId: bacnetDeviceId == null && nullToAbsent
          ? const Value.absent()
          : Value(bacnetDeviceId),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      lastConnectedAt: lastConnectedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastConnectedAt),
      designerUrl: designerUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(designerUrl),
    );
  }

  factory Connection.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Connection(
      id: serializer.fromJson<int>(json['id']),
      folderId: serializer.fromJson<int?>(json['folderId']),
      name: serializer.fromJson<String>(json['name']),
      host: serializer.fromJson<String>(json['host']),
      port: serializer.fromJson<int>(json['port']),
      useHttps: serializer.fromJson<bool>(json['useHttps']),
      username: serializer.fromJson<String>(json['username']),
      passwordKey: serializer.fromJson<String>(json['passwordKey']),
      apiVersion: serializer.fromJson<String?>(json['apiVersion']),
      modelName: serializer.fromJson<String?>(json['modelName']),
      certificateFingerprint: serializer.fromJson<String?>(
        json['certificateFingerprint'],
      ),
      connectionType: serializer.fromJson<String>(json['connectionType']),
      bacnetDeviceId: serializer.fromJson<int?>(json['bacnetDeviceId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      lastConnectedAt: serializer.fromJson<DateTime?>(json['lastConnectedAt']),
      designerUrl: serializer.fromJson<String?>(json['designerUrl']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'folderId': serializer.toJson<int?>(folderId),
      'name': serializer.toJson<String>(name),
      'host': serializer.toJson<String>(host),
      'port': serializer.toJson<int>(port),
      'useHttps': serializer.toJson<bool>(useHttps),
      'username': serializer.toJson<String>(username),
      'passwordKey': serializer.toJson<String>(passwordKey),
      'apiVersion': serializer.toJson<String?>(apiVersion),
      'modelName': serializer.toJson<String?>(modelName),
      'certificateFingerprint': serializer.toJson<String?>(
        certificateFingerprint,
      ),
      'connectionType': serializer.toJson<String>(connectionType),
      'bacnetDeviceId': serializer.toJson<int?>(bacnetDeviceId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'lastConnectedAt': serializer.toJson<DateTime?>(lastConnectedAt),
      'designerUrl': serializer.toJson<String?>(designerUrl),
    };
  }

  Connection copyWith({
    int? id,
    Value<int?> folderId = const Value.absent(),
    String? name,
    String? host,
    int? port,
    bool? useHttps,
    String? username,
    String? passwordKey,
    Value<String?> apiVersion = const Value.absent(),
    Value<String?> modelName = const Value.absent(),
    Value<String?> certificateFingerprint = const Value.absent(),
    String? connectionType,
    Value<int?> bacnetDeviceId = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> lastConnectedAt = const Value.absent(),
    Value<String?> designerUrl = const Value.absent(),
  }) => Connection(
    id: id ?? this.id,
    folderId: folderId.present ? folderId.value : this.folderId,
    name: name ?? this.name,
    host: host ?? this.host,
    port: port ?? this.port,
    useHttps: useHttps ?? this.useHttps,
    username: username ?? this.username,
    passwordKey: passwordKey ?? this.passwordKey,
    apiVersion: apiVersion.present ? apiVersion.value : this.apiVersion,
    modelName: modelName.present ? modelName.value : this.modelName,
    certificateFingerprint: certificateFingerprint.present
        ? certificateFingerprint.value
        : this.certificateFingerprint,
    connectionType: connectionType ?? this.connectionType,
    bacnetDeviceId: bacnetDeviceId.present
        ? bacnetDeviceId.value
        : this.bacnetDeviceId,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    lastConnectedAt: lastConnectedAt.present
        ? lastConnectedAt.value
        : this.lastConnectedAt,
    designerUrl: designerUrl.present ? designerUrl.value : this.designerUrl,
  );
  Connection copyWithCompanion(ConnectionsCompanion data) {
    return Connection(
      id: data.id.present ? data.id.value : this.id,
      folderId: data.folderId.present ? data.folderId.value : this.folderId,
      name: data.name.present ? data.name.value : this.name,
      host: data.host.present ? data.host.value : this.host,
      port: data.port.present ? data.port.value : this.port,
      useHttps: data.useHttps.present ? data.useHttps.value : this.useHttps,
      username: data.username.present ? data.username.value : this.username,
      passwordKey: data.passwordKey.present
          ? data.passwordKey.value
          : this.passwordKey,
      apiVersion: data.apiVersion.present
          ? data.apiVersion.value
          : this.apiVersion,
      modelName: data.modelName.present ? data.modelName.value : this.modelName,
      certificateFingerprint: data.certificateFingerprint.present
          ? data.certificateFingerprint.value
          : this.certificateFingerprint,
      connectionType: data.connectionType.present
          ? data.connectionType.value
          : this.connectionType,
      bacnetDeviceId: data.bacnetDeviceId.present
          ? data.bacnetDeviceId.value
          : this.bacnetDeviceId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      lastConnectedAt: data.lastConnectedAt.present
          ? data.lastConnectedAt.value
          : this.lastConnectedAt,
      designerUrl: data.designerUrl.present
          ? data.designerUrl.value
          : this.designerUrl,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Connection(')
          ..write('id: $id, ')
          ..write('folderId: $folderId, ')
          ..write('name: $name, ')
          ..write('host: $host, ')
          ..write('port: $port, ')
          ..write('useHttps: $useHttps, ')
          ..write('username: $username, ')
          ..write('passwordKey: $passwordKey, ')
          ..write('apiVersion: $apiVersion, ')
          ..write('modelName: $modelName, ')
          ..write('certificateFingerprint: $certificateFingerprint, ')
          ..write('connectionType: $connectionType, ')
          ..write('bacnetDeviceId: $bacnetDeviceId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('lastConnectedAt: $lastConnectedAt, ')
          ..write('designerUrl: $designerUrl')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    folderId,
    name,
    host,
    port,
    useHttps,
    username,
    passwordKey,
    apiVersion,
    modelName,
    certificateFingerprint,
    connectionType,
    bacnetDeviceId,
    createdAt,
    updatedAt,
    lastConnectedAt,
    designerUrl,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Connection &&
          other.id == this.id &&
          other.folderId == this.folderId &&
          other.name == this.name &&
          other.host == this.host &&
          other.port == this.port &&
          other.useHttps == this.useHttps &&
          other.username == this.username &&
          other.passwordKey == this.passwordKey &&
          other.apiVersion == this.apiVersion &&
          other.modelName == this.modelName &&
          other.certificateFingerprint == this.certificateFingerprint &&
          other.connectionType == this.connectionType &&
          other.bacnetDeviceId == this.bacnetDeviceId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.lastConnectedAt == this.lastConnectedAt &&
          other.designerUrl == this.designerUrl);
}

class ConnectionsCompanion extends UpdateCompanion<Connection> {
  final Value<int> id;
  final Value<int?> folderId;
  final Value<String> name;
  final Value<String> host;
  final Value<int> port;
  final Value<bool> useHttps;
  final Value<String> username;
  final Value<String> passwordKey;
  final Value<String?> apiVersion;
  final Value<String?> modelName;
  final Value<String?> certificateFingerprint;
  final Value<String> connectionType;
  final Value<int?> bacnetDeviceId;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> lastConnectedAt;
  final Value<String?> designerUrl;
  const ConnectionsCompanion({
    this.id = const Value.absent(),
    this.folderId = const Value.absent(),
    this.name = const Value.absent(),
    this.host = const Value.absent(),
    this.port = const Value.absent(),
    this.useHttps = const Value.absent(),
    this.username = const Value.absent(),
    this.passwordKey = const Value.absent(),
    this.apiVersion = const Value.absent(),
    this.modelName = const Value.absent(),
    this.certificateFingerprint = const Value.absent(),
    this.connectionType = const Value.absent(),
    this.bacnetDeviceId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.lastConnectedAt = const Value.absent(),
    this.designerUrl = const Value.absent(),
  });
  ConnectionsCompanion.insert({
    this.id = const Value.absent(),
    this.folderId = const Value.absent(),
    required String name,
    required String host,
    this.port = const Value.absent(),
    this.useHttps = const Value.absent(),
    required String username,
    required String passwordKey,
    this.apiVersion = const Value.absent(),
    this.modelName = const Value.absent(),
    this.certificateFingerprint = const Value.absent(),
    this.connectionType = const Value.absent(),
    this.bacnetDeviceId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.lastConnectedAt = const Value.absent(),
    this.designerUrl = const Value.absent(),
  }) : name = Value(name),
       host = Value(host),
       username = Value(username),
       passwordKey = Value(passwordKey);
  static Insertable<Connection> custom({
    Expression<int>? id,
    Expression<int>? folderId,
    Expression<String>? name,
    Expression<String>? host,
    Expression<int>? port,
    Expression<bool>? useHttps,
    Expression<String>? username,
    Expression<String>? passwordKey,
    Expression<String>? apiVersion,
    Expression<String>? modelName,
    Expression<String>? certificateFingerprint,
    Expression<String>? connectionType,
    Expression<int>? bacnetDeviceId,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? lastConnectedAt,
    Expression<String>? designerUrl,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (folderId != null) 'folder_id': folderId,
      if (name != null) 'name': name,
      if (host != null) 'host': host,
      if (port != null) 'port': port,
      if (useHttps != null) 'use_https': useHttps,
      if (username != null) 'username': username,
      if (passwordKey != null) 'password_key': passwordKey,
      if (apiVersion != null) 'api_version': apiVersion,
      if (modelName != null) 'model_name': modelName,
      if (certificateFingerprint != null)
        'certificate_fingerprint': certificateFingerprint,
      if (connectionType != null) 'connection_type': connectionType,
      if (bacnetDeviceId != null) 'bacnet_device_id': bacnetDeviceId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (lastConnectedAt != null) 'last_connected_at': lastConnectedAt,
      if (designerUrl != null) 'designer_url': designerUrl,
    });
  }

  ConnectionsCompanion copyWith({
    Value<int>? id,
    Value<int?>? folderId,
    Value<String>? name,
    Value<String>? host,
    Value<int>? port,
    Value<bool>? useHttps,
    Value<String>? username,
    Value<String>? passwordKey,
    Value<String?>? apiVersion,
    Value<String?>? modelName,
    Value<String?>? certificateFingerprint,
    Value<String>? connectionType,
    Value<int?>? bacnetDeviceId,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? lastConnectedAt,
    Value<String?>? designerUrl,
  }) {
    return ConnectionsCompanion(
      id: id ?? this.id,
      folderId: folderId ?? this.folderId,
      name: name ?? this.name,
      host: host ?? this.host,
      port: port ?? this.port,
      useHttps: useHttps ?? this.useHttps,
      username: username ?? this.username,
      passwordKey: passwordKey ?? this.passwordKey,
      apiVersion: apiVersion ?? this.apiVersion,
      modelName: modelName ?? this.modelName,
      certificateFingerprint:
          certificateFingerprint ?? this.certificateFingerprint,
      connectionType: connectionType ?? this.connectionType,
      bacnetDeviceId: bacnetDeviceId ?? this.bacnetDeviceId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastConnectedAt: lastConnectedAt ?? this.lastConnectedAt,
      designerUrl: designerUrl ?? this.designerUrl,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (folderId.present) {
      map['folder_id'] = Variable<int>(folderId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (host.present) {
      map['host'] = Variable<String>(host.value);
    }
    if (port.present) {
      map['port'] = Variable<int>(port.value);
    }
    if (useHttps.present) {
      map['use_https'] = Variable<bool>(useHttps.value);
    }
    if (username.present) {
      map['username'] = Variable<String>(username.value);
    }
    if (passwordKey.present) {
      map['password_key'] = Variable<String>(passwordKey.value);
    }
    if (apiVersion.present) {
      map['api_version'] = Variable<String>(apiVersion.value);
    }
    if (modelName.present) {
      map['model_name'] = Variable<String>(modelName.value);
    }
    if (certificateFingerprint.present) {
      map['certificate_fingerprint'] = Variable<String>(
        certificateFingerprint.value,
      );
    }
    if (connectionType.present) {
      map['connection_type'] = Variable<String>(connectionType.value);
    }
    if (bacnetDeviceId.present) {
      map['bacnet_device_id'] = Variable<int>(bacnetDeviceId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (lastConnectedAt.present) {
      map['last_connected_at'] = Variable<DateTime>(lastConnectedAt.value);
    }
    if (designerUrl.present) {
      map['designer_url'] = Variable<String>(designerUrl.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ConnectionsCompanion(')
          ..write('id: $id, ')
          ..write('folderId: $folderId, ')
          ..write('name: $name, ')
          ..write('host: $host, ')
          ..write('port: $port, ')
          ..write('useHttps: $useHttps, ')
          ..write('username: $username, ')
          ..write('passwordKey: $passwordKey, ')
          ..write('apiVersion: $apiVersion, ')
          ..write('modelName: $modelName, ')
          ..write('certificateFingerprint: $certificateFingerprint, ')
          ..write('connectionType: $connectionType, ')
          ..write('bacnetDeviceId: $bacnetDeviceId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('lastConnectedAt: $lastConnectedAt, ')
          ..write('designerUrl: $designerUrl')
          ..write(')'))
        .toString();
  }
}

class $FavoritesTable extends Favorites
    with TableInfo<$FavoritesTable, Favorite> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FavoritesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _connectionIdMeta = const VerificationMeta(
    'connectionId',
  );
  @override
  late final GeneratedColumn<int> connectionId = GeneratedColumn<int>(
    'connection_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES connections (id)',
    ),
  );
  static const VerificationMeta _pointRefMeta = const VerificationMeta(
    'pointRef',
  );
  @override
  late final GeneratedColumn<String> pointRef = GeneratedColumn<String>(
    'point_ref',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 50,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pointNameMeta = const VerificationMeta(
    'pointName',
  );
  @override
  late final GeneratedColumn<String> pointName = GeneratedColumn<String>(
    'point_name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 255,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pointDescriptionMeta = const VerificationMeta(
    'pointDescription',
  );
  @override
  late final GeneratedColumn<String> pointDescription = GeneratedColumn<String>(
    'point_description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _objectTypeMeta = const VerificationMeta(
    'objectType',
  );
  @override
  late final GeneratedColumn<String> objectType = GeneratedColumn<String>(
    'object_type',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 50,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _isSuperFavoriteMeta = const VerificationMeta(
    'isSuperFavorite',
  );
  @override
  late final GeneratedColumn<bool> isSuperFavorite = GeneratedColumn<bool>(
    'is_super_favorite',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_super_favorite" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _wasPromotedMeta = const VerificationMeta(
    'wasPromoted',
  );
  @override
  late final GeneratedColumn<bool> wasPromoted = GeneratedColumn<bool>(
    'was_promoted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("was_promoted" IN (0, 1))',
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    connectionId,
    pointRef,
    pointName,
    pointDescription,
    objectType,
    sortOrder,
    isSuperFavorite,
    wasPromoted,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'favorites';
  @override
  VerificationContext validateIntegrity(
    Insertable<Favorite> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('connection_id')) {
      context.handle(
        _connectionIdMeta,
        connectionId.isAcceptableOrUnknown(
          data['connection_id']!,
          _connectionIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_connectionIdMeta);
    }
    if (data.containsKey('point_ref')) {
      context.handle(
        _pointRefMeta,
        pointRef.isAcceptableOrUnknown(data['point_ref']!, _pointRefMeta),
      );
    } else if (isInserting) {
      context.missing(_pointRefMeta);
    }
    if (data.containsKey('point_name')) {
      context.handle(
        _pointNameMeta,
        pointName.isAcceptableOrUnknown(data['point_name']!, _pointNameMeta),
      );
    } else if (isInserting) {
      context.missing(_pointNameMeta);
    }
    if (data.containsKey('point_description')) {
      context.handle(
        _pointDescriptionMeta,
        pointDescription.isAcceptableOrUnknown(
          data['point_description']!,
          _pointDescriptionMeta,
        ),
      );
    }
    if (data.containsKey('object_type')) {
      context.handle(
        _objectTypeMeta,
        objectType.isAcceptableOrUnknown(data['object_type']!, _objectTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_objectTypeMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    if (data.containsKey('is_super_favorite')) {
      context.handle(
        _isSuperFavoriteMeta,
        isSuperFavorite.isAcceptableOrUnknown(
          data['is_super_favorite']!,
          _isSuperFavoriteMeta,
        ),
      );
    }
    if (data.containsKey('was_promoted')) {
      context.handle(
        _wasPromotedMeta,
        wasPromoted.isAcceptableOrUnknown(
          data['was_promoted']!,
          _wasPromotedMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {connectionId, pointRef},
  ];
  @override
  Favorite map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Favorite(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      connectionId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}connection_id'],
      )!,
      pointRef: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}point_ref'],
      )!,
      pointName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}point_name'],
      )!,
      pointDescription: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}point_description'],
      ),
      objectType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}object_type'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      isSuperFavorite: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_super_favorite'],
      )!,
      wasPromoted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}was_promoted'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $FavoritesTable createAlias(String alias) {
    return $FavoritesTable(attachedDatabase, alias);
  }
}

class Favorite extends DataClass implements Insertable<Favorite> {
  /// Identifiant unique
  final int id;

  /// Connexion associée (chaque contrôleur a ses propres favoris)
  final int connectionId;

  /// Référence du point BACnet (ex: "AV:1", "BI:5")
  final String pointRef;

  /// Nom du point (pour affichage même offline)
  final String pointName;

  /// Description du point (optionnel)
  final String? pointDescription;

  /// Type d'objet BACnet (ex: "analog-value", "binary-input")
  final String objectType;

  /// Ordre de tri (pour réorganiser les favoris)
  final int sortOrder;

  /// Super favori (affiché sur la page de connexions)
  final bool isSuperFavorite;

  /// Indique si le favori a été rétrogradé de super favori (pour le cycle)
  /// Permet de savoir si on "monte" ou "descend" dans le cycle
  final bool wasPromoted;

  /// Date d'ajout aux favoris
  final DateTime createdAt;
  const Favorite({
    required this.id,
    required this.connectionId,
    required this.pointRef,
    required this.pointName,
    this.pointDescription,
    required this.objectType,
    required this.sortOrder,
    required this.isSuperFavorite,
    required this.wasPromoted,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['connection_id'] = Variable<int>(connectionId);
    map['point_ref'] = Variable<String>(pointRef);
    map['point_name'] = Variable<String>(pointName);
    if (!nullToAbsent || pointDescription != null) {
      map['point_description'] = Variable<String>(pointDescription);
    }
    map['object_type'] = Variable<String>(objectType);
    map['sort_order'] = Variable<int>(sortOrder);
    map['is_super_favorite'] = Variable<bool>(isSuperFavorite);
    map['was_promoted'] = Variable<bool>(wasPromoted);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  FavoritesCompanion toCompanion(bool nullToAbsent) {
    return FavoritesCompanion(
      id: Value(id),
      connectionId: Value(connectionId),
      pointRef: Value(pointRef),
      pointName: Value(pointName),
      pointDescription: pointDescription == null && nullToAbsent
          ? const Value.absent()
          : Value(pointDescription),
      objectType: Value(objectType),
      sortOrder: Value(sortOrder),
      isSuperFavorite: Value(isSuperFavorite),
      wasPromoted: Value(wasPromoted),
      createdAt: Value(createdAt),
    );
  }

  factory Favorite.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Favorite(
      id: serializer.fromJson<int>(json['id']),
      connectionId: serializer.fromJson<int>(json['connectionId']),
      pointRef: serializer.fromJson<String>(json['pointRef']),
      pointName: serializer.fromJson<String>(json['pointName']),
      pointDescription: serializer.fromJson<String?>(json['pointDescription']),
      objectType: serializer.fromJson<String>(json['objectType']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      isSuperFavorite: serializer.fromJson<bool>(json['isSuperFavorite']),
      wasPromoted: serializer.fromJson<bool>(json['wasPromoted']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'connectionId': serializer.toJson<int>(connectionId),
      'pointRef': serializer.toJson<String>(pointRef),
      'pointName': serializer.toJson<String>(pointName),
      'pointDescription': serializer.toJson<String?>(pointDescription),
      'objectType': serializer.toJson<String>(objectType),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'isSuperFavorite': serializer.toJson<bool>(isSuperFavorite),
      'wasPromoted': serializer.toJson<bool>(wasPromoted),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Favorite copyWith({
    int? id,
    int? connectionId,
    String? pointRef,
    String? pointName,
    Value<String?> pointDescription = const Value.absent(),
    String? objectType,
    int? sortOrder,
    bool? isSuperFavorite,
    bool? wasPromoted,
    DateTime? createdAt,
  }) => Favorite(
    id: id ?? this.id,
    connectionId: connectionId ?? this.connectionId,
    pointRef: pointRef ?? this.pointRef,
    pointName: pointName ?? this.pointName,
    pointDescription: pointDescription.present
        ? pointDescription.value
        : this.pointDescription,
    objectType: objectType ?? this.objectType,
    sortOrder: sortOrder ?? this.sortOrder,
    isSuperFavorite: isSuperFavorite ?? this.isSuperFavorite,
    wasPromoted: wasPromoted ?? this.wasPromoted,
    createdAt: createdAt ?? this.createdAt,
  );
  Favorite copyWithCompanion(FavoritesCompanion data) {
    return Favorite(
      id: data.id.present ? data.id.value : this.id,
      connectionId: data.connectionId.present
          ? data.connectionId.value
          : this.connectionId,
      pointRef: data.pointRef.present ? data.pointRef.value : this.pointRef,
      pointName: data.pointName.present ? data.pointName.value : this.pointName,
      pointDescription: data.pointDescription.present
          ? data.pointDescription.value
          : this.pointDescription,
      objectType: data.objectType.present
          ? data.objectType.value
          : this.objectType,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      isSuperFavorite: data.isSuperFavorite.present
          ? data.isSuperFavorite.value
          : this.isSuperFavorite,
      wasPromoted: data.wasPromoted.present
          ? data.wasPromoted.value
          : this.wasPromoted,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Favorite(')
          ..write('id: $id, ')
          ..write('connectionId: $connectionId, ')
          ..write('pointRef: $pointRef, ')
          ..write('pointName: $pointName, ')
          ..write('pointDescription: $pointDescription, ')
          ..write('objectType: $objectType, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('isSuperFavorite: $isSuperFavorite, ')
          ..write('wasPromoted: $wasPromoted, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    connectionId,
    pointRef,
    pointName,
    pointDescription,
    objectType,
    sortOrder,
    isSuperFavorite,
    wasPromoted,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Favorite &&
          other.id == this.id &&
          other.connectionId == this.connectionId &&
          other.pointRef == this.pointRef &&
          other.pointName == this.pointName &&
          other.pointDescription == this.pointDescription &&
          other.objectType == this.objectType &&
          other.sortOrder == this.sortOrder &&
          other.isSuperFavorite == this.isSuperFavorite &&
          other.wasPromoted == this.wasPromoted &&
          other.createdAt == this.createdAt);
}

class FavoritesCompanion extends UpdateCompanion<Favorite> {
  final Value<int> id;
  final Value<int> connectionId;
  final Value<String> pointRef;
  final Value<String> pointName;
  final Value<String?> pointDescription;
  final Value<String> objectType;
  final Value<int> sortOrder;
  final Value<bool> isSuperFavorite;
  final Value<bool> wasPromoted;
  final Value<DateTime> createdAt;
  const FavoritesCompanion({
    this.id = const Value.absent(),
    this.connectionId = const Value.absent(),
    this.pointRef = const Value.absent(),
    this.pointName = const Value.absent(),
    this.pointDescription = const Value.absent(),
    this.objectType = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.isSuperFavorite = const Value.absent(),
    this.wasPromoted = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  FavoritesCompanion.insert({
    this.id = const Value.absent(),
    required int connectionId,
    required String pointRef,
    required String pointName,
    this.pointDescription = const Value.absent(),
    required String objectType,
    this.sortOrder = const Value.absent(),
    this.isSuperFavorite = const Value.absent(),
    this.wasPromoted = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : connectionId = Value(connectionId),
       pointRef = Value(pointRef),
       pointName = Value(pointName),
       objectType = Value(objectType);
  static Insertable<Favorite> custom({
    Expression<int>? id,
    Expression<int>? connectionId,
    Expression<String>? pointRef,
    Expression<String>? pointName,
    Expression<String>? pointDescription,
    Expression<String>? objectType,
    Expression<int>? sortOrder,
    Expression<bool>? isSuperFavorite,
    Expression<bool>? wasPromoted,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (connectionId != null) 'connection_id': connectionId,
      if (pointRef != null) 'point_ref': pointRef,
      if (pointName != null) 'point_name': pointName,
      if (pointDescription != null) 'point_description': pointDescription,
      if (objectType != null) 'object_type': objectType,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (isSuperFavorite != null) 'is_super_favorite': isSuperFavorite,
      if (wasPromoted != null) 'was_promoted': wasPromoted,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  FavoritesCompanion copyWith({
    Value<int>? id,
    Value<int>? connectionId,
    Value<String>? pointRef,
    Value<String>? pointName,
    Value<String?>? pointDescription,
    Value<String>? objectType,
    Value<int>? sortOrder,
    Value<bool>? isSuperFavorite,
    Value<bool>? wasPromoted,
    Value<DateTime>? createdAt,
  }) {
    return FavoritesCompanion(
      id: id ?? this.id,
      connectionId: connectionId ?? this.connectionId,
      pointRef: pointRef ?? this.pointRef,
      pointName: pointName ?? this.pointName,
      pointDescription: pointDescription ?? this.pointDescription,
      objectType: objectType ?? this.objectType,
      sortOrder: sortOrder ?? this.sortOrder,
      isSuperFavorite: isSuperFavorite ?? this.isSuperFavorite,
      wasPromoted: wasPromoted ?? this.wasPromoted,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (connectionId.present) {
      map['connection_id'] = Variable<int>(connectionId.value);
    }
    if (pointRef.present) {
      map['point_ref'] = Variable<String>(pointRef.value);
    }
    if (pointName.present) {
      map['point_name'] = Variable<String>(pointName.value);
    }
    if (pointDescription.present) {
      map['point_description'] = Variable<String>(pointDescription.value);
    }
    if (objectType.present) {
      map['object_type'] = Variable<String>(objectType.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (isSuperFavorite.present) {
      map['is_super_favorite'] = Variable<bool>(isSuperFavorite.value);
    }
    if (wasPromoted.present) {
      map['was_promoted'] = Variable<bool>(wasPromoted.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FavoritesCompanion(')
          ..write('id: $id, ')
          ..write('connectionId: $connectionId, ')
          ..write('pointRef: $pointRef, ')
          ..write('pointName: $pointName, ')
          ..write('pointDescription: $pointDescription, ')
          ..write('objectType: $objectType, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('isSuperFavorite: $isSuperFavorite, ')
          ..write('wasPromoted: $wasPromoted, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $FavoriteFoldersTable extends FavoriteFolders
    with TableInfo<$FavoriteFoldersTable, FavoriteFolder> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FavoriteFoldersTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _connectionIdMeta = const VerificationMeta(
    'connectionId',
  );
  @override
  late final GeneratedColumn<int> connectionId = GeneratedColumn<int>(
    'connection_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES connections (id)',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 100,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<String> color = GeneratedColumn<String>(
    'color',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 7,
      maxTextLength: 7,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('#2196F3'),
  );
  static const VerificationMeta _iconMeta = const VerificationMeta('icon');
  @override
  late final GeneratedColumn<String> icon = GeneratedColumn<String>(
    'icon',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 50,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('folder'),
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    connectionId,
    name,
    color,
    icon,
    sortOrder,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'favorite_folders';
  @override
  VerificationContext validateIntegrity(
    Insertable<FavoriteFolder> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('connection_id')) {
      context.handle(
        _connectionIdMeta,
        connectionId.isAcceptableOrUnknown(
          data['connection_id']!,
          _connectionIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_connectionIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('color')) {
      context.handle(
        _colorMeta,
        color.isAcceptableOrUnknown(data['color']!, _colorMeta),
      );
    }
    if (data.containsKey('icon')) {
      context.handle(
        _iconMeta,
        icon.isAcceptableOrUnknown(data['icon']!, _iconMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {connectionId, name},
  ];
  @override
  FavoriteFolder map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FavoriteFolder(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      connectionId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}connection_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      color: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}color'],
      )!,
      icon: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}icon'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $FavoriteFoldersTable createAlias(String alias) {
    return $FavoriteFoldersTable(attachedDatabase, alias);
  }
}

class FavoriteFolder extends DataClass implements Insertable<FavoriteFolder> {
  /// Identifiant unique
  final int id;

  /// Connexion associée (chaque automate a ses propres dossiers)
  final int connectionId;

  /// Nom du dossier (ex: "Chaudière", "Circuit 1")
  final String name;

  /// Couleur du dossier (format hex: "#FF5722")
  final String color;

  /// Icône du dossier (nom de l'icône Material: "local_fire_department", "water_drop", etc.)
  final String icon;

  /// Ordre de tri (pour réorganiser les dossiers)
  final int sortOrder;

  /// Date de création
  final DateTime createdAt;
  const FavoriteFolder({
    required this.id,
    required this.connectionId,
    required this.name,
    required this.color,
    required this.icon,
    required this.sortOrder,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['connection_id'] = Variable<int>(connectionId);
    map['name'] = Variable<String>(name);
    map['color'] = Variable<String>(color);
    map['icon'] = Variable<String>(icon);
    map['sort_order'] = Variable<int>(sortOrder);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  FavoriteFoldersCompanion toCompanion(bool nullToAbsent) {
    return FavoriteFoldersCompanion(
      id: Value(id),
      connectionId: Value(connectionId),
      name: Value(name),
      color: Value(color),
      icon: Value(icon),
      sortOrder: Value(sortOrder),
      createdAt: Value(createdAt),
    );
  }

  factory FavoriteFolder.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FavoriteFolder(
      id: serializer.fromJson<int>(json['id']),
      connectionId: serializer.fromJson<int>(json['connectionId']),
      name: serializer.fromJson<String>(json['name']),
      color: serializer.fromJson<String>(json['color']),
      icon: serializer.fromJson<String>(json['icon']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'connectionId': serializer.toJson<int>(connectionId),
      'name': serializer.toJson<String>(name),
      'color': serializer.toJson<String>(color),
      'icon': serializer.toJson<String>(icon),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  FavoriteFolder copyWith({
    int? id,
    int? connectionId,
    String? name,
    String? color,
    String? icon,
    int? sortOrder,
    DateTime? createdAt,
  }) => FavoriteFolder(
    id: id ?? this.id,
    connectionId: connectionId ?? this.connectionId,
    name: name ?? this.name,
    color: color ?? this.color,
    icon: icon ?? this.icon,
    sortOrder: sortOrder ?? this.sortOrder,
    createdAt: createdAt ?? this.createdAt,
  );
  FavoriteFolder copyWithCompanion(FavoriteFoldersCompanion data) {
    return FavoriteFolder(
      id: data.id.present ? data.id.value : this.id,
      connectionId: data.connectionId.present
          ? data.connectionId.value
          : this.connectionId,
      name: data.name.present ? data.name.value : this.name,
      color: data.color.present ? data.color.value : this.color,
      icon: data.icon.present ? data.icon.value : this.icon,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FavoriteFolder(')
          ..write('id: $id, ')
          ..write('connectionId: $connectionId, ')
          ..write('name: $name, ')
          ..write('color: $color, ')
          ..write('icon: $icon, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, connectionId, name, color, icon, sortOrder, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FavoriteFolder &&
          other.id == this.id &&
          other.connectionId == this.connectionId &&
          other.name == this.name &&
          other.color == this.color &&
          other.icon == this.icon &&
          other.sortOrder == this.sortOrder &&
          other.createdAt == this.createdAt);
}

class FavoriteFoldersCompanion extends UpdateCompanion<FavoriteFolder> {
  final Value<int> id;
  final Value<int> connectionId;
  final Value<String> name;
  final Value<String> color;
  final Value<String> icon;
  final Value<int> sortOrder;
  final Value<DateTime> createdAt;
  const FavoriteFoldersCompanion({
    this.id = const Value.absent(),
    this.connectionId = const Value.absent(),
    this.name = const Value.absent(),
    this.color = const Value.absent(),
    this.icon = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  FavoriteFoldersCompanion.insert({
    this.id = const Value.absent(),
    required int connectionId,
    required String name,
    this.color = const Value.absent(),
    this.icon = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : connectionId = Value(connectionId),
       name = Value(name);
  static Insertable<FavoriteFolder> custom({
    Expression<int>? id,
    Expression<int>? connectionId,
    Expression<String>? name,
    Expression<String>? color,
    Expression<String>? icon,
    Expression<int>? sortOrder,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (connectionId != null) 'connection_id': connectionId,
      if (name != null) 'name': name,
      if (color != null) 'color': color,
      if (icon != null) 'icon': icon,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  FavoriteFoldersCompanion copyWith({
    Value<int>? id,
    Value<int>? connectionId,
    Value<String>? name,
    Value<String>? color,
    Value<String>? icon,
    Value<int>? sortOrder,
    Value<DateTime>? createdAt,
  }) {
    return FavoriteFoldersCompanion(
      id: id ?? this.id,
      connectionId: connectionId ?? this.connectionId,
      name: name ?? this.name,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (connectionId.present) {
      map['connection_id'] = Variable<int>(connectionId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (color.present) {
      map['color'] = Variable<String>(color.value);
    }
    if (icon.present) {
      map['icon'] = Variable<String>(icon.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FavoriteFoldersCompanion(')
          ..write('id: $id, ')
          ..write('connectionId: $connectionId, ')
          ..write('name: $name, ')
          ..write('color: $color, ')
          ..write('icon: $icon, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $FavoriteFolderAssignmentsTable extends FavoriteFolderAssignments
    with TableInfo<$FavoriteFolderAssignmentsTable, FavoriteFolderAssignment> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FavoriteFolderAssignmentsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _favoriteIdMeta = const VerificationMeta(
    'favoriteId',
  );
  @override
  late final GeneratedColumn<int> favoriteId = GeneratedColumn<int>(
    'favorite_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES favorites (id)',
    ),
  );
  static const VerificationMeta _folderIdMeta = const VerificationMeta(
    'folderId',
  );
  @override
  late final GeneratedColumn<int> folderId = GeneratedColumn<int>(
    'folder_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES favorite_folders (id)',
    ),
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [id, favoriteId, folderId, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'favorite_folder_assignments';
  @override
  VerificationContext validateIntegrity(
    Insertable<FavoriteFolderAssignment> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('favorite_id')) {
      context.handle(
        _favoriteIdMeta,
        favoriteId.isAcceptableOrUnknown(data['favorite_id']!, _favoriteIdMeta),
      );
    } else if (isInserting) {
      context.missing(_favoriteIdMeta);
    }
    if (data.containsKey('folder_id')) {
      context.handle(
        _folderIdMeta,
        folderId.isAcceptableOrUnknown(data['folder_id']!, _folderIdMeta),
      );
    } else if (isInserting) {
      context.missing(_folderIdMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {favoriteId, folderId},
  ];
  @override
  FavoriteFolderAssignment map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FavoriteFolderAssignment(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      favoriteId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}favorite_id'],
      )!,
      folderId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}folder_id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $FavoriteFolderAssignmentsTable createAlias(String alias) {
    return $FavoriteFolderAssignmentsTable(attachedDatabase, alias);
  }
}

class FavoriteFolderAssignment extends DataClass
    implements Insertable<FavoriteFolderAssignment> {
  /// Identifiant unique
  final int id;

  /// Favori concerné
  final int favoriteId;

  /// Dossier concerné
  final int folderId;

  /// Date d'assignation
  final DateTime createdAt;
  const FavoriteFolderAssignment({
    required this.id,
    required this.favoriteId,
    required this.folderId,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['favorite_id'] = Variable<int>(favoriteId);
    map['folder_id'] = Variable<int>(folderId);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  FavoriteFolderAssignmentsCompanion toCompanion(bool nullToAbsent) {
    return FavoriteFolderAssignmentsCompanion(
      id: Value(id),
      favoriteId: Value(favoriteId),
      folderId: Value(folderId),
      createdAt: Value(createdAt),
    );
  }

  factory FavoriteFolderAssignment.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FavoriteFolderAssignment(
      id: serializer.fromJson<int>(json['id']),
      favoriteId: serializer.fromJson<int>(json['favoriteId']),
      folderId: serializer.fromJson<int>(json['folderId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'favoriteId': serializer.toJson<int>(favoriteId),
      'folderId': serializer.toJson<int>(folderId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  FavoriteFolderAssignment copyWith({
    int? id,
    int? favoriteId,
    int? folderId,
    DateTime? createdAt,
  }) => FavoriteFolderAssignment(
    id: id ?? this.id,
    favoriteId: favoriteId ?? this.favoriteId,
    folderId: folderId ?? this.folderId,
    createdAt: createdAt ?? this.createdAt,
  );
  FavoriteFolderAssignment copyWithCompanion(
    FavoriteFolderAssignmentsCompanion data,
  ) {
    return FavoriteFolderAssignment(
      id: data.id.present ? data.id.value : this.id,
      favoriteId: data.favoriteId.present
          ? data.favoriteId.value
          : this.favoriteId,
      folderId: data.folderId.present ? data.folderId.value : this.folderId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FavoriteFolderAssignment(')
          ..write('id: $id, ')
          ..write('favoriteId: $favoriteId, ')
          ..write('folderId: $folderId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, favoriteId, folderId, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FavoriteFolderAssignment &&
          other.id == this.id &&
          other.favoriteId == this.favoriteId &&
          other.folderId == this.folderId &&
          other.createdAt == this.createdAt);
}

class FavoriteFolderAssignmentsCompanion
    extends UpdateCompanion<FavoriteFolderAssignment> {
  final Value<int> id;
  final Value<int> favoriteId;
  final Value<int> folderId;
  final Value<DateTime> createdAt;
  const FavoriteFolderAssignmentsCompanion({
    this.id = const Value.absent(),
    this.favoriteId = const Value.absent(),
    this.folderId = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  FavoriteFolderAssignmentsCompanion.insert({
    this.id = const Value.absent(),
    required int favoriteId,
    required int folderId,
    this.createdAt = const Value.absent(),
  }) : favoriteId = Value(favoriteId),
       folderId = Value(folderId);
  static Insertable<FavoriteFolderAssignment> custom({
    Expression<int>? id,
    Expression<int>? favoriteId,
    Expression<int>? folderId,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (favoriteId != null) 'favorite_id': favoriteId,
      if (folderId != null) 'folder_id': folderId,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  FavoriteFolderAssignmentsCompanion copyWith({
    Value<int>? id,
    Value<int>? favoriteId,
    Value<int>? folderId,
    Value<DateTime>? createdAt,
  }) {
    return FavoriteFolderAssignmentsCompanion(
      id: id ?? this.id,
      favoriteId: favoriteId ?? this.favoriteId,
      folderId: folderId ?? this.folderId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (favoriteId.present) {
      map['favorite_id'] = Variable<int>(favoriteId.value);
    }
    if (folderId.present) {
      map['folder_id'] = Variable<int>(folderId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FavoriteFolderAssignmentsCompanion(')
          ..write('id: $id, ')
          ..write('favoriteId: $favoriteId, ')
          ..write('folderId: $folderId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $CachedPointsTable extends CachedPoints
    with TableInfo<$CachedPointsTable, CachedPoint> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedPointsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _connectionIdMeta = const VerificationMeta(
    'connectionId',
  );
  @override
  late final GeneratedColumn<int> connectionId = GeneratedColumn<int>(
    'connection_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES connections (id)',
    ),
  );
  static const VerificationMeta _pointRefMeta = const VerificationMeta(
    'pointRef',
  );
  @override
  late final GeneratedColumn<String> pointRef = GeneratedColumn<String>(
    'point_ref',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 50,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _objectTypeMeta = const VerificationMeta(
    'objectType',
  );
  @override
  late final GeneratedColumn<String> objectType = GeneratedColumn<String>(
    'object_type',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 50,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _instanceMeta = const VerificationMeta(
    'instance',
  );
  @override
  late final GeneratedColumn<int> instance = GeneratedColumn<int>(
    'instance',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _objectNameMeta = const VerificationMeta(
    'objectName',
  );
  @override
  late final GeneratedColumn<String> objectName = GeneratedColumn<String>(
    'object_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _unitsMeta = const VerificationMeta('units');
  @override
  late final GeneratedColumn<String> units = GeneratedColumn<String>(
    'units',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _activeTextMeta = const VerificationMeta(
    'activeText',
  );
  @override
  late final GeneratedColumn<String> activeText = GeneratedColumn<String>(
    'active_text',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _inactiveTextMeta = const VerificationMeta(
    'inactiveText',
  );
  @override
  late final GeneratedColumn<String> inactiveText = GeneratedColumn<String>(
    'inactive_text',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cachedAtMeta = const VerificationMeta(
    'cachedAt',
  );
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
    'cached_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    connectionId,
    pointRef,
    objectType,
    instance,
    objectName,
    units,
    description,
    activeText,
    inactiveText,
    cachedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_points';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedPoint> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('connection_id')) {
      context.handle(
        _connectionIdMeta,
        connectionId.isAcceptableOrUnknown(
          data['connection_id']!,
          _connectionIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_connectionIdMeta);
    }
    if (data.containsKey('point_ref')) {
      context.handle(
        _pointRefMeta,
        pointRef.isAcceptableOrUnknown(data['point_ref']!, _pointRefMeta),
      );
    } else if (isInserting) {
      context.missing(_pointRefMeta);
    }
    if (data.containsKey('object_type')) {
      context.handle(
        _objectTypeMeta,
        objectType.isAcceptableOrUnknown(data['object_type']!, _objectTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_objectTypeMeta);
    }
    if (data.containsKey('instance')) {
      context.handle(
        _instanceMeta,
        this.instance.isAcceptableOrUnknown(data['instance']!, _instanceMeta),
      );
    } else if (isInserting) {
      context.missing(_instanceMeta);
    }
    if (data.containsKey('object_name')) {
      context.handle(
        _objectNameMeta,
        objectName.isAcceptableOrUnknown(data['object_name']!, _objectNameMeta),
      );
    } else if (isInserting) {
      context.missing(_objectNameMeta);
    }
    if (data.containsKey('units')) {
      context.handle(
        _unitsMeta,
        units.isAcceptableOrUnknown(data['units']!, _unitsMeta),
      );
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('active_text')) {
      context.handle(
        _activeTextMeta,
        activeText.isAcceptableOrUnknown(data['active_text']!, _activeTextMeta),
      );
    }
    if (data.containsKey('inactive_text')) {
      context.handle(
        _inactiveTextMeta,
        inactiveText.isAcceptableOrUnknown(
          data['inactive_text']!,
          _inactiveTextMeta,
        ),
      );
    }
    if (data.containsKey('cached_at')) {
      context.handle(
        _cachedAtMeta,
        cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {connectionId, pointRef};
  @override
  CachedPoint map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedPoint(
      connectionId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}connection_id'],
      )!,
      pointRef: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}point_ref'],
      )!,
      objectType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}object_type'],
      )!,
      instance: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}instance'],
      )!,
      objectName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}object_name'],
      )!,
      units: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}units'],
      ),
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      activeText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}active_text'],
      ),
      inactiveText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}inactive_text'],
      ),
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cached_at'],
      )!,
    );
  }

  @override
  $CachedPointsTable createAlias(String alias) {
    return $CachedPointsTable(attachedDatabase, alias);
  }
}

class CachedPoint extends DataClass implements Insertable<CachedPoint> {
  /// Connexion associée
  final int connectionId;

  /// Référence du point (ex: "AV:1", "BI:5")
  final String pointRef;

  /// Type d'objet BACnet (ex: "analog-value")
  final String objectType;

  /// Instance du point
  final int instance;

  /// Nom de l'objet
  final String objectName;

  /// Unité (ex: "°C", "%")
  final String? units;

  /// Description
  final String? description;

  /// Texte pour valeur active (binaires)
  final String? activeText;

  /// Texte pour valeur inactive (binaires)
  final String? inactiveText;

  /// Date de mise en cache
  final DateTime cachedAt;
  const CachedPoint({
    required this.connectionId,
    required this.pointRef,
    required this.objectType,
    required this.instance,
    required this.objectName,
    this.units,
    this.description,
    this.activeText,
    this.inactiveText,
    required this.cachedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['connection_id'] = Variable<int>(connectionId);
    map['point_ref'] = Variable<String>(pointRef);
    map['object_type'] = Variable<String>(objectType);
    map['instance'] = Variable<int>(instance);
    map['object_name'] = Variable<String>(objectName);
    if (!nullToAbsent || units != null) {
      map['units'] = Variable<String>(units);
    }
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || activeText != null) {
      map['active_text'] = Variable<String>(activeText);
    }
    if (!nullToAbsent || inactiveText != null) {
      map['inactive_text'] = Variable<String>(inactiveText);
    }
    map['cached_at'] = Variable<DateTime>(cachedAt);
    return map;
  }

  CachedPointsCompanion toCompanion(bool nullToAbsent) {
    return CachedPointsCompanion(
      connectionId: Value(connectionId),
      pointRef: Value(pointRef),
      objectType: Value(objectType),
      instance: Value(instance),
      objectName: Value(objectName),
      units: units == null && nullToAbsent
          ? const Value.absent()
          : Value(units),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      activeText: activeText == null && nullToAbsent
          ? const Value.absent()
          : Value(activeText),
      inactiveText: inactiveText == null && nullToAbsent
          ? const Value.absent()
          : Value(inactiveText),
      cachedAt: Value(cachedAt),
    );
  }

  factory CachedPoint.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedPoint(
      connectionId: serializer.fromJson<int>(json['connectionId']),
      pointRef: serializer.fromJson<String>(json['pointRef']),
      objectType: serializer.fromJson<String>(json['objectType']),
      instance: serializer.fromJson<int>(json['instance']),
      objectName: serializer.fromJson<String>(json['objectName']),
      units: serializer.fromJson<String?>(json['units']),
      description: serializer.fromJson<String?>(json['description']),
      activeText: serializer.fromJson<String?>(json['activeText']),
      inactiveText: serializer.fromJson<String?>(json['inactiveText']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'connectionId': serializer.toJson<int>(connectionId),
      'pointRef': serializer.toJson<String>(pointRef),
      'objectType': serializer.toJson<String>(objectType),
      'instance': serializer.toJson<int>(instance),
      'objectName': serializer.toJson<String>(objectName),
      'units': serializer.toJson<String?>(units),
      'description': serializer.toJson<String?>(description),
      'activeText': serializer.toJson<String?>(activeText),
      'inactiveText': serializer.toJson<String?>(inactiveText),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
    };
  }

  CachedPoint copyWith({
    int? connectionId,
    String? pointRef,
    String? objectType,
    int? instance,
    String? objectName,
    Value<String?> units = const Value.absent(),
    Value<String?> description = const Value.absent(),
    Value<String?> activeText = const Value.absent(),
    Value<String?> inactiveText = const Value.absent(),
    DateTime? cachedAt,
  }) => CachedPoint(
    connectionId: connectionId ?? this.connectionId,
    pointRef: pointRef ?? this.pointRef,
    objectType: objectType ?? this.objectType,
    instance: instance ?? this.instance,
    objectName: objectName ?? this.objectName,
    units: units.present ? units.value : this.units,
    description: description.present ? description.value : this.description,
    activeText: activeText.present ? activeText.value : this.activeText,
    inactiveText: inactiveText.present ? inactiveText.value : this.inactiveText,
    cachedAt: cachedAt ?? this.cachedAt,
  );
  CachedPoint copyWithCompanion(CachedPointsCompanion data) {
    return CachedPoint(
      connectionId: data.connectionId.present
          ? data.connectionId.value
          : this.connectionId,
      pointRef: data.pointRef.present ? data.pointRef.value : this.pointRef,
      objectType: data.objectType.present
          ? data.objectType.value
          : this.objectType,
      instance: data.instance.present ? data.instance.value : this.instance,
      objectName: data.objectName.present
          ? data.objectName.value
          : this.objectName,
      units: data.units.present ? data.units.value : this.units,
      description: data.description.present
          ? data.description.value
          : this.description,
      activeText: data.activeText.present
          ? data.activeText.value
          : this.activeText,
      inactiveText: data.inactiveText.present
          ? data.inactiveText.value
          : this.inactiveText,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedPoint(')
          ..write('connectionId: $connectionId, ')
          ..write('pointRef: $pointRef, ')
          ..write('objectType: $objectType, ')
          ..write('instance: $instance, ')
          ..write('objectName: $objectName, ')
          ..write('units: $units, ')
          ..write('description: $description, ')
          ..write('activeText: $activeText, ')
          ..write('inactiveText: $inactiveText, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    connectionId,
    pointRef,
    objectType,
    instance,
    objectName,
    units,
    description,
    activeText,
    inactiveText,
    cachedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedPoint &&
          other.connectionId == this.connectionId &&
          other.pointRef == this.pointRef &&
          other.objectType == this.objectType &&
          other.instance == this.instance &&
          other.objectName == this.objectName &&
          other.units == this.units &&
          other.description == this.description &&
          other.activeText == this.activeText &&
          other.inactiveText == this.inactiveText &&
          other.cachedAt == this.cachedAt);
}

class CachedPointsCompanion extends UpdateCompanion<CachedPoint> {
  final Value<int> connectionId;
  final Value<String> pointRef;
  final Value<String> objectType;
  final Value<int> instance;
  final Value<String> objectName;
  final Value<String?> units;
  final Value<String?> description;
  final Value<String?> activeText;
  final Value<String?> inactiveText;
  final Value<DateTime> cachedAt;
  final Value<int> rowid;
  const CachedPointsCompanion({
    this.connectionId = const Value.absent(),
    this.pointRef = const Value.absent(),
    this.objectType = const Value.absent(),
    this.instance = const Value.absent(),
    this.objectName = const Value.absent(),
    this.units = const Value.absent(),
    this.description = const Value.absent(),
    this.activeText = const Value.absent(),
    this.inactiveText = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedPointsCompanion.insert({
    required int connectionId,
    required String pointRef,
    required String objectType,
    required int instance,
    required String objectName,
    this.units = const Value.absent(),
    this.description = const Value.absent(),
    this.activeText = const Value.absent(),
    this.inactiveText = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : connectionId = Value(connectionId),
       pointRef = Value(pointRef),
       objectType = Value(objectType),
       instance = Value(instance),
       objectName = Value(objectName);
  static Insertable<CachedPoint> custom({
    Expression<int>? connectionId,
    Expression<String>? pointRef,
    Expression<String>? objectType,
    Expression<int>? instance,
    Expression<String>? objectName,
    Expression<String>? units,
    Expression<String>? description,
    Expression<String>? activeText,
    Expression<String>? inactiveText,
    Expression<DateTime>? cachedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (connectionId != null) 'connection_id': connectionId,
      if (pointRef != null) 'point_ref': pointRef,
      if (objectType != null) 'object_type': objectType,
      if (instance != null) 'instance': instance,
      if (objectName != null) 'object_name': objectName,
      if (units != null) 'units': units,
      if (description != null) 'description': description,
      if (activeText != null) 'active_text': activeText,
      if (inactiveText != null) 'inactive_text': inactiveText,
      if (cachedAt != null) 'cached_at': cachedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedPointsCompanion copyWith({
    Value<int>? connectionId,
    Value<String>? pointRef,
    Value<String>? objectType,
    Value<int>? instance,
    Value<String>? objectName,
    Value<String?>? units,
    Value<String?>? description,
    Value<String?>? activeText,
    Value<String?>? inactiveText,
    Value<DateTime>? cachedAt,
    Value<int>? rowid,
  }) {
    return CachedPointsCompanion(
      connectionId: connectionId ?? this.connectionId,
      pointRef: pointRef ?? this.pointRef,
      objectType: objectType ?? this.objectType,
      instance: instance ?? this.instance,
      objectName: objectName ?? this.objectName,
      units: units ?? this.units,
      description: description ?? this.description,
      activeText: activeText ?? this.activeText,
      inactiveText: inactiveText ?? this.inactiveText,
      cachedAt: cachedAt ?? this.cachedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (connectionId.present) {
      map['connection_id'] = Variable<int>(connectionId.value);
    }
    if (pointRef.present) {
      map['point_ref'] = Variable<String>(pointRef.value);
    }
    if (objectType.present) {
      map['object_type'] = Variable<String>(objectType.value);
    }
    if (instance.present) {
      map['instance'] = Variable<int>(instance.value);
    }
    if (objectName.present) {
      map['object_name'] = Variable<String>(objectName.value);
    }
    if (units.present) {
      map['units'] = Variable<String>(units.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (activeText.present) {
      map['active_text'] = Variable<String>(activeText.value);
    }
    if (inactiveText.present) {
      map['inactive_text'] = Variable<String>(inactiveText.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedPointsCompanion(')
          ..write('connectionId: $connectionId, ')
          ..write('pointRef: $pointRef, ')
          ..write('objectType: $objectType, ')
          ..write('instance: $instance, ')
          ..write('objectName: $objectName, ')
          ..write('units: $units, ')
          ..write('description: $description, ')
          ..write('activeText: $activeText, ')
          ..write('inactiveText: $inactiveText, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedDeviceInfoTable extends CachedDeviceInfo
    with TableInfo<$CachedDeviceInfoTable, CachedDeviceInfoData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedDeviceInfoTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _connectionIdMeta = const VerificationMeta(
    'connectionId',
  );
  @override
  late final GeneratedColumn<int> connectionId = GeneratedColumn<int>(
    'connection_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES connections (id)',
    ),
  );
  static const VerificationMeta _objectNameMeta = const VerificationMeta(
    'objectName',
  );
  @override
  late final GeneratedColumn<String> objectName = GeneratedColumn<String>(
    'object_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _modelNameMeta = const VerificationMeta(
    'modelName',
  );
  @override
  late final GeneratedColumn<String> modelName = GeneratedColumn<String>(
    'model_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _modelTypeMeta = const VerificationMeta(
    'modelType',
  );
  @override
  late final GeneratedColumn<String> modelType = GeneratedColumn<String>(
    'model_type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _softwareVersionMeta = const VerificationMeta(
    'softwareVersion',
  );
  @override
  late final GeneratedColumn<String> softwareVersion = GeneratedColumn<String>(
    'software_version',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _hostIdMeta = const VerificationMeta('hostId');
  @override
  late final GeneratedColumn<String> hostId = GeneratedColumn<String>(
    'host_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _hostNameMeta = const VerificationMeta(
    'hostName',
  );
  @override
  late final GeneratedColumn<String> hostName = GeneratedColumn<String>(
    'host_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _vendorNameMeta = const VerificationMeta(
    'vendorName',
  );
  @override
  late final GeneratedColumn<String> vendorName = GeneratedColumn<String>(
    'vendor_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _locationMeta = const VerificationMeta(
    'location',
  );
  @override
  late final GeneratedColumn<String> location = GeneratedColumn<String>(
    'location',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deviceInstanceMeta = const VerificationMeta(
    'deviceInstance',
  );
  @override
  late final GeneratedColumn<int> deviceInstance = GeneratedColumn<int>(
    'device_instance',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cachedAtMeta = const VerificationMeta(
    'cachedAt',
  );
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
    'cached_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    connectionId,
    objectName,
    modelName,
    modelType,
    softwareVersion,
    hostId,
    hostName,
    vendorName,
    description,
    location,
    deviceInstance,
    cachedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_device_info';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedDeviceInfoData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('connection_id')) {
      context.handle(
        _connectionIdMeta,
        connectionId.isAcceptableOrUnknown(
          data['connection_id']!,
          _connectionIdMeta,
        ),
      );
    }
    if (data.containsKey('object_name')) {
      context.handle(
        _objectNameMeta,
        objectName.isAcceptableOrUnknown(data['object_name']!, _objectNameMeta),
      );
    } else if (isInserting) {
      context.missing(_objectNameMeta);
    }
    if (data.containsKey('model_name')) {
      context.handle(
        _modelNameMeta,
        modelName.isAcceptableOrUnknown(data['model_name']!, _modelNameMeta),
      );
    }
    if (data.containsKey('model_type')) {
      context.handle(
        _modelTypeMeta,
        modelType.isAcceptableOrUnknown(data['model_type']!, _modelTypeMeta),
      );
    }
    if (data.containsKey('software_version')) {
      context.handle(
        _softwareVersionMeta,
        softwareVersion.isAcceptableOrUnknown(
          data['software_version']!,
          _softwareVersionMeta,
        ),
      );
    }
    if (data.containsKey('host_id')) {
      context.handle(
        _hostIdMeta,
        hostId.isAcceptableOrUnknown(data['host_id']!, _hostIdMeta),
      );
    }
    if (data.containsKey('host_name')) {
      context.handle(
        _hostNameMeta,
        hostName.isAcceptableOrUnknown(data['host_name']!, _hostNameMeta),
      );
    }
    if (data.containsKey('vendor_name')) {
      context.handle(
        _vendorNameMeta,
        vendorName.isAcceptableOrUnknown(data['vendor_name']!, _vendorNameMeta),
      );
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('location')) {
      context.handle(
        _locationMeta,
        location.isAcceptableOrUnknown(data['location']!, _locationMeta),
      );
    }
    if (data.containsKey('device_instance')) {
      context.handle(
        _deviceInstanceMeta,
        deviceInstance.isAcceptableOrUnknown(
          data['device_instance']!,
          _deviceInstanceMeta,
        ),
      );
    }
    if (data.containsKey('cached_at')) {
      context.handle(
        _cachedAtMeta,
        cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {connectionId};
  @override
  CachedDeviceInfoData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedDeviceInfoData(
      connectionId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}connection_id'],
      )!,
      objectName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}object_name'],
      )!,
      modelName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}model_name'],
      ),
      modelType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}model_type'],
      ),
      softwareVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}software_version'],
      ),
      hostId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}host_id'],
      ),
      hostName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}host_name'],
      ),
      vendorName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}vendor_name'],
      ),
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      location: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}location'],
      ),
      deviceInstance: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}device_instance'],
      ),
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cached_at'],
      )!,
    );
  }

  @override
  $CachedDeviceInfoTable createAlias(String alias) {
    return $CachedDeviceInfoTable(attachedDatabase, alias);
  }
}

class CachedDeviceInfoData extends DataClass
    implements Insertable<CachedDeviceInfoData> {
  /// Connexion associée (clé primaire)
  final int connectionId;

  /// Nom de l'objet device
  final String objectName;

  /// Nom du modèle
  final String? modelName;

  /// Type de modèle
  final String? modelType;

  /// Version du firmware
  final String? softwareVersion;

  /// Host ID
  final String? hostId;

  /// Host Name
  final String? hostName;

  /// Nom du vendeur
  final String? vendorName;

  /// Description
  final String? description;

  /// Localisation
  final String? location;

  /// Instance device
  final int? deviceInstance;

  /// Date de mise en cache
  final DateTime cachedAt;
  const CachedDeviceInfoData({
    required this.connectionId,
    required this.objectName,
    this.modelName,
    this.modelType,
    this.softwareVersion,
    this.hostId,
    this.hostName,
    this.vendorName,
    this.description,
    this.location,
    this.deviceInstance,
    required this.cachedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['connection_id'] = Variable<int>(connectionId);
    map['object_name'] = Variable<String>(objectName);
    if (!nullToAbsent || modelName != null) {
      map['model_name'] = Variable<String>(modelName);
    }
    if (!nullToAbsent || modelType != null) {
      map['model_type'] = Variable<String>(modelType);
    }
    if (!nullToAbsent || softwareVersion != null) {
      map['software_version'] = Variable<String>(softwareVersion);
    }
    if (!nullToAbsent || hostId != null) {
      map['host_id'] = Variable<String>(hostId);
    }
    if (!nullToAbsent || hostName != null) {
      map['host_name'] = Variable<String>(hostName);
    }
    if (!nullToAbsent || vendorName != null) {
      map['vendor_name'] = Variable<String>(vendorName);
    }
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || location != null) {
      map['location'] = Variable<String>(location);
    }
    if (!nullToAbsent || deviceInstance != null) {
      map['device_instance'] = Variable<int>(deviceInstance);
    }
    map['cached_at'] = Variable<DateTime>(cachedAt);
    return map;
  }

  CachedDeviceInfoCompanion toCompanion(bool nullToAbsent) {
    return CachedDeviceInfoCompanion(
      connectionId: Value(connectionId),
      objectName: Value(objectName),
      modelName: modelName == null && nullToAbsent
          ? const Value.absent()
          : Value(modelName),
      modelType: modelType == null && nullToAbsent
          ? const Value.absent()
          : Value(modelType),
      softwareVersion: softwareVersion == null && nullToAbsent
          ? const Value.absent()
          : Value(softwareVersion),
      hostId: hostId == null && nullToAbsent
          ? const Value.absent()
          : Value(hostId),
      hostName: hostName == null && nullToAbsent
          ? const Value.absent()
          : Value(hostName),
      vendorName: vendorName == null && nullToAbsent
          ? const Value.absent()
          : Value(vendorName),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      location: location == null && nullToAbsent
          ? const Value.absent()
          : Value(location),
      deviceInstance: deviceInstance == null && nullToAbsent
          ? const Value.absent()
          : Value(deviceInstance),
      cachedAt: Value(cachedAt),
    );
  }

  factory CachedDeviceInfoData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedDeviceInfoData(
      connectionId: serializer.fromJson<int>(json['connectionId']),
      objectName: serializer.fromJson<String>(json['objectName']),
      modelName: serializer.fromJson<String?>(json['modelName']),
      modelType: serializer.fromJson<String?>(json['modelType']),
      softwareVersion: serializer.fromJson<String?>(json['softwareVersion']),
      hostId: serializer.fromJson<String?>(json['hostId']),
      hostName: serializer.fromJson<String?>(json['hostName']),
      vendorName: serializer.fromJson<String?>(json['vendorName']),
      description: serializer.fromJson<String?>(json['description']),
      location: serializer.fromJson<String?>(json['location']),
      deviceInstance: serializer.fromJson<int?>(json['deviceInstance']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'connectionId': serializer.toJson<int>(connectionId),
      'objectName': serializer.toJson<String>(objectName),
      'modelName': serializer.toJson<String?>(modelName),
      'modelType': serializer.toJson<String?>(modelType),
      'softwareVersion': serializer.toJson<String?>(softwareVersion),
      'hostId': serializer.toJson<String?>(hostId),
      'hostName': serializer.toJson<String?>(hostName),
      'vendorName': serializer.toJson<String?>(vendorName),
      'description': serializer.toJson<String?>(description),
      'location': serializer.toJson<String?>(location),
      'deviceInstance': serializer.toJson<int?>(deviceInstance),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
    };
  }

  CachedDeviceInfoData copyWith({
    int? connectionId,
    String? objectName,
    Value<String?> modelName = const Value.absent(),
    Value<String?> modelType = const Value.absent(),
    Value<String?> softwareVersion = const Value.absent(),
    Value<String?> hostId = const Value.absent(),
    Value<String?> hostName = const Value.absent(),
    Value<String?> vendorName = const Value.absent(),
    Value<String?> description = const Value.absent(),
    Value<String?> location = const Value.absent(),
    Value<int?> deviceInstance = const Value.absent(),
    DateTime? cachedAt,
  }) => CachedDeviceInfoData(
    connectionId: connectionId ?? this.connectionId,
    objectName: objectName ?? this.objectName,
    modelName: modelName.present ? modelName.value : this.modelName,
    modelType: modelType.present ? modelType.value : this.modelType,
    softwareVersion: softwareVersion.present
        ? softwareVersion.value
        : this.softwareVersion,
    hostId: hostId.present ? hostId.value : this.hostId,
    hostName: hostName.present ? hostName.value : this.hostName,
    vendorName: vendorName.present ? vendorName.value : this.vendorName,
    description: description.present ? description.value : this.description,
    location: location.present ? location.value : this.location,
    deviceInstance: deviceInstance.present
        ? deviceInstance.value
        : this.deviceInstance,
    cachedAt: cachedAt ?? this.cachedAt,
  );
  CachedDeviceInfoData copyWithCompanion(CachedDeviceInfoCompanion data) {
    return CachedDeviceInfoData(
      connectionId: data.connectionId.present
          ? data.connectionId.value
          : this.connectionId,
      objectName: data.objectName.present
          ? data.objectName.value
          : this.objectName,
      modelName: data.modelName.present ? data.modelName.value : this.modelName,
      modelType: data.modelType.present ? data.modelType.value : this.modelType,
      softwareVersion: data.softwareVersion.present
          ? data.softwareVersion.value
          : this.softwareVersion,
      hostId: data.hostId.present ? data.hostId.value : this.hostId,
      hostName: data.hostName.present ? data.hostName.value : this.hostName,
      vendorName: data.vendorName.present
          ? data.vendorName.value
          : this.vendorName,
      description: data.description.present
          ? data.description.value
          : this.description,
      location: data.location.present ? data.location.value : this.location,
      deviceInstance: data.deviceInstance.present
          ? data.deviceInstance.value
          : this.deviceInstance,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedDeviceInfoData(')
          ..write('connectionId: $connectionId, ')
          ..write('objectName: $objectName, ')
          ..write('modelName: $modelName, ')
          ..write('modelType: $modelType, ')
          ..write('softwareVersion: $softwareVersion, ')
          ..write('hostId: $hostId, ')
          ..write('hostName: $hostName, ')
          ..write('vendorName: $vendorName, ')
          ..write('description: $description, ')
          ..write('location: $location, ')
          ..write('deviceInstance: $deviceInstance, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    connectionId,
    objectName,
    modelName,
    modelType,
    softwareVersion,
    hostId,
    hostName,
    vendorName,
    description,
    location,
    deviceInstance,
    cachedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedDeviceInfoData &&
          other.connectionId == this.connectionId &&
          other.objectName == this.objectName &&
          other.modelName == this.modelName &&
          other.modelType == this.modelType &&
          other.softwareVersion == this.softwareVersion &&
          other.hostId == this.hostId &&
          other.hostName == this.hostName &&
          other.vendorName == this.vendorName &&
          other.description == this.description &&
          other.location == this.location &&
          other.deviceInstance == this.deviceInstance &&
          other.cachedAt == this.cachedAt);
}

class CachedDeviceInfoCompanion extends UpdateCompanion<CachedDeviceInfoData> {
  final Value<int> connectionId;
  final Value<String> objectName;
  final Value<String?> modelName;
  final Value<String?> modelType;
  final Value<String?> softwareVersion;
  final Value<String?> hostId;
  final Value<String?> hostName;
  final Value<String?> vendorName;
  final Value<String?> description;
  final Value<String?> location;
  final Value<int?> deviceInstance;
  final Value<DateTime> cachedAt;
  const CachedDeviceInfoCompanion({
    this.connectionId = const Value.absent(),
    this.objectName = const Value.absent(),
    this.modelName = const Value.absent(),
    this.modelType = const Value.absent(),
    this.softwareVersion = const Value.absent(),
    this.hostId = const Value.absent(),
    this.hostName = const Value.absent(),
    this.vendorName = const Value.absent(),
    this.description = const Value.absent(),
    this.location = const Value.absent(),
    this.deviceInstance = const Value.absent(),
    this.cachedAt = const Value.absent(),
  });
  CachedDeviceInfoCompanion.insert({
    this.connectionId = const Value.absent(),
    required String objectName,
    this.modelName = const Value.absent(),
    this.modelType = const Value.absent(),
    this.softwareVersion = const Value.absent(),
    this.hostId = const Value.absent(),
    this.hostName = const Value.absent(),
    this.vendorName = const Value.absent(),
    this.description = const Value.absent(),
    this.location = const Value.absent(),
    this.deviceInstance = const Value.absent(),
    this.cachedAt = const Value.absent(),
  }) : objectName = Value(objectName);
  static Insertable<CachedDeviceInfoData> custom({
    Expression<int>? connectionId,
    Expression<String>? objectName,
    Expression<String>? modelName,
    Expression<String>? modelType,
    Expression<String>? softwareVersion,
    Expression<String>? hostId,
    Expression<String>? hostName,
    Expression<String>? vendorName,
    Expression<String>? description,
    Expression<String>? location,
    Expression<int>? deviceInstance,
    Expression<DateTime>? cachedAt,
  }) {
    return RawValuesInsertable({
      if (connectionId != null) 'connection_id': connectionId,
      if (objectName != null) 'object_name': objectName,
      if (modelName != null) 'model_name': modelName,
      if (modelType != null) 'model_type': modelType,
      if (softwareVersion != null) 'software_version': softwareVersion,
      if (hostId != null) 'host_id': hostId,
      if (hostName != null) 'host_name': hostName,
      if (vendorName != null) 'vendor_name': vendorName,
      if (description != null) 'description': description,
      if (location != null) 'location': location,
      if (deviceInstance != null) 'device_instance': deviceInstance,
      if (cachedAt != null) 'cached_at': cachedAt,
    });
  }

  CachedDeviceInfoCompanion copyWith({
    Value<int>? connectionId,
    Value<String>? objectName,
    Value<String?>? modelName,
    Value<String?>? modelType,
    Value<String?>? softwareVersion,
    Value<String?>? hostId,
    Value<String?>? hostName,
    Value<String?>? vendorName,
    Value<String?>? description,
    Value<String?>? location,
    Value<int?>? deviceInstance,
    Value<DateTime>? cachedAt,
  }) {
    return CachedDeviceInfoCompanion(
      connectionId: connectionId ?? this.connectionId,
      objectName: objectName ?? this.objectName,
      modelName: modelName ?? this.modelName,
      modelType: modelType ?? this.modelType,
      softwareVersion: softwareVersion ?? this.softwareVersion,
      hostId: hostId ?? this.hostId,
      hostName: hostName ?? this.hostName,
      vendorName: vendorName ?? this.vendorName,
      description: description ?? this.description,
      location: location ?? this.location,
      deviceInstance: deviceInstance ?? this.deviceInstance,
      cachedAt: cachedAt ?? this.cachedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (connectionId.present) {
      map['connection_id'] = Variable<int>(connectionId.value);
    }
    if (objectName.present) {
      map['object_name'] = Variable<String>(objectName.value);
    }
    if (modelName.present) {
      map['model_name'] = Variable<String>(modelName.value);
    }
    if (modelType.present) {
      map['model_type'] = Variable<String>(modelType.value);
    }
    if (softwareVersion.present) {
      map['software_version'] = Variable<String>(softwareVersion.value);
    }
    if (hostId.present) {
      map['host_id'] = Variable<String>(hostId.value);
    }
    if (hostName.present) {
      map['host_name'] = Variable<String>(hostName.value);
    }
    if (vendorName.present) {
      map['vendor_name'] = Variable<String>(vendorName.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (location.present) {
      map['location'] = Variable<String>(location.value);
    }
    if (deviceInstance.present) {
      map['device_instance'] = Variable<int>(deviceInstance.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedDeviceInfoCompanion(')
          ..write('connectionId: $connectionId, ')
          ..write('objectName: $objectName, ')
          ..write('modelName: $modelName, ')
          ..write('modelType: $modelType, ')
          ..write('softwareVersion: $softwareVersion, ')
          ..write('hostId: $hostId, ')
          ..write('hostName: $hostName, ')
          ..write('vendorName: $vendorName, ')
          ..write('description: $description, ')
          ..write('location: $location, ')
          ..write('deviceInstance: $deviceInstance, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }
}

class $CachedTrendLogMappingTable extends CachedTrendLogMapping
    with TableInfo<$CachedTrendLogMappingTable, CachedTrendLogMappingData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedTrendLogMappingTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _connectionIdMeta = const VerificationMeta(
    'connectionId',
  );
  @override
  late final GeneratedColumn<int> connectionId = GeneratedColumn<int>(
    'connection_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES connections (id)',
    ),
  );
  static const VerificationMeta _mappingJsonMeta = const VerificationMeta(
    'mappingJson',
  );
  @override
  late final GeneratedColumn<String> mappingJson = GeneratedColumn<String>(
    'mapping_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entryCountMeta = const VerificationMeta(
    'entryCount',
  );
  @override
  late final GeneratedColumn<int> entryCount = GeneratedColumn<int>(
    'entry_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _cachedAtMeta = const VerificationMeta(
    'cachedAt',
  );
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
    'cached_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    connectionId,
    mappingJson,
    entryCount,
    cachedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_trend_log_mapping';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedTrendLogMappingData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('connection_id')) {
      context.handle(
        _connectionIdMeta,
        connectionId.isAcceptableOrUnknown(
          data['connection_id']!,
          _connectionIdMeta,
        ),
      );
    }
    if (data.containsKey('mapping_json')) {
      context.handle(
        _mappingJsonMeta,
        mappingJson.isAcceptableOrUnknown(
          data['mapping_json']!,
          _mappingJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_mappingJsonMeta);
    }
    if (data.containsKey('entry_count')) {
      context.handle(
        _entryCountMeta,
        entryCount.isAcceptableOrUnknown(data['entry_count']!, _entryCountMeta),
      );
    }
    if (data.containsKey('cached_at')) {
      context.handle(
        _cachedAtMeta,
        cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {connectionId};
  @override
  CachedTrendLogMappingData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedTrendLogMappingData(
      connectionId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}connection_id'],
      )!,
      mappingJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mapping_json'],
      )!,
      entryCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}entry_count'],
      )!,
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cached_at'],
      )!,
    );
  }

  @override
  $CachedTrendLogMappingTable createAlias(String alias) {
    return $CachedTrendLogMappingTable(attachedDatabase, alias);
  }
}

class CachedTrendLogMappingData extends DataClass
    implements Insertable<CachedTrendLogMappingData> {
  /// Connexion associée (clé primaire)
  final int connectionId;

  /// Mapping JSON sérialisé (Map<String, int> : pointKey -> trendLogInstance)
  final String mappingJson;

  /// Nombre d'entrées dans le mapping
  final int entryCount;

  /// Date de mise en cache
  final DateTime cachedAt;
  const CachedTrendLogMappingData({
    required this.connectionId,
    required this.mappingJson,
    required this.entryCount,
    required this.cachedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['connection_id'] = Variable<int>(connectionId);
    map['mapping_json'] = Variable<String>(mappingJson);
    map['entry_count'] = Variable<int>(entryCount);
    map['cached_at'] = Variable<DateTime>(cachedAt);
    return map;
  }

  CachedTrendLogMappingCompanion toCompanion(bool nullToAbsent) {
    return CachedTrendLogMappingCompanion(
      connectionId: Value(connectionId),
      mappingJson: Value(mappingJson),
      entryCount: Value(entryCount),
      cachedAt: Value(cachedAt),
    );
  }

  factory CachedTrendLogMappingData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedTrendLogMappingData(
      connectionId: serializer.fromJson<int>(json['connectionId']),
      mappingJson: serializer.fromJson<String>(json['mappingJson']),
      entryCount: serializer.fromJson<int>(json['entryCount']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'connectionId': serializer.toJson<int>(connectionId),
      'mappingJson': serializer.toJson<String>(mappingJson),
      'entryCount': serializer.toJson<int>(entryCount),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
    };
  }

  CachedTrendLogMappingData copyWith({
    int? connectionId,
    String? mappingJson,
    int? entryCount,
    DateTime? cachedAt,
  }) => CachedTrendLogMappingData(
    connectionId: connectionId ?? this.connectionId,
    mappingJson: mappingJson ?? this.mappingJson,
    entryCount: entryCount ?? this.entryCount,
    cachedAt: cachedAt ?? this.cachedAt,
  );
  CachedTrendLogMappingData copyWithCompanion(
    CachedTrendLogMappingCompanion data,
  ) {
    return CachedTrendLogMappingData(
      connectionId: data.connectionId.present
          ? data.connectionId.value
          : this.connectionId,
      mappingJson: data.mappingJson.present
          ? data.mappingJson.value
          : this.mappingJson,
      entryCount: data.entryCount.present
          ? data.entryCount.value
          : this.entryCount,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedTrendLogMappingData(')
          ..write('connectionId: $connectionId, ')
          ..write('mappingJson: $mappingJson, ')
          ..write('entryCount: $entryCount, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(connectionId, mappingJson, entryCount, cachedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedTrendLogMappingData &&
          other.connectionId == this.connectionId &&
          other.mappingJson == this.mappingJson &&
          other.entryCount == this.entryCount &&
          other.cachedAt == this.cachedAt);
}

class CachedTrendLogMappingCompanion
    extends UpdateCompanion<CachedTrendLogMappingData> {
  final Value<int> connectionId;
  final Value<String> mappingJson;
  final Value<int> entryCount;
  final Value<DateTime> cachedAt;
  const CachedTrendLogMappingCompanion({
    this.connectionId = const Value.absent(),
    this.mappingJson = const Value.absent(),
    this.entryCount = const Value.absent(),
    this.cachedAt = const Value.absent(),
  });
  CachedTrendLogMappingCompanion.insert({
    this.connectionId = const Value.absent(),
    required String mappingJson,
    this.entryCount = const Value.absent(),
    this.cachedAt = const Value.absent(),
  }) : mappingJson = Value(mappingJson);
  static Insertable<CachedTrendLogMappingData> custom({
    Expression<int>? connectionId,
    Expression<String>? mappingJson,
    Expression<int>? entryCount,
    Expression<DateTime>? cachedAt,
  }) {
    return RawValuesInsertable({
      if (connectionId != null) 'connection_id': connectionId,
      if (mappingJson != null) 'mapping_json': mappingJson,
      if (entryCount != null) 'entry_count': entryCount,
      if (cachedAt != null) 'cached_at': cachedAt,
    });
  }

  CachedTrendLogMappingCompanion copyWith({
    Value<int>? connectionId,
    Value<String>? mappingJson,
    Value<int>? entryCount,
    Value<DateTime>? cachedAt,
  }) {
    return CachedTrendLogMappingCompanion(
      connectionId: connectionId ?? this.connectionId,
      mappingJson: mappingJson ?? this.mappingJson,
      entryCount: entryCount ?? this.entryCount,
      cachedAt: cachedAt ?? this.cachedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (connectionId.present) {
      map['connection_id'] = Variable<int>(connectionId.value);
    }
    if (mappingJson.present) {
      map['mapping_json'] = Variable<String>(mappingJson.value);
    }
    if (entryCount.present) {
      map['entry_count'] = Variable<int>(entryCount.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedTrendLogMappingCompanion(')
          ..write('connectionId: $connectionId, ')
          ..write('mappingJson: $mappingJson, ')
          ..write('entryCount: $entryCount, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }
}

class $CachedObjectsSummaryTable extends CachedObjectsSummary
    with TableInfo<$CachedObjectsSummaryTable, CachedObjectsSummaryData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedObjectsSummaryTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _connectionIdMeta = const VerificationMeta(
    'connectionId',
  );
  @override
  late final GeneratedColumn<int> connectionId = GeneratedColumn<int>(
    'connection_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES connections (id)',
    ),
  );
  static const VerificationMeta _analogInputsMeta = const VerificationMeta(
    'analogInputs',
  );
  @override
  late final GeneratedColumn<int> analogInputs = GeneratedColumn<int>(
    'analog_inputs',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _analogOutputsMeta = const VerificationMeta(
    'analogOutputs',
  );
  @override
  late final GeneratedColumn<int> analogOutputs = GeneratedColumn<int>(
    'analog_outputs',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _analogValuesMeta = const VerificationMeta(
    'analogValues',
  );
  @override
  late final GeneratedColumn<int> analogValues = GeneratedColumn<int>(
    'analog_values',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _binaryInputsMeta = const VerificationMeta(
    'binaryInputs',
  );
  @override
  late final GeneratedColumn<int> binaryInputs = GeneratedColumn<int>(
    'binary_inputs',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _binaryOutputsMeta = const VerificationMeta(
    'binaryOutputs',
  );
  @override
  late final GeneratedColumn<int> binaryOutputs = GeneratedColumn<int>(
    'binary_outputs',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _binaryValuesMeta = const VerificationMeta(
    'binaryValues',
  );
  @override
  late final GeneratedColumn<int> binaryValues = GeneratedColumn<int>(
    'binary_values',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _multiStateInputsMeta = const VerificationMeta(
    'multiStateInputs',
  );
  @override
  late final GeneratedColumn<int> multiStateInputs = GeneratedColumn<int>(
    'multi_state_inputs',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _multiStateOutputsMeta = const VerificationMeta(
    'multiStateOutputs',
  );
  @override
  late final GeneratedColumn<int> multiStateOutputs = GeneratedColumn<int>(
    'multi_state_outputs',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _multiStateValuesMeta = const VerificationMeta(
    'multiStateValues',
  );
  @override
  late final GeneratedColumn<int> multiStateValues = GeneratedColumn<int>(
    'multi_state_values',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _schedulesMeta = const VerificationMeta(
    'schedules',
  );
  @override
  late final GeneratedColumn<int> schedules = GeneratedColumn<int>(
    'schedules',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _cachedAtMeta = const VerificationMeta(
    'cachedAt',
  );
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
    'cached_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    connectionId,
    analogInputs,
    analogOutputs,
    analogValues,
    binaryInputs,
    binaryOutputs,
    binaryValues,
    multiStateInputs,
    multiStateOutputs,
    multiStateValues,
    schedules,
    cachedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_objects_summary';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedObjectsSummaryData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('connection_id')) {
      context.handle(
        _connectionIdMeta,
        connectionId.isAcceptableOrUnknown(
          data['connection_id']!,
          _connectionIdMeta,
        ),
      );
    }
    if (data.containsKey('analog_inputs')) {
      context.handle(
        _analogInputsMeta,
        analogInputs.isAcceptableOrUnknown(
          data['analog_inputs']!,
          _analogInputsMeta,
        ),
      );
    }
    if (data.containsKey('analog_outputs')) {
      context.handle(
        _analogOutputsMeta,
        analogOutputs.isAcceptableOrUnknown(
          data['analog_outputs']!,
          _analogOutputsMeta,
        ),
      );
    }
    if (data.containsKey('analog_values')) {
      context.handle(
        _analogValuesMeta,
        analogValues.isAcceptableOrUnknown(
          data['analog_values']!,
          _analogValuesMeta,
        ),
      );
    }
    if (data.containsKey('binary_inputs')) {
      context.handle(
        _binaryInputsMeta,
        binaryInputs.isAcceptableOrUnknown(
          data['binary_inputs']!,
          _binaryInputsMeta,
        ),
      );
    }
    if (data.containsKey('binary_outputs')) {
      context.handle(
        _binaryOutputsMeta,
        binaryOutputs.isAcceptableOrUnknown(
          data['binary_outputs']!,
          _binaryOutputsMeta,
        ),
      );
    }
    if (data.containsKey('binary_values')) {
      context.handle(
        _binaryValuesMeta,
        binaryValues.isAcceptableOrUnknown(
          data['binary_values']!,
          _binaryValuesMeta,
        ),
      );
    }
    if (data.containsKey('multi_state_inputs')) {
      context.handle(
        _multiStateInputsMeta,
        multiStateInputs.isAcceptableOrUnknown(
          data['multi_state_inputs']!,
          _multiStateInputsMeta,
        ),
      );
    }
    if (data.containsKey('multi_state_outputs')) {
      context.handle(
        _multiStateOutputsMeta,
        multiStateOutputs.isAcceptableOrUnknown(
          data['multi_state_outputs']!,
          _multiStateOutputsMeta,
        ),
      );
    }
    if (data.containsKey('multi_state_values')) {
      context.handle(
        _multiStateValuesMeta,
        multiStateValues.isAcceptableOrUnknown(
          data['multi_state_values']!,
          _multiStateValuesMeta,
        ),
      );
    }
    if (data.containsKey('schedules')) {
      context.handle(
        _schedulesMeta,
        schedules.isAcceptableOrUnknown(data['schedules']!, _schedulesMeta),
      );
    }
    if (data.containsKey('cached_at')) {
      context.handle(
        _cachedAtMeta,
        cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {connectionId};
  @override
  CachedObjectsSummaryData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedObjectsSummaryData(
      connectionId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}connection_id'],
      )!,
      analogInputs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}analog_inputs'],
      )!,
      analogOutputs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}analog_outputs'],
      )!,
      analogValues: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}analog_values'],
      )!,
      binaryInputs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}binary_inputs'],
      )!,
      binaryOutputs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}binary_outputs'],
      )!,
      binaryValues: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}binary_values'],
      )!,
      multiStateInputs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}multi_state_inputs'],
      )!,
      multiStateOutputs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}multi_state_outputs'],
      )!,
      multiStateValues: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}multi_state_values'],
      )!,
      schedules: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}schedules'],
      )!,
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cached_at'],
      )!,
    );
  }

  @override
  $CachedObjectsSummaryTable createAlias(String alias) {
    return $CachedObjectsSummaryTable(attachedDatabase, alias);
  }
}

class CachedObjectsSummaryData extends DataClass
    implements Insertable<CachedObjectsSummaryData> {
  /// Connexion associée (clé primaire)
  final int connectionId;

  /// Compteurs par type
  final int analogInputs;
  final int analogOutputs;
  final int analogValues;
  final int binaryInputs;
  final int binaryOutputs;
  final int binaryValues;
  final int multiStateInputs;
  final int multiStateOutputs;
  final int multiStateValues;
  final int schedules;

  /// Date de mise en cache
  final DateTime cachedAt;
  const CachedObjectsSummaryData({
    required this.connectionId,
    required this.analogInputs,
    required this.analogOutputs,
    required this.analogValues,
    required this.binaryInputs,
    required this.binaryOutputs,
    required this.binaryValues,
    required this.multiStateInputs,
    required this.multiStateOutputs,
    required this.multiStateValues,
    required this.schedules,
    required this.cachedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['connection_id'] = Variable<int>(connectionId);
    map['analog_inputs'] = Variable<int>(analogInputs);
    map['analog_outputs'] = Variable<int>(analogOutputs);
    map['analog_values'] = Variable<int>(analogValues);
    map['binary_inputs'] = Variable<int>(binaryInputs);
    map['binary_outputs'] = Variable<int>(binaryOutputs);
    map['binary_values'] = Variable<int>(binaryValues);
    map['multi_state_inputs'] = Variable<int>(multiStateInputs);
    map['multi_state_outputs'] = Variable<int>(multiStateOutputs);
    map['multi_state_values'] = Variable<int>(multiStateValues);
    map['schedules'] = Variable<int>(schedules);
    map['cached_at'] = Variable<DateTime>(cachedAt);
    return map;
  }

  CachedObjectsSummaryCompanion toCompanion(bool nullToAbsent) {
    return CachedObjectsSummaryCompanion(
      connectionId: Value(connectionId),
      analogInputs: Value(analogInputs),
      analogOutputs: Value(analogOutputs),
      analogValues: Value(analogValues),
      binaryInputs: Value(binaryInputs),
      binaryOutputs: Value(binaryOutputs),
      binaryValues: Value(binaryValues),
      multiStateInputs: Value(multiStateInputs),
      multiStateOutputs: Value(multiStateOutputs),
      multiStateValues: Value(multiStateValues),
      schedules: Value(schedules),
      cachedAt: Value(cachedAt),
    );
  }

  factory CachedObjectsSummaryData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedObjectsSummaryData(
      connectionId: serializer.fromJson<int>(json['connectionId']),
      analogInputs: serializer.fromJson<int>(json['analogInputs']),
      analogOutputs: serializer.fromJson<int>(json['analogOutputs']),
      analogValues: serializer.fromJson<int>(json['analogValues']),
      binaryInputs: serializer.fromJson<int>(json['binaryInputs']),
      binaryOutputs: serializer.fromJson<int>(json['binaryOutputs']),
      binaryValues: serializer.fromJson<int>(json['binaryValues']),
      multiStateInputs: serializer.fromJson<int>(json['multiStateInputs']),
      multiStateOutputs: serializer.fromJson<int>(json['multiStateOutputs']),
      multiStateValues: serializer.fromJson<int>(json['multiStateValues']),
      schedules: serializer.fromJson<int>(json['schedules']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'connectionId': serializer.toJson<int>(connectionId),
      'analogInputs': serializer.toJson<int>(analogInputs),
      'analogOutputs': serializer.toJson<int>(analogOutputs),
      'analogValues': serializer.toJson<int>(analogValues),
      'binaryInputs': serializer.toJson<int>(binaryInputs),
      'binaryOutputs': serializer.toJson<int>(binaryOutputs),
      'binaryValues': serializer.toJson<int>(binaryValues),
      'multiStateInputs': serializer.toJson<int>(multiStateInputs),
      'multiStateOutputs': serializer.toJson<int>(multiStateOutputs),
      'multiStateValues': serializer.toJson<int>(multiStateValues),
      'schedules': serializer.toJson<int>(schedules),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
    };
  }

  CachedObjectsSummaryData copyWith({
    int? connectionId,
    int? analogInputs,
    int? analogOutputs,
    int? analogValues,
    int? binaryInputs,
    int? binaryOutputs,
    int? binaryValues,
    int? multiStateInputs,
    int? multiStateOutputs,
    int? multiStateValues,
    int? schedules,
    DateTime? cachedAt,
  }) => CachedObjectsSummaryData(
    connectionId: connectionId ?? this.connectionId,
    analogInputs: analogInputs ?? this.analogInputs,
    analogOutputs: analogOutputs ?? this.analogOutputs,
    analogValues: analogValues ?? this.analogValues,
    binaryInputs: binaryInputs ?? this.binaryInputs,
    binaryOutputs: binaryOutputs ?? this.binaryOutputs,
    binaryValues: binaryValues ?? this.binaryValues,
    multiStateInputs: multiStateInputs ?? this.multiStateInputs,
    multiStateOutputs: multiStateOutputs ?? this.multiStateOutputs,
    multiStateValues: multiStateValues ?? this.multiStateValues,
    schedules: schedules ?? this.schedules,
    cachedAt: cachedAt ?? this.cachedAt,
  );
  CachedObjectsSummaryData copyWithCompanion(
    CachedObjectsSummaryCompanion data,
  ) {
    return CachedObjectsSummaryData(
      connectionId: data.connectionId.present
          ? data.connectionId.value
          : this.connectionId,
      analogInputs: data.analogInputs.present
          ? data.analogInputs.value
          : this.analogInputs,
      analogOutputs: data.analogOutputs.present
          ? data.analogOutputs.value
          : this.analogOutputs,
      analogValues: data.analogValues.present
          ? data.analogValues.value
          : this.analogValues,
      binaryInputs: data.binaryInputs.present
          ? data.binaryInputs.value
          : this.binaryInputs,
      binaryOutputs: data.binaryOutputs.present
          ? data.binaryOutputs.value
          : this.binaryOutputs,
      binaryValues: data.binaryValues.present
          ? data.binaryValues.value
          : this.binaryValues,
      multiStateInputs: data.multiStateInputs.present
          ? data.multiStateInputs.value
          : this.multiStateInputs,
      multiStateOutputs: data.multiStateOutputs.present
          ? data.multiStateOutputs.value
          : this.multiStateOutputs,
      multiStateValues: data.multiStateValues.present
          ? data.multiStateValues.value
          : this.multiStateValues,
      schedules: data.schedules.present ? data.schedules.value : this.schedules,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedObjectsSummaryData(')
          ..write('connectionId: $connectionId, ')
          ..write('analogInputs: $analogInputs, ')
          ..write('analogOutputs: $analogOutputs, ')
          ..write('analogValues: $analogValues, ')
          ..write('binaryInputs: $binaryInputs, ')
          ..write('binaryOutputs: $binaryOutputs, ')
          ..write('binaryValues: $binaryValues, ')
          ..write('multiStateInputs: $multiStateInputs, ')
          ..write('multiStateOutputs: $multiStateOutputs, ')
          ..write('multiStateValues: $multiStateValues, ')
          ..write('schedules: $schedules, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    connectionId,
    analogInputs,
    analogOutputs,
    analogValues,
    binaryInputs,
    binaryOutputs,
    binaryValues,
    multiStateInputs,
    multiStateOutputs,
    multiStateValues,
    schedules,
    cachedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedObjectsSummaryData &&
          other.connectionId == this.connectionId &&
          other.analogInputs == this.analogInputs &&
          other.analogOutputs == this.analogOutputs &&
          other.analogValues == this.analogValues &&
          other.binaryInputs == this.binaryInputs &&
          other.binaryOutputs == this.binaryOutputs &&
          other.binaryValues == this.binaryValues &&
          other.multiStateInputs == this.multiStateInputs &&
          other.multiStateOutputs == this.multiStateOutputs &&
          other.multiStateValues == this.multiStateValues &&
          other.schedules == this.schedules &&
          other.cachedAt == this.cachedAt);
}

class CachedObjectsSummaryCompanion
    extends UpdateCompanion<CachedObjectsSummaryData> {
  final Value<int> connectionId;
  final Value<int> analogInputs;
  final Value<int> analogOutputs;
  final Value<int> analogValues;
  final Value<int> binaryInputs;
  final Value<int> binaryOutputs;
  final Value<int> binaryValues;
  final Value<int> multiStateInputs;
  final Value<int> multiStateOutputs;
  final Value<int> multiStateValues;
  final Value<int> schedules;
  final Value<DateTime> cachedAt;
  const CachedObjectsSummaryCompanion({
    this.connectionId = const Value.absent(),
    this.analogInputs = const Value.absent(),
    this.analogOutputs = const Value.absent(),
    this.analogValues = const Value.absent(),
    this.binaryInputs = const Value.absent(),
    this.binaryOutputs = const Value.absent(),
    this.binaryValues = const Value.absent(),
    this.multiStateInputs = const Value.absent(),
    this.multiStateOutputs = const Value.absent(),
    this.multiStateValues = const Value.absent(),
    this.schedules = const Value.absent(),
    this.cachedAt = const Value.absent(),
  });
  CachedObjectsSummaryCompanion.insert({
    this.connectionId = const Value.absent(),
    this.analogInputs = const Value.absent(),
    this.analogOutputs = const Value.absent(),
    this.analogValues = const Value.absent(),
    this.binaryInputs = const Value.absent(),
    this.binaryOutputs = const Value.absent(),
    this.binaryValues = const Value.absent(),
    this.multiStateInputs = const Value.absent(),
    this.multiStateOutputs = const Value.absent(),
    this.multiStateValues = const Value.absent(),
    this.schedules = const Value.absent(),
    this.cachedAt = const Value.absent(),
  });
  static Insertable<CachedObjectsSummaryData> custom({
    Expression<int>? connectionId,
    Expression<int>? analogInputs,
    Expression<int>? analogOutputs,
    Expression<int>? analogValues,
    Expression<int>? binaryInputs,
    Expression<int>? binaryOutputs,
    Expression<int>? binaryValues,
    Expression<int>? multiStateInputs,
    Expression<int>? multiStateOutputs,
    Expression<int>? multiStateValues,
    Expression<int>? schedules,
    Expression<DateTime>? cachedAt,
  }) {
    return RawValuesInsertable({
      if (connectionId != null) 'connection_id': connectionId,
      if (analogInputs != null) 'analog_inputs': analogInputs,
      if (analogOutputs != null) 'analog_outputs': analogOutputs,
      if (analogValues != null) 'analog_values': analogValues,
      if (binaryInputs != null) 'binary_inputs': binaryInputs,
      if (binaryOutputs != null) 'binary_outputs': binaryOutputs,
      if (binaryValues != null) 'binary_values': binaryValues,
      if (multiStateInputs != null) 'multi_state_inputs': multiStateInputs,
      if (multiStateOutputs != null) 'multi_state_outputs': multiStateOutputs,
      if (multiStateValues != null) 'multi_state_values': multiStateValues,
      if (schedules != null) 'schedules': schedules,
      if (cachedAt != null) 'cached_at': cachedAt,
    });
  }

  CachedObjectsSummaryCompanion copyWith({
    Value<int>? connectionId,
    Value<int>? analogInputs,
    Value<int>? analogOutputs,
    Value<int>? analogValues,
    Value<int>? binaryInputs,
    Value<int>? binaryOutputs,
    Value<int>? binaryValues,
    Value<int>? multiStateInputs,
    Value<int>? multiStateOutputs,
    Value<int>? multiStateValues,
    Value<int>? schedules,
    Value<DateTime>? cachedAt,
  }) {
    return CachedObjectsSummaryCompanion(
      connectionId: connectionId ?? this.connectionId,
      analogInputs: analogInputs ?? this.analogInputs,
      analogOutputs: analogOutputs ?? this.analogOutputs,
      analogValues: analogValues ?? this.analogValues,
      binaryInputs: binaryInputs ?? this.binaryInputs,
      binaryOutputs: binaryOutputs ?? this.binaryOutputs,
      binaryValues: binaryValues ?? this.binaryValues,
      multiStateInputs: multiStateInputs ?? this.multiStateInputs,
      multiStateOutputs: multiStateOutputs ?? this.multiStateOutputs,
      multiStateValues: multiStateValues ?? this.multiStateValues,
      schedules: schedules ?? this.schedules,
      cachedAt: cachedAt ?? this.cachedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (connectionId.present) {
      map['connection_id'] = Variable<int>(connectionId.value);
    }
    if (analogInputs.present) {
      map['analog_inputs'] = Variable<int>(analogInputs.value);
    }
    if (analogOutputs.present) {
      map['analog_outputs'] = Variable<int>(analogOutputs.value);
    }
    if (analogValues.present) {
      map['analog_values'] = Variable<int>(analogValues.value);
    }
    if (binaryInputs.present) {
      map['binary_inputs'] = Variable<int>(binaryInputs.value);
    }
    if (binaryOutputs.present) {
      map['binary_outputs'] = Variable<int>(binaryOutputs.value);
    }
    if (binaryValues.present) {
      map['binary_values'] = Variable<int>(binaryValues.value);
    }
    if (multiStateInputs.present) {
      map['multi_state_inputs'] = Variable<int>(multiStateInputs.value);
    }
    if (multiStateOutputs.present) {
      map['multi_state_outputs'] = Variable<int>(multiStateOutputs.value);
    }
    if (multiStateValues.present) {
      map['multi_state_values'] = Variable<int>(multiStateValues.value);
    }
    if (schedules.present) {
      map['schedules'] = Variable<int>(schedules.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedObjectsSummaryCompanion(')
          ..write('connectionId: $connectionId, ')
          ..write('analogInputs: $analogInputs, ')
          ..write('analogOutputs: $analogOutputs, ')
          ..write('analogValues: $analogValues, ')
          ..write('binaryInputs: $binaryInputs, ')
          ..write('binaryOutputs: $binaryOutputs, ')
          ..write('binaryValues: $binaryValues, ')
          ..write('multiStateInputs: $multiStateInputs, ')
          ..write('multiStateOutputs: $multiStateOutputs, ')
          ..write('multiStateValues: $multiStateValues, ')
          ..write('schedules: $schedules, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }
}

class $SynopticsTable extends Synoptics
    with TableInfo<$SynopticsTable, Synoptic> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SynopticsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 100,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _svgAssetPathMeta = const VerificationMeta(
    'svgAssetPath',
  );
  @override
  late final GeneratedColumn<String> svgAssetPath = GeneratedColumn<String>(
    'svg_asset_path',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 255,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _connectionIdMeta = const VerificationMeta(
    'connectionId',
  );
  @override
  late final GeneratedColumn<int> connectionId = GeneratedColumn<int>(
    'connection_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    svgAssetPath,
    connectionId,
    description,
    sortOrder,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'synoptics';
  @override
  VerificationContext validateIntegrity(
    Insertable<Synoptic> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('svg_asset_path')) {
      context.handle(
        _svgAssetPathMeta,
        svgAssetPath.isAcceptableOrUnknown(
          data['svg_asset_path']!,
          _svgAssetPathMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_svgAssetPathMeta);
    }
    if (data.containsKey('connection_id')) {
      context.handle(
        _connectionIdMeta,
        connectionId.isAcceptableOrUnknown(
          data['connection_id']!,
          _connectionIdMeta,
        ),
      );
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Synoptic map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Synoptic(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      svgAssetPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}svg_asset_path'],
      )!,
      connectionId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}connection_id'],
      ),
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $SynopticsTable createAlias(String alias) {
    return $SynopticsTable(attachedDatabase, alias);
  }
}

class Synoptic extends DataClass implements Insertable<Synoptic> {
  /// Identifiant unique
  final int id;

  /// Nom du synoptique (donné par l'utilisateur)
  final String name;

  /// Chemin de l'asset SVG (ex: "assets/synoptics/CR_V0.1.svg")
  final String svgAssetPath;

  /// Connexion associée (null = synoptique global réutilisable)
  final int? connectionId;

  /// Description optionnelle
  final String? description;

  /// Ordre de tri pour l'affichage
  final int sortOrder;

  /// Date de création
  final DateTime createdAt;

  /// Date de dernière modification
  final DateTime updatedAt;
  const Synoptic({
    required this.id,
    required this.name,
    required this.svgAssetPath,
    this.connectionId,
    this.description,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['svg_asset_path'] = Variable<String>(svgAssetPath);
    if (!nullToAbsent || connectionId != null) {
      map['connection_id'] = Variable<int>(connectionId);
    }
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['sort_order'] = Variable<int>(sortOrder);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  SynopticsCompanion toCompanion(bool nullToAbsent) {
    return SynopticsCompanion(
      id: Value(id),
      name: Value(name),
      svgAssetPath: Value(svgAssetPath),
      connectionId: connectionId == null && nullToAbsent
          ? const Value.absent()
          : Value(connectionId),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      sortOrder: Value(sortOrder),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Synoptic.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Synoptic(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      svgAssetPath: serializer.fromJson<String>(json['svgAssetPath']),
      connectionId: serializer.fromJson<int?>(json['connectionId']),
      description: serializer.fromJson<String?>(json['description']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'svgAssetPath': serializer.toJson<String>(svgAssetPath),
      'connectionId': serializer.toJson<int?>(connectionId),
      'description': serializer.toJson<String?>(description),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Synoptic copyWith({
    int? id,
    String? name,
    String? svgAssetPath,
    Value<int?> connectionId = const Value.absent(),
    Value<String?> description = const Value.absent(),
    int? sortOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Synoptic(
    id: id ?? this.id,
    name: name ?? this.name,
    svgAssetPath: svgAssetPath ?? this.svgAssetPath,
    connectionId: connectionId.present ? connectionId.value : this.connectionId,
    description: description.present ? description.value : this.description,
    sortOrder: sortOrder ?? this.sortOrder,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Synoptic copyWithCompanion(SynopticsCompanion data) {
    return Synoptic(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      svgAssetPath: data.svgAssetPath.present
          ? data.svgAssetPath.value
          : this.svgAssetPath,
      connectionId: data.connectionId.present
          ? data.connectionId.value
          : this.connectionId,
      description: data.description.present
          ? data.description.value
          : this.description,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Synoptic(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('svgAssetPath: $svgAssetPath, ')
          ..write('connectionId: $connectionId, ')
          ..write('description: $description, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    svgAssetPath,
    connectionId,
    description,
    sortOrder,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Synoptic &&
          other.id == this.id &&
          other.name == this.name &&
          other.svgAssetPath == this.svgAssetPath &&
          other.connectionId == this.connectionId &&
          other.description == this.description &&
          other.sortOrder == this.sortOrder &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class SynopticsCompanion extends UpdateCompanion<Synoptic> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> svgAssetPath;
  final Value<int?> connectionId;
  final Value<String?> description;
  final Value<int> sortOrder;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const SynopticsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.svgAssetPath = const Value.absent(),
    this.connectionId = const Value.absent(),
    this.description = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  SynopticsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required String svgAssetPath,
    this.connectionId = const Value.absent(),
    this.description = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : name = Value(name),
       svgAssetPath = Value(svgAssetPath);
  static Insertable<Synoptic> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? svgAssetPath,
    Expression<int>? connectionId,
    Expression<String>? description,
    Expression<int>? sortOrder,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (svgAssetPath != null) 'svg_asset_path': svgAssetPath,
      if (connectionId != null) 'connection_id': connectionId,
      if (description != null) 'description': description,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  SynopticsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String>? svgAssetPath,
    Value<int?>? connectionId,
    Value<String?>? description,
    Value<int>? sortOrder,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return SynopticsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      svgAssetPath: svgAssetPath ?? this.svgAssetPath,
      connectionId: connectionId ?? this.connectionId,
      description: description ?? this.description,
      sortOrder: sortOrder ?? this.sortOrder,
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
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (svgAssetPath.present) {
      map['svg_asset_path'] = Variable<String>(svgAssetPath.value);
    }
    if (connectionId.present) {
      map['connection_id'] = Variable<int>(connectionId.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
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
    return (StringBuffer('SynopticsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('svgAssetPath: $svgAssetPath, ')
          ..write('connectionId: $connectionId, ')
          ..write('description: $description, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $SynopticBindingsTable extends SynopticBindings
    with TableInfo<$SynopticBindingsTable, SynopticBinding> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SynopticBindingsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _synopticIdMeta = const VerificationMeta(
    'synopticId',
  );
  @override
  late final GeneratedColumn<int> synopticId = GeneratedColumn<int>(
    'synoptic_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES synoptics (id)',
    ),
  );
  static const VerificationMeta _svgElementIdMeta = const VerificationMeta(
    'svgElementId',
  );
  @override
  late final GeneratedColumn<String> svgElementId = GeneratedColumn<String>(
    'svg_element_id',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 100,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pointRefMeta = const VerificationMeta(
    'pointRef',
  );
  @override
  late final GeneratedColumn<String> pointRef = GeneratedColumn<String>(
    'point_ref',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 50,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<BindingType, String> bindingType =
      GeneratedColumn<String>(
        'binding_type',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<BindingType>(
        $SynopticBindingsTable.$converterbindingType,
      );
  static const VerificationMeta _configJsonMeta = const VerificationMeta(
    'configJson',
  );
  @override
  late final GeneratedColumn<String> configJson = GeneratedColumn<String>(
    'config_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pointNameMeta = const VerificationMeta(
    'pointName',
  );
  @override
  late final GeneratedColumn<String> pointName = GeneratedColumn<String>(
    'point_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    synopticId,
    svgElementId,
    pointRef,
    bindingType,
    configJson,
    pointName,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'synoptic_bindings';
  @override
  VerificationContext validateIntegrity(
    Insertable<SynopticBinding> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('synoptic_id')) {
      context.handle(
        _synopticIdMeta,
        synopticId.isAcceptableOrUnknown(data['synoptic_id']!, _synopticIdMeta),
      );
    } else if (isInserting) {
      context.missing(_synopticIdMeta);
    }
    if (data.containsKey('svg_element_id')) {
      context.handle(
        _svgElementIdMeta,
        svgElementId.isAcceptableOrUnknown(
          data['svg_element_id']!,
          _svgElementIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_svgElementIdMeta);
    }
    if (data.containsKey('point_ref')) {
      context.handle(
        _pointRefMeta,
        pointRef.isAcceptableOrUnknown(data['point_ref']!, _pointRefMeta),
      );
    } else if (isInserting) {
      context.missing(_pointRefMeta);
    }
    if (data.containsKey('config_json')) {
      context.handle(
        _configJsonMeta,
        configJson.isAcceptableOrUnknown(data['config_json']!, _configJsonMeta),
      );
    }
    if (data.containsKey('point_name')) {
      context.handle(
        _pointNameMeta,
        pointName.isAcceptableOrUnknown(data['point_name']!, _pointNameMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {synopticId, svgElementId},
  ];
  @override
  SynopticBinding map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SynopticBinding(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      synopticId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}synoptic_id'],
      )!,
      svgElementId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}svg_element_id'],
      )!,
      pointRef: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}point_ref'],
      )!,
      bindingType: $SynopticBindingsTable.$converterbindingType.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}binding_type'],
        )!,
      ),
      configJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}config_json'],
      ),
      pointName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}point_name'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $SynopticBindingsTable createAlias(String alias) {
    return $SynopticBindingsTable(attachedDatabase, alias);
  }

  static TypeConverter<BindingType, String> $converterbindingType =
      const BindingTypeConverter();
}

class SynopticBinding extends DataClass implements Insertable<SynopticBinding> {
  /// Identifiant unique
  final int id;

  /// Synoptique parent
  final int synopticId;

  /// ID de l'élément dans le SVG (ex: "val_temp_depart", "ind_pompe_etat")
  final String svgElementId;

  /// Référence du point BACnet (ex: "AV:1", "BI:5")
  final String pointRef;

  /// Type de liaison
  final BindingType bindingType;

  /// Configuration JSON (format, couleurs ON/OFF, seuils, etc.)
  /// Exemple pour value: {"format": "{value}°C", "decimals": 1}
  /// Exemple pour color: {"onColor": "#27ae60", "offColor": "#e74c3c", "threshold": 0.5}
  /// Exemple pour animation: {"property": "visibility", "onValue": "visible", "offValue": "hidden"}
  final String? configJson;

  /// Nom du point (pour affichage même offline)
  final String? pointName;

  /// Date de création
  final DateTime createdAt;
  const SynopticBinding({
    required this.id,
    required this.synopticId,
    required this.svgElementId,
    required this.pointRef,
    required this.bindingType,
    this.configJson,
    this.pointName,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['synoptic_id'] = Variable<int>(synopticId);
    map['svg_element_id'] = Variable<String>(svgElementId);
    map['point_ref'] = Variable<String>(pointRef);
    {
      map['binding_type'] = Variable<String>(
        $SynopticBindingsTable.$converterbindingType.toSql(bindingType),
      );
    }
    if (!nullToAbsent || configJson != null) {
      map['config_json'] = Variable<String>(configJson);
    }
    if (!nullToAbsent || pointName != null) {
      map['point_name'] = Variable<String>(pointName);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  SynopticBindingsCompanion toCompanion(bool nullToAbsent) {
    return SynopticBindingsCompanion(
      id: Value(id),
      synopticId: Value(synopticId),
      svgElementId: Value(svgElementId),
      pointRef: Value(pointRef),
      bindingType: Value(bindingType),
      configJson: configJson == null && nullToAbsent
          ? const Value.absent()
          : Value(configJson),
      pointName: pointName == null && nullToAbsent
          ? const Value.absent()
          : Value(pointName),
      createdAt: Value(createdAt),
    );
  }

  factory SynopticBinding.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SynopticBinding(
      id: serializer.fromJson<int>(json['id']),
      synopticId: serializer.fromJson<int>(json['synopticId']),
      svgElementId: serializer.fromJson<String>(json['svgElementId']),
      pointRef: serializer.fromJson<String>(json['pointRef']),
      bindingType: serializer.fromJson<BindingType>(json['bindingType']),
      configJson: serializer.fromJson<String?>(json['configJson']),
      pointName: serializer.fromJson<String?>(json['pointName']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'synopticId': serializer.toJson<int>(synopticId),
      'svgElementId': serializer.toJson<String>(svgElementId),
      'pointRef': serializer.toJson<String>(pointRef),
      'bindingType': serializer.toJson<BindingType>(bindingType),
      'configJson': serializer.toJson<String?>(configJson),
      'pointName': serializer.toJson<String?>(pointName),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  SynopticBinding copyWith({
    int? id,
    int? synopticId,
    String? svgElementId,
    String? pointRef,
    BindingType? bindingType,
    Value<String?> configJson = const Value.absent(),
    Value<String?> pointName = const Value.absent(),
    DateTime? createdAt,
  }) => SynopticBinding(
    id: id ?? this.id,
    synopticId: synopticId ?? this.synopticId,
    svgElementId: svgElementId ?? this.svgElementId,
    pointRef: pointRef ?? this.pointRef,
    bindingType: bindingType ?? this.bindingType,
    configJson: configJson.present ? configJson.value : this.configJson,
    pointName: pointName.present ? pointName.value : this.pointName,
    createdAt: createdAt ?? this.createdAt,
  );
  SynopticBinding copyWithCompanion(SynopticBindingsCompanion data) {
    return SynopticBinding(
      id: data.id.present ? data.id.value : this.id,
      synopticId: data.synopticId.present
          ? data.synopticId.value
          : this.synopticId,
      svgElementId: data.svgElementId.present
          ? data.svgElementId.value
          : this.svgElementId,
      pointRef: data.pointRef.present ? data.pointRef.value : this.pointRef,
      bindingType: data.bindingType.present
          ? data.bindingType.value
          : this.bindingType,
      configJson: data.configJson.present
          ? data.configJson.value
          : this.configJson,
      pointName: data.pointName.present ? data.pointName.value : this.pointName,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SynopticBinding(')
          ..write('id: $id, ')
          ..write('synopticId: $synopticId, ')
          ..write('svgElementId: $svgElementId, ')
          ..write('pointRef: $pointRef, ')
          ..write('bindingType: $bindingType, ')
          ..write('configJson: $configJson, ')
          ..write('pointName: $pointName, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    synopticId,
    svgElementId,
    pointRef,
    bindingType,
    configJson,
    pointName,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SynopticBinding &&
          other.id == this.id &&
          other.synopticId == this.synopticId &&
          other.svgElementId == this.svgElementId &&
          other.pointRef == this.pointRef &&
          other.bindingType == this.bindingType &&
          other.configJson == this.configJson &&
          other.pointName == this.pointName &&
          other.createdAt == this.createdAt);
}

class SynopticBindingsCompanion extends UpdateCompanion<SynopticBinding> {
  final Value<int> id;
  final Value<int> synopticId;
  final Value<String> svgElementId;
  final Value<String> pointRef;
  final Value<BindingType> bindingType;
  final Value<String?> configJson;
  final Value<String?> pointName;
  final Value<DateTime> createdAt;
  const SynopticBindingsCompanion({
    this.id = const Value.absent(),
    this.synopticId = const Value.absent(),
    this.svgElementId = const Value.absent(),
    this.pointRef = const Value.absent(),
    this.bindingType = const Value.absent(),
    this.configJson = const Value.absent(),
    this.pointName = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  SynopticBindingsCompanion.insert({
    this.id = const Value.absent(),
    required int synopticId,
    required String svgElementId,
    required String pointRef,
    required BindingType bindingType,
    this.configJson = const Value.absent(),
    this.pointName = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : synopticId = Value(synopticId),
       svgElementId = Value(svgElementId),
       pointRef = Value(pointRef),
       bindingType = Value(bindingType);
  static Insertable<SynopticBinding> custom({
    Expression<int>? id,
    Expression<int>? synopticId,
    Expression<String>? svgElementId,
    Expression<String>? pointRef,
    Expression<String>? bindingType,
    Expression<String>? configJson,
    Expression<String>? pointName,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (synopticId != null) 'synoptic_id': synopticId,
      if (svgElementId != null) 'svg_element_id': svgElementId,
      if (pointRef != null) 'point_ref': pointRef,
      if (bindingType != null) 'binding_type': bindingType,
      if (configJson != null) 'config_json': configJson,
      if (pointName != null) 'point_name': pointName,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  SynopticBindingsCompanion copyWith({
    Value<int>? id,
    Value<int>? synopticId,
    Value<String>? svgElementId,
    Value<String>? pointRef,
    Value<BindingType>? bindingType,
    Value<String?>? configJson,
    Value<String?>? pointName,
    Value<DateTime>? createdAt,
  }) {
    return SynopticBindingsCompanion(
      id: id ?? this.id,
      synopticId: synopticId ?? this.synopticId,
      svgElementId: svgElementId ?? this.svgElementId,
      pointRef: pointRef ?? this.pointRef,
      bindingType: bindingType ?? this.bindingType,
      configJson: configJson ?? this.configJson,
      pointName: pointName ?? this.pointName,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (synopticId.present) {
      map['synoptic_id'] = Variable<int>(synopticId.value);
    }
    if (svgElementId.present) {
      map['svg_element_id'] = Variable<String>(svgElementId.value);
    }
    if (pointRef.present) {
      map['point_ref'] = Variable<String>(pointRef.value);
    }
    if (bindingType.present) {
      map['binding_type'] = Variable<String>(
        $SynopticBindingsTable.$converterbindingType.toSql(bindingType.value),
      );
    }
    if (configJson.present) {
      map['config_json'] = Variable<String>(configJson.value);
    }
    if (pointName.present) {
      map['point_name'] = Variable<String>(pointName.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SynopticBindingsCompanion(')
          ..write('id: $id, ')
          ..write('synopticId: $synopticId, ')
          ..write('svgElementId: $svgElementId, ')
          ..write('pointRef: $pointRef, ')
          ..write('bindingType: $bindingType, ')
          ..write('configJson: $configJson, ')
          ..write('pointName: $pointName, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $DashboardsTable extends Dashboards
    with TableInfo<$DashboardsTable, Dashboard> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DashboardsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 100,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _connectionIdMeta = const VerificationMeta(
    'connectionId',
  );
  @override
  late final GeneratedColumn<int> connectionId = GeneratedColumn<int>(
    'connection_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES connections (id)',
    ),
  );
  static const VerificationMeta _columnsMeta = const VerificationMeta(
    'columns',
  );
  @override
  late final GeneratedColumn<int> columns = GeneratedColumn<int>(
    'columns',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(2),
  );
  static const VerificationMeta _rowsMeta = const VerificationMeta('rows');
  @override
  late final GeneratedColumn<int> rows = GeneratedColumn<int>(
    'rows',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(2),
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    connectionId,
    columns,
    rows,
    sortOrder,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'dashboards';
  @override
  VerificationContext validateIntegrity(
    Insertable<Dashboard> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('connection_id')) {
      context.handle(
        _connectionIdMeta,
        connectionId.isAcceptableOrUnknown(
          data['connection_id']!,
          _connectionIdMeta,
        ),
      );
    }
    if (data.containsKey('columns')) {
      context.handle(
        _columnsMeta,
        columns.isAcceptableOrUnknown(data['columns']!, _columnsMeta),
      );
    }
    if (data.containsKey('rows')) {
      context.handle(
        _rowsMeta,
        rows.isAcceptableOrUnknown(data['rows']!, _rowsMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Dashboard map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Dashboard(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      connectionId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}connection_id'],
      ),
      columns: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}columns'],
      )!,
      rows: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rows'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $DashboardsTable createAlias(String alias) {
    return $DashboardsTable(attachedDatabase, alias);
  }
}

class Dashboard extends DataClass implements Insertable<Dashboard> {
  /// Identifiant unique
  final int id;

  /// Nom du dashboard (donné par l'utilisateur)
  final String name;

  /// Connexion associée (null = dashboard global)
  final int? connectionId;

  /// Nombre de colonnes de la grille (2-4)
  final int columns;

  /// Nombre de lignes de la grille (2-4)
  final int rows;

  /// Ordre de tri pour l'affichage
  final int sortOrder;

  /// Date de création
  final DateTime createdAt;

  /// Date de dernière modification
  final DateTime updatedAt;
  const Dashboard({
    required this.id,
    required this.name,
    this.connectionId,
    required this.columns,
    required this.rows,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || connectionId != null) {
      map['connection_id'] = Variable<int>(connectionId);
    }
    map['columns'] = Variable<int>(columns);
    map['rows'] = Variable<int>(rows);
    map['sort_order'] = Variable<int>(sortOrder);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  DashboardsCompanion toCompanion(bool nullToAbsent) {
    return DashboardsCompanion(
      id: Value(id),
      name: Value(name),
      connectionId: connectionId == null && nullToAbsent
          ? const Value.absent()
          : Value(connectionId),
      columns: Value(columns),
      rows: Value(rows),
      sortOrder: Value(sortOrder),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Dashboard.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Dashboard(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      connectionId: serializer.fromJson<int?>(json['connectionId']),
      columns: serializer.fromJson<int>(json['columns']),
      rows: serializer.fromJson<int>(json['rows']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'connectionId': serializer.toJson<int?>(connectionId),
      'columns': serializer.toJson<int>(columns),
      'rows': serializer.toJson<int>(rows),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Dashboard copyWith({
    int? id,
    String? name,
    Value<int?> connectionId = const Value.absent(),
    int? columns,
    int? rows,
    int? sortOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Dashboard(
    id: id ?? this.id,
    name: name ?? this.name,
    connectionId: connectionId.present ? connectionId.value : this.connectionId,
    columns: columns ?? this.columns,
    rows: rows ?? this.rows,
    sortOrder: sortOrder ?? this.sortOrder,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Dashboard copyWithCompanion(DashboardsCompanion data) {
    return Dashboard(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      connectionId: data.connectionId.present
          ? data.connectionId.value
          : this.connectionId,
      columns: data.columns.present ? data.columns.value : this.columns,
      rows: data.rows.present ? data.rows.value : this.rows,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Dashboard(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('connectionId: $connectionId, ')
          ..write('columns: $columns, ')
          ..write('rows: $rows, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    connectionId,
    columns,
    rows,
    sortOrder,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Dashboard &&
          other.id == this.id &&
          other.name == this.name &&
          other.connectionId == this.connectionId &&
          other.columns == this.columns &&
          other.rows == this.rows &&
          other.sortOrder == this.sortOrder &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class DashboardsCompanion extends UpdateCompanion<Dashboard> {
  final Value<int> id;
  final Value<String> name;
  final Value<int?> connectionId;
  final Value<int> columns;
  final Value<int> rows;
  final Value<int> sortOrder;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const DashboardsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.connectionId = const Value.absent(),
    this.columns = const Value.absent(),
    this.rows = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  DashboardsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.connectionId = const Value.absent(),
    this.columns = const Value.absent(),
    this.rows = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : name = Value(name);
  static Insertable<Dashboard> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<int>? connectionId,
    Expression<int>? columns,
    Expression<int>? rows,
    Expression<int>? sortOrder,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (connectionId != null) 'connection_id': connectionId,
      if (columns != null) 'columns': columns,
      if (rows != null) 'rows': rows,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  DashboardsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<int?>? connectionId,
    Value<int>? columns,
    Value<int>? rows,
    Value<int>? sortOrder,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return DashboardsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      connectionId: connectionId ?? this.connectionId,
      columns: columns ?? this.columns,
      rows: rows ?? this.rows,
      sortOrder: sortOrder ?? this.sortOrder,
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
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (connectionId.present) {
      map['connection_id'] = Variable<int>(connectionId.value);
    }
    if (columns.present) {
      map['columns'] = Variable<int>(columns.value);
    }
    if (rows.present) {
      map['rows'] = Variable<int>(rows.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
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
    return (StringBuffer('DashboardsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('connectionId: $connectionId, ')
          ..write('columns: $columns, ')
          ..write('rows: $rows, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $DashboardWidgetsTable extends DashboardWidgets
    with TableInfo<$DashboardWidgetsTable, DashboardWidget> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DashboardWidgetsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _dashboardIdMeta = const VerificationMeta(
    'dashboardId',
  );
  @override
  late final GeneratedColumn<int> dashboardId = GeneratedColumn<int>(
    'dashboard_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES dashboards (id)',
    ),
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DashboardWidgetType, String>
  widgetType =
      GeneratedColumn<String>(
        'widget_type',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<DashboardWidgetType>(
        $DashboardWidgetsTable.$converterwidgetType,
      );
  static const VerificationMeta _configJsonMeta = const VerificationMeta(
    'configJson',
  );
  @override
  late final GeneratedColumn<String> configJson = GeneratedColumn<String>(
    'config_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    dashboardId,
    position,
    widgetType,
    configJson,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'dashboard_widgets';
  @override
  VerificationContext validateIntegrity(
    Insertable<DashboardWidget> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('dashboard_id')) {
      context.handle(
        _dashboardIdMeta,
        dashboardId.isAcceptableOrUnknown(
          data['dashboard_id']!,
          _dashboardIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_dashboardIdMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('config_json')) {
      context.handle(
        _configJsonMeta,
        configJson.isAcceptableOrUnknown(data['config_json']!, _configJsonMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DashboardWidget map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DashboardWidget(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      dashboardId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}dashboard_id'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      widgetType: $DashboardWidgetsTable.$converterwidgetType.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}widget_type'],
        )!,
      ),
      configJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}config_json'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $DashboardWidgetsTable createAlias(String alias) {
    return $DashboardWidgetsTable(attachedDatabase, alias);
  }

  static TypeConverter<DashboardWidgetType, String> $converterwidgetType =
      const DashboardWidgetTypeConverter();
}

class DashboardWidget extends DataClass implements Insertable<DashboardWidget> {
  /// Identifiant unique
  final int id;

  /// Dashboard parent
  final int dashboardId;

  /// Position dans la grille (index 0-based)
  final int position;

  /// Type de widget
  final DashboardWidgetType widgetType;

  /// Configuration JSON du widget
  ///
  /// Pour singleTrendChart:
  /// {
  ///   "trendLogInstance": 300123,
  ///   "pointName": "Temperature",
  ///   "units": "°C",
  ///   "colorTheme": "blue"
  /// }
  ///
  /// Pour multiCurveChart:
  /// {
  ///   "trendLogInstances": [300123, 300124, 300125],
  ///   "curveNames": {"300123": "Temp 1", "300124": "Temp 2"},
  ///   "curveUnits": {"300123": "°C", "300124": "°C"}
  /// }
  ///
  /// Pour statsCard:
  /// {
  ///   "trendLogInstance": 300123,
  ///   "pointName": "Zone Temperature",
  ///   "units": "°C",
  ///   "showCurrent": true,
  ///   "showMin": true,
  ///   "showMax": true,
  ///   "showAvg": true
  /// }
  final String? configJson;

  /// Date de création
  final DateTime createdAt;
  const DashboardWidget({
    required this.id,
    required this.dashboardId,
    required this.position,
    required this.widgetType,
    this.configJson,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['dashboard_id'] = Variable<int>(dashboardId);
    map['position'] = Variable<int>(position);
    {
      map['widget_type'] = Variable<String>(
        $DashboardWidgetsTable.$converterwidgetType.toSql(widgetType),
      );
    }
    if (!nullToAbsent || configJson != null) {
      map['config_json'] = Variable<String>(configJson);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  DashboardWidgetsCompanion toCompanion(bool nullToAbsent) {
    return DashboardWidgetsCompanion(
      id: Value(id),
      dashboardId: Value(dashboardId),
      position: Value(position),
      widgetType: Value(widgetType),
      configJson: configJson == null && nullToAbsent
          ? const Value.absent()
          : Value(configJson),
      createdAt: Value(createdAt),
    );
  }

  factory DashboardWidget.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DashboardWidget(
      id: serializer.fromJson<int>(json['id']),
      dashboardId: serializer.fromJson<int>(json['dashboardId']),
      position: serializer.fromJson<int>(json['position']),
      widgetType: serializer.fromJson<DashboardWidgetType>(json['widgetType']),
      configJson: serializer.fromJson<String?>(json['configJson']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'dashboardId': serializer.toJson<int>(dashboardId),
      'position': serializer.toJson<int>(position),
      'widgetType': serializer.toJson<DashboardWidgetType>(widgetType),
      'configJson': serializer.toJson<String?>(configJson),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  DashboardWidget copyWith({
    int? id,
    int? dashboardId,
    int? position,
    DashboardWidgetType? widgetType,
    Value<String?> configJson = const Value.absent(),
    DateTime? createdAt,
  }) => DashboardWidget(
    id: id ?? this.id,
    dashboardId: dashboardId ?? this.dashboardId,
    position: position ?? this.position,
    widgetType: widgetType ?? this.widgetType,
    configJson: configJson.present ? configJson.value : this.configJson,
    createdAt: createdAt ?? this.createdAt,
  );
  DashboardWidget copyWithCompanion(DashboardWidgetsCompanion data) {
    return DashboardWidget(
      id: data.id.present ? data.id.value : this.id,
      dashboardId: data.dashboardId.present
          ? data.dashboardId.value
          : this.dashboardId,
      position: data.position.present ? data.position.value : this.position,
      widgetType: data.widgetType.present
          ? data.widgetType.value
          : this.widgetType,
      configJson: data.configJson.present
          ? data.configJson.value
          : this.configJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DashboardWidget(')
          ..write('id: $id, ')
          ..write('dashboardId: $dashboardId, ')
          ..write('position: $position, ')
          ..write('widgetType: $widgetType, ')
          ..write('configJson: $configJson, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, dashboardId, position, widgetType, configJson, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DashboardWidget &&
          other.id == this.id &&
          other.dashboardId == this.dashboardId &&
          other.position == this.position &&
          other.widgetType == this.widgetType &&
          other.configJson == this.configJson &&
          other.createdAt == this.createdAt);
}

class DashboardWidgetsCompanion extends UpdateCompanion<DashboardWidget> {
  final Value<int> id;
  final Value<int> dashboardId;
  final Value<int> position;
  final Value<DashboardWidgetType> widgetType;
  final Value<String?> configJson;
  final Value<DateTime> createdAt;
  const DashboardWidgetsCompanion({
    this.id = const Value.absent(),
    this.dashboardId = const Value.absent(),
    this.position = const Value.absent(),
    this.widgetType = const Value.absent(),
    this.configJson = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  DashboardWidgetsCompanion.insert({
    this.id = const Value.absent(),
    required int dashboardId,
    required int position,
    required DashboardWidgetType widgetType,
    this.configJson = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : dashboardId = Value(dashboardId),
       position = Value(position),
       widgetType = Value(widgetType);
  static Insertable<DashboardWidget> custom({
    Expression<int>? id,
    Expression<int>? dashboardId,
    Expression<int>? position,
    Expression<String>? widgetType,
    Expression<String>? configJson,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (dashboardId != null) 'dashboard_id': dashboardId,
      if (position != null) 'position': position,
      if (widgetType != null) 'widget_type': widgetType,
      if (configJson != null) 'config_json': configJson,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  DashboardWidgetsCompanion copyWith({
    Value<int>? id,
    Value<int>? dashboardId,
    Value<int>? position,
    Value<DashboardWidgetType>? widgetType,
    Value<String?>? configJson,
    Value<DateTime>? createdAt,
  }) {
    return DashboardWidgetsCompanion(
      id: id ?? this.id,
      dashboardId: dashboardId ?? this.dashboardId,
      position: position ?? this.position,
      widgetType: widgetType ?? this.widgetType,
      configJson: configJson ?? this.configJson,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (dashboardId.present) {
      map['dashboard_id'] = Variable<int>(dashboardId.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (widgetType.present) {
      map['widget_type'] = Variable<String>(
        $DashboardWidgetsTable.$converterwidgetType.toSql(widgetType.value),
      );
    }
    if (configJson.present) {
      map['config_json'] = Variable<String>(configJson.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DashboardWidgetsCompanion(')
          ..write('id: $id, ')
          ..write('dashboardId: $dashboardId, ')
          ..write('position: $position, ')
          ..write('widgetType: $widgetType, ')
          ..write('configJson: $configJson, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $FoldersTable folders = $FoldersTable(this);
  late final $ConnectionsTable connections = $ConnectionsTable(this);
  late final $FavoritesTable favorites = $FavoritesTable(this);
  late final $FavoriteFoldersTable favoriteFolders = $FavoriteFoldersTable(
    this,
  );
  late final $FavoriteFolderAssignmentsTable favoriteFolderAssignments =
      $FavoriteFolderAssignmentsTable(this);
  late final $CachedPointsTable cachedPoints = $CachedPointsTable(this);
  late final $CachedDeviceInfoTable cachedDeviceInfo = $CachedDeviceInfoTable(
    this,
  );
  late final $CachedTrendLogMappingTable cachedTrendLogMapping =
      $CachedTrendLogMappingTable(this);
  late final $CachedObjectsSummaryTable cachedObjectsSummary =
      $CachedObjectsSummaryTable(this);
  late final $SynopticsTable synoptics = $SynopticsTable(this);
  late final $SynopticBindingsTable synopticBindings = $SynopticBindingsTable(
    this,
  );
  late final $DashboardsTable dashboards = $DashboardsTable(this);
  late final $DashboardWidgetsTable dashboardWidgets = $DashboardWidgetsTable(
    this,
  );
  late final Index idxFavoriteFolderAssignmentsFolderId = Index(
    'idx_favorite_folder_assignments_folder_id',
    'CREATE INDEX idx_favorite_folder_assignments_folder_id ON favorite_folder_assignments (folder_id)',
  );
  late final Index idxSynopticsConnectionId = Index(
    'idx_synoptics_connection_id',
    'CREATE INDEX idx_synoptics_connection_id ON synoptics (connection_id)',
  );
  late final Index idxDashboardsConnectionId = Index(
    'idx_dashboards_connection_id',
    'CREATE INDEX idx_dashboards_connection_id ON dashboards (connection_id)',
  );
  late final Index idxDashboardWidgetsDashboardId = Index(
    'idx_dashboard_widgets_dashboard_id',
    'CREATE INDEX idx_dashboard_widgets_dashboard_id ON dashboard_widgets (dashboard_id)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    folders,
    connections,
    favorites,
    favoriteFolders,
    favoriteFolderAssignments,
    cachedPoints,
    cachedDeviceInfo,
    cachedTrendLogMapping,
    cachedObjectsSummary,
    synoptics,
    synopticBindings,
    dashboards,
    dashboardWidgets,
    idxFavoriteFolderAssignmentsFolderId,
    idxSynopticsConnectionId,
    idxDashboardsConnectionId,
    idxDashboardWidgetsDashboardId,
  ];
}

typedef $$FoldersTableCreateCompanionBuilder =
    FoldersCompanion Function({
      Value<int> id,
      required String name,
      Value<String> icon,
      Value<String> color,
      Value<int> sortOrder,
      Value<DateTime> createdAt,
    });
typedef $$FoldersTableUpdateCompanionBuilder =
    FoldersCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String> icon,
      Value<String> color,
      Value<int> sortOrder,
      Value<DateTime> createdAt,
    });

final class $$FoldersTableReferences
    extends BaseReferences<_$AppDatabase, $FoldersTable, Folder> {
  $$FoldersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$ConnectionsTable, List<Connection>>
  _connectionsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.connections,
    aliasName: $_aliasNameGenerator(db.folders.id, db.connections.folderId),
  );

  $$ConnectionsTableProcessedTableManager get connectionsRefs {
    final manager = $$ConnectionsTableTableManager(
      $_db,
      $_db.connections,
    ).filter((f) => f.folderId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_connectionsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$FoldersTableFilterComposer
    extends Composer<_$AppDatabase, $FoldersTable> {
  $$FoldersTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> connectionsRefs(
    Expression<bool> Function($$ConnectionsTableFilterComposer f) f,
  ) {
    final $$ConnectionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.connections,
      getReferencedColumn: (t) => t.folderId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ConnectionsTableFilterComposer(
            $db: $db,
            $table: $db.connections,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$FoldersTableOrderingComposer
    extends Composer<_$AppDatabase, $FoldersTable> {
  $$FoldersTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FoldersTableAnnotationComposer
    extends Composer<_$AppDatabase, $FoldersTable> {
  $$FoldersTableAnnotationComposer({
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

  GeneratedColumn<String> get icon =>
      $composableBuilder(column: $table.icon, builder: (column) => column);

  GeneratedColumn<String> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> connectionsRefs<T extends Object>(
    Expression<T> Function($$ConnectionsTableAnnotationComposer a) f,
  ) {
    final $$ConnectionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.connections,
      getReferencedColumn: (t) => t.folderId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ConnectionsTableAnnotationComposer(
            $db: $db,
            $table: $db.connections,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$FoldersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FoldersTable,
          Folder,
          $$FoldersTableFilterComposer,
          $$FoldersTableOrderingComposer,
          $$FoldersTableAnnotationComposer,
          $$FoldersTableCreateCompanionBuilder,
          $$FoldersTableUpdateCompanionBuilder,
          (Folder, $$FoldersTableReferences),
          Folder,
          PrefetchHooks Function({bool connectionsRefs})
        > {
  $$FoldersTableTableManager(_$AppDatabase db, $FoldersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FoldersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FoldersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FoldersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> icon = const Value.absent(),
                Value<String> color = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => FoldersCompanion(
                id: id,
                name: name,
                icon: icon,
                color: color,
                sortOrder: sortOrder,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                Value<String> icon = const Value.absent(),
                Value<String> color = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => FoldersCompanion.insert(
                id: id,
                name: name,
                icon: icon,
                color: color,
                sortOrder: sortOrder,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$FoldersTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({connectionsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (connectionsRefs) db.connections],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (connectionsRefs)
                    await $_getPrefetchedData<
                      Folder,
                      $FoldersTable,
                      Connection
                    >(
                      currentTable: table,
                      referencedTable: $$FoldersTableReferences
                          ._connectionsRefsTable(db),
                      managerFromTypedResult: (p0) => $$FoldersTableReferences(
                        db,
                        table,
                        p0,
                      ).connectionsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.folderId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$FoldersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FoldersTable,
      Folder,
      $$FoldersTableFilterComposer,
      $$FoldersTableOrderingComposer,
      $$FoldersTableAnnotationComposer,
      $$FoldersTableCreateCompanionBuilder,
      $$FoldersTableUpdateCompanionBuilder,
      (Folder, $$FoldersTableReferences),
      Folder,
      PrefetchHooks Function({bool connectionsRefs})
    >;
typedef $$ConnectionsTableCreateCompanionBuilder =
    ConnectionsCompanion Function({
      Value<int> id,
      Value<int?> folderId,
      required String name,
      required String host,
      Value<int> port,
      Value<bool> useHttps,
      required String username,
      required String passwordKey,
      Value<String?> apiVersion,
      Value<String?> modelName,
      Value<String?> certificateFingerprint,
      Value<String> connectionType,
      Value<int?> bacnetDeviceId,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> lastConnectedAt,
      Value<String?> designerUrl,
    });
typedef $$ConnectionsTableUpdateCompanionBuilder =
    ConnectionsCompanion Function({
      Value<int> id,
      Value<int?> folderId,
      Value<String> name,
      Value<String> host,
      Value<int> port,
      Value<bool> useHttps,
      Value<String> username,
      Value<String> passwordKey,
      Value<String?> apiVersion,
      Value<String?> modelName,
      Value<String?> certificateFingerprint,
      Value<String> connectionType,
      Value<int?> bacnetDeviceId,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> lastConnectedAt,
      Value<String?> designerUrl,
    });

final class $$ConnectionsTableReferences
    extends BaseReferences<_$AppDatabase, $ConnectionsTable, Connection> {
  $$ConnectionsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $FoldersTable _folderIdTable(_$AppDatabase db) =>
      db.folders.createAlias(
        $_aliasNameGenerator(db.connections.folderId, db.folders.id),
      );

  $$FoldersTableProcessedTableManager? get folderId {
    final $_column = $_itemColumn<int>('folder_id');
    if ($_column == null) return null;
    final manager = $$FoldersTableTableManager(
      $_db,
      $_db.folders,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_folderIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$FavoritesTable, List<Favorite>>
  _favoritesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.favorites,
    aliasName: $_aliasNameGenerator(
      db.connections.id,
      db.favorites.connectionId,
    ),
  );

  $$FavoritesTableProcessedTableManager get favoritesRefs {
    final manager = $$FavoritesTableTableManager(
      $_db,
      $_db.favorites,
    ).filter((f) => f.connectionId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_favoritesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$FavoriteFoldersTable, List<FavoriteFolder>>
  _favoriteFoldersRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.favoriteFolders,
    aliasName: $_aliasNameGenerator(
      db.connections.id,
      db.favoriteFolders.connectionId,
    ),
  );

  $$FavoriteFoldersTableProcessedTableManager get favoriteFoldersRefs {
    final manager = $$FavoriteFoldersTableTableManager(
      $_db,
      $_db.favoriteFolders,
    ).filter((f) => f.connectionId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _favoriteFoldersRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$CachedPointsTable, List<CachedPoint>>
  _cachedPointsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.cachedPoints,
    aliasName: $_aliasNameGenerator(
      db.connections.id,
      db.cachedPoints.connectionId,
    ),
  );

  $$CachedPointsTableProcessedTableManager get cachedPointsRefs {
    final manager = $$CachedPointsTableTableManager(
      $_db,
      $_db.cachedPoints,
    ).filter((f) => f.connectionId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_cachedPointsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$CachedDeviceInfoTable, List<CachedDeviceInfoData>>
  _cachedDeviceInfoRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.cachedDeviceInfo,
    aliasName: $_aliasNameGenerator(
      db.connections.id,
      db.cachedDeviceInfo.connectionId,
    ),
  );

  $$CachedDeviceInfoTableProcessedTableManager get cachedDeviceInfoRefs {
    final manager = $$CachedDeviceInfoTableTableManager(
      $_db,
      $_db.cachedDeviceInfo,
    ).filter((f) => f.connectionId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _cachedDeviceInfoRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $CachedTrendLogMappingTable,
    List<CachedTrendLogMappingData>
  >
  _cachedTrendLogMappingRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.cachedTrendLogMapping,
        aliasName: $_aliasNameGenerator(
          db.connections.id,
          db.cachedTrendLogMapping.connectionId,
        ),
      );

  $$CachedTrendLogMappingTableProcessedTableManager
  get cachedTrendLogMappingRefs {
    final manager = $$CachedTrendLogMappingTableTableManager(
      $_db,
      $_db.cachedTrendLogMapping,
    ).filter((f) => f.connectionId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _cachedTrendLogMappingRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $CachedObjectsSummaryTable,
    List<CachedObjectsSummaryData>
  >
  _cachedObjectsSummaryRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.cachedObjectsSummary,
        aliasName: $_aliasNameGenerator(
          db.connections.id,
          db.cachedObjectsSummary.connectionId,
        ),
      );

  $$CachedObjectsSummaryTableProcessedTableManager
  get cachedObjectsSummaryRefs {
    final manager = $$CachedObjectsSummaryTableTableManager(
      $_db,
      $_db.cachedObjectsSummary,
    ).filter((f) => f.connectionId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _cachedObjectsSummaryRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$DashboardsTable, List<Dashboard>>
  _dashboardsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.dashboards,
    aliasName: $_aliasNameGenerator(
      db.connections.id,
      db.dashboards.connectionId,
    ),
  );

  $$DashboardsTableProcessedTableManager get dashboardsRefs {
    final manager = $$DashboardsTableTableManager(
      $_db,
      $_db.dashboards,
    ).filter((f) => f.connectionId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_dashboardsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ConnectionsTableFilterComposer
    extends Composer<_$AppDatabase, $ConnectionsTable> {
  $$ConnectionsTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get host => $composableBuilder(
    column: $table.host,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get port => $composableBuilder(
    column: $table.port,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get useHttps => $composableBuilder(
    column: $table.useHttps,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get username => $composableBuilder(
    column: $table.username,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get passwordKey => $composableBuilder(
    column: $table.passwordKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get apiVersion => $composableBuilder(
    column: $table.apiVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get modelName => $composableBuilder(
    column: $table.modelName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get certificateFingerprint => $composableBuilder(
    column: $table.certificateFingerprint,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get connectionType => $composableBuilder(
    column: $table.connectionType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get bacnetDeviceId => $composableBuilder(
    column: $table.bacnetDeviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastConnectedAt => $composableBuilder(
    column: $table.lastConnectedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get designerUrl => $composableBuilder(
    column: $table.designerUrl,
    builder: (column) => ColumnFilters(column),
  );

  $$FoldersTableFilterComposer get folderId {
    final $$FoldersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.folderId,
      referencedTable: $db.folders,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FoldersTableFilterComposer(
            $db: $db,
            $table: $db.folders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> favoritesRefs(
    Expression<bool> Function($$FavoritesTableFilterComposer f) f,
  ) {
    final $$FavoritesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.favorites,
      getReferencedColumn: (t) => t.connectionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FavoritesTableFilterComposer(
            $db: $db,
            $table: $db.favorites,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> favoriteFoldersRefs(
    Expression<bool> Function($$FavoriteFoldersTableFilterComposer f) f,
  ) {
    final $$FavoriteFoldersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.favoriteFolders,
      getReferencedColumn: (t) => t.connectionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FavoriteFoldersTableFilterComposer(
            $db: $db,
            $table: $db.favoriteFolders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> cachedPointsRefs(
    Expression<bool> Function($$CachedPointsTableFilterComposer f) f,
  ) {
    final $$CachedPointsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.cachedPoints,
      getReferencedColumn: (t) => t.connectionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CachedPointsTableFilterComposer(
            $db: $db,
            $table: $db.cachedPoints,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> cachedDeviceInfoRefs(
    Expression<bool> Function($$CachedDeviceInfoTableFilterComposer f) f,
  ) {
    final $$CachedDeviceInfoTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.cachedDeviceInfo,
      getReferencedColumn: (t) => t.connectionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CachedDeviceInfoTableFilterComposer(
            $db: $db,
            $table: $db.cachedDeviceInfo,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> cachedTrendLogMappingRefs(
    Expression<bool> Function($$CachedTrendLogMappingTableFilterComposer f) f,
  ) {
    final $$CachedTrendLogMappingTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.cachedTrendLogMapping,
          getReferencedColumn: (t) => t.connectionId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$CachedTrendLogMappingTableFilterComposer(
                $db: $db,
                $table: $db.cachedTrendLogMapping,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<bool> cachedObjectsSummaryRefs(
    Expression<bool> Function($$CachedObjectsSummaryTableFilterComposer f) f,
  ) {
    final $$CachedObjectsSummaryTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.cachedObjectsSummary,
      getReferencedColumn: (t) => t.connectionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CachedObjectsSummaryTableFilterComposer(
            $db: $db,
            $table: $db.cachedObjectsSummary,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> dashboardsRefs(
    Expression<bool> Function($$DashboardsTableFilterComposer f) f,
  ) {
    final $$DashboardsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.dashboards,
      getReferencedColumn: (t) => t.connectionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DashboardsTableFilterComposer(
            $db: $db,
            $table: $db.dashboards,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ConnectionsTableOrderingComposer
    extends Composer<_$AppDatabase, $ConnectionsTable> {
  $$ConnectionsTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get host => $composableBuilder(
    column: $table.host,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get port => $composableBuilder(
    column: $table.port,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get useHttps => $composableBuilder(
    column: $table.useHttps,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get username => $composableBuilder(
    column: $table.username,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get passwordKey => $composableBuilder(
    column: $table.passwordKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get apiVersion => $composableBuilder(
    column: $table.apiVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get modelName => $composableBuilder(
    column: $table.modelName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get certificateFingerprint => $composableBuilder(
    column: $table.certificateFingerprint,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get connectionType => $composableBuilder(
    column: $table.connectionType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get bacnetDeviceId => $composableBuilder(
    column: $table.bacnetDeviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastConnectedAt => $composableBuilder(
    column: $table.lastConnectedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get designerUrl => $composableBuilder(
    column: $table.designerUrl,
    builder: (column) => ColumnOrderings(column),
  );

  $$FoldersTableOrderingComposer get folderId {
    final $$FoldersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.folderId,
      referencedTable: $db.folders,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FoldersTableOrderingComposer(
            $db: $db,
            $table: $db.folders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ConnectionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ConnectionsTable> {
  $$ConnectionsTableAnnotationComposer({
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

  GeneratedColumn<String> get host =>
      $composableBuilder(column: $table.host, builder: (column) => column);

  GeneratedColumn<int> get port =>
      $composableBuilder(column: $table.port, builder: (column) => column);

  GeneratedColumn<bool> get useHttps =>
      $composableBuilder(column: $table.useHttps, builder: (column) => column);

  GeneratedColumn<String> get username =>
      $composableBuilder(column: $table.username, builder: (column) => column);

  GeneratedColumn<String> get passwordKey => $composableBuilder(
    column: $table.passwordKey,
    builder: (column) => column,
  );

  GeneratedColumn<String> get apiVersion => $composableBuilder(
    column: $table.apiVersion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get modelName =>
      $composableBuilder(column: $table.modelName, builder: (column) => column);

  GeneratedColumn<String> get certificateFingerprint => $composableBuilder(
    column: $table.certificateFingerprint,
    builder: (column) => column,
  );

  GeneratedColumn<String> get connectionType => $composableBuilder(
    column: $table.connectionType,
    builder: (column) => column,
  );

  GeneratedColumn<int> get bacnetDeviceId => $composableBuilder(
    column: $table.bacnetDeviceId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastConnectedAt => $composableBuilder(
    column: $table.lastConnectedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get designerUrl => $composableBuilder(
    column: $table.designerUrl,
    builder: (column) => column,
  );

  $$FoldersTableAnnotationComposer get folderId {
    final $$FoldersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.folderId,
      referencedTable: $db.folders,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FoldersTableAnnotationComposer(
            $db: $db,
            $table: $db.folders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> favoritesRefs<T extends Object>(
    Expression<T> Function($$FavoritesTableAnnotationComposer a) f,
  ) {
    final $$FavoritesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.favorites,
      getReferencedColumn: (t) => t.connectionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FavoritesTableAnnotationComposer(
            $db: $db,
            $table: $db.favorites,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> favoriteFoldersRefs<T extends Object>(
    Expression<T> Function($$FavoriteFoldersTableAnnotationComposer a) f,
  ) {
    final $$FavoriteFoldersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.favoriteFolders,
      getReferencedColumn: (t) => t.connectionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FavoriteFoldersTableAnnotationComposer(
            $db: $db,
            $table: $db.favoriteFolders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> cachedPointsRefs<T extends Object>(
    Expression<T> Function($$CachedPointsTableAnnotationComposer a) f,
  ) {
    final $$CachedPointsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.cachedPoints,
      getReferencedColumn: (t) => t.connectionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CachedPointsTableAnnotationComposer(
            $db: $db,
            $table: $db.cachedPoints,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> cachedDeviceInfoRefs<T extends Object>(
    Expression<T> Function($$CachedDeviceInfoTableAnnotationComposer a) f,
  ) {
    final $$CachedDeviceInfoTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.cachedDeviceInfo,
      getReferencedColumn: (t) => t.connectionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CachedDeviceInfoTableAnnotationComposer(
            $db: $db,
            $table: $db.cachedDeviceInfo,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> cachedTrendLogMappingRefs<T extends Object>(
    Expression<T> Function($$CachedTrendLogMappingTableAnnotationComposer a) f,
  ) {
    final $$CachedTrendLogMappingTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.cachedTrendLogMapping,
          getReferencedColumn: (t) => t.connectionId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$CachedTrendLogMappingTableAnnotationComposer(
                $db: $db,
                $table: $db.cachedTrendLogMapping,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> cachedObjectsSummaryRefs<T extends Object>(
    Expression<T> Function($$CachedObjectsSummaryTableAnnotationComposer a) f,
  ) {
    final $$CachedObjectsSummaryTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.cachedObjectsSummary,
          getReferencedColumn: (t) => t.connectionId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$CachedObjectsSummaryTableAnnotationComposer(
                $db: $db,
                $table: $db.cachedObjectsSummary,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> dashboardsRefs<T extends Object>(
    Expression<T> Function($$DashboardsTableAnnotationComposer a) f,
  ) {
    final $$DashboardsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.dashboards,
      getReferencedColumn: (t) => t.connectionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DashboardsTableAnnotationComposer(
            $db: $db,
            $table: $db.dashboards,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ConnectionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ConnectionsTable,
          Connection,
          $$ConnectionsTableFilterComposer,
          $$ConnectionsTableOrderingComposer,
          $$ConnectionsTableAnnotationComposer,
          $$ConnectionsTableCreateCompanionBuilder,
          $$ConnectionsTableUpdateCompanionBuilder,
          (Connection, $$ConnectionsTableReferences),
          Connection,
          PrefetchHooks Function({
            bool folderId,
            bool favoritesRefs,
            bool favoriteFoldersRefs,
            bool cachedPointsRefs,
            bool cachedDeviceInfoRefs,
            bool cachedTrendLogMappingRefs,
            bool cachedObjectsSummaryRefs,
            bool dashboardsRefs,
          })
        > {
  $$ConnectionsTableTableManager(_$AppDatabase db, $ConnectionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ConnectionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ConnectionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ConnectionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> folderId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> host = const Value.absent(),
                Value<int> port = const Value.absent(),
                Value<bool> useHttps = const Value.absent(),
                Value<String> username = const Value.absent(),
                Value<String> passwordKey = const Value.absent(),
                Value<String?> apiVersion = const Value.absent(),
                Value<String?> modelName = const Value.absent(),
                Value<String?> certificateFingerprint = const Value.absent(),
                Value<String> connectionType = const Value.absent(),
                Value<int?> bacnetDeviceId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> lastConnectedAt = const Value.absent(),
                Value<String?> designerUrl = const Value.absent(),
              }) => ConnectionsCompanion(
                id: id,
                folderId: folderId,
                name: name,
                host: host,
                port: port,
                useHttps: useHttps,
                username: username,
                passwordKey: passwordKey,
                apiVersion: apiVersion,
                modelName: modelName,
                certificateFingerprint: certificateFingerprint,
                connectionType: connectionType,
                bacnetDeviceId: bacnetDeviceId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                lastConnectedAt: lastConnectedAt,
                designerUrl: designerUrl,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> folderId = const Value.absent(),
                required String name,
                required String host,
                Value<int> port = const Value.absent(),
                Value<bool> useHttps = const Value.absent(),
                required String username,
                required String passwordKey,
                Value<String?> apiVersion = const Value.absent(),
                Value<String?> modelName = const Value.absent(),
                Value<String?> certificateFingerprint = const Value.absent(),
                Value<String> connectionType = const Value.absent(),
                Value<int?> bacnetDeviceId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> lastConnectedAt = const Value.absent(),
                Value<String?> designerUrl = const Value.absent(),
              }) => ConnectionsCompanion.insert(
                id: id,
                folderId: folderId,
                name: name,
                host: host,
                port: port,
                useHttps: useHttps,
                username: username,
                passwordKey: passwordKey,
                apiVersion: apiVersion,
                modelName: modelName,
                certificateFingerprint: certificateFingerprint,
                connectionType: connectionType,
                bacnetDeviceId: bacnetDeviceId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                lastConnectedAt: lastConnectedAt,
                designerUrl: designerUrl,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ConnectionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                folderId = false,
                favoritesRefs = false,
                favoriteFoldersRefs = false,
                cachedPointsRefs = false,
                cachedDeviceInfoRefs = false,
                cachedTrendLogMappingRefs = false,
                cachedObjectsSummaryRefs = false,
                dashboardsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (favoritesRefs) db.favorites,
                    if (favoriteFoldersRefs) db.favoriteFolders,
                    if (cachedPointsRefs) db.cachedPoints,
                    if (cachedDeviceInfoRefs) db.cachedDeviceInfo,
                    if (cachedTrendLogMappingRefs) db.cachedTrendLogMapping,
                    if (cachedObjectsSummaryRefs) db.cachedObjectsSummary,
                    if (dashboardsRefs) db.dashboards,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (folderId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.folderId,
                                    referencedTable:
                                        $$ConnectionsTableReferences
                                            ._folderIdTable(db),
                                    referencedColumn:
                                        $$ConnectionsTableReferences
                                            ._folderIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (favoritesRefs)
                        await $_getPrefetchedData<
                          Connection,
                          $ConnectionsTable,
                          Favorite
                        >(
                          currentTable: table,
                          referencedTable: $$ConnectionsTableReferences
                              ._favoritesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ConnectionsTableReferences(
                                db,
                                table,
                                p0,
                              ).favoritesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.connectionId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (favoriteFoldersRefs)
                        await $_getPrefetchedData<
                          Connection,
                          $ConnectionsTable,
                          FavoriteFolder
                        >(
                          currentTable: table,
                          referencedTable: $$ConnectionsTableReferences
                              ._favoriteFoldersRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ConnectionsTableReferences(
                                db,
                                table,
                                p0,
                              ).favoriteFoldersRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.connectionId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (cachedPointsRefs)
                        await $_getPrefetchedData<
                          Connection,
                          $ConnectionsTable,
                          CachedPoint
                        >(
                          currentTable: table,
                          referencedTable: $$ConnectionsTableReferences
                              ._cachedPointsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ConnectionsTableReferences(
                                db,
                                table,
                                p0,
                              ).cachedPointsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.connectionId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (cachedDeviceInfoRefs)
                        await $_getPrefetchedData<
                          Connection,
                          $ConnectionsTable,
                          CachedDeviceInfoData
                        >(
                          currentTable: table,
                          referencedTable: $$ConnectionsTableReferences
                              ._cachedDeviceInfoRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ConnectionsTableReferences(
                                db,
                                table,
                                p0,
                              ).cachedDeviceInfoRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.connectionId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (cachedTrendLogMappingRefs)
                        await $_getPrefetchedData<
                          Connection,
                          $ConnectionsTable,
                          CachedTrendLogMappingData
                        >(
                          currentTable: table,
                          referencedTable: $$ConnectionsTableReferences
                              ._cachedTrendLogMappingRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ConnectionsTableReferences(
                                db,
                                table,
                                p0,
                              ).cachedTrendLogMappingRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.connectionId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (cachedObjectsSummaryRefs)
                        await $_getPrefetchedData<
                          Connection,
                          $ConnectionsTable,
                          CachedObjectsSummaryData
                        >(
                          currentTable: table,
                          referencedTable: $$ConnectionsTableReferences
                              ._cachedObjectsSummaryRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ConnectionsTableReferences(
                                db,
                                table,
                                p0,
                              ).cachedObjectsSummaryRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.connectionId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (dashboardsRefs)
                        await $_getPrefetchedData<
                          Connection,
                          $ConnectionsTable,
                          Dashboard
                        >(
                          currentTable: table,
                          referencedTable: $$ConnectionsTableReferences
                              ._dashboardsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ConnectionsTableReferences(
                                db,
                                table,
                                p0,
                              ).dashboardsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.connectionId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$ConnectionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ConnectionsTable,
      Connection,
      $$ConnectionsTableFilterComposer,
      $$ConnectionsTableOrderingComposer,
      $$ConnectionsTableAnnotationComposer,
      $$ConnectionsTableCreateCompanionBuilder,
      $$ConnectionsTableUpdateCompanionBuilder,
      (Connection, $$ConnectionsTableReferences),
      Connection,
      PrefetchHooks Function({
        bool folderId,
        bool favoritesRefs,
        bool favoriteFoldersRefs,
        bool cachedPointsRefs,
        bool cachedDeviceInfoRefs,
        bool cachedTrendLogMappingRefs,
        bool cachedObjectsSummaryRefs,
        bool dashboardsRefs,
      })
    >;
typedef $$FavoritesTableCreateCompanionBuilder =
    FavoritesCompanion Function({
      Value<int> id,
      required int connectionId,
      required String pointRef,
      required String pointName,
      Value<String?> pointDescription,
      required String objectType,
      Value<int> sortOrder,
      Value<bool> isSuperFavorite,
      Value<bool> wasPromoted,
      Value<DateTime> createdAt,
    });
typedef $$FavoritesTableUpdateCompanionBuilder =
    FavoritesCompanion Function({
      Value<int> id,
      Value<int> connectionId,
      Value<String> pointRef,
      Value<String> pointName,
      Value<String?> pointDescription,
      Value<String> objectType,
      Value<int> sortOrder,
      Value<bool> isSuperFavorite,
      Value<bool> wasPromoted,
      Value<DateTime> createdAt,
    });

final class $$FavoritesTableReferences
    extends BaseReferences<_$AppDatabase, $FavoritesTable, Favorite> {
  $$FavoritesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ConnectionsTable _connectionIdTable(_$AppDatabase db) =>
      db.connections.createAlias(
        $_aliasNameGenerator(db.favorites.connectionId, db.connections.id),
      );

  $$ConnectionsTableProcessedTableManager get connectionId {
    final $_column = $_itemColumn<int>('connection_id')!;

    final manager = $$ConnectionsTableTableManager(
      $_db,
      $_db.connections,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_connectionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<
    $FavoriteFolderAssignmentsTable,
    List<FavoriteFolderAssignment>
  >
  _favoriteFolderAssignmentsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.favoriteFolderAssignments,
        aliasName: $_aliasNameGenerator(
          db.favorites.id,
          db.favoriteFolderAssignments.favoriteId,
        ),
      );

  $$FavoriteFolderAssignmentsTableProcessedTableManager
  get favoriteFolderAssignmentsRefs {
    final manager = $$FavoriteFolderAssignmentsTableTableManager(
      $_db,
      $_db.favoriteFolderAssignments,
    ).filter((f) => f.favoriteId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _favoriteFolderAssignmentsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$FavoritesTableFilterComposer
    extends Composer<_$AppDatabase, $FavoritesTable> {
  $$FavoritesTableFilterComposer({
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

  ColumnFilters<String> get pointRef => $composableBuilder(
    column: $table.pointRef,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pointName => $composableBuilder(
    column: $table.pointName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pointDescription => $composableBuilder(
    column: $table.pointDescription,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get objectType => $composableBuilder(
    column: $table.objectType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isSuperFavorite => $composableBuilder(
    column: $table.isSuperFavorite,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get wasPromoted => $composableBuilder(
    column: $table.wasPromoted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$ConnectionsTableFilterComposer get connectionId {
    final $$ConnectionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.connectionId,
      referencedTable: $db.connections,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ConnectionsTableFilterComposer(
            $db: $db,
            $table: $db.connections,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> favoriteFolderAssignmentsRefs(
    Expression<bool> Function($$FavoriteFolderAssignmentsTableFilterComposer f)
    f,
  ) {
    final $$FavoriteFolderAssignmentsTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.favoriteFolderAssignments,
          getReferencedColumn: (t) => t.favoriteId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$FavoriteFolderAssignmentsTableFilterComposer(
                $db: $db,
                $table: $db.favoriteFolderAssignments,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$FavoritesTableOrderingComposer
    extends Composer<_$AppDatabase, $FavoritesTable> {
  $$FavoritesTableOrderingComposer({
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

  ColumnOrderings<String> get pointRef => $composableBuilder(
    column: $table.pointRef,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pointName => $composableBuilder(
    column: $table.pointName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pointDescription => $composableBuilder(
    column: $table.pointDescription,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get objectType => $composableBuilder(
    column: $table.objectType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isSuperFavorite => $composableBuilder(
    column: $table.isSuperFavorite,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get wasPromoted => $composableBuilder(
    column: $table.wasPromoted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$ConnectionsTableOrderingComposer get connectionId {
    final $$ConnectionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.connectionId,
      referencedTable: $db.connections,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ConnectionsTableOrderingComposer(
            $db: $db,
            $table: $db.connections,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FavoritesTableAnnotationComposer
    extends Composer<_$AppDatabase, $FavoritesTable> {
  $$FavoritesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get pointRef =>
      $composableBuilder(column: $table.pointRef, builder: (column) => column);

  GeneratedColumn<String> get pointName =>
      $composableBuilder(column: $table.pointName, builder: (column) => column);

  GeneratedColumn<String> get pointDescription => $composableBuilder(
    column: $table.pointDescription,
    builder: (column) => column,
  );

  GeneratedColumn<String> get objectType => $composableBuilder(
    column: $table.objectType,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<bool> get isSuperFavorite => $composableBuilder(
    column: $table.isSuperFavorite,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get wasPromoted => $composableBuilder(
    column: $table.wasPromoted,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$ConnectionsTableAnnotationComposer get connectionId {
    final $$ConnectionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.connectionId,
      referencedTable: $db.connections,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ConnectionsTableAnnotationComposer(
            $db: $db,
            $table: $db.connections,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> favoriteFolderAssignmentsRefs<T extends Object>(
    Expression<T> Function($$FavoriteFolderAssignmentsTableAnnotationComposer a)
    f,
  ) {
    final $$FavoriteFolderAssignmentsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.favoriteFolderAssignments,
          getReferencedColumn: (t) => t.favoriteId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$FavoriteFolderAssignmentsTableAnnotationComposer(
                $db: $db,
                $table: $db.favoriteFolderAssignments,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$FavoritesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FavoritesTable,
          Favorite,
          $$FavoritesTableFilterComposer,
          $$FavoritesTableOrderingComposer,
          $$FavoritesTableAnnotationComposer,
          $$FavoritesTableCreateCompanionBuilder,
          $$FavoritesTableUpdateCompanionBuilder,
          (Favorite, $$FavoritesTableReferences),
          Favorite,
          PrefetchHooks Function({
            bool connectionId,
            bool favoriteFolderAssignmentsRefs,
          })
        > {
  $$FavoritesTableTableManager(_$AppDatabase db, $FavoritesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FavoritesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FavoritesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FavoritesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> connectionId = const Value.absent(),
                Value<String> pointRef = const Value.absent(),
                Value<String> pointName = const Value.absent(),
                Value<String?> pointDescription = const Value.absent(),
                Value<String> objectType = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<bool> isSuperFavorite = const Value.absent(),
                Value<bool> wasPromoted = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => FavoritesCompanion(
                id: id,
                connectionId: connectionId,
                pointRef: pointRef,
                pointName: pointName,
                pointDescription: pointDescription,
                objectType: objectType,
                sortOrder: sortOrder,
                isSuperFavorite: isSuperFavorite,
                wasPromoted: wasPromoted,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int connectionId,
                required String pointRef,
                required String pointName,
                Value<String?> pointDescription = const Value.absent(),
                required String objectType,
                Value<int> sortOrder = const Value.absent(),
                Value<bool> isSuperFavorite = const Value.absent(),
                Value<bool> wasPromoted = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => FavoritesCompanion.insert(
                id: id,
                connectionId: connectionId,
                pointRef: pointRef,
                pointName: pointName,
                pointDescription: pointDescription,
                objectType: objectType,
                sortOrder: sortOrder,
                isSuperFavorite: isSuperFavorite,
                wasPromoted: wasPromoted,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$FavoritesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({connectionId = false, favoriteFolderAssignmentsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (favoriteFolderAssignmentsRefs)
                      db.favoriteFolderAssignments,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (connectionId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.connectionId,
                                    referencedTable: $$FavoritesTableReferences
                                        ._connectionIdTable(db),
                                    referencedColumn: $$FavoritesTableReferences
                                        ._connectionIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (favoriteFolderAssignmentsRefs)
                        await $_getPrefetchedData<
                          Favorite,
                          $FavoritesTable,
                          FavoriteFolderAssignment
                        >(
                          currentTable: table,
                          referencedTable: $$FavoritesTableReferences
                              ._favoriteFolderAssignmentsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$FavoritesTableReferences(
                                db,
                                table,
                                p0,
                              ).favoriteFolderAssignmentsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.favoriteId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$FavoritesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FavoritesTable,
      Favorite,
      $$FavoritesTableFilterComposer,
      $$FavoritesTableOrderingComposer,
      $$FavoritesTableAnnotationComposer,
      $$FavoritesTableCreateCompanionBuilder,
      $$FavoritesTableUpdateCompanionBuilder,
      (Favorite, $$FavoritesTableReferences),
      Favorite,
      PrefetchHooks Function({
        bool connectionId,
        bool favoriteFolderAssignmentsRefs,
      })
    >;
typedef $$FavoriteFoldersTableCreateCompanionBuilder =
    FavoriteFoldersCompanion Function({
      Value<int> id,
      required int connectionId,
      required String name,
      Value<String> color,
      Value<String> icon,
      Value<int> sortOrder,
      Value<DateTime> createdAt,
    });
typedef $$FavoriteFoldersTableUpdateCompanionBuilder =
    FavoriteFoldersCompanion Function({
      Value<int> id,
      Value<int> connectionId,
      Value<String> name,
      Value<String> color,
      Value<String> icon,
      Value<int> sortOrder,
      Value<DateTime> createdAt,
    });

final class $$FavoriteFoldersTableReferences
    extends
        BaseReferences<_$AppDatabase, $FavoriteFoldersTable, FavoriteFolder> {
  $$FavoriteFoldersTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ConnectionsTable _connectionIdTable(_$AppDatabase db) =>
      db.connections.createAlias(
        $_aliasNameGenerator(
          db.favoriteFolders.connectionId,
          db.connections.id,
        ),
      );

  $$ConnectionsTableProcessedTableManager get connectionId {
    final $_column = $_itemColumn<int>('connection_id')!;

    final manager = $$ConnectionsTableTableManager(
      $_db,
      $_db.connections,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_connectionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<
    $FavoriteFolderAssignmentsTable,
    List<FavoriteFolderAssignment>
  >
  _favoriteFolderAssignmentsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.favoriteFolderAssignments,
        aliasName: $_aliasNameGenerator(
          db.favoriteFolders.id,
          db.favoriteFolderAssignments.folderId,
        ),
      );

  $$FavoriteFolderAssignmentsTableProcessedTableManager
  get favoriteFolderAssignmentsRefs {
    final manager = $$FavoriteFolderAssignmentsTableTableManager(
      $_db,
      $_db.favoriteFolderAssignments,
    ).filter((f) => f.folderId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _favoriteFolderAssignmentsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$FavoriteFoldersTableFilterComposer
    extends Composer<_$AppDatabase, $FavoriteFoldersTable> {
  $$FavoriteFoldersTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$ConnectionsTableFilterComposer get connectionId {
    final $$ConnectionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.connectionId,
      referencedTable: $db.connections,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ConnectionsTableFilterComposer(
            $db: $db,
            $table: $db.connections,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> favoriteFolderAssignmentsRefs(
    Expression<bool> Function($$FavoriteFolderAssignmentsTableFilterComposer f)
    f,
  ) {
    final $$FavoriteFolderAssignmentsTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.favoriteFolderAssignments,
          getReferencedColumn: (t) => t.folderId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$FavoriteFolderAssignmentsTableFilterComposer(
                $db: $db,
                $table: $db.favoriteFolderAssignments,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$FavoriteFoldersTableOrderingComposer
    extends Composer<_$AppDatabase, $FavoriteFoldersTable> {
  $$FavoriteFoldersTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$ConnectionsTableOrderingComposer get connectionId {
    final $$ConnectionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.connectionId,
      referencedTable: $db.connections,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ConnectionsTableOrderingComposer(
            $db: $db,
            $table: $db.connections,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FavoriteFoldersTableAnnotationComposer
    extends Composer<_$AppDatabase, $FavoriteFoldersTable> {
  $$FavoriteFoldersTableAnnotationComposer({
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

  GeneratedColumn<String> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumn<String> get icon =>
      $composableBuilder(column: $table.icon, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$ConnectionsTableAnnotationComposer get connectionId {
    final $$ConnectionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.connectionId,
      referencedTable: $db.connections,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ConnectionsTableAnnotationComposer(
            $db: $db,
            $table: $db.connections,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> favoriteFolderAssignmentsRefs<T extends Object>(
    Expression<T> Function($$FavoriteFolderAssignmentsTableAnnotationComposer a)
    f,
  ) {
    final $$FavoriteFolderAssignmentsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.favoriteFolderAssignments,
          getReferencedColumn: (t) => t.folderId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$FavoriteFolderAssignmentsTableAnnotationComposer(
                $db: $db,
                $table: $db.favoriteFolderAssignments,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$FavoriteFoldersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FavoriteFoldersTable,
          FavoriteFolder,
          $$FavoriteFoldersTableFilterComposer,
          $$FavoriteFoldersTableOrderingComposer,
          $$FavoriteFoldersTableAnnotationComposer,
          $$FavoriteFoldersTableCreateCompanionBuilder,
          $$FavoriteFoldersTableUpdateCompanionBuilder,
          (FavoriteFolder, $$FavoriteFoldersTableReferences),
          FavoriteFolder,
          PrefetchHooks Function({
            bool connectionId,
            bool favoriteFolderAssignmentsRefs,
          })
        > {
  $$FavoriteFoldersTableTableManager(
    _$AppDatabase db,
    $FavoriteFoldersTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FavoriteFoldersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FavoriteFoldersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FavoriteFoldersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> connectionId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> color = const Value.absent(),
                Value<String> icon = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => FavoriteFoldersCompanion(
                id: id,
                connectionId: connectionId,
                name: name,
                color: color,
                icon: icon,
                sortOrder: sortOrder,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int connectionId,
                required String name,
                Value<String> color = const Value.absent(),
                Value<String> icon = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => FavoriteFoldersCompanion.insert(
                id: id,
                connectionId: connectionId,
                name: name,
                color: color,
                icon: icon,
                sortOrder: sortOrder,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$FavoriteFoldersTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({connectionId = false, favoriteFolderAssignmentsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (favoriteFolderAssignmentsRefs)
                      db.favoriteFolderAssignments,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (connectionId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.connectionId,
                                    referencedTable:
                                        $$FavoriteFoldersTableReferences
                                            ._connectionIdTable(db),
                                    referencedColumn:
                                        $$FavoriteFoldersTableReferences
                                            ._connectionIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (favoriteFolderAssignmentsRefs)
                        await $_getPrefetchedData<
                          FavoriteFolder,
                          $FavoriteFoldersTable,
                          FavoriteFolderAssignment
                        >(
                          currentTable: table,
                          referencedTable: $$FavoriteFoldersTableReferences
                              ._favoriteFolderAssignmentsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$FavoriteFoldersTableReferences(
                                db,
                                table,
                                p0,
                              ).favoriteFolderAssignmentsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.folderId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$FavoriteFoldersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FavoriteFoldersTable,
      FavoriteFolder,
      $$FavoriteFoldersTableFilterComposer,
      $$FavoriteFoldersTableOrderingComposer,
      $$FavoriteFoldersTableAnnotationComposer,
      $$FavoriteFoldersTableCreateCompanionBuilder,
      $$FavoriteFoldersTableUpdateCompanionBuilder,
      (FavoriteFolder, $$FavoriteFoldersTableReferences),
      FavoriteFolder,
      PrefetchHooks Function({
        bool connectionId,
        bool favoriteFolderAssignmentsRefs,
      })
    >;
typedef $$FavoriteFolderAssignmentsTableCreateCompanionBuilder =
    FavoriteFolderAssignmentsCompanion Function({
      Value<int> id,
      required int favoriteId,
      required int folderId,
      Value<DateTime> createdAt,
    });
typedef $$FavoriteFolderAssignmentsTableUpdateCompanionBuilder =
    FavoriteFolderAssignmentsCompanion Function({
      Value<int> id,
      Value<int> favoriteId,
      Value<int> folderId,
      Value<DateTime> createdAt,
    });

final class $$FavoriteFolderAssignmentsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $FavoriteFolderAssignmentsTable,
          FavoriteFolderAssignment
        > {
  $$FavoriteFolderAssignmentsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $FavoritesTable _favoriteIdTable(_$AppDatabase db) =>
      db.favorites.createAlias(
        $_aliasNameGenerator(
          db.favoriteFolderAssignments.favoriteId,
          db.favorites.id,
        ),
      );

  $$FavoritesTableProcessedTableManager get favoriteId {
    final $_column = $_itemColumn<int>('favorite_id')!;

    final manager = $$FavoritesTableTableManager(
      $_db,
      $_db.favorites,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_favoriteIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $FavoriteFoldersTable _folderIdTable(_$AppDatabase db) =>
      db.favoriteFolders.createAlias(
        $_aliasNameGenerator(
          db.favoriteFolderAssignments.folderId,
          db.favoriteFolders.id,
        ),
      );

  $$FavoriteFoldersTableProcessedTableManager get folderId {
    final $_column = $_itemColumn<int>('folder_id')!;

    final manager = $$FavoriteFoldersTableTableManager(
      $_db,
      $_db.favoriteFolders,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_folderIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$FavoriteFolderAssignmentsTableFilterComposer
    extends Composer<_$AppDatabase, $FavoriteFolderAssignmentsTable> {
  $$FavoriteFolderAssignmentsTableFilterComposer({
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

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$FavoritesTableFilterComposer get favoriteId {
    final $$FavoritesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.favoriteId,
      referencedTable: $db.favorites,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FavoritesTableFilterComposer(
            $db: $db,
            $table: $db.favorites,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$FavoriteFoldersTableFilterComposer get folderId {
    final $$FavoriteFoldersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.folderId,
      referencedTable: $db.favoriteFolders,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FavoriteFoldersTableFilterComposer(
            $db: $db,
            $table: $db.favoriteFolders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FavoriteFolderAssignmentsTableOrderingComposer
    extends Composer<_$AppDatabase, $FavoriteFolderAssignmentsTable> {
  $$FavoriteFolderAssignmentsTableOrderingComposer({
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

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$FavoritesTableOrderingComposer get favoriteId {
    final $$FavoritesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.favoriteId,
      referencedTable: $db.favorites,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FavoritesTableOrderingComposer(
            $db: $db,
            $table: $db.favorites,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$FavoriteFoldersTableOrderingComposer get folderId {
    final $$FavoriteFoldersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.folderId,
      referencedTable: $db.favoriteFolders,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FavoriteFoldersTableOrderingComposer(
            $db: $db,
            $table: $db.favoriteFolders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FavoriteFolderAssignmentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $FavoriteFolderAssignmentsTable> {
  $$FavoriteFolderAssignmentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$FavoritesTableAnnotationComposer get favoriteId {
    final $$FavoritesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.favoriteId,
      referencedTable: $db.favorites,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FavoritesTableAnnotationComposer(
            $db: $db,
            $table: $db.favorites,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$FavoriteFoldersTableAnnotationComposer get folderId {
    final $$FavoriteFoldersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.folderId,
      referencedTable: $db.favoriteFolders,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FavoriteFoldersTableAnnotationComposer(
            $db: $db,
            $table: $db.favoriteFolders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FavoriteFolderAssignmentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FavoriteFolderAssignmentsTable,
          FavoriteFolderAssignment,
          $$FavoriteFolderAssignmentsTableFilterComposer,
          $$FavoriteFolderAssignmentsTableOrderingComposer,
          $$FavoriteFolderAssignmentsTableAnnotationComposer,
          $$FavoriteFolderAssignmentsTableCreateCompanionBuilder,
          $$FavoriteFolderAssignmentsTableUpdateCompanionBuilder,
          (
            FavoriteFolderAssignment,
            $$FavoriteFolderAssignmentsTableReferences,
          ),
          FavoriteFolderAssignment,
          PrefetchHooks Function({bool favoriteId, bool folderId})
        > {
  $$FavoriteFolderAssignmentsTableTableManager(
    _$AppDatabase db,
    $FavoriteFolderAssignmentsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FavoriteFolderAssignmentsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$FavoriteFolderAssignmentsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$FavoriteFolderAssignmentsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> favoriteId = const Value.absent(),
                Value<int> folderId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => FavoriteFolderAssignmentsCompanion(
                id: id,
                favoriteId: favoriteId,
                folderId: folderId,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int favoriteId,
                required int folderId,
                Value<DateTime> createdAt = const Value.absent(),
              }) => FavoriteFolderAssignmentsCompanion.insert(
                id: id,
                favoriteId: favoriteId,
                folderId: folderId,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$FavoriteFolderAssignmentsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({favoriteId = false, folderId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (favoriteId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.favoriteId,
                                referencedTable:
                                    $$FavoriteFolderAssignmentsTableReferences
                                        ._favoriteIdTable(db),
                                referencedColumn:
                                    $$FavoriteFolderAssignmentsTableReferences
                                        ._favoriteIdTable(db)
                                        .id,
                              )
                              as T;
                    }
                    if (folderId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.folderId,
                                referencedTable:
                                    $$FavoriteFolderAssignmentsTableReferences
                                        ._folderIdTable(db),
                                referencedColumn:
                                    $$FavoriteFolderAssignmentsTableReferences
                                        ._folderIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$FavoriteFolderAssignmentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FavoriteFolderAssignmentsTable,
      FavoriteFolderAssignment,
      $$FavoriteFolderAssignmentsTableFilterComposer,
      $$FavoriteFolderAssignmentsTableOrderingComposer,
      $$FavoriteFolderAssignmentsTableAnnotationComposer,
      $$FavoriteFolderAssignmentsTableCreateCompanionBuilder,
      $$FavoriteFolderAssignmentsTableUpdateCompanionBuilder,
      (FavoriteFolderAssignment, $$FavoriteFolderAssignmentsTableReferences),
      FavoriteFolderAssignment,
      PrefetchHooks Function({bool favoriteId, bool folderId})
    >;
typedef $$CachedPointsTableCreateCompanionBuilder =
    CachedPointsCompanion Function({
      required int connectionId,
      required String pointRef,
      required String objectType,
      required int instance,
      required String objectName,
      Value<String?> units,
      Value<String?> description,
      Value<String?> activeText,
      Value<String?> inactiveText,
      Value<DateTime> cachedAt,
      Value<int> rowid,
    });
typedef $$CachedPointsTableUpdateCompanionBuilder =
    CachedPointsCompanion Function({
      Value<int> connectionId,
      Value<String> pointRef,
      Value<String> objectType,
      Value<int> instance,
      Value<String> objectName,
      Value<String?> units,
      Value<String?> description,
      Value<String?> activeText,
      Value<String?> inactiveText,
      Value<DateTime> cachedAt,
      Value<int> rowid,
    });

final class $$CachedPointsTableReferences
    extends BaseReferences<_$AppDatabase, $CachedPointsTable, CachedPoint> {
  $$CachedPointsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ConnectionsTable _connectionIdTable(_$AppDatabase db) =>
      db.connections.createAlias(
        $_aliasNameGenerator(db.cachedPoints.connectionId, db.connections.id),
      );

  $$ConnectionsTableProcessedTableManager get connectionId {
    final $_column = $_itemColumn<int>('connection_id')!;

    final manager = $$ConnectionsTableTableManager(
      $_db,
      $_db.connections,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_connectionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$CachedPointsTableFilterComposer
    extends Composer<_$AppDatabase, $CachedPointsTable> {
  $$CachedPointsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get pointRef => $composableBuilder(
    column: $table.pointRef,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get objectType => $composableBuilder(
    column: $table.objectType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get instance => $composableBuilder(
    column: $table.instance,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get objectName => $composableBuilder(
    column: $table.objectName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get units => $composableBuilder(
    column: $table.units,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get activeText => $composableBuilder(
    column: $table.activeText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get inactiveText => $composableBuilder(
    column: $table.inactiveText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$ConnectionsTableFilterComposer get connectionId {
    final $$ConnectionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.connectionId,
      referencedTable: $db.connections,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ConnectionsTableFilterComposer(
            $db: $db,
            $table: $db.connections,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CachedPointsTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedPointsTable> {
  $$CachedPointsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get pointRef => $composableBuilder(
    column: $table.pointRef,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get objectType => $composableBuilder(
    column: $table.objectType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get instance => $composableBuilder(
    column: $table.instance,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get objectName => $composableBuilder(
    column: $table.objectName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get units => $composableBuilder(
    column: $table.units,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get activeText => $composableBuilder(
    column: $table.activeText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get inactiveText => $composableBuilder(
    column: $table.inactiveText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$ConnectionsTableOrderingComposer get connectionId {
    final $$ConnectionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.connectionId,
      referencedTable: $db.connections,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ConnectionsTableOrderingComposer(
            $db: $db,
            $table: $db.connections,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CachedPointsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedPointsTable> {
  $$CachedPointsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get pointRef =>
      $composableBuilder(column: $table.pointRef, builder: (column) => column);

  GeneratedColumn<String> get objectType => $composableBuilder(
    column: $table.objectType,
    builder: (column) => column,
  );

  GeneratedColumn<int> get instance =>
      $composableBuilder(column: $table.instance, builder: (column) => column);

  GeneratedColumn<String> get objectName => $composableBuilder(
    column: $table.objectName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get units =>
      $composableBuilder(column: $table.units, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get activeText => $composableBuilder(
    column: $table.activeText,
    builder: (column) => column,
  );

  GeneratedColumn<String> get inactiveText => $composableBuilder(
    column: $table.inactiveText,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);

  $$ConnectionsTableAnnotationComposer get connectionId {
    final $$ConnectionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.connectionId,
      referencedTable: $db.connections,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ConnectionsTableAnnotationComposer(
            $db: $db,
            $table: $db.connections,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CachedPointsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedPointsTable,
          CachedPoint,
          $$CachedPointsTableFilterComposer,
          $$CachedPointsTableOrderingComposer,
          $$CachedPointsTableAnnotationComposer,
          $$CachedPointsTableCreateCompanionBuilder,
          $$CachedPointsTableUpdateCompanionBuilder,
          (CachedPoint, $$CachedPointsTableReferences),
          CachedPoint,
          PrefetchHooks Function({bool connectionId})
        > {
  $$CachedPointsTableTableManager(_$AppDatabase db, $CachedPointsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedPointsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedPointsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedPointsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> connectionId = const Value.absent(),
                Value<String> pointRef = const Value.absent(),
                Value<String> objectType = const Value.absent(),
                Value<int> instance = const Value.absent(),
                Value<String> objectName = const Value.absent(),
                Value<String?> units = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String?> activeText = const Value.absent(),
                Value<String?> inactiveText = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedPointsCompanion(
                connectionId: connectionId,
                pointRef: pointRef,
                objectType: objectType,
                instance: instance,
                objectName: objectName,
                units: units,
                description: description,
                activeText: activeText,
                inactiveText: inactiveText,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int connectionId,
                required String pointRef,
                required String objectType,
                required int instance,
                required String objectName,
                Value<String?> units = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String?> activeText = const Value.absent(),
                Value<String?> inactiveText = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedPointsCompanion.insert(
                connectionId: connectionId,
                pointRef: pointRef,
                objectType: objectType,
                instance: instance,
                objectName: objectName,
                units: units,
                description: description,
                activeText: activeText,
                inactiveText: inactiveText,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CachedPointsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({connectionId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (connectionId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.connectionId,
                                referencedTable: $$CachedPointsTableReferences
                                    ._connectionIdTable(db),
                                referencedColumn: $$CachedPointsTableReferences
                                    ._connectionIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$CachedPointsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedPointsTable,
      CachedPoint,
      $$CachedPointsTableFilterComposer,
      $$CachedPointsTableOrderingComposer,
      $$CachedPointsTableAnnotationComposer,
      $$CachedPointsTableCreateCompanionBuilder,
      $$CachedPointsTableUpdateCompanionBuilder,
      (CachedPoint, $$CachedPointsTableReferences),
      CachedPoint,
      PrefetchHooks Function({bool connectionId})
    >;
typedef $$CachedDeviceInfoTableCreateCompanionBuilder =
    CachedDeviceInfoCompanion Function({
      Value<int> connectionId,
      required String objectName,
      Value<String?> modelName,
      Value<String?> modelType,
      Value<String?> softwareVersion,
      Value<String?> hostId,
      Value<String?> hostName,
      Value<String?> vendorName,
      Value<String?> description,
      Value<String?> location,
      Value<int?> deviceInstance,
      Value<DateTime> cachedAt,
    });
typedef $$CachedDeviceInfoTableUpdateCompanionBuilder =
    CachedDeviceInfoCompanion Function({
      Value<int> connectionId,
      Value<String> objectName,
      Value<String?> modelName,
      Value<String?> modelType,
      Value<String?> softwareVersion,
      Value<String?> hostId,
      Value<String?> hostName,
      Value<String?> vendorName,
      Value<String?> description,
      Value<String?> location,
      Value<int?> deviceInstance,
      Value<DateTime> cachedAt,
    });

final class $$CachedDeviceInfoTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $CachedDeviceInfoTable,
          CachedDeviceInfoData
        > {
  $$CachedDeviceInfoTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ConnectionsTable _connectionIdTable(_$AppDatabase db) =>
      db.connections.createAlias(
        $_aliasNameGenerator(
          db.cachedDeviceInfo.connectionId,
          db.connections.id,
        ),
      );

  $$ConnectionsTableProcessedTableManager get connectionId {
    final $_column = $_itemColumn<int>('connection_id')!;

    final manager = $$ConnectionsTableTableManager(
      $_db,
      $_db.connections,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_connectionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$CachedDeviceInfoTableFilterComposer
    extends Composer<_$AppDatabase, $CachedDeviceInfoTable> {
  $$CachedDeviceInfoTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get objectName => $composableBuilder(
    column: $table.objectName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get modelName => $composableBuilder(
    column: $table.modelName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get modelType => $composableBuilder(
    column: $table.modelType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get softwareVersion => $composableBuilder(
    column: $table.softwareVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get hostId => $composableBuilder(
    column: $table.hostId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get hostName => $composableBuilder(
    column: $table.hostName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get vendorName => $composableBuilder(
    column: $table.vendorName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get location => $composableBuilder(
    column: $table.location,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deviceInstance => $composableBuilder(
    column: $table.deviceInstance,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$ConnectionsTableFilterComposer get connectionId {
    final $$ConnectionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.connectionId,
      referencedTable: $db.connections,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ConnectionsTableFilterComposer(
            $db: $db,
            $table: $db.connections,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CachedDeviceInfoTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedDeviceInfoTable> {
  $$CachedDeviceInfoTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get objectName => $composableBuilder(
    column: $table.objectName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get modelName => $composableBuilder(
    column: $table.modelName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get modelType => $composableBuilder(
    column: $table.modelType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get softwareVersion => $composableBuilder(
    column: $table.softwareVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get hostId => $composableBuilder(
    column: $table.hostId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get hostName => $composableBuilder(
    column: $table.hostName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get vendorName => $composableBuilder(
    column: $table.vendorName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get location => $composableBuilder(
    column: $table.location,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deviceInstance => $composableBuilder(
    column: $table.deviceInstance,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$ConnectionsTableOrderingComposer get connectionId {
    final $$ConnectionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.connectionId,
      referencedTable: $db.connections,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ConnectionsTableOrderingComposer(
            $db: $db,
            $table: $db.connections,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CachedDeviceInfoTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedDeviceInfoTable> {
  $$CachedDeviceInfoTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get objectName => $composableBuilder(
    column: $table.objectName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get modelName =>
      $composableBuilder(column: $table.modelName, builder: (column) => column);

  GeneratedColumn<String> get modelType =>
      $composableBuilder(column: $table.modelType, builder: (column) => column);

  GeneratedColumn<String> get softwareVersion => $composableBuilder(
    column: $table.softwareVersion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get hostId =>
      $composableBuilder(column: $table.hostId, builder: (column) => column);

  GeneratedColumn<String> get hostName =>
      $composableBuilder(column: $table.hostName, builder: (column) => column);

  GeneratedColumn<String> get vendorName => $composableBuilder(
    column: $table.vendorName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get location =>
      $composableBuilder(column: $table.location, builder: (column) => column);

  GeneratedColumn<int> get deviceInstance => $composableBuilder(
    column: $table.deviceInstance,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);

  $$ConnectionsTableAnnotationComposer get connectionId {
    final $$ConnectionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.connectionId,
      referencedTable: $db.connections,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ConnectionsTableAnnotationComposer(
            $db: $db,
            $table: $db.connections,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CachedDeviceInfoTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedDeviceInfoTable,
          CachedDeviceInfoData,
          $$CachedDeviceInfoTableFilterComposer,
          $$CachedDeviceInfoTableOrderingComposer,
          $$CachedDeviceInfoTableAnnotationComposer,
          $$CachedDeviceInfoTableCreateCompanionBuilder,
          $$CachedDeviceInfoTableUpdateCompanionBuilder,
          (CachedDeviceInfoData, $$CachedDeviceInfoTableReferences),
          CachedDeviceInfoData,
          PrefetchHooks Function({bool connectionId})
        > {
  $$CachedDeviceInfoTableTableManager(
    _$AppDatabase db,
    $CachedDeviceInfoTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedDeviceInfoTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedDeviceInfoTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedDeviceInfoTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> connectionId = const Value.absent(),
                Value<String> objectName = const Value.absent(),
                Value<String?> modelName = const Value.absent(),
                Value<String?> modelType = const Value.absent(),
                Value<String?> softwareVersion = const Value.absent(),
                Value<String?> hostId = const Value.absent(),
                Value<String?> hostName = const Value.absent(),
                Value<String?> vendorName = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String?> location = const Value.absent(),
                Value<int?> deviceInstance = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
              }) => CachedDeviceInfoCompanion(
                connectionId: connectionId,
                objectName: objectName,
                modelName: modelName,
                modelType: modelType,
                softwareVersion: softwareVersion,
                hostId: hostId,
                hostName: hostName,
                vendorName: vendorName,
                description: description,
                location: location,
                deviceInstance: deviceInstance,
                cachedAt: cachedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> connectionId = const Value.absent(),
                required String objectName,
                Value<String?> modelName = const Value.absent(),
                Value<String?> modelType = const Value.absent(),
                Value<String?> softwareVersion = const Value.absent(),
                Value<String?> hostId = const Value.absent(),
                Value<String?> hostName = const Value.absent(),
                Value<String?> vendorName = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String?> location = const Value.absent(),
                Value<int?> deviceInstance = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
              }) => CachedDeviceInfoCompanion.insert(
                connectionId: connectionId,
                objectName: objectName,
                modelName: modelName,
                modelType: modelType,
                softwareVersion: softwareVersion,
                hostId: hostId,
                hostName: hostName,
                vendorName: vendorName,
                description: description,
                location: location,
                deviceInstance: deviceInstance,
                cachedAt: cachedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CachedDeviceInfoTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({connectionId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (connectionId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.connectionId,
                                referencedTable:
                                    $$CachedDeviceInfoTableReferences
                                        ._connectionIdTable(db),
                                referencedColumn:
                                    $$CachedDeviceInfoTableReferences
                                        ._connectionIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$CachedDeviceInfoTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedDeviceInfoTable,
      CachedDeviceInfoData,
      $$CachedDeviceInfoTableFilterComposer,
      $$CachedDeviceInfoTableOrderingComposer,
      $$CachedDeviceInfoTableAnnotationComposer,
      $$CachedDeviceInfoTableCreateCompanionBuilder,
      $$CachedDeviceInfoTableUpdateCompanionBuilder,
      (CachedDeviceInfoData, $$CachedDeviceInfoTableReferences),
      CachedDeviceInfoData,
      PrefetchHooks Function({bool connectionId})
    >;
typedef $$CachedTrendLogMappingTableCreateCompanionBuilder =
    CachedTrendLogMappingCompanion Function({
      Value<int> connectionId,
      required String mappingJson,
      Value<int> entryCount,
      Value<DateTime> cachedAt,
    });
typedef $$CachedTrendLogMappingTableUpdateCompanionBuilder =
    CachedTrendLogMappingCompanion Function({
      Value<int> connectionId,
      Value<String> mappingJson,
      Value<int> entryCount,
      Value<DateTime> cachedAt,
    });

final class $$CachedTrendLogMappingTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $CachedTrendLogMappingTable,
          CachedTrendLogMappingData
        > {
  $$CachedTrendLogMappingTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ConnectionsTable _connectionIdTable(_$AppDatabase db) =>
      db.connections.createAlias(
        $_aliasNameGenerator(
          db.cachedTrendLogMapping.connectionId,
          db.connections.id,
        ),
      );

  $$ConnectionsTableProcessedTableManager get connectionId {
    final $_column = $_itemColumn<int>('connection_id')!;

    final manager = $$ConnectionsTableTableManager(
      $_db,
      $_db.connections,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_connectionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$CachedTrendLogMappingTableFilterComposer
    extends Composer<_$AppDatabase, $CachedTrendLogMappingTable> {
  $$CachedTrendLogMappingTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get mappingJson => $composableBuilder(
    column: $table.mappingJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get entryCount => $composableBuilder(
    column: $table.entryCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$ConnectionsTableFilterComposer get connectionId {
    final $$ConnectionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.connectionId,
      referencedTable: $db.connections,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ConnectionsTableFilterComposer(
            $db: $db,
            $table: $db.connections,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CachedTrendLogMappingTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedTrendLogMappingTable> {
  $$CachedTrendLogMappingTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get mappingJson => $composableBuilder(
    column: $table.mappingJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get entryCount => $composableBuilder(
    column: $table.entryCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$ConnectionsTableOrderingComposer get connectionId {
    final $$ConnectionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.connectionId,
      referencedTable: $db.connections,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ConnectionsTableOrderingComposer(
            $db: $db,
            $table: $db.connections,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CachedTrendLogMappingTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedTrendLogMappingTable> {
  $$CachedTrendLogMappingTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get mappingJson => $composableBuilder(
    column: $table.mappingJson,
    builder: (column) => column,
  );

  GeneratedColumn<int> get entryCount => $composableBuilder(
    column: $table.entryCount,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);

  $$ConnectionsTableAnnotationComposer get connectionId {
    final $$ConnectionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.connectionId,
      referencedTable: $db.connections,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ConnectionsTableAnnotationComposer(
            $db: $db,
            $table: $db.connections,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CachedTrendLogMappingTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedTrendLogMappingTable,
          CachedTrendLogMappingData,
          $$CachedTrendLogMappingTableFilterComposer,
          $$CachedTrendLogMappingTableOrderingComposer,
          $$CachedTrendLogMappingTableAnnotationComposer,
          $$CachedTrendLogMappingTableCreateCompanionBuilder,
          $$CachedTrendLogMappingTableUpdateCompanionBuilder,
          (CachedTrendLogMappingData, $$CachedTrendLogMappingTableReferences),
          CachedTrendLogMappingData,
          PrefetchHooks Function({bool connectionId})
        > {
  $$CachedTrendLogMappingTableTableManager(
    _$AppDatabase db,
    $CachedTrendLogMappingTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedTrendLogMappingTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$CachedTrendLogMappingTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$CachedTrendLogMappingTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> connectionId = const Value.absent(),
                Value<String> mappingJson = const Value.absent(),
                Value<int> entryCount = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
              }) => CachedTrendLogMappingCompanion(
                connectionId: connectionId,
                mappingJson: mappingJson,
                entryCount: entryCount,
                cachedAt: cachedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> connectionId = const Value.absent(),
                required String mappingJson,
                Value<int> entryCount = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
              }) => CachedTrendLogMappingCompanion.insert(
                connectionId: connectionId,
                mappingJson: mappingJson,
                entryCount: entryCount,
                cachedAt: cachedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CachedTrendLogMappingTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({connectionId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (connectionId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.connectionId,
                                referencedTable:
                                    $$CachedTrendLogMappingTableReferences
                                        ._connectionIdTable(db),
                                referencedColumn:
                                    $$CachedTrendLogMappingTableReferences
                                        ._connectionIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$CachedTrendLogMappingTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedTrendLogMappingTable,
      CachedTrendLogMappingData,
      $$CachedTrendLogMappingTableFilterComposer,
      $$CachedTrendLogMappingTableOrderingComposer,
      $$CachedTrendLogMappingTableAnnotationComposer,
      $$CachedTrendLogMappingTableCreateCompanionBuilder,
      $$CachedTrendLogMappingTableUpdateCompanionBuilder,
      (CachedTrendLogMappingData, $$CachedTrendLogMappingTableReferences),
      CachedTrendLogMappingData,
      PrefetchHooks Function({bool connectionId})
    >;
typedef $$CachedObjectsSummaryTableCreateCompanionBuilder =
    CachedObjectsSummaryCompanion Function({
      Value<int> connectionId,
      Value<int> analogInputs,
      Value<int> analogOutputs,
      Value<int> analogValues,
      Value<int> binaryInputs,
      Value<int> binaryOutputs,
      Value<int> binaryValues,
      Value<int> multiStateInputs,
      Value<int> multiStateOutputs,
      Value<int> multiStateValues,
      Value<int> schedules,
      Value<DateTime> cachedAt,
    });
typedef $$CachedObjectsSummaryTableUpdateCompanionBuilder =
    CachedObjectsSummaryCompanion Function({
      Value<int> connectionId,
      Value<int> analogInputs,
      Value<int> analogOutputs,
      Value<int> analogValues,
      Value<int> binaryInputs,
      Value<int> binaryOutputs,
      Value<int> binaryValues,
      Value<int> multiStateInputs,
      Value<int> multiStateOutputs,
      Value<int> multiStateValues,
      Value<int> schedules,
      Value<DateTime> cachedAt,
    });

final class $$CachedObjectsSummaryTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $CachedObjectsSummaryTable,
          CachedObjectsSummaryData
        > {
  $$CachedObjectsSummaryTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ConnectionsTable _connectionIdTable(_$AppDatabase db) =>
      db.connections.createAlias(
        $_aliasNameGenerator(
          db.cachedObjectsSummary.connectionId,
          db.connections.id,
        ),
      );

  $$ConnectionsTableProcessedTableManager get connectionId {
    final $_column = $_itemColumn<int>('connection_id')!;

    final manager = $$ConnectionsTableTableManager(
      $_db,
      $_db.connections,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_connectionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$CachedObjectsSummaryTableFilterComposer
    extends Composer<_$AppDatabase, $CachedObjectsSummaryTable> {
  $$CachedObjectsSummaryTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get analogInputs => $composableBuilder(
    column: $table.analogInputs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get analogOutputs => $composableBuilder(
    column: $table.analogOutputs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get analogValues => $composableBuilder(
    column: $table.analogValues,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get binaryInputs => $composableBuilder(
    column: $table.binaryInputs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get binaryOutputs => $composableBuilder(
    column: $table.binaryOutputs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get binaryValues => $composableBuilder(
    column: $table.binaryValues,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get multiStateInputs => $composableBuilder(
    column: $table.multiStateInputs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get multiStateOutputs => $composableBuilder(
    column: $table.multiStateOutputs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get multiStateValues => $composableBuilder(
    column: $table.multiStateValues,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get schedules => $composableBuilder(
    column: $table.schedules,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$ConnectionsTableFilterComposer get connectionId {
    final $$ConnectionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.connectionId,
      referencedTable: $db.connections,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ConnectionsTableFilterComposer(
            $db: $db,
            $table: $db.connections,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CachedObjectsSummaryTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedObjectsSummaryTable> {
  $$CachedObjectsSummaryTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get analogInputs => $composableBuilder(
    column: $table.analogInputs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get analogOutputs => $composableBuilder(
    column: $table.analogOutputs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get analogValues => $composableBuilder(
    column: $table.analogValues,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get binaryInputs => $composableBuilder(
    column: $table.binaryInputs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get binaryOutputs => $composableBuilder(
    column: $table.binaryOutputs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get binaryValues => $composableBuilder(
    column: $table.binaryValues,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get multiStateInputs => $composableBuilder(
    column: $table.multiStateInputs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get multiStateOutputs => $composableBuilder(
    column: $table.multiStateOutputs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get multiStateValues => $composableBuilder(
    column: $table.multiStateValues,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get schedules => $composableBuilder(
    column: $table.schedules,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$ConnectionsTableOrderingComposer get connectionId {
    final $$ConnectionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.connectionId,
      referencedTable: $db.connections,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ConnectionsTableOrderingComposer(
            $db: $db,
            $table: $db.connections,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CachedObjectsSummaryTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedObjectsSummaryTable> {
  $$CachedObjectsSummaryTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get analogInputs => $composableBuilder(
    column: $table.analogInputs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get analogOutputs => $composableBuilder(
    column: $table.analogOutputs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get analogValues => $composableBuilder(
    column: $table.analogValues,
    builder: (column) => column,
  );

  GeneratedColumn<int> get binaryInputs => $composableBuilder(
    column: $table.binaryInputs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get binaryOutputs => $composableBuilder(
    column: $table.binaryOutputs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get binaryValues => $composableBuilder(
    column: $table.binaryValues,
    builder: (column) => column,
  );

  GeneratedColumn<int> get multiStateInputs => $composableBuilder(
    column: $table.multiStateInputs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get multiStateOutputs => $composableBuilder(
    column: $table.multiStateOutputs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get multiStateValues => $composableBuilder(
    column: $table.multiStateValues,
    builder: (column) => column,
  );

  GeneratedColumn<int> get schedules =>
      $composableBuilder(column: $table.schedules, builder: (column) => column);

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);

  $$ConnectionsTableAnnotationComposer get connectionId {
    final $$ConnectionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.connectionId,
      referencedTable: $db.connections,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ConnectionsTableAnnotationComposer(
            $db: $db,
            $table: $db.connections,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CachedObjectsSummaryTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedObjectsSummaryTable,
          CachedObjectsSummaryData,
          $$CachedObjectsSummaryTableFilterComposer,
          $$CachedObjectsSummaryTableOrderingComposer,
          $$CachedObjectsSummaryTableAnnotationComposer,
          $$CachedObjectsSummaryTableCreateCompanionBuilder,
          $$CachedObjectsSummaryTableUpdateCompanionBuilder,
          (CachedObjectsSummaryData, $$CachedObjectsSummaryTableReferences),
          CachedObjectsSummaryData,
          PrefetchHooks Function({bool connectionId})
        > {
  $$CachedObjectsSummaryTableTableManager(
    _$AppDatabase db,
    $CachedObjectsSummaryTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedObjectsSummaryTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedObjectsSummaryTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$CachedObjectsSummaryTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> connectionId = const Value.absent(),
                Value<int> analogInputs = const Value.absent(),
                Value<int> analogOutputs = const Value.absent(),
                Value<int> analogValues = const Value.absent(),
                Value<int> binaryInputs = const Value.absent(),
                Value<int> binaryOutputs = const Value.absent(),
                Value<int> binaryValues = const Value.absent(),
                Value<int> multiStateInputs = const Value.absent(),
                Value<int> multiStateOutputs = const Value.absent(),
                Value<int> multiStateValues = const Value.absent(),
                Value<int> schedules = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
              }) => CachedObjectsSummaryCompanion(
                connectionId: connectionId,
                analogInputs: analogInputs,
                analogOutputs: analogOutputs,
                analogValues: analogValues,
                binaryInputs: binaryInputs,
                binaryOutputs: binaryOutputs,
                binaryValues: binaryValues,
                multiStateInputs: multiStateInputs,
                multiStateOutputs: multiStateOutputs,
                multiStateValues: multiStateValues,
                schedules: schedules,
                cachedAt: cachedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> connectionId = const Value.absent(),
                Value<int> analogInputs = const Value.absent(),
                Value<int> analogOutputs = const Value.absent(),
                Value<int> analogValues = const Value.absent(),
                Value<int> binaryInputs = const Value.absent(),
                Value<int> binaryOutputs = const Value.absent(),
                Value<int> binaryValues = const Value.absent(),
                Value<int> multiStateInputs = const Value.absent(),
                Value<int> multiStateOutputs = const Value.absent(),
                Value<int> multiStateValues = const Value.absent(),
                Value<int> schedules = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
              }) => CachedObjectsSummaryCompanion.insert(
                connectionId: connectionId,
                analogInputs: analogInputs,
                analogOutputs: analogOutputs,
                analogValues: analogValues,
                binaryInputs: binaryInputs,
                binaryOutputs: binaryOutputs,
                binaryValues: binaryValues,
                multiStateInputs: multiStateInputs,
                multiStateOutputs: multiStateOutputs,
                multiStateValues: multiStateValues,
                schedules: schedules,
                cachedAt: cachedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CachedObjectsSummaryTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({connectionId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (connectionId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.connectionId,
                                referencedTable:
                                    $$CachedObjectsSummaryTableReferences
                                        ._connectionIdTable(db),
                                referencedColumn:
                                    $$CachedObjectsSummaryTableReferences
                                        ._connectionIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$CachedObjectsSummaryTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedObjectsSummaryTable,
      CachedObjectsSummaryData,
      $$CachedObjectsSummaryTableFilterComposer,
      $$CachedObjectsSummaryTableOrderingComposer,
      $$CachedObjectsSummaryTableAnnotationComposer,
      $$CachedObjectsSummaryTableCreateCompanionBuilder,
      $$CachedObjectsSummaryTableUpdateCompanionBuilder,
      (CachedObjectsSummaryData, $$CachedObjectsSummaryTableReferences),
      CachedObjectsSummaryData,
      PrefetchHooks Function({bool connectionId})
    >;
typedef $$SynopticsTableCreateCompanionBuilder =
    SynopticsCompanion Function({
      Value<int> id,
      required String name,
      required String svgAssetPath,
      Value<int?> connectionId,
      Value<String?> description,
      Value<int> sortOrder,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });
typedef $$SynopticsTableUpdateCompanionBuilder =
    SynopticsCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String> svgAssetPath,
      Value<int?> connectionId,
      Value<String?> description,
      Value<int> sortOrder,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

final class $$SynopticsTableReferences
    extends BaseReferences<_$AppDatabase, $SynopticsTable, Synoptic> {
  $$SynopticsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$SynopticBindingsTable, List<SynopticBinding>>
  _synopticBindingsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.synopticBindings,
    aliasName: $_aliasNameGenerator(
      db.synoptics.id,
      db.synopticBindings.synopticId,
    ),
  );

  $$SynopticBindingsTableProcessedTableManager get synopticBindingsRefs {
    final manager = $$SynopticBindingsTableTableManager(
      $_db,
      $_db.synopticBindings,
    ).filter((f) => f.synopticId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _synopticBindingsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$SynopticsTableFilterComposer
    extends Composer<_$AppDatabase, $SynopticsTable> {
  $$SynopticsTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get svgAssetPath => $composableBuilder(
    column: $table.svgAssetPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get connectionId => $composableBuilder(
    column: $table.connectionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> synopticBindingsRefs(
    Expression<bool> Function($$SynopticBindingsTableFilterComposer f) f,
  ) {
    final $$SynopticBindingsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.synopticBindings,
      getReferencedColumn: (t) => t.synopticId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SynopticBindingsTableFilterComposer(
            $db: $db,
            $table: $db.synopticBindings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SynopticsTableOrderingComposer
    extends Composer<_$AppDatabase, $SynopticsTable> {
  $$SynopticsTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get svgAssetPath => $composableBuilder(
    column: $table.svgAssetPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get connectionId => $composableBuilder(
    column: $table.connectionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SynopticsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SynopticsTable> {
  $$SynopticsTableAnnotationComposer({
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

  GeneratedColumn<String> get svgAssetPath => $composableBuilder(
    column: $table.svgAssetPath,
    builder: (column) => column,
  );

  GeneratedColumn<int> get connectionId => $composableBuilder(
    column: $table.connectionId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> synopticBindingsRefs<T extends Object>(
    Expression<T> Function($$SynopticBindingsTableAnnotationComposer a) f,
  ) {
    final $$SynopticBindingsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.synopticBindings,
      getReferencedColumn: (t) => t.synopticId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SynopticBindingsTableAnnotationComposer(
            $db: $db,
            $table: $db.synopticBindings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SynopticsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SynopticsTable,
          Synoptic,
          $$SynopticsTableFilterComposer,
          $$SynopticsTableOrderingComposer,
          $$SynopticsTableAnnotationComposer,
          $$SynopticsTableCreateCompanionBuilder,
          $$SynopticsTableUpdateCompanionBuilder,
          (Synoptic, $$SynopticsTableReferences),
          Synoptic,
          PrefetchHooks Function({bool synopticBindingsRefs})
        > {
  $$SynopticsTableTableManager(_$AppDatabase db, $SynopticsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SynopticsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SynopticsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SynopticsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> svgAssetPath = const Value.absent(),
                Value<int?> connectionId = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => SynopticsCompanion(
                id: id,
                name: name,
                svgAssetPath: svgAssetPath,
                connectionId: connectionId,
                description: description,
                sortOrder: sortOrder,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required String svgAssetPath,
                Value<int?> connectionId = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => SynopticsCompanion.insert(
                id: id,
                name: name,
                svgAssetPath: svgAssetPath,
                connectionId: connectionId,
                description: description,
                sortOrder: sortOrder,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$SynopticsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({synopticBindingsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (synopticBindingsRefs) db.synopticBindings,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (synopticBindingsRefs)
                    await $_getPrefetchedData<
                      Synoptic,
                      $SynopticsTable,
                      SynopticBinding
                    >(
                      currentTable: table,
                      referencedTable: $$SynopticsTableReferences
                          ._synopticBindingsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$SynopticsTableReferences(
                            db,
                            table,
                            p0,
                          ).synopticBindingsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.synopticId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$SynopticsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SynopticsTable,
      Synoptic,
      $$SynopticsTableFilterComposer,
      $$SynopticsTableOrderingComposer,
      $$SynopticsTableAnnotationComposer,
      $$SynopticsTableCreateCompanionBuilder,
      $$SynopticsTableUpdateCompanionBuilder,
      (Synoptic, $$SynopticsTableReferences),
      Synoptic,
      PrefetchHooks Function({bool synopticBindingsRefs})
    >;
typedef $$SynopticBindingsTableCreateCompanionBuilder =
    SynopticBindingsCompanion Function({
      Value<int> id,
      required int synopticId,
      required String svgElementId,
      required String pointRef,
      required BindingType bindingType,
      Value<String?> configJson,
      Value<String?> pointName,
      Value<DateTime> createdAt,
    });
typedef $$SynopticBindingsTableUpdateCompanionBuilder =
    SynopticBindingsCompanion Function({
      Value<int> id,
      Value<int> synopticId,
      Value<String> svgElementId,
      Value<String> pointRef,
      Value<BindingType> bindingType,
      Value<String?> configJson,
      Value<String?> pointName,
      Value<DateTime> createdAt,
    });

final class $$SynopticBindingsTableReferences
    extends
        BaseReferences<_$AppDatabase, $SynopticBindingsTable, SynopticBinding> {
  $$SynopticBindingsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $SynopticsTable _synopticIdTable(_$AppDatabase db) =>
      db.synoptics.createAlias(
        $_aliasNameGenerator(db.synopticBindings.synopticId, db.synoptics.id),
      );

  $$SynopticsTableProcessedTableManager get synopticId {
    final $_column = $_itemColumn<int>('synoptic_id')!;

    final manager = $$SynopticsTableTableManager(
      $_db,
      $_db.synoptics,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_synopticIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$SynopticBindingsTableFilterComposer
    extends Composer<_$AppDatabase, $SynopticBindingsTable> {
  $$SynopticBindingsTableFilterComposer({
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

  ColumnFilters<String> get svgElementId => $composableBuilder(
    column: $table.svgElementId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pointRef => $composableBuilder(
    column: $table.pointRef,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<BindingType, BindingType, String>
  get bindingType => $composableBuilder(
    column: $table.bindingType,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get configJson => $composableBuilder(
    column: $table.configJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pointName => $composableBuilder(
    column: $table.pointName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$SynopticsTableFilterComposer get synopticId {
    final $$SynopticsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.synopticId,
      referencedTable: $db.synoptics,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SynopticsTableFilterComposer(
            $db: $db,
            $table: $db.synoptics,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SynopticBindingsTableOrderingComposer
    extends Composer<_$AppDatabase, $SynopticBindingsTable> {
  $$SynopticBindingsTableOrderingComposer({
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

  ColumnOrderings<String> get svgElementId => $composableBuilder(
    column: $table.svgElementId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pointRef => $composableBuilder(
    column: $table.pointRef,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bindingType => $composableBuilder(
    column: $table.bindingType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get configJson => $composableBuilder(
    column: $table.configJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pointName => $composableBuilder(
    column: $table.pointName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$SynopticsTableOrderingComposer get synopticId {
    final $$SynopticsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.synopticId,
      referencedTable: $db.synoptics,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SynopticsTableOrderingComposer(
            $db: $db,
            $table: $db.synoptics,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SynopticBindingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SynopticBindingsTable> {
  $$SynopticBindingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get svgElementId => $composableBuilder(
    column: $table.svgElementId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get pointRef =>
      $composableBuilder(column: $table.pointRef, builder: (column) => column);

  GeneratedColumnWithTypeConverter<BindingType, String> get bindingType =>
      $composableBuilder(
        column: $table.bindingType,
        builder: (column) => column,
      );

  GeneratedColumn<String> get configJson => $composableBuilder(
    column: $table.configJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get pointName =>
      $composableBuilder(column: $table.pointName, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$SynopticsTableAnnotationComposer get synopticId {
    final $$SynopticsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.synopticId,
      referencedTable: $db.synoptics,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SynopticsTableAnnotationComposer(
            $db: $db,
            $table: $db.synoptics,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SynopticBindingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SynopticBindingsTable,
          SynopticBinding,
          $$SynopticBindingsTableFilterComposer,
          $$SynopticBindingsTableOrderingComposer,
          $$SynopticBindingsTableAnnotationComposer,
          $$SynopticBindingsTableCreateCompanionBuilder,
          $$SynopticBindingsTableUpdateCompanionBuilder,
          (SynopticBinding, $$SynopticBindingsTableReferences),
          SynopticBinding,
          PrefetchHooks Function({bool synopticId})
        > {
  $$SynopticBindingsTableTableManager(
    _$AppDatabase db,
    $SynopticBindingsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SynopticBindingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SynopticBindingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SynopticBindingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> synopticId = const Value.absent(),
                Value<String> svgElementId = const Value.absent(),
                Value<String> pointRef = const Value.absent(),
                Value<BindingType> bindingType = const Value.absent(),
                Value<String?> configJson = const Value.absent(),
                Value<String?> pointName = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => SynopticBindingsCompanion(
                id: id,
                synopticId: synopticId,
                svgElementId: svgElementId,
                pointRef: pointRef,
                bindingType: bindingType,
                configJson: configJson,
                pointName: pointName,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int synopticId,
                required String svgElementId,
                required String pointRef,
                required BindingType bindingType,
                Value<String?> configJson = const Value.absent(),
                Value<String?> pointName = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => SynopticBindingsCompanion.insert(
                id: id,
                synopticId: synopticId,
                svgElementId: svgElementId,
                pointRef: pointRef,
                bindingType: bindingType,
                configJson: configJson,
                pointName: pointName,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$SynopticBindingsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({synopticId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (synopticId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.synopticId,
                                referencedTable:
                                    $$SynopticBindingsTableReferences
                                        ._synopticIdTable(db),
                                referencedColumn:
                                    $$SynopticBindingsTableReferences
                                        ._synopticIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$SynopticBindingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SynopticBindingsTable,
      SynopticBinding,
      $$SynopticBindingsTableFilterComposer,
      $$SynopticBindingsTableOrderingComposer,
      $$SynopticBindingsTableAnnotationComposer,
      $$SynopticBindingsTableCreateCompanionBuilder,
      $$SynopticBindingsTableUpdateCompanionBuilder,
      (SynopticBinding, $$SynopticBindingsTableReferences),
      SynopticBinding,
      PrefetchHooks Function({bool synopticId})
    >;
typedef $$DashboardsTableCreateCompanionBuilder =
    DashboardsCompanion Function({
      Value<int> id,
      required String name,
      Value<int?> connectionId,
      Value<int> columns,
      Value<int> rows,
      Value<int> sortOrder,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });
typedef $$DashboardsTableUpdateCompanionBuilder =
    DashboardsCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<int?> connectionId,
      Value<int> columns,
      Value<int> rows,
      Value<int> sortOrder,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

final class $$DashboardsTableReferences
    extends BaseReferences<_$AppDatabase, $DashboardsTable, Dashboard> {
  $$DashboardsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ConnectionsTable _connectionIdTable(_$AppDatabase db) =>
      db.connections.createAlias(
        $_aliasNameGenerator(db.dashboards.connectionId, db.connections.id),
      );

  $$ConnectionsTableProcessedTableManager? get connectionId {
    final $_column = $_itemColumn<int>('connection_id');
    if ($_column == null) return null;
    final manager = $$ConnectionsTableTableManager(
      $_db,
      $_db.connections,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_connectionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$DashboardWidgetsTable, List<DashboardWidget>>
  _dashboardWidgetsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.dashboardWidgets,
    aliasName: $_aliasNameGenerator(
      db.dashboards.id,
      db.dashboardWidgets.dashboardId,
    ),
  );

  $$DashboardWidgetsTableProcessedTableManager get dashboardWidgetsRefs {
    final manager = $$DashboardWidgetsTableTableManager(
      $_db,
      $_db.dashboardWidgets,
    ).filter((f) => f.dashboardId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _dashboardWidgetsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$DashboardsTableFilterComposer
    extends Composer<_$AppDatabase, $DashboardsTable> {
  $$DashboardsTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get columns => $composableBuilder(
    column: $table.columns,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rows => $composableBuilder(
    column: $table.rows,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$ConnectionsTableFilterComposer get connectionId {
    final $$ConnectionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.connectionId,
      referencedTable: $db.connections,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ConnectionsTableFilterComposer(
            $db: $db,
            $table: $db.connections,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> dashboardWidgetsRefs(
    Expression<bool> Function($$DashboardWidgetsTableFilterComposer f) f,
  ) {
    final $$DashboardWidgetsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.dashboardWidgets,
      getReferencedColumn: (t) => t.dashboardId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DashboardWidgetsTableFilterComposer(
            $db: $db,
            $table: $db.dashboardWidgets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$DashboardsTableOrderingComposer
    extends Composer<_$AppDatabase, $DashboardsTable> {
  $$DashboardsTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get columns => $composableBuilder(
    column: $table.columns,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rows => $composableBuilder(
    column: $table.rows,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$ConnectionsTableOrderingComposer get connectionId {
    final $$ConnectionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.connectionId,
      referencedTable: $db.connections,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ConnectionsTableOrderingComposer(
            $db: $db,
            $table: $db.connections,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DashboardsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DashboardsTable> {
  $$DashboardsTableAnnotationComposer({
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

  GeneratedColumn<int> get columns =>
      $composableBuilder(column: $table.columns, builder: (column) => column);

  GeneratedColumn<int> get rows =>
      $composableBuilder(column: $table.rows, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$ConnectionsTableAnnotationComposer get connectionId {
    final $$ConnectionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.connectionId,
      referencedTable: $db.connections,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ConnectionsTableAnnotationComposer(
            $db: $db,
            $table: $db.connections,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> dashboardWidgetsRefs<T extends Object>(
    Expression<T> Function($$DashboardWidgetsTableAnnotationComposer a) f,
  ) {
    final $$DashboardWidgetsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.dashboardWidgets,
      getReferencedColumn: (t) => t.dashboardId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DashboardWidgetsTableAnnotationComposer(
            $db: $db,
            $table: $db.dashboardWidgets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$DashboardsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DashboardsTable,
          Dashboard,
          $$DashboardsTableFilterComposer,
          $$DashboardsTableOrderingComposer,
          $$DashboardsTableAnnotationComposer,
          $$DashboardsTableCreateCompanionBuilder,
          $$DashboardsTableUpdateCompanionBuilder,
          (Dashboard, $$DashboardsTableReferences),
          Dashboard,
          PrefetchHooks Function({bool connectionId, bool dashboardWidgetsRefs})
        > {
  $$DashboardsTableTableManager(_$AppDatabase db, $DashboardsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DashboardsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DashboardsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DashboardsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int?> connectionId = const Value.absent(),
                Value<int> columns = const Value.absent(),
                Value<int> rows = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => DashboardsCompanion(
                id: id,
                name: name,
                connectionId: connectionId,
                columns: columns,
                rows: rows,
                sortOrder: sortOrder,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                Value<int?> connectionId = const Value.absent(),
                Value<int> columns = const Value.absent(),
                Value<int> rows = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => DashboardsCompanion.insert(
                id: id,
                name: name,
                connectionId: connectionId,
                columns: columns,
                rows: rows,
                sortOrder: sortOrder,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$DashboardsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({connectionId = false, dashboardWidgetsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (dashboardWidgetsRefs) db.dashboardWidgets,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (connectionId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.connectionId,
                                    referencedTable: $$DashboardsTableReferences
                                        ._connectionIdTable(db),
                                    referencedColumn:
                                        $$DashboardsTableReferences
                                            ._connectionIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (dashboardWidgetsRefs)
                        await $_getPrefetchedData<
                          Dashboard,
                          $DashboardsTable,
                          DashboardWidget
                        >(
                          currentTable: table,
                          referencedTable: $$DashboardsTableReferences
                              ._dashboardWidgetsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$DashboardsTableReferences(
                                db,
                                table,
                                p0,
                              ).dashboardWidgetsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.dashboardId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$DashboardsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DashboardsTable,
      Dashboard,
      $$DashboardsTableFilterComposer,
      $$DashboardsTableOrderingComposer,
      $$DashboardsTableAnnotationComposer,
      $$DashboardsTableCreateCompanionBuilder,
      $$DashboardsTableUpdateCompanionBuilder,
      (Dashboard, $$DashboardsTableReferences),
      Dashboard,
      PrefetchHooks Function({bool connectionId, bool dashboardWidgetsRefs})
    >;
typedef $$DashboardWidgetsTableCreateCompanionBuilder =
    DashboardWidgetsCompanion Function({
      Value<int> id,
      required int dashboardId,
      required int position,
      required DashboardWidgetType widgetType,
      Value<String?> configJson,
      Value<DateTime> createdAt,
    });
typedef $$DashboardWidgetsTableUpdateCompanionBuilder =
    DashboardWidgetsCompanion Function({
      Value<int> id,
      Value<int> dashboardId,
      Value<int> position,
      Value<DashboardWidgetType> widgetType,
      Value<String?> configJson,
      Value<DateTime> createdAt,
    });

final class $$DashboardWidgetsTableReferences
    extends
        BaseReferences<_$AppDatabase, $DashboardWidgetsTable, DashboardWidget> {
  $$DashboardWidgetsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $DashboardsTable _dashboardIdTable(_$AppDatabase db) =>
      db.dashboards.createAlias(
        $_aliasNameGenerator(db.dashboardWidgets.dashboardId, db.dashboards.id),
      );

  $$DashboardsTableProcessedTableManager get dashboardId {
    final $_column = $_itemColumn<int>('dashboard_id')!;

    final manager = $$DashboardsTableTableManager(
      $_db,
      $_db.dashboards,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_dashboardIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$DashboardWidgetsTableFilterComposer
    extends Composer<_$AppDatabase, $DashboardWidgetsTable> {
  $$DashboardWidgetsTableFilterComposer({
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

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<
    DashboardWidgetType,
    DashboardWidgetType,
    String
  >
  get widgetType => $composableBuilder(
    column: $table.widgetType,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get configJson => $composableBuilder(
    column: $table.configJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$DashboardsTableFilterComposer get dashboardId {
    final $$DashboardsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.dashboardId,
      referencedTable: $db.dashboards,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DashboardsTableFilterComposer(
            $db: $db,
            $table: $db.dashboards,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DashboardWidgetsTableOrderingComposer
    extends Composer<_$AppDatabase, $DashboardWidgetsTable> {
  $$DashboardWidgetsTableOrderingComposer({
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

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get widgetType => $composableBuilder(
    column: $table.widgetType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get configJson => $composableBuilder(
    column: $table.configJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$DashboardsTableOrderingComposer get dashboardId {
    final $$DashboardsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.dashboardId,
      referencedTable: $db.dashboards,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DashboardsTableOrderingComposer(
            $db: $db,
            $table: $db.dashboards,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DashboardWidgetsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DashboardWidgetsTable> {
  $$DashboardWidgetsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DashboardWidgetType, String>
  get widgetType => $composableBuilder(
    column: $table.widgetType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get configJson => $composableBuilder(
    column: $table.configJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$DashboardsTableAnnotationComposer get dashboardId {
    final $$DashboardsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.dashboardId,
      referencedTable: $db.dashboards,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DashboardsTableAnnotationComposer(
            $db: $db,
            $table: $db.dashboards,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DashboardWidgetsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DashboardWidgetsTable,
          DashboardWidget,
          $$DashboardWidgetsTableFilterComposer,
          $$DashboardWidgetsTableOrderingComposer,
          $$DashboardWidgetsTableAnnotationComposer,
          $$DashboardWidgetsTableCreateCompanionBuilder,
          $$DashboardWidgetsTableUpdateCompanionBuilder,
          (DashboardWidget, $$DashboardWidgetsTableReferences),
          DashboardWidget,
          PrefetchHooks Function({bool dashboardId})
        > {
  $$DashboardWidgetsTableTableManager(
    _$AppDatabase db,
    $DashboardWidgetsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DashboardWidgetsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DashboardWidgetsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DashboardWidgetsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> dashboardId = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<DashboardWidgetType> widgetType = const Value.absent(),
                Value<String?> configJson = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => DashboardWidgetsCompanion(
                id: id,
                dashboardId: dashboardId,
                position: position,
                widgetType: widgetType,
                configJson: configJson,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int dashboardId,
                required int position,
                required DashboardWidgetType widgetType,
                Value<String?> configJson = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => DashboardWidgetsCompanion.insert(
                id: id,
                dashboardId: dashboardId,
                position: position,
                widgetType: widgetType,
                configJson: configJson,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$DashboardWidgetsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({dashboardId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (dashboardId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.dashboardId,
                                referencedTable:
                                    $$DashboardWidgetsTableReferences
                                        ._dashboardIdTable(db),
                                referencedColumn:
                                    $$DashboardWidgetsTableReferences
                                        ._dashboardIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$DashboardWidgetsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DashboardWidgetsTable,
      DashboardWidget,
      $$DashboardWidgetsTableFilterComposer,
      $$DashboardWidgetsTableOrderingComposer,
      $$DashboardWidgetsTableAnnotationComposer,
      $$DashboardWidgetsTableCreateCompanionBuilder,
      $$DashboardWidgetsTableUpdateCompanionBuilder,
      (DashboardWidget, $$DashboardWidgetsTableReferences),
      DashboardWidget,
      PrefetchHooks Function({bool dashboardId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$FoldersTableTableManager get folders =>
      $$FoldersTableTableManager(_db, _db.folders);
  $$ConnectionsTableTableManager get connections =>
      $$ConnectionsTableTableManager(_db, _db.connections);
  $$FavoritesTableTableManager get favorites =>
      $$FavoritesTableTableManager(_db, _db.favorites);
  $$FavoriteFoldersTableTableManager get favoriteFolders =>
      $$FavoriteFoldersTableTableManager(_db, _db.favoriteFolders);
  $$FavoriteFolderAssignmentsTableTableManager get favoriteFolderAssignments =>
      $$FavoriteFolderAssignmentsTableTableManager(
        _db,
        _db.favoriteFolderAssignments,
      );
  $$CachedPointsTableTableManager get cachedPoints =>
      $$CachedPointsTableTableManager(_db, _db.cachedPoints);
  $$CachedDeviceInfoTableTableManager get cachedDeviceInfo =>
      $$CachedDeviceInfoTableTableManager(_db, _db.cachedDeviceInfo);
  $$CachedTrendLogMappingTableTableManager get cachedTrendLogMapping =>
      $$CachedTrendLogMappingTableTableManager(_db, _db.cachedTrendLogMapping);
  $$CachedObjectsSummaryTableTableManager get cachedObjectsSummary =>
      $$CachedObjectsSummaryTableTableManager(_db, _db.cachedObjectsSummary);
  $$SynopticsTableTableManager get synoptics =>
      $$SynopticsTableTableManager(_db, _db.synoptics);
  $$SynopticBindingsTableTableManager get synopticBindings =>
      $$SynopticBindingsTableTableManager(_db, _db.synopticBindings);
  $$DashboardsTableTableManager get dashboards =>
      $$DashboardsTableTableManager(_db, _db.dashboards);
  $$DashboardWidgetsTableTableManager get dashboardWidgets =>
      $$DashboardWidgetsTableTableManager(_db, _db.dashboardWidgets);
}
