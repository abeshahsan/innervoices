import 'package:innervoices/data/models/realm/note_realm_model.dart';
import 'package:innervoices/models/note.dart';
import 'package:realm/realm.dart';

class NoteRealmService {
  final Realm _realm;

  NoteRealmService(this._realm);

  /// Get all notes for a specific user, sorted by last edited (newest first)
  Future<List<Note>> getNotes(String userId) async {
    final realmNotes = _realm.query<NoteRealm>(
      r'userId == $0 SORT(lastEdited DESC)',
      [userId],
    );

    return realmNotes.map(_convertRealmToUI).toList();
  }

  /// Add a new note to Realm
  Future<void> addNote(Note note, String userId) async {
    final realmNote = NoteRealm(
      Uuid.v4().toString(),
      note.title,
      note.content,
      note.lastEdited,
      userId,
    );

    _realm.write(() {
      _realm.add(realmNote);
    });
  }

  /// Update an existing note in Realm
  Future<void> updateNote(Note note) async {
    final existingNote = _realm.find<NoteRealm>(note.id);

    if (existingNote != null) {
      _realm.write(() {
        existingNote.title = note.title;
        existingNote.content = note.content;
        existingNote.lastEdited = note.lastEdited;
      });
    }
  }

  /// Delete a note from Realm
  Future<void> deleteNote(String id) async {
    final noteToDelete = _realm.find<NoteRealm>(id);

    if (noteToDelete != null) {
      _realm.write(() {
        _realm.delete(noteToDelete);
      });
    }
  }

  /// Search notes by title or content for a specific user
  Future<List<Note>> searchNotes(String query, String userId) async {
    final realmNotes = _realm.query<NoteRealm>(
      r'userId == $0 AND (title CONTAINS[c] $1 OR content CONTAINS[c] $1) SORT(lastEdited DESC)',
      [userId, query],
    );

    return realmNotes.map(_convertRealmToUI).toList();
  }

  /// Convert Realm model to UI model
  Note _convertRealmToUI(NoteRealm realmNote) {
    return Note(
      id: realmNote.id,
      title: realmNote.title,
      content: realmNote.content,
      lastEdited: realmNote.lastEdited,
    );
  }
}
