// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'note_realm_model.dart';

// **************************************************************************
// RealmObjectGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: type=lint
class NoteRealm extends _NoteRealm
    with RealmEntity, RealmObjectBase, RealmObject {
  NoteRealm(
    String id,
    String title,
    String content,
    DateTime lastEdited,
    String userId,
  ) {
    RealmObjectBase.set(this, 'id', id);
    RealmObjectBase.set(this, 'title', title);
    RealmObjectBase.set(this, 'content', content);
    RealmObjectBase.set(this, 'lastEdited', lastEdited);
    RealmObjectBase.set(this, 'userId', userId);
  }

  NoteRealm._();

  @override
  String get id => RealmObjectBase.get<String>(this, 'id') as String;
  @override
  set id(String value) => RealmObjectBase.set(this, 'id', value);

  @override
  String get title => RealmObjectBase.get<String>(this, 'title') as String;
  @override
  set title(String value) => RealmObjectBase.set(this, 'title', value);

  @override
  String get content => RealmObjectBase.get<String>(this, 'content') as String;
  @override
  set content(String value) => RealmObjectBase.set(this, 'content', value);

  @override
  DateTime get lastEdited =>
      RealmObjectBase.get<DateTime>(this, 'lastEdited') as DateTime;
  @override
  set lastEdited(DateTime value) =>
      RealmObjectBase.set(this, 'lastEdited', value);

  @override
  String get userId => RealmObjectBase.get<String>(this, 'userId') as String;
  @override
  set userId(String value) => RealmObjectBase.set(this, 'userId', value);

  @override
  Stream<RealmObjectChanges<NoteRealm>> get changes =>
      RealmObjectBase.getChanges<NoteRealm>(this);

  @override
  Stream<RealmObjectChanges<NoteRealm>> changesFor([List<String>? keyPaths]) =>
      RealmObjectBase.getChangesFor<NoteRealm>(this, keyPaths);

  @override
  NoteRealm freeze() => RealmObjectBase.freezeObject<NoteRealm>(this);

  EJsonValue toEJson() {
    return <String, dynamic>{
      'id': id.toEJson(),
      'title': title.toEJson(),
      'content': content.toEJson(),
      'lastEdited': lastEdited.toEJson(),
      'userId': userId.toEJson(),
    };
  }

  static EJsonValue _toEJson(NoteRealm value) => value.toEJson();
  static NoteRealm _fromEJson(EJsonValue ejson) {
    if (ejson is! Map<String, dynamic>) return raiseInvalidEJson(ejson);
    return switch (ejson) {
      {
        'id': EJsonValue id,
        'title': EJsonValue title,
        'content': EJsonValue content,
        'lastEdited': EJsonValue lastEdited,
        'userId': EJsonValue userId,
      } =>
        NoteRealm(
          fromEJson(id),
          fromEJson(title),
          fromEJson(content),
          fromEJson(lastEdited),
          fromEJson(userId),
        ),
      _ => raiseInvalidEJson(ejson),
    };
  }

  static final schema = () {
    RealmObjectBase.registerFactory(NoteRealm._);
    register(_toEJson, _fromEJson);
    return const SchemaObject(ObjectType.realmObject, NoteRealm, 'NoteRealm', [
      SchemaProperty('id', RealmPropertyType.string, primaryKey: true),
      SchemaProperty('title', RealmPropertyType.string),
      SchemaProperty('content', RealmPropertyType.string),
      SchemaProperty('lastEdited', RealmPropertyType.timestamp),
      SchemaProperty('userId', RealmPropertyType.string),
    ]);
  }();

  @override
  SchemaObject get objectSchema => RealmObjectBase.getSchema(this) ?? schema;
}
