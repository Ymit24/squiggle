// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $DocumentsTable extends Documents
    with TableInfo<$DocumentsTable, DocumentRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DocumentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
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
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _previewPngMeta = const VerificationMeta(
    'previewPng',
  );
  @override
  late final GeneratedColumn<Uint8List> previewPng = GeneratedColumn<Uint8List>(
    'preview_png',
    aliasedName,
    true,
    type: DriftSqlType.blob,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    createdAt,
    updatedAt,
    previewPng,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'documents';
  @override
  VerificationContext validateIntegrity(
    Insertable<DocumentRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
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
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('preview_png')) {
      context.handle(
        _previewPngMeta,
        previewPng.isAcceptableOrUnknown(data['preview_png']!, _previewPngMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DocumentRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DocumentRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
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
      previewPng: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}preview_png'],
      ),
    );
  }

  @override
  $DocumentsTable createAlias(String alias) {
    return $DocumentsTable(attachedDatabase, alias);
  }
}

class DocumentRow extends DataClass implements Insertable<DocumentRow> {
  final String id;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Cached library thumbnail; null until previews are generated.
  final Uint8List? previewPng;
  const DocumentRow({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    this.previewPng,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || previewPng != null) {
      map['preview_png'] = Variable<Uint8List>(previewPng);
    }
    return map;
  }

  DocumentsCompanion toCompanion(bool nullToAbsent) {
    return DocumentsCompanion(
      id: Value(id),
      name: Value(name),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      previewPng: previewPng == null && nullToAbsent
          ? const Value.absent()
          : Value(previewPng),
    );
  }

  factory DocumentRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DocumentRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      previewPng: serializer.fromJson<Uint8List?>(json['previewPng']),
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
      'previewPng': serializer.toJson<Uint8List?>(previewPng),
    };
  }

  DocumentRow copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<Uint8List?> previewPng = const Value.absent(),
  }) => DocumentRow(
    id: id ?? this.id,
    name: name ?? this.name,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    previewPng: previewPng.present ? previewPng.value : this.previewPng,
  );
  DocumentRow copyWithCompanion(DocumentsCompanion data) {
    return DocumentRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      previewPng: data.previewPng.present
          ? data.previewPng.value
          : this.previewPng,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DocumentRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('previewPng: $previewPng')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    createdAt,
    updatedAt,
    $driftBlobEquality.hash(previewPng),
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DocumentRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          $driftBlobEquality.equals(other.previewPng, this.previewPng));
}

class DocumentsCompanion extends UpdateCompanion<DocumentRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<Uint8List?> previewPng;
  final Value<int> rowid;
  const DocumentsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.previewPng = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DocumentsCompanion.insert({
    required String id,
    required String name,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.previewPng = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<DocumentRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<Uint8List>? previewPng,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (previewPng != null) 'preview_png': previewPng,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DocumentsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<Uint8List?>? previewPng,
    Value<int>? rowid,
  }) {
    return DocumentsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      previewPng: previewPng ?? this.previewPng,
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
    if (previewPng.present) {
      map['preview_png'] = Variable<Uint8List>(previewPng.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DocumentsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('previewPng: $previewPng, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DocumentBodiesTable extends DocumentBodies
    with TableInfo<$DocumentBodiesTable, DocumentBodyRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DocumentBodiesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _documentIdMeta = const VerificationMeta(
    'documentId',
  );
  @override
  late final GeneratedColumn<String> documentId = GeneratedColumn<String>(
    'document_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES documents (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _formatVersionMeta = const VerificationMeta(
    'formatVersion',
  );
  @override
  late final GeneratedColumn<int> formatVersion = GeneratedColumn<int>(
    'format_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
    'body',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [documentId, formatVersion, body];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'document_bodies';
  @override
  VerificationContext validateIntegrity(
    Insertable<DocumentBodyRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('document_id')) {
      context.handle(
        _documentIdMeta,
        documentId.isAcceptableOrUnknown(data['document_id']!, _documentIdMeta),
      );
    } else if (isInserting) {
      context.missing(_documentIdMeta);
    }
    if (data.containsKey('format_version')) {
      context.handle(
        _formatVersionMeta,
        formatVersion.isAcceptableOrUnknown(
          data['format_version']!,
          _formatVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_formatVersionMeta);
    }
    if (data.containsKey('body')) {
      context.handle(
        _bodyMeta,
        body.isAcceptableOrUnknown(data['body']!, _bodyMeta),
      );
    } else if (isInserting) {
      context.missing(_bodyMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {documentId};
  @override
  DocumentBodyRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DocumentBodyRow(
      documentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}document_id'],
      )!,
      formatVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}format_version'],
      )!,
      body: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}body'],
      )!,
    );
  }

  @override
  $DocumentBodiesTable createAlias(String alias) {
    return $DocumentBodiesTable(attachedDatabase, alias);
  }
}

