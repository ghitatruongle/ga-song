// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: experimental_member_use

part of 'cover_art_cache.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetCoverArtCacheCollection on Isar {
  IsarCollection<CoverArtCache> get coverArtCaches => this.collection();
}

const CoverArtCacheSchema = CollectionSchema(
  name: r'CoverArtCache',
  id: 5771803829804902709,
  properties: {
    r'bytes': PropertySchema(
      id: 0,
      name: r'bytes',
      type: IsarType.longList,
    ),
    r'fileName': PropertySchema(
      id: 1,
      name: r'fileName',
      type: IsarType.string,
    ),
    r'lastAccessed': PropertySchema(
      id: 2,
      name: r'lastAccessed',
      type: IsarType.dateTime,
    )
  },
  estimateSize: _coverArtCacheEstimateSize,
  serialize: _coverArtCacheSerialize,
  deserialize: _coverArtCacheDeserialize,
  deserializeProp: _coverArtCacheDeserializeProp,
  idName: r'id',
  indexes: {
    r'fileName': IndexSchema(
      id: -6213672517780651480,
      name: r'fileName',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'fileName',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _coverArtCacheGetId,
  getLinks: _coverArtCacheGetLinks,
  attach: _coverArtCacheAttach,
  version: '3.1.0+1',
);

int _coverArtCacheEstimateSize(
  CoverArtCache object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.bytes.length * 8;
  bytesCount += 3 + object.fileName.length * 3;
  return bytesCount;
}

void _coverArtCacheSerialize(
  CoverArtCache object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLongList(offsets[0], object.bytes);
  writer.writeString(offsets[1], object.fileName);
  writer.writeDateTime(offsets[2], object.lastAccessed);
}

CoverArtCache _coverArtCacheDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = CoverArtCache();
  object.bytes = reader.readLongList(offsets[0]) ?? [];
  object.fileName = reader.readString(offsets[1]);
  object.id = id;
  object.lastAccessed = reader.readDateTime(offsets[2]);
  return object;
}

P _coverArtCacheDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLongList(offset) ?? []) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readDateTime(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _coverArtCacheGetId(CoverArtCache object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _coverArtCacheGetLinks(CoverArtCache object) {
  return [];
}

void _coverArtCacheAttach(
    IsarCollection<dynamic> col, Id id, CoverArtCache object) {
  object.id = id;
}

extension CoverArtCacheByIndex on IsarCollection<CoverArtCache> {
  Future<CoverArtCache?> getByFileName(String fileName) {
    return getByIndex(r'fileName', [fileName]);
  }

  CoverArtCache? getByFileNameSync(String fileName) {
    return getByIndexSync(r'fileName', [fileName]);
  }

  Future<bool> deleteByFileName(String fileName) {
    return deleteByIndex(r'fileName', [fileName]);
  }

  bool deleteByFileNameSync(String fileName) {
    return deleteByIndexSync(r'fileName', [fileName]);
  }

  Future<List<CoverArtCache?>> getAllByFileName(List<String> fileNameValues) {
    final values = fileNameValues.map((e) => [e]).toList();
    return getAllByIndex(r'fileName', values);
  }

  List<CoverArtCache?> getAllByFileNameSync(List<String> fileNameValues) {
    final values = fileNameValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'fileName', values);
  }

  Future<int> deleteAllByFileName(List<String> fileNameValues) {
    final values = fileNameValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'fileName', values);
  }

  int deleteAllByFileNameSync(List<String> fileNameValues) {
    final values = fileNameValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'fileName', values);
  }

  Future<Id> putByFileName(CoverArtCache object) {
    return putByIndex(r'fileName', object);
  }

  Id putByFileNameSync(CoverArtCache object, {bool saveLinks = true}) {
    return putByIndexSync(r'fileName', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByFileName(List<CoverArtCache> objects) {
    return putAllByIndex(r'fileName', objects);
  }

  List<Id> putAllByFileNameSync(List<CoverArtCache> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'fileName', objects, saveLinks: saveLinks);
  }
}

extension CoverArtCacheQueryWhereSort
    on QueryBuilder<CoverArtCache, CoverArtCache, QWhere> {
  QueryBuilder<CoverArtCache, CoverArtCache, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension CoverArtCacheQueryWhere
    on QueryBuilder<CoverArtCache, CoverArtCache, QWhereClause> {
  QueryBuilder<CoverArtCache, CoverArtCache, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<CoverArtCache, CoverArtCache, QAfterWhereClause> idNotEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<CoverArtCache, CoverArtCache, QAfterWhereClause> idGreaterThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<CoverArtCache, CoverArtCache, QAfterWhereClause> idLessThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<CoverArtCache, CoverArtCache, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<CoverArtCache, CoverArtCache, QAfterWhereClause> fileNameEqualTo(
      String fileName) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'fileName',
        value: [fileName],
      ));
    });
  }

  QueryBuilder<CoverArtCache, CoverArtCache, QAfterWhereClause>
      fileNameNotEqualTo(String fileName) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'fileName',
              lower: [],
              upper: [fileName],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'fileName',
              lower: [fileName],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'fileName',
              lower: [fileName],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'fileName',
              lower: [],
              upper: [fileName],
              includeUpper: false,
            ));
      }
    });
  }
}

