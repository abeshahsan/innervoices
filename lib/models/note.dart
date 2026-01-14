// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class Note {
  final String id;
  final String title;
  final String content;
  final DateTime lastEdited;

  Note({
    required this.id,
    required this.title,
    required this.content,
    required this.lastEdited,
  });

  Note copyWith({
    String? id,
    String? title,
    String? content,
    DateTime? lastEdited,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      lastEdited: lastEdited ?? this.lastEdited,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'content': content,
      'lastEdited': lastEdited.millisecondsSinceEpoch,
    };
  }

  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'] as String,
      title: map['title'] as String,
      content: map['content'] as String,
      lastEdited: DateTime.fromMillisecondsSinceEpoch(map['lastEdited'] as int),
    );
  }

  String toJson() => json.encode(toMap());

  factory Note.fromJson(String source) =>
      Note.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'Note(id: $id, title: $title, content: $content, lastEdited: $lastEdited)';
  }

  @override
  bool operator ==(covariant Note other) {
    if (identical(this, other)) return true;

    return other.id == id &&
        other.title == title &&
        other.content == content &&
        other.lastEdited == lastEdited;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        title.hashCode ^
        content.hashCode ^
        lastEdited.hashCode;
  }
}