class DocumentBodyRow extends DataClass implements Insertable<DocumentBodyRow> {
  final String documentId;

  /// `dataModelFormatVersion` the [body] was written with.
  final int formatVersion;

  /// `data.Document.encode()`.
  final String body;
  const DocumentBodyRow({
    required this.documentId,
    required this.formatVersion,
    required this.body,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['document_id'] = Variable<String>(documentId);
    map['format_version'] = Variable<int>(formatVersion);
    map['body'] = Variable<String>(body);
    return map;
  }

  DocumentBodiesCompanion toCompanion(bool nullToAbsent) {
    return DocumentBodiesCompanion(
      documentId: Value(documentId),
      formatVersion: Value(formatVersion),
      body: Value(body),
    );
  }

  factory DocumentBodyRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DocumentBodyRow(
      documentId: serializer.fromJson<String>(json['documentId']),
      formatVersion: serializer.fromJson<int>(json['formatVersion']),
      body: serializer.fromJson<String>(json['body']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'documentId': serializer.toJson<String>(documentId),
      'formatVersion': serializer.toJson<int>(formatVersion),
      'body': serializer.toJson<String>(body),
    };
  }

  DocumentBodyRow copyWith({
    String? documentId,
    int? formatVersion,
    String? body,
  }) => DocumentBodyRow(
    documentId: documentId ?? this.documentId,
    formatVersion: formatVersion ?? this.formatVersion,
    body: body ?? this.body,
  );
  DocumentBodyRow copyWithCompanion(DocumentBodiesCompanion data) {
    return DocumentBodyRow(
      documentId: data.documentId.present
          ? data.documentId.value
          : this.documentId,
      formatVersion: data.formatVersion.present
          ? data.formatVersion.value
          : this.formatVersion,
      body: data.body.present ? data.body.value : this.body,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DocumentBodyRow(')
          ..write('documentId: $documentId, ')
          ..write('formatVersion: $formatVersion, ')
          ..write('body: $body')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(documentId, formatVersion, body);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DocumentBodyRow &&
          other.documentId == this.documentId &&
          other.formatVersion == this.formatVersion &&
          other.body == this.body);
}

class DocumentBodiesCompanion extends UpdateCompanion<DocumentBodyRow> {
  final Value<String> documentId;
  final Value<int> formatVersion;
  final Value<String> body;
  final Value<int> rowid;
  const DocumentBodiesCompanion({
    this.documentId = const Value.absent(),
    this.formatVersion = const Value.absent(),
    this.body = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DocumentBodiesCompanion.insert({
    required String documentId,
    required int formatVersion,
    required String body,
    this.rowid = const Value.absent(),
  }) : documentId = Value(documentId),
       formatVersion = Value(formatVersion),
       body = Value(body);
  static Insertable<DocumentBodyRow> custom({
    Expression<String>? documentId,
    Expression<int>? formatVersion,
    Expression<String>? body,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (documentId != null) 'document_id': documentId,
      if (formatVersion != null) 'format_version': formatVersion,
      if (body != null) 'body': body,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DocumentBodiesCompanion copyWith({
    Value<String>? documentId,
    Value<int>? formatVersion,
    Value<String>? body,
    Value<int>? rowid,
  }) {
    return DocumentBodiesCompanion(
      documentId: documentId ?? this.documentId,
      formatVersion: formatVersion ?? this.formatVersion,
      body: body ?? this.body,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (documentId.present) {
      map['document_id'] = Variable<String>(documentId.value);
    }
    if (formatVersion.present) {
      map['format_version'] = Variable<int>(formatVersion.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DocumentBodiesCompanion(')
          ..write('documentId: $documentId, ')
          ..write('formatVersion: $formatVersion, ')
          ..write('body: $body, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ImagesTable extends Images with TableInfo<$ImagesTable, ImageRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ImagesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _hashMeta = const VerificationMeta('hash');
  @override
  late final GeneratedColumn<String> hash = GeneratedColumn<String>(
    'hash',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  List<GeneratedColumn> get $columns => [hash, bytes, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'images';
  @override
  VerificationContext validateIntegrity(
    Insertable<ImageRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('hash')) {
      context.handle(
        _hashMeta,
        hash.isAcceptableOrUnknown(data['hash']!, _hashMeta),
      );
    } else if (isInserting) {
      context.missing(_hashMeta);
    }
    if (data.containsKey('bytes')) {
      context.handle(
        _bytesMeta,
        bytes.isAcceptableOrUnknown(data['bytes']!, _bytesMeta),
      );
    } else if (isInserting) {
      context.missing(_bytesMeta);
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
  Set<GeneratedColumn> get $primaryKey => {hash};
  @override
  ImageRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ImageRow(
      hash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hash'],
      )!,
      bytes: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}bytes'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $ImagesTable createAlias(String alias) {
    return $ImagesTable(attachedDatabase, alias);
  }
}

class ImageRow extends DataClass implements Insertable<ImageRow> {
  final String hash;
  final Uint8List bytes;
  final DateTime createdAt;
  const ImageRow({
    required this.hash,
    required this.bytes,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['hash'] = Variable<String>(hash);
    map['bytes'] = Variable<Uint8List>(bytes);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  ImagesCompanion toCompanion(bool nullToAbsent) {
    return ImagesCompanion(
      hash: Value(hash),
      bytes: Value(bytes),
      createdAt: Value(createdAt),
    );
  }

  factory ImageRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ImageRow(
      hash: serializer.fromJson<String>(json['hash']),
      bytes: serializer.fromJson<Uint8List>(json['bytes']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'hash': serializer.toJson<String>(hash),
      'bytes': serializer.toJson<Uint8List>(bytes),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  ImageRow copyWith({String? hash, Uint8List? bytes, DateTime? createdAt}) =>
      ImageRow(
        hash: hash ?? this.hash,
        bytes: bytes ?? this.bytes,
        createdAt: createdAt ?? this.createdAt,
      );
  ImageRow copyWithCompanion(ImagesCompanion data) {
    return ImageRow(
      hash: data.hash.present ? data.hash.value : this.hash,
      bytes: data.bytes.present ? data.bytes.value : this.bytes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ImageRow(')
          ..write('hash: $hash, ')
          ..write('bytes: $bytes, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(hash, $driftBlobEquality.hash(bytes), createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ImageRow &&
          other.hash == this.hash &&
          $driftBlobEquality.equals(other.bytes, this.bytes) &&
          other.createdAt == this.createdAt);
}

class ImagesCompanion extends UpdateCompanion<ImageRow> {
  final Value<String> hash;
  final Value<Uint8List> bytes;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const ImagesCompanion({
    this.hash = const Value.absent(),
    this.bytes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ImagesCompanion.insert({
    required String hash,
    required Uint8List bytes,
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : hash = Value(hash),
       bytes = Value(bytes),
       createdAt = Value(createdAt);
  static Insertable<ImageRow> custom({
    Expression<String>? hash,
    Expression<Uint8List>? bytes,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (hash != null) 'hash': hash,
      if (bytes != null) 'bytes': bytes,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ImagesCompanion copyWith({
    Value<String>? hash,
    Value<Uint8List>? bytes,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return ImagesCompanion(
      hash: hash ?? this.hash,
      bytes: bytes ?? this.bytes,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (hash.present) {
      map['hash'] = Variable<String>(hash.value);
    }
    if (bytes.present) {
      map['bytes'] = Variable<Uint8List>(bytes.value);
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
    return (StringBuffer('ImagesCompanion(')
          ..write('hash: $hash, ')
          ..write('bytes: $bytes, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ImageRefsTable extends ImageRefs
    with TableInfo<$ImageRefsTable, ImageRefRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ImageRefsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _documentIdMeta = const VerificationMeta(
    'documentId',
  );
  @override
  late final GeneratedColumn<String> documentId = GeneratedColumn<String>(
    'document_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES documents (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _imageHashMeta = const VerificationMeta(
    'imageHash',
  );
  @override
  late final GeneratedColumn<String> imageHash = GeneratedColumn<String>(
    'image_hash',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [documentId, imageHash];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'image_refs';
  @override
  VerificationContext validateIntegrity(
    Insertable<ImageRefRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('document_id')) {
      context.handle(
        _documentIdMeta,
        documentId.isAcceptableOrUnknown(data['document_id']!, _documentIdMeta),
      );
    } else if (isInserting) {
      context.missing(_documentIdMeta);
    }
    if (data.containsKey('image_hash')) {
      context.handle(
        _imageHashMeta,
        imageHash.isAcceptableOrUnknown(data['image_hash']!, _imageHashMeta),
      );
    } else if (isInserting) {
      context.missing(_imageHashMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {documentId, imageHash};
  @override
  ImageRefRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ImageRefRow(
      documentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}document_id'],
      )!,
      imageHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_hash'],
      )!,
    );
  }

  @override
  $ImageRefsTable createAlias(String alias) {
    return $ImageRefsTable(attachedDatabase, alias);
  }
}

class ImageRefRow extends DataClass implements Insertable<ImageRefRow> {
  final String documentId;
  final String imageHash;
  const ImageRefRow({required this.documentId, required this.imageHash});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['document_id'] = Variable<String>(documentId);
    map['image_hash'] = Variable<String>(imageHash);
    return map;
  }

  ImageRefsCompanion toCompanion(bool nullToAbsent) {
    return ImageRefsCompanion(
      documentId: Value(documentId),
      imageHash: Value(imageHash),
    );
  }

  factory ImageRefRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ImageRefRow(
      documentId: serializer.fromJson<String>(json['documentId']),
      imageHash: serializer.fromJson<String>(json['imageHash']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'documentId': serializer.toJson<String>(documentId),
      'imageHash': serializer.toJson<String>(imageHash),
    };
  }

  ImageRefRow copyWith({String? documentId, String? imageHash}) => ImageRefRow(
    documentId: documentId ?? this.documentId,
    imageHash: imageHash ?? this.imageHash,
  );
  ImageRefRow copyWithCompanion(ImageRefsCompanion data) {
    return ImageRefRow(
      documentId: data.documentId.present
          ? data.documentId.value
          : this.documentId,
      imageHash: data.imageHash.present ? data.imageHash.value : this.imageHash,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ImageRefRow(')
          ..write('documentId: $documentId, ')
          ..write('imageHash: $imageHash')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(documentId, imageHash);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ImageRefRow &&
          other.documentId == this.documentId &&
          other.imageHash == this.imageHash);
}

class ImageRefsCompanion extends UpdateCompanion<ImageRefRow> {
  final Value<String> documentId;
  final Value<String> imageHash;
  final Value<int> rowid;
  const ImageRefsCompanion({
    this.documentId = const Value.absent(),
    this.imageHash = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ImageRefsCompanion.insert({
    required String documentId,
    required String imageHash,
    this.rowid = const Value.absent(),
  }) : documentId = Value(documentId),
       imageHash = Value(imageHash);
  static Insertable<ImageRefRow> custom({
    Expression<String>? documentId,
    Expression<String>? imageHash,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (documentId != null) 'document_id': documentId,
      if (imageHash != null) 'image_hash': imageHash,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ImageRefsCompanion copyWith({
    Value<String>? documentId,
    Value<String>? imageHash,
    Value<int>? rowid,
  }) {
    return ImageRefsCompanion(
      documentId: documentId ?? this.documentId,
      imageHash: imageHash ?? this.imageHash,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (documentId.present) {
      map['document_id'] = Variable<String>(documentId.value);
    }
    if (imageHash.present) {
      map['image_hash'] = Variable<String>(imageHash.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ImageRefsCompanion(')
          ..write('documentId: $documentId, ')
          ..write('imageHash: $imageHash, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AppStateTable extends AppState
    with TableInfo<$AppStateTable, AppStateRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppStateTable(this.attachedDatabase, [this._alias]);
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
  static const String $name = 'app_state';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppStateRow> instance, {
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
  AppStateRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppStateRow(
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
  $AppStateTable createAlias(String alias) {
    return $AppStateTable(attachedDatabase, alias);
  }
}

class AppStateRow extends DataClass implements Insertable<AppStateRow> {
  final String key;
  final String value;
  const AppStateRow({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  AppStateCompanion toCompanion(bool nullToAbsent) {
    return AppStateCompanion(key: Value(key), value: Value(value));
  }

  factory AppStateRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppStateRow(
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

  AppStateRow copyWith({String? key, String? value}) =>
      AppStateRow(key: key ?? this.key, value: value ?? this.value);
  AppStateRow copyWithCompanion(AppStateCompanion data) {
    return AppStateRow(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppStateRow(')
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
      (other is AppStateRow &&
          other.key == this.key &&
          other.value == this.value);
}

class AppStateCompanion extends UpdateCompanion<AppStateRow> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const AppStateCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppStateCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<AppStateRow> custom({
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

  AppStateCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return AppStateCompanion(
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
    return (StringBuffer('AppStateCompanion(')
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
  late final $DocumentsTable documents = $DocumentsTable(this);
  late final $DocumentBodiesTable documentBodies = $DocumentBodiesTable(this);
  late final $ImagesTable images = $ImagesTable(this);
  late final $ImageRefsTable imageRefs = $ImageRefsTable(this);
  late final $AppStateTable appState = $AppStateTable(this);
  late final DocumentsDao documentsDao = DocumentsDao(this as AppDatabase);
  late final ImagesDao imagesDao = ImagesDao(this as AppDatabase);
  late final AppStateDao appStateDao = AppStateDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    documents,
    documentBodies,
    images,
    imageRefs,
    appState,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'documents',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('document_bodies', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'documents',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('image_refs', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$DocumentsTableCreateCompanionBuilder = DocumentsCompanion Function({
  required String id,
  required String name,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<Uint8List?> previewPng,
  Value<int> rowid,
});
typedef $$DocumentsTableUpdateCompanionBuilder = DocumentsCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<Uint8List?> previewPng,
  Value<int> rowid,
});

final class $$DocumentsTableReferences
    extends BaseReferences<_$AppDatabase, $DocumentsTable, DocumentRow> {
  $$DocumentsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$DocumentBodiesTable, List<DocumentBodyRow>>
  _documentBodiesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.documentBodies,
    aliasName: 'documents__id__document_bodies__document_id',
  );

  $$DocumentBodiesTableProcessedTableManager get documentBodiesRefs {
    final manager = $$DocumentBodiesTableTableManager(
      $_db,
      $_db.documentBodies,
    ).filter((f) => f.documentId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_documentBodiesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ImageRefsTable, List<ImageRefRow>>
  _imageRefsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.imageRefs,
    aliasName: 'documents__id__image_refs__document_id',
  );

  $$ImageRefsTableProcessedTableManager get imageRefsRefs {
    final manager = $$ImageRefsTableTableManager(
      $_db,
      $_db.imageRefs,
    ).filter((f) => f.documentId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_imageRefsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$DocumentsTableFilterComposer
    extends Composer<_$AppDatabase, $DocumentsTable> {
  $$DocumentsTableFilterComposer({
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

  ColumnFilters<Uint8List> get previewPng => $composableBuilder(
    column: $table.previewPng,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> documentBodiesRefs(
    Expression<bool> Function($$DocumentBodiesTableFilterComposer f) f,
  ) {
    final $$DocumentBodiesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.documentBodies,
      getReferencedColumn: (t) => t.documentId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DocumentBodiesTableFilterComposer(
            $db: $db,
            $table: $db.documentBodies,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> imageRefsRefs(
    Expression<bool> Function($$ImageRefsTableFilterComposer f) f,
  ) {
    final $$ImageRefsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.imageRefs,
      getReferencedColumn: (t) => t.documentId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ImageRefsTableFilterComposer(
            $db: $db,
            $table: $db.imageRefs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$DocumentsTableOrderingComposer
    extends Composer<_$AppDatabase, $DocumentsTable> {
  $$DocumentsTableOrderingComposer({
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

  ColumnOrderings<Uint8List> get previewPng => $composableBuilder(
    column: $table.previewPng,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DocumentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DocumentsTable> {
  $$DocumentsTableAnnotationComposer({
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

  GeneratedColumn<Uint8List> get previewPng => $composableBuilder(
    column: $table.previewPng,
    builder: (column) => column,
  );

  Expression<T> documentBodiesRefs<T extends Object>(
    Expression<T> Function($$DocumentBodiesTableAnnotationComposer a) f,
  ) {
    final $$DocumentBodiesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.documentBodies,
      getReferencedColumn: (t) => t.documentId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DocumentBodiesTableAnnotationComposer(
            $db: $db,
            $table: $db.documentBodies,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> imageRefsRefs<T extends Object>(
    Expression<T> Function($$ImageRefsTableAnnotationComposer a) f,
  ) {
    final $$ImageRefsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.imageRefs,
      getReferencedColumn: (t) => t.documentId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ImageRefsTableAnnotationComposer(
            $db: $db,
            $table: $db.imageRefs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$DocumentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DocumentsTable,
          DocumentRow,
          $$DocumentsTableFilterComposer,
          $$DocumentsTableOrderingComposer,
          $$DocumentsTableAnnotationComposer,
          $$DocumentsTableCreateCompanionBuilder,
          $$DocumentsTableUpdateCompanionBuilder,
          (DocumentRow, $$DocumentsTableReferences),
          DocumentRow,
          PrefetchHooks Function({bool documentBodiesRefs, bool imageRefsRefs})
        > {
  $$DocumentsTableTableManager(_$AppDatabase db, $DocumentsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DocumentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DocumentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DocumentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<Uint8List?> previewPng = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DocumentsCompanion(
                id: id,
                name: name,
                createdAt: createdAt,
                updatedAt: updatedAt,
                previewPng: previewPng,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<Uint8List?> previewPng = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DocumentsCompanion.insert(
                id: id,
                name: name,
                createdAt: createdAt,
                updatedAt: updatedAt,
                previewPng: previewPng,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$DocumentsTable, DocumentRow>(table),
                  $$DocumentsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({documentBodiesRefs = false, imageRefsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (documentBodiesRefs) db.documentBodies,
                    if (imageRefsRefs) db.imageRefs,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (documentBodiesRefs)
                        await $_getPrefetchedData<
                          DocumentRow,
                          $DocumentsTable,
                          DocumentBodyRow
                        >(
                          currentTable: table,
                          referencedTable: $$DocumentsTableReferences
                              ._documentBodiesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$DocumentsTableReferences(
                                db,
                                table,
                                p0,
                              ).documentBodiesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.documentId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (imageRefsRefs)
                        await $_getPrefetchedData<
                          DocumentRow,
                          $DocumentsTable,
                          ImageRefRow
                        >(
                          currentTable: table,
                          referencedTable: $$DocumentsTableReferences
                              ._imageRefsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$DocumentsTableReferences(
                                db,
                                table,
                                p0,
                              ).imageRefsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.documentId == item.id,
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

typedef $$DocumentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DocumentsTable,
      DocumentRow,
      $$DocumentsTableFilterComposer,
      $$DocumentsTableOrderingComposer,
      $$DocumentsTableAnnotationComposer,
      $$DocumentsTableCreateCompanionBuilder,
      $$DocumentsTableUpdateCompanionBuilder,
      (DocumentRow, $$DocumentsTableReferences),
      DocumentRow,
      PrefetchHooks Function({bool documentBodiesRefs, bool imageRefsRefs})
    >;
typedef $$DocumentBodiesTableCreateCompanionBuilder =
    DocumentBodiesCompanion Function({
      required String documentId,
      required int formatVersion,
      required String body,
      Value<int> rowid,
    });
typedef $$DocumentBodiesTableUpdateCompanionBuilder =
    DocumentBodiesCompanion Function({
      Value<String> documentId,
      Value<int> formatVersion,
      Value<String> body,
      Value<int> rowid,
    });

final class $$DocumentBodiesTableReferences
    extends
        BaseReferences<_$AppDatabase, $DocumentBodiesTable, DocumentBodyRow> {
  $$DocumentBodiesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $DocumentsTable _documentIdTable(_$AppDatabase db) =>
      db.documents.createAlias('document_bodies__document_id__documents__id');

  $$DocumentsTableProcessedTableManager get documentId {
    final $_column = $_itemColumn<String>('document_id')!;

    final manager = $$DocumentsTableTableManager(
      $_db,
      $_db.documents,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_documentIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$DocumentBodiesTableFilterComposer
    extends Composer<_$AppDatabase, $DocumentBodiesTable> {
  $$DocumentBodiesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get formatVersion => $composableBuilder(
    column: $table.formatVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnFilters(column),
  );

  $$DocumentsTableFilterComposer get documentId {
    final $$DocumentsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.documentId,
      referencedTable: $db.documents,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DocumentsTableFilterComposer(
            $db: $db,
            $table: $db.documents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DocumentBodiesTableOrderingComposer
    extends Composer<_$AppDatabase, $DocumentBodiesTable> {
  $$DocumentBodiesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get formatVersion => $composableBuilder(
    column: $table.formatVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnOrderings(column),
  );

  $$DocumentsTableOrderingComposer get documentId {
    final $$DocumentsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.documentId,
      referencedTable: $db.documents,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DocumentsTableOrderingComposer(
            $db: $db,
            $table: $db.documents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DocumentBodiesTableAnnotationComposer
    extends Composer<_$AppDatabase, $DocumentBodiesTable> {
  $$DocumentBodiesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get formatVersion => $composableBuilder(
    column: $table.formatVersion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);

  $$DocumentsTableAnnotationComposer get documentId {
    final $$DocumentsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.documentId,
      referencedTable: $db.documents,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DocumentsTableAnnotationComposer(
            $db: $db,
            $table: $db.documents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DocumentBodiesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DocumentBodiesTable,
          DocumentBodyRow,
          $$DocumentBodiesTableFilterComposer,
          $$DocumentBodiesTableOrderingComposer,
          $$DocumentBodiesTableAnnotationComposer,
          $$DocumentBodiesTableCreateCompanionBuilder,
          $$DocumentBodiesTableUpdateCompanionBuilder,
          (DocumentBodyRow, $$DocumentBodiesTableReferences),
          DocumentBodyRow,
          PrefetchHooks Function({bool documentId})
        > {
  $$DocumentBodiesTableTableManager(
    _$AppDatabase db,
    $DocumentBodiesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DocumentBodiesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DocumentBodiesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DocumentBodiesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> documentId = const Value.absent(),
                Value<int> formatVersion = const Value.absent(),
                Value<String> body = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DocumentBodiesCompanion(
                documentId: documentId,
                formatVersion: formatVersion,
                body: body,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String documentId,
                required int formatVersion,
                required String body,
                Value<int> rowid = const Value.absent(),
              }) => DocumentBodiesCompanion.insert(
                documentId: documentId,
                formatVersion: formatVersion,
                body: body,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$DocumentBodiesTable, DocumentBodyRow>(table),
                  $$DocumentBodiesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({documentId = false}) {
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
                    if (documentId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.documentId,
                        referencedTable: $$DocumentBodiesTableReferences
                            ._documentIdTable(db),
                        referencedColumn: $$DocumentBodiesTableReferences
                            ._documentIdTable(db)
                            .id,
                      ) as T;
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

typedef $$DocumentBodiesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DocumentBodiesTable,
      DocumentBodyRow,
      $$DocumentBodiesTableFilterComposer,
      $$DocumentBodiesTableOrderingComposer,
      $$DocumentBodiesTableAnnotationComposer,
      $$DocumentBodiesTableCreateCompanionBuilder,
      $$DocumentBodiesTableUpdateCompanionBuilder,
      (DocumentBodyRow, $$DocumentBodiesTableReferences),
      DocumentBodyRow,
      PrefetchHooks Function({bool documentId})
    >;
typedef $$ImagesTableCreateCompanionBuilder = ImagesCompanion Function({
  required String hash,
  required Uint8List bytes,
  required DateTime createdAt,
  Value<int> rowid,
});
typedef $$ImagesTableUpdateCompanionBuilder = ImagesCompanion Function({
  Value<String> hash,
  Value<Uint8List> bytes,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

class $$ImagesTableFilterComposer
    extends Composer<_$AppDatabase, $ImagesTable> {
  $$ImagesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get hash => $composableBuilder(
    column: $table.hash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get bytes => $composableBuilder(
    column: $table.bytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ImagesTableOrderingComposer
    extends Composer<_$AppDatabase, $ImagesTable> {
  $$ImagesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get hash => $composableBuilder(
    column: $table.hash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get bytes => $composableBuilder(
    column: $table.bytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ImagesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ImagesTable> {
  $$ImagesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get hash =>
      $composableBuilder(column: $table.hash, builder: (column) => column);

  GeneratedColumn<Uint8List> get bytes =>
      $composableBuilder(column: $table.bytes, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$ImagesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ImagesTable,
          ImageRow,
          $$ImagesTableFilterComposer,
          $$ImagesTableOrderingComposer,
          $$ImagesTableAnnotationComposer,
          $$ImagesTableCreateCompanionBuilder,
          $$ImagesTableUpdateCompanionBuilder,
          (ImageRow, BaseReferences<_$AppDatabase, $ImagesTable, ImageRow>),
          ImageRow,
          PrefetchHooks Function()
        > {
  $$ImagesTableTableManager(_$AppDatabase db, $ImagesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ImagesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ImagesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ImagesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> hash = const Value.absent(),
                Value<Uint8List> bytes = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ImagesCompanion(
                hash: hash,
                bytes: bytes,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String hash,
                required Uint8List bytes,
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => ImagesCompanion.insert(
                hash: hash,
                bytes: bytes,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ImagesTable, ImageRow>(table),
                  BaseReferences<_$AppDatabase, $ImagesTable, ImageRow>(
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

typedef $$ImagesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ImagesTable,
      ImageRow,
      $$ImagesTableFilterComposer,
      $$ImagesTableOrderingComposer,
      $$ImagesTableAnnotationComposer,
      $$ImagesTableCreateCompanionBuilder,
      $$ImagesTableUpdateCompanionBuilder,
      (ImageRow, BaseReferences<_$AppDatabase, $ImagesTable, ImageRow>),
      ImageRow,
      PrefetchHooks Function()
    >;
typedef $$ImageRefsTableCreateCompanionBuilder = ImageRefsCompanion Function({
  required String documentId,
  required String imageHash,
  Value<int> rowid,
});
typedef $$ImageRefsTableUpdateCompanionBuilder = ImageRefsCompanion Function({
  Value<String> documentId,
  Value<String> imageHash,
  Value<int> rowid,
});

final class $$ImageRefsTableReferences
    extends BaseReferences<_$AppDatabase, $ImageRefsTable, ImageRefRow> {
  $$ImageRefsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $DocumentsTable _documentIdTable(_$AppDatabase db) =>
      db.documents.createAlias('image_refs__document_id__documents__id');

  $$DocumentsTableProcessedTableManager get documentId {
    final $_column = $_itemColumn<String>('document_id')!;

    final manager = $$DocumentsTableTableManager(
      $_db,
      $_db.documents,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_documentIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ImageRefsTableFilterComposer
    extends Composer<_$AppDatabase, $ImageRefsTable> {
  $$ImageRefsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get imageHash => $composableBuilder(
    column: $table.imageHash,
    builder: (column) => ColumnFilters(column),
  );

  $$DocumentsTableFilterComposer get documentId {
    final $$DocumentsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.documentId,
      referencedTable: $db.documents,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DocumentsTableFilterComposer(
            $db: $db,
            $table: $db.documents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ImageRefsTableOrderingComposer
    extends Composer<_$AppDatabase, $ImageRefsTable> {
  $$ImageRefsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get imageHash => $composableBuilder(
    column: $table.imageHash,
    builder: (column) => ColumnOrderings(column),
  );

  $$DocumentsTableOrderingComposer get documentId {
    final $$DocumentsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.documentId,
      referencedTable: $db.documents,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DocumentsTableOrderingComposer(
            $db: $db,
            $table: $db.documents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ImageRefsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ImageRefsTable> {
  $$ImageRefsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get imageHash =>
      $composableBuilder(column: $table.imageHash, builder: (column) => column);

  $$DocumentsTableAnnotationComposer get documentId {
    final $$DocumentsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.documentId,
      referencedTable: $db.documents,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DocumentsTableAnnotationComposer(
            $db: $db,
            $table: $db.documents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ImageRefsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ImageRefsTable,
          ImageRefRow,
          $$ImageRefsTableFilterComposer,
          $$ImageRefsTableOrderingComposer,
          $$ImageRefsTableAnnotationComposer,
          $$ImageRefsTableCreateCompanionBuilder,
          $$ImageRefsTableUpdateCompanionBuilder,
          (ImageRefRow, $$ImageRefsTableReferences),
          ImageRefRow,
          PrefetchHooks Function({bool documentId})
        > {
  $$ImageRefsTableTableManager(_$AppDatabase db, $ImageRefsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ImageRefsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ImageRefsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ImageRefsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> documentId = const Value.absent(),
                Value<String> imageHash = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ImageRefsCompanion(
                documentId: documentId,
                imageHash: imageHash,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String documentId,
                required String imageHash,
                Value<int> rowid = const Value.absent(),
              }) => ImageRefsCompanion.insert(
                documentId: documentId,
                imageHash: imageHash,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ImageRefsTable, ImageRefRow>(table),
                  $$ImageRefsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({documentId = false}) {
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
                    if (documentId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.documentId,
                        referencedTable: $$ImageRefsTableReferences
                            ._documentIdTable(db),
                        referencedColumn: $$ImageRefsTableReferences
                            ._documentIdTable(db)
                            .id,
                      ) as T;
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

typedef $$ImageRefsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ImageRefsTable,
      ImageRefRow,
      $$ImageRefsTableFilterComposer,
      $$ImageRefsTableOrderingComposer,
      $$ImageRefsTableAnnotationComposer,
      $$ImageRefsTableCreateCompanionBuilder,
      $$ImageRefsTableUpdateCompanionBuilder,
      (ImageRefRow, $$ImageRefsTableReferences),
      ImageRefRow,
      PrefetchHooks Function({bool documentId})
    >;
typedef $$AppStateTableCreateCompanionBuilder = AppStateCompanion Function({
  required String key,
  required String value,
  Value<int> rowid,
});
typedef $$AppStateTableUpdateCompanionBuilder = AppStateCompanion Function({
  Value<String> key,
  Value<String> value,
  Value<int> rowid,
});

class $$AppStateTableFilterComposer
    extends Composer<_$AppDatabase, $AppStateTable> {
  $$AppStateTableFilterComposer({
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

class $$AppStateTableOrderingComposer
    extends Composer<_$AppDatabase, $AppStateTable> {
  $$AppStateTableOrderingComposer({
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

class $$AppStateTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppStateTable> {
  $$AppStateTableAnnotationComposer({
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

class $$AppStateTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AppStateTable,
          AppStateRow,
          $$AppStateTableFilterComposer,
          $$AppStateTableOrderingComposer,
          $$AppStateTableAnnotationComposer,
          $$AppStateTableCreateCompanionBuilder,
          $$AppStateTableUpdateCompanionBuilder,
          (
            AppStateRow,
            BaseReferences<_$AppDatabase, $AppStateTable, AppStateRow>,
          ),
          AppStateRow,
          PrefetchHooks Function()
        > {
  $$AppStateTableTableManager(_$AppDatabase db, $AppStateTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppStateTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppStateTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppStateTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => AppStateCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback: ({
            required String key,
            required String value,
            Value<int> rowid = const Value.absent(),
          }) => AppStateCompanion.insert(key: key, value: value, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AppStateTable, AppStateRow>(table),
                  BaseReferences<_$AppDatabase, $AppStateTable, AppStateRow>(
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

typedef $$AppStateTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AppStateTable,
      AppStateRow,
      $$AppStateTableFilterComposer,
      $$AppStateTableOrderingComposer,
      $$AppStateTableAnnotationComposer,
      $$AppStateTableCreateCompanionBuilder,
      $$AppStateTableUpdateCompanionBuilder,
      (AppStateRow, BaseReferences<_$AppDatabase, $AppStateTable, AppStateRow>),
      AppStateRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$DocumentsTableTableManager get documents =>
      $$DocumentsTableTableManager(_db, _db.documents);
  $$DocumentBodiesTableTableManager get documentBodies =>
      $$DocumentBodiesTableTableManager(_db, _db.documentBodies);
  $$ImagesTableTableManager get images =>
      $$ImagesTableTableManager(_db, _db.images);
  $$ImageRefsTableTableManager get imageRefs =>
      $$ImageRefsTableTableManager(_db, _db.imageRefs);
  $$AppStateTableTableManager get appState =>
      $$AppStateTableTableManager(_db, _db.appState);
}