extension CoverArtCacheQueryFilter
    on QueryBuilder<CoverArtCache, CoverArtCache, QFilterCondition> {
  QueryBuilder<CoverArtCache, CoverArtCache, QAfterFilterCondition>
      bytesElementEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'bytes',
        value: value,
      ));
    });
  }

  QueryBuilder<CoverArtCache, CoverArtCache, QAfterFilterCondition>
      bytesElementGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'bytes',
        value: value,
      ));
    });
  }

  QueryBuilder<CoverArtCache, CoverArtCache, QAfterFilterCondition>
      bytesElementLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'bytes',
        value: value,
      ));
    });
  }

  QueryBuilder<CoverArtCache, CoverArtCache, QAfterFilterCondition>
      bytesElementBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'bytes',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<CoverArtCache, CoverArtCache, QAfterFilterCondition>
      bytesLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'bytes',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<CoverArtCache, CoverArtCache, QAfterFilterCondition>
      bytesIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'bytes',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<CoverArtCache, CoverArtCache, QAfterFilterCondition>
      bytesIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'bytes',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<CoverArtCache, CoverArtCache, QAfterFilterCondition>
      bytesLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'bytes',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<CoverArtCache, CoverArtCache, QAfterFilterCondition>
      bytesLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'bytes',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<CoverArtCache, CoverArtCache, QAfterFilterCondition>
      bytesLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'bytes',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<CoverArtCache, CoverArtCache, QAfterFilterCondition>
      fileNameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'fileName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CoverArtCache, CoverArtCache, QAfterFilterCondition>
      fileNameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'fileName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CoverArtCache, CoverArtCache, QAfterFilterCondition>
      fileNameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'fileName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CoverArtCache, CoverArtCache, QAfterFilterCondition>
      fileNameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'fileName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CoverArtCache, CoverArtCache, QAfterFilterCondition>
      fileNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'fileName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CoverArtCache, CoverArtCache, QAfterFilterCondition>
      fileNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'fileName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CoverArtCache, CoverArtCache, QAfterFilterCondition>
      fileNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'fileName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CoverArtCache, CoverArtCache, QAfterFilterCondition>
      fileNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'fileName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CoverArtCache, CoverArtCache, QAfterFilterCondition>
      fileNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'fileName',
        value: '',
      ));
    });
  }

  QueryBuilder<CoverArtCache, CoverArtCache, QAfterFilterCondition>
      fileNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'fileName',
        value: '',
      ));
    });
  }

  QueryBuilder<CoverArtCache, CoverArtCache, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<CoverArtCache, CoverArtCache, QAfterFilterCondition>
      idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<CoverArtCache, CoverArtCache, QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<CoverArtCache, CoverArtCache, QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<CoverArtCache, CoverArtCache, QAfterFilterCondition>
      lastAccessedEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastAccessed',
        value: value,
      ));
    });
  }

  QueryBuilder<CoverArtCache, CoverArtCache, QAfterFilterCondition>
      lastAccessedGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'lastAccessed',
        value: value,
      ));
    });
  }

  QueryBuilder<CoverArtCache, CoverArtCache, QAfterFilterCondition>
      lastAccessedLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'lastAccessed',
        value: value,
      ));
    });
  }

  QueryBuilder<CoverArtCache, CoverArtCache, QAfterFilterCondition>
      lastAccessedBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'lastAccessed',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension CoverArtCacheQueryObject
    on QueryBuilder<CoverArtCache, CoverArtCache, QFilterCondition> {}

extension CoverArtCacheQueryLinks
    on QueryBuilder<CoverArtCache, CoverArtCache, QFilterCondition> {}

extension CoverArtCacheQuerySortBy
    on QueryBuilder<CoverArtCache, CoverArtCache, QSortBy> {
  QueryBuilder<CoverArtCache, CoverArtCache, QAfterSortBy> sortByFileName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fileName', Sort.asc);
    });
  }

  QueryBuilder<CoverArtCache, CoverArtCache, QAfterSortBy>
      sortByFileNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fileName', Sort.desc);
    });
  }

  QueryBuilder<CoverArtCache, CoverArtCache, QAfterSortBy>
      sortByLastAccessed() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastAccessed', Sort.asc);
    });
  }

  QueryBuilder<CoverArtCache, CoverArtCache, QAfterSortBy>
      sortByLastAccessedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastAccessed', Sort.desc);
    });
  }
}

extension CoverArtCacheQuerySortThenBy
    on QueryBuilder<CoverArtCache, CoverArtCache, QSortThenBy> {
  QueryBuilder<CoverArtCache, CoverArtCache, QAfterSortBy> thenByFileName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fileName', Sort.asc);
    });
  }

  QueryBuilder<CoverArtCache, CoverArtCache, QAfterSortBy>
      thenByFileNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fileName', Sort.desc);
    });
  }

  QueryBuilder<CoverArtCache, CoverArtCache, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<CoverArtCache, CoverArtCache, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<CoverArtCache, CoverArtCache, QAfterSortBy>
      thenByLastAccessed() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastAccessed', Sort.asc);
    });
  }

  QueryBuilder<CoverArtCache, CoverArtCache, QAfterSortBy>
      thenByLastAccessedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastAccessed', Sort.desc);
    });
  }
}

extension CoverArtCacheQueryWhereDistinct
    on QueryBuilder<CoverArtCache, CoverArtCache, QDistinct> {
  QueryBuilder<CoverArtCache, CoverArtCache, QDistinct> distinctByBytes() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'bytes');
    });
  }

  QueryBuilder<CoverArtCache, CoverArtCache, QDistinct> distinctByFileName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'fileName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CoverArtCache, CoverArtCache, QDistinct>
      distinctByLastAccessed() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastAccessed');
    });
  }
}

extension CoverArtCacheQueryProperty
    on QueryBuilder<CoverArtCache, CoverArtCache, QQueryProperty> {
  QueryBuilder<CoverArtCache, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<CoverArtCache, List<int>, QQueryOperations> bytesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'bytes');
    });
  }

  QueryBuilder<CoverArtCache, String, QQueryOperations> fileNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'fileName');
    });
  }

  QueryBuilder<CoverArtCache, DateTime, QQueryOperations>
      lastAccessedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastAccessed');
    });
  }
}
