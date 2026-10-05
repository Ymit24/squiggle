// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $DocumentMetadatasTable extends DocumentMetadatas
    with TableInfo<$DocumentMetadatasTable, DocumentMetadata> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DocumentMetadatasTable(this.attachedDatabase, [this._alias]);
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
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
    clientDefault: () => DateTime.now().toUtc(),
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
    clientDefault: () => DateTime.now().toUtc(),
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, createdAt, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'document_metadatas';
  @override
  VerificationContext validateIntegrity(
    Insertable<DocumentMetadata> instance, {
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
  DocumentMetadata map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DocumentMetadata(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
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
  $DocumentMetadatasTable createAlias(String alias) {
    return $DocumentMetadatasTable(attachedDatabase, alias);
  }
}

class DocumentMetadata extends DataClass
    implements Insertable<DocumentMetadata> {
  final int id;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;
  const DocumentMetadata({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  DocumentMetadatasCompanion toCompanion(bool nullToAbsent) {
    return DocumentMetadatasCompanion(
      id: Value(id),
      name: Value(name),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory DocumentMetadata.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DocumentMetadata(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
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
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  DocumentMetadata copyWith({
    int? id,
    String? name,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => DocumentMetadata(
    id: id ?? this.id,
    name: name ?? this.name,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  DocumentMetadata copyWithCompanion(DocumentMetadatasCompanion data) {
    return DocumentMetadata(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DocumentMetadata(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DocumentMetadata &&
          other.id == this.id &&
          other.name == this.name &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class DocumentMetadatasCompanion extends UpdateCompanion<DocumentMetadata> {
  final Value<int> id;
  final Value<String> name;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const DocumentMetadatasCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  DocumentMetadatasCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : name = Value(name);
  static Insertable<DocumentMetadata> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  DocumentMetadatasCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return DocumentMetadatasCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
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
    return (StringBuffer('DocumentMetadatasCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $BrushProfilesTable extends BrushProfiles
    with TableInfo<$BrushProfilesTable, BrushProfile> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BrushProfilesTable(this.attachedDatabase, [this._alias]);
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
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valuesMeta = const VerificationMeta('values');
  @override
  late final GeneratedColumn<String> values = GeneratedColumn<String>(
    'values',
    aliasedName,
    false,
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
    requiredDuringInsert: true,
  );
  static const VerificationMeta _documentMeta = const VerificationMeta(
    'document',
  );
  @override
  late final GeneratedColumn<int> document = GeneratedColumn<int>(
    'document',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES document_metadatas (id)',
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
    clientDefault: () => DateTime.now().toUtc(),
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
    clientDefault: () => DateTime.now().toUtc(),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    values,
    sortOrder,
    document,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'brush_profiles';
  @override
  VerificationContext validateIntegrity(
    Insertable<BrushProfile> instance, {
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
    if (data.containsKey('values')) {
      context.handle(
        _valuesMeta,
        values.isAcceptableOrUnknown(data['values']!, _valuesMeta),
      );
    } else if (isInserting) {
      context.missing(_valuesMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    } else if (isInserting) {
      context.missing(_sortOrderMeta);
    }
    if (data.containsKey('document')) {
      context.handle(
        _documentMeta,
        document.isAcceptableOrUnknown(data['document']!, _documentMeta),
      );
    } else if (isInserting) {
      context.missing(_documentMeta);
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
  BrushProfile map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BrushProfile(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      values: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}values'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      document: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}document'],
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
  $BrushProfilesTable createAlias(String alias) {
    return $BrushProfilesTable(attachedDatabase, alias);
  }
}

class BrushProfile extends DataClass implements Insertable<BrushProfile> {
  final int id;
  final String name;
  final String values;
  final int sortOrder;
  final int document;
  final DateTime createdAt;
  final DateTime updatedAt;
  const BrushProfile({
    required this.id,
    required this.name,
    required this.values,
    required this.sortOrder,
    required this.document,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['values'] = Variable<String>(values);
    map['sort_order'] = Variable<int>(sortOrder);
    map['document'] = Variable<int>(document);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  BrushProfilesCompanion toCompanion(bool nullToAbsent) {
    return BrushProfilesCompanion(
      id: Value(id),
      name: Value(name),
      values: Value(values),
      sortOrder: Value(sortOrder),
      document: Value(document),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory BrushProfile.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BrushProfile(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      values: serializer.fromJson<String>(json['values']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      document: serializer.fromJson<int>(json['document']),
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
      'values': serializer.toJson<String>(values),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'document': serializer.toJson<int>(document),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  BrushProfile copyWith({
    int? id,
    String? name,
    String? values,
    int? sortOrder,
    int? document,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => BrushProfile(
    id: id ?? this.id,
    name: name ?? this.name,
    values: values ?? this.values,
    sortOrder: sortOrder ?? this.sortOrder,
    document: document ?? this.document,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  BrushProfile copyWithCompanion(BrushProfilesCompanion data) {
    return BrushProfile(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      values: data.values.present ? data.values.value : this.values,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      document: data.document.present ? data.document.value : this.document,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BrushProfile(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('values: $values, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('document: $document, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, values, sortOrder, document, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BrushProfile &&
          other.id == this.id &&
          other.name == this.name &&
          other.values == this.values &&
          other.sortOrder == this.sortOrder &&
          other.document == this.document &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class BrushProfilesCompanion extends UpdateCompanion<BrushProfile> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> values;
  final Value<int> sortOrder;
  final Value<int> document;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const BrushProfilesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.values = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.document = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  BrushProfilesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required String values,
    required int sortOrder,
    required int document,
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : name = Value(name),
       values = Value(values),
       sortOrder = Value(sortOrder),
       document = Value(document);
  static Insertable<BrushProfile> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? values,
    Expression<int>? sortOrder,
    Expression<int>? document,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (values != null) 'values': values,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (document != null) 'document': document,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  BrushProfilesCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String>? values,
    Value<int>? sortOrder,
    Value<int>? document,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return BrushProfilesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      values: values ?? this.values,
      sortOrder: sortOrder ?? this.sortOrder,
      document: document ?? this.document,
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
    if (values.present) {
      map['values'] = Variable<String>(values.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (document.present) {
      map['document'] = Variable<int>(document.value);
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
    return (StringBuffer('BrushProfilesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('values: $values, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('document: $document, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $NodesTable extends Nodes with TableInfo<$NodesTable, Node> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NodesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
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
    'content',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nodeIdMeta = const VerificationMeta('nodeId');
  @override
  late final GeneratedColumn<int> nodeId = GeneratedColumn<int>(
    'node_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _documentMeta = const VerificationMeta(
    'document',
  );
  @override
  late final GeneratedColumn<int> document = GeneratedColumn<int>(
    'document',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES document_metadatas (id)',
    ),
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
    requiredDuringInsert: true,
  );
  static const VerificationMeta _parentMeta = const VerificationMeta('parent');
  @override
  late final GeneratedColumn<int> parent = GeneratedColumn<int>(
    'parent',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES nodes (id)',
    ),
  );
  static const VerificationMeta _originXMeta = const VerificationMeta(
    'originX',
  );
  @override
  late final GeneratedColumn<double> originX = GeneratedColumn<double>(
    'origin_x',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _originYMeta = const VerificationMeta(
    'originY',
  );
  @override
  late final GeneratedColumn<double> originY = GeneratedColumn<double>(
    'origin_y',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
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
    clientDefault: () => DateTime.now().toUtc(),
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
    clientDefault: () => DateTime.now().toUtc(),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    type,
    content,
    nodeId,
    document,
    sortOrder,
    parent,
    originX,
    originY,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'nodes';
  @override
  VerificationContext validateIntegrity(
    Insertable<Node> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('node_id')) {
      context.handle(
        _nodeIdMeta,
        nodeId.isAcceptableOrUnknown(data['node_id']!, _nodeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_nodeIdMeta);
    }
    if (data.containsKey('document')) {
      context.handle(
        _documentMeta,
        document.isAcceptableOrUnknown(data['document']!, _documentMeta),
      );
    } else if (isInserting) {
      context.missing(_documentMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    } else if (isInserting) {
      context.missing(_sortOrderMeta);
    }
    if (data.containsKey('parent')) {
      context.handle(
        _parentMeta,
        parent.isAcceptableOrUnknown(data['parent']!, _parentMeta),
      );
    }
    if (data.containsKey('origin_x')) {
      context.handle(
        _originXMeta,
        originX.isAcceptableOrUnknown(data['origin_x']!, _originXMeta),
      );
    } else if (isInserting) {
      context.missing(_originXMeta);
    }
    if (data.containsKey('origin_y')) {
      context.handle(
        _originYMeta,
        originY.isAcceptableOrUnknown(data['origin_y']!, _originYMeta),
      );
    } else if (isInserting) {
      context.missing(_originYMeta);
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
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {document, id},
  ];
  @override
  Node map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Node(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      )!,
      nodeId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}node_id'],
      )!,
      document: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}document'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      parent: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}parent'],
      ),
      originX: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}origin_x'],
      )!,
      originY: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}origin_y'],
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
  $NodesTable createAlias(String alias) {
    return $NodesTable(attachedDatabase, alias);
  }
}

class Node extends DataClass implements Insertable<Node> {
  final int id;
  final String type;
  final String content;
  final int nodeId;
  final int document;
  final int sortOrder;
  final int? parent;
  final double originX;
  final double originY;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Node({
    required this.id,
    required this.type,
    required this.content,
    required this.nodeId,
    required this.document,
    required this.sortOrder,
    this.parent,
    required this.originX,
    required this.originY,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['type'] = Variable<String>(type);
    map['content'] = Variable<String>(content);
    map['node_id'] = Variable<int>(nodeId);
    map['document'] = Variable<int>(document);
    map['sort_order'] = Variable<int>(sortOrder);
    if (!nullToAbsent || parent != null) {
      map['parent'] = Variable<int>(parent);
    }
    map['origin_x'] = Variable<double>(originX);
    map['origin_y'] = Variable<double>(originY);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  NodesCompanion toCompanion(bool nullToAbsent) {
    return NodesCompanion(
      id: Value(id),
      type: Value(type),
      content: Value(content),
      nodeId: Value(nodeId),
      document: Value(document),
      sortOrder: Value(sortOrder),
      parent: parent == null && nullToAbsent
          ? const Value.absent()
          : Value(parent),
      originX: Value(originX),
      originY: Value(originY),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Node.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Node(
      id: serializer.fromJson<int>(json['id']),
      type: serializer.fromJson<String>(json['type']),
      content: serializer.fromJson<String>(json['content']),
      nodeId: serializer.fromJson<int>(json['nodeId']),
      document: serializer.fromJson<int>(json['document']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      parent: serializer.fromJson<int?>(json['parent']),
      originX: serializer.fromJson<double>(json['originX']),
      originY: serializer.fromJson<double>(json['originY']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'type': serializer.toJson<String>(type),
      'content': serializer.toJson<String>(content),
      'nodeId': serializer.toJson<int>(nodeId),
      'document': serializer.toJson<int>(document),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'parent': serializer.toJson<int?>(parent),
      'originX': serializer.toJson<double>(originX),
      'originY': serializer.toJson<double>(originY),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Node copyWith({
    int? id,
    String? type,
    String? content,
    int? nodeId,
    int? document,
    int? sortOrder,
    Value<int?> parent = const Value.absent(),
    double? originX,
    double? originY,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Node(
    id: id ?? this.id,
    type: type ?? this.type,
    content: content ?? this.content,
    nodeId: nodeId ?? this.nodeId,
    document: document ?? this.document,
    sortOrder: sortOrder ?? this.sortOrder,
    parent: parent.present ? parent.value : this.parent,
    originX: originX ?? this.originX,
    originY: originY ?? this.originY,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Node copyWithCompanion(NodesCompanion data) {
    return Node(
      id: data.id.present ? data.id.value : this.id,
      type: data.type.present ? data.type.value : this.type,
      content: data.content.present ? data.content.value : this.content,
      nodeId: data.nodeId.present ? data.nodeId.value : this.nodeId,
      document: data.document.present ? data.document.value : this.document,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      parent: data.parent.present ? data.parent.value : this.parent,
      originX: data.originX.present ? data.originX.value : this.originX,
      originY: data.originY.present ? data.originY.value : this.originY,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Node(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('content: $content, ')
          ..write('nodeId: $nodeId, ')
          ..write('document: $document, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('parent: $parent, ')
          ..write('originX: $originX, ')
          ..write('originY: $originY, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    type,
    content,
    nodeId,
    document,
    sortOrder,
    parent,
    originX,
    originY,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Node &&
          other.id == this.id &&
          other.type == this.type &&
          other.content == this.content &&
          other.nodeId == this.nodeId &&
          other.document == this.document &&
          other.sortOrder == this.sortOrder &&
          other.parent == this.parent &&
          other.originX == this.originX &&
          other.originY == this.originY &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class NodesCompanion extends UpdateCompanion<Node> {
  final Value<int> id;
  final Value<String> type;
  final Value<String> content;
  final Value<int> nodeId;
  final Value<int> document;
  final Value<int> sortOrder;
  final Value<int?> parent;
  final Value<double> originX;
  final Value<double> originY;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const NodesCompanion({
    this.id = const Value.absent(),
    this.type = const Value.absent(),
    this.content = const Value.absent(),
    this.nodeId = const Value.absent(),
    this.document = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.parent = const Value.absent(),
    this.originX = const Value.absent(),
    this.originY = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  NodesCompanion.insert({
    this.id = const Value.absent(),
    required String type,
    required String content,
    required int nodeId,
    required int document,
    required int sortOrder,
    this.parent = const Value.absent(),
    required double originX,
    required double originY,
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : type = Value(type),
       content = Value(content),
       nodeId = Value(nodeId),
       document = Value(document),
       sortOrder = Value(sortOrder),
       originX = Value(originX),
       originY = Value(originY);
  static Insertable<Node> custom({
    Expression<int>? id,
    Expression<String>? type,
    Expression<String>? content,
    Expression<int>? nodeId,
    Expression<int>? document,
    Expression<int>? sortOrder,
    Expression<int>? parent,
    Expression<double>? originX,
    Expression<double>? originY,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (type != null) 'type': type,
      if (content != null) 'content': content,
      if (nodeId != null) 'node_id': nodeId,
      if (document != null) 'document': document,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (parent != null) 'parent': parent,
      if (originX != null) 'origin_x': originX,
      if (originY != null) 'origin_y': originY,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  NodesCompanion copyWith({
    Value<int>? id,
    Value<String>? type,
    Value<String>? content,
    Value<int>? nodeId,
    Value<int>? document,
    Value<int>? sortOrder,
    Value<int?>? parent,
    Value<double>? originX,
    Value<double>? originY,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return NodesCompanion(
      id: id ?? this.id,
      type: type ?? this.type,
      content: content ?? this.content,
      nodeId: nodeId ?? this.nodeId,
      document: document ?? this.document,
      sortOrder: sortOrder ?? this.sortOrder,
      parent: parent ?? this.parent,
      originX: originX ?? this.originX,
      originY: originY ?? this.originY,
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
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (nodeId.present) {
      map['node_id'] = Variable<int>(nodeId.value);
    }
    if (document.present) {
      map['document'] = Variable<int>(document.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (parent.present) {
      map['parent'] = Variable<int>(parent.value);
    }
    if (originX.present) {
      map['origin_x'] = Variable<double>(originX.value);
    }
    if (originY.present) {
      map['origin_y'] = Variable<double>(originY.value);
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
    return (StringBuffer('NodesCompanion(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('content: $content, ')
          ..write('nodeId: $nodeId, ')
          ..write('document: $document, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('parent: $parent, ')
          ..write('originX: $originX, ')
          ..write('originY: $originY, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $DocumentMetadatasTable documentMetadatas =
      $DocumentMetadatasTable(this);
  late final $BrushProfilesTable brushProfiles = $BrushProfilesTable(this);
  late final $NodesTable nodes = $NodesTable(this);
  late final DocumentMetadataDao documentMetadataDao = DocumentMetadataDao(
    this as AppDatabase,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    documentMetadatas,
    brushProfiles,
    nodes,
  ];
}

typedef $$DocumentMetadatasTableCreateCompanionBuilder =
    DocumentMetadatasCompanion Function({
      Value<int> id,
      required String name,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });
typedef $$DocumentMetadatasTableUpdateCompanionBuilder =
    DocumentMetadatasCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

final class $$DocumentMetadatasTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $DocumentMetadatasTable,
          DocumentMetadata
        > {
  $$DocumentMetadatasTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$BrushProfilesTable, List<BrushProfile>>
  _brushProfilesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.brushProfiles,
    aliasName: 'document_metadatas__id__brush_profiles__document',
  );

  $$BrushProfilesTableProcessedTableManager get brushProfilesRefs {
    final manager = $$BrushProfilesTableTableManager(
      $_db,
      $_db.brushProfiles,
    ).filter((f) => f.document.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_brushProfilesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$NodesTable, List<Node>> _nodesRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.nodes,
    aliasName: 'document_metadatas__id__nodes__document',
  );

  $$NodesTableProcessedTableManager get nodesRefs {
    final manager = $$NodesTableTableManager(
      $_db,
      $_db.nodes,
    ).filter((f) => f.document.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_nodesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$DocumentMetadatasTableFilterComposer
    extends Composer<_$AppDatabase, $DocumentMetadatasTable> {
  $$DocumentMetadatasTableFilterComposer({
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

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> brushProfilesRefs(
    Expression<bool> Function($$BrushProfilesTableFilterComposer f) f,
  ) {
    final $$BrushProfilesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.brushProfiles,
      getReferencedColumn: (t) => t.document,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BrushProfilesTableFilterComposer(
            $db: $db,
            $table: $db.brushProfiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> nodesRefs(
    Expression<bool> Function($$NodesTableFilterComposer f) f,
  ) {
    final $$NodesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.nodes,
      getReferencedColumn: (t) => t.document,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NodesTableFilterComposer(
            $db: $db,
            $table: $db.nodes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$DocumentMetadatasTableOrderingComposer
    extends Composer<_$AppDatabase, $DocumentMetadatasTable> {
  $$DocumentMetadatasTableOrderingComposer({
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

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DocumentMetadatasTableAnnotationComposer
    extends Composer<_$AppDatabase, $DocumentMetadatasTable> {
  $$DocumentMetadatasTableAnnotationComposer({
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

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> brushProfilesRefs<T extends Object>(
    Expression<T> Function($$BrushProfilesTableAnnotationComposer a) f,
  ) {
    final $$BrushProfilesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.brushProfiles,
      getReferencedColumn: (t) => t.document,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BrushProfilesTableAnnotationComposer(
            $db: $db,
            $table: $db.brushProfiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> nodesRefs<T extends Object>(
    Expression<T> Function($$NodesTableAnnotationComposer a) f,
  ) {
    final $$NodesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.nodes,
      getReferencedColumn: (t) => t.document,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NodesTableAnnotationComposer(
            $db: $db,
            $table: $db.nodes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$DocumentMetadatasTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DocumentMetadatasTable,
          DocumentMetadata,
          $$DocumentMetadatasTableFilterComposer,
          $$DocumentMetadatasTableOrderingComposer,
          $$DocumentMetadatasTableAnnotationComposer,
          $$DocumentMetadatasTableCreateCompanionBuilder,
          $$DocumentMetadatasTableUpdateCompanionBuilder,
          (DocumentMetadata, $$DocumentMetadatasTableReferences),
          DocumentMetadata,
          PrefetchHooks Function({bool brushProfilesRefs, bool nodesRefs})
        > {
  $$DocumentMetadatasTableTableManager(
    _$AppDatabase db,
    $DocumentMetadatasTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DocumentMetadatasTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DocumentMetadatasTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DocumentMetadatasTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => DocumentMetadatasCompanion(
                id: id,
                name: name,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => DocumentMetadatasCompanion.insert(
                id: id,
                name: name,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$DocumentMetadatasTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({brushProfilesRefs = false, nodesRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (brushProfilesRefs) db.brushProfiles,
                    if (nodesRefs) db.nodes,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (brushProfilesRefs)
                        await $_getPrefetchedData<
                          DocumentMetadata,
                          $DocumentMetadatasTable,
                          BrushProfile
                        >(
                          currentTable: table,
                          referencedTable: $$DocumentMetadatasTableReferences
                              ._brushProfilesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$DocumentMetadatasTableReferences(
                                db,
                                table,
                                p0,
                              ).brushProfilesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.document == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (nodesRefs)
                        await $_getPrefetchedData<
                          DocumentMetadata,
                          $DocumentMetadatasTable,
                          Node
                        >(
                          currentTable: table,
                          referencedTable: $$DocumentMetadatasTableReferences
                              ._nodesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$DocumentMetadatasTableReferences(
                                db,
                                table,
                                p0,
                              ).nodesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.document == item.id,
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

typedef $$DocumentMetadatasTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DocumentMetadatasTable,
      DocumentMetadata,
      $$DocumentMetadatasTableFilterComposer,
      $$DocumentMetadatasTableOrderingComposer,
      $$DocumentMetadatasTableAnnotationComposer,
      $$DocumentMetadatasTableCreateCompanionBuilder,
      $$DocumentMetadatasTableUpdateCompanionBuilder,
      (DocumentMetadata, $$DocumentMetadatasTableReferences),
      DocumentMetadata,
      PrefetchHooks Function({bool brushProfilesRefs, bool nodesRefs})
    >;
typedef $$BrushProfilesTableCreateCompanionBuilder =
    BrushProfilesCompanion Function({
      Value<int> id,
      required String name,
      required String values,
      required int sortOrder,
      required int document,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });
typedef $$BrushProfilesTableUpdateCompanionBuilder =
    BrushProfilesCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String> values,
      Value<int> sortOrder,
      Value<int> document,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

final class $$BrushProfilesTableReferences
    extends BaseReferences<_$AppDatabase, $BrushProfilesTable, BrushProfile> {
  $$BrushProfilesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $DocumentMetadatasTable _documentTable(_$AppDatabase db) => db
      .documentMetadatas
      .createAlias('brush_profiles__document__document_metadatas__id');

  $$DocumentMetadatasTableProcessedTableManager get document {
    final $_column = $_itemColumn<int>('document')!;

    final manager = $$DocumentMetadatasTableTableManager(
      $_db,
      $_db.documentMetadatas,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_documentTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$BrushProfilesTableFilterComposer
    extends Composer<_$AppDatabase, $BrushProfilesTable> {
  $$BrushProfilesTableFilterComposer({
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

  ColumnFilters<String> get values => $composableBuilder(
    column: $table.values,
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

  $$DocumentMetadatasTableFilterComposer get document {
    final $$DocumentMetadatasTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.document,
      referencedTable: $db.documentMetadatas,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DocumentMetadatasTableFilterComposer(
            $db: $db,
            $table: $db.documentMetadatas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BrushProfilesTableOrderingComposer
    extends Composer<_$AppDatabase, $BrushProfilesTable> {
  $$BrushProfilesTableOrderingComposer({
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

  ColumnOrderings<String> get values => $composableBuilder(
    column: $table.values,
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

  $$DocumentMetadatasTableOrderingComposer get document {
    final $$DocumentMetadatasTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.document,
      referencedTable: $db.documentMetadatas,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DocumentMetadatasTableOrderingComposer(
            $db: $db,
            $table: $db.documentMetadatas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BrushProfilesTableAnnotationComposer
    extends Composer<_$AppDatabase, $BrushProfilesTable> {
  $$BrushProfilesTableAnnotationComposer({
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

  GeneratedColumn<String> get values =>
      $composableBuilder(column: $table.values, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$DocumentMetadatasTableAnnotationComposer get document {
    final $$DocumentMetadatasTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.document,
          referencedTable: $db.documentMetadatas,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$DocumentMetadatasTableAnnotationComposer(
                $db: $db,
                $table: $db.documentMetadatas,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$BrushProfilesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BrushProfilesTable,
          BrushProfile,
          $$BrushProfilesTableFilterComposer,
          $$BrushProfilesTableOrderingComposer,
          $$BrushProfilesTableAnnotationComposer,
          $$BrushProfilesTableCreateCompanionBuilder,
          $$BrushProfilesTableUpdateCompanionBuilder,
          (BrushProfile, $$BrushProfilesTableReferences),
          BrushProfile,
          PrefetchHooks Function({bool document})
        > {
  $$BrushProfilesTableTableManager(_$AppDatabase db, $BrushProfilesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BrushProfilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BrushProfilesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BrushProfilesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> values = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> document = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => BrushProfilesCompanion(
                id: id,
                name: name,
                values: values,
                sortOrder: sortOrder,
                document: document,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required String values,
                required int sortOrder,
                required int document,
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => BrushProfilesCompanion.insert(
                id: id,
                name: name,
                values: values,
                sortOrder: sortOrder,
                document: document,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$BrushProfilesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({document = false}) {
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
                    if (document) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.document,
                                referencedTable: $$BrushProfilesTableReferences
                                    ._documentTable(db),
                                referencedColumn: $$BrushProfilesTableReferences
                                    ._documentTable(db)
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

typedef $$BrushProfilesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BrushProfilesTable,
      BrushProfile,
      $$BrushProfilesTableFilterComposer,
      $$BrushProfilesTableOrderingComposer,
      $$BrushProfilesTableAnnotationComposer,
      $$BrushProfilesTableCreateCompanionBuilder,
      $$BrushProfilesTableUpdateCompanionBuilder,
      (BrushProfile, $$BrushProfilesTableReferences),
      BrushProfile,
      PrefetchHooks Function({bool document})
    >;
typedef $$NodesTableCreateCompanionBuilder =
    NodesCompanion Function({
      Value<int> id,
      required String type,
      required String content,
      required int nodeId,
      required int document,
      required int sortOrder,
      Value<int?> parent,
      required double originX,
      required double originY,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });
typedef $$NodesTableUpdateCompanionBuilder =
    NodesCompanion Function({
      Value<int> id,
      Value<String> type,
      Value<String> content,
      Value<int> nodeId,
      Value<int> document,
      Value<int> sortOrder,
      Value<int?> parent,
      Value<double> originX,
      Value<double> originY,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

final class $$NodesTableReferences
    extends BaseReferences<_$AppDatabase, $NodesTable, Node> {
  $$NodesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $DocumentMetadatasTable _documentTable(_$AppDatabase db) => db
      .documentMetadatas
      .createAlias('nodes__document__document_metadatas__id');

  $$DocumentMetadatasTableProcessedTableManager get document {
    final $_column = $_itemColumn<int>('document')!;

    final manager = $$DocumentMetadatasTableTableManager(
      $_db,
      $_db.documentMetadatas,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_documentTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $NodesTable _parentTable(_$AppDatabase db) =>
      db.nodes.createAlias('nodes__parent__nodes__id');

  $$NodesTableProcessedTableManager? get parent {
    final $_column = $_itemColumn<int>('parent');
    if ($_column == null) return null;
    final manager = $$NodesTableTableManager(
      $_db,
      $_db.nodes,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_parentTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$NodesTableFilterComposer extends Composer<_$AppDatabase, $NodesTable> {
  $$NodesTableFilterComposer({
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

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get nodeId => $composableBuilder(
    column: $table.nodeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get originX => $composableBuilder(
    column: $table.originX,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get originY => $composableBuilder(
    column: $table.originY,
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

  $$DocumentMetadatasTableFilterComposer get document {
    final $$DocumentMetadatasTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.document,
      referencedTable: $db.documentMetadatas,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DocumentMetadatasTableFilterComposer(
            $db: $db,
            $table: $db.documentMetadatas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$NodesTableFilterComposer get parent {
    final $$NodesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.parent,
      referencedTable: $db.nodes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NodesTableFilterComposer(
            $db: $db,
            $table: $db.nodes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$NodesTableOrderingComposer
    extends Composer<_$AppDatabase, $NodesTable> {
  $$NodesTableOrderingComposer({
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

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get nodeId => $composableBuilder(
    column: $table.nodeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get originX => $composableBuilder(
    column: $table.originX,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get originY => $composableBuilder(
    column: $table.originY,
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

  $$DocumentMetadatasTableOrderingComposer get document {
    final $$DocumentMetadatasTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.document,
      referencedTable: $db.documentMetadatas,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DocumentMetadatasTableOrderingComposer(
            $db: $db,
            $table: $db.documentMetadatas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$NodesTableOrderingComposer get parent {
    final $$NodesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.parent,
      referencedTable: $db.nodes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NodesTableOrderingComposer(
            $db: $db,
            $table: $db.nodes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$NodesTableAnnotationComposer
    extends Composer<_$AppDatabase, $NodesTable> {
  $$NodesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<int> get nodeId =>
      $composableBuilder(column: $table.nodeId, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<double> get originX =>
      $composableBuilder(column: $table.originX, builder: (column) => column);

  GeneratedColumn<double> get originY =>
      $composableBuilder(column: $table.originY, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$DocumentMetadatasTableAnnotationComposer get document {
    final $$DocumentMetadatasTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.document,
          referencedTable: $db.documentMetadatas,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$DocumentMetadatasTableAnnotationComposer(
                $db: $db,
                $table: $db.documentMetadatas,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }

  $$NodesTableAnnotationComposer get parent {
    final $$NodesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.parent,
      referencedTable: $db.nodes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NodesTableAnnotationComposer(
            $db: $db,
            $table: $db.nodes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$NodesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $NodesTable,
          Node,
          $$NodesTableFilterComposer,
          $$NodesTableOrderingComposer,
          $$NodesTableAnnotationComposer,
          $$NodesTableCreateCompanionBuilder,
          $$NodesTableUpdateCompanionBuilder,
          (Node, $$NodesTableReferences),
          Node,
          PrefetchHooks Function({bool document, bool parent})
        > {
  $$NodesTableTableManager(_$AppDatabase db, $NodesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NodesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$NodesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$NodesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<int> nodeId = const Value.absent(),
                Value<int> document = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int?> parent = const Value.absent(),
                Value<double> originX = const Value.absent(),
                Value<double> originY = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => NodesCompanion(
                id: id,
                type: type,
                content: content,
                nodeId: nodeId,
                document: document,
                sortOrder: sortOrder,
                parent: parent,
                originX: originX,
                originY: originY,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String type,
                required String content,
                required int nodeId,
                required int document,
                required int sortOrder,
                Value<int?> parent = const Value.absent(),
                required double originX,
                required double originY,
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => NodesCompanion.insert(
                id: id,
                type: type,
                content: content,
                nodeId: nodeId,
                document: document,
                sortOrder: sortOrder,
                parent: parent,
                originX: originX,
                originY: originY,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$NodesTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({document = false, parent = false}) {
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
                    if (document) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.document,
                                referencedTable: $$NodesTableReferences
                                    ._documentTable(db),
                                referencedColumn: $$NodesTableReferences
                                    ._documentTable(db)
                                    .id,
                              )
                              as T;
                    }
                    if (parent) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.parent,
                                referencedTable: $$NodesTableReferences
                                    ._parentTable(db),
                                referencedColumn: $$NodesTableReferences
                                    ._parentTable(db)
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

typedef $$NodesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $NodesTable,
      Node,
      $$NodesTableFilterComposer,
      $$NodesTableOrderingComposer,
      $$NodesTableAnnotationComposer,
      $$NodesTableCreateCompanionBuilder,
      $$NodesTableUpdateCompanionBuilder,
      (Node, $$NodesTableReferences),
      Node,
      PrefetchHooks Function({bool document, bool parent})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$DocumentMetadatasTableTableManager get documentMetadatas =>
      $$DocumentMetadatasTableTableManager(_db, _db.documentMetadatas);
  $$BrushProfilesTableTableManager get brushProfiles =>
      $$BrushProfilesTableTableManager(_db, _db.brushProfiles);
  $$NodesTableTableManager get nodes =>
      $$NodesTableTableManager(_db, _db.nodes);
}
