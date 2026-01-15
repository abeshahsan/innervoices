import 'package:innervoices/models/note.dart';

abstract class NoteRepository {
  Future<void> addNote(Note note, String userId);
  Future<void> updateNote(Note note);
  Future<void> deleteNote(String noteId);
  Future<List<Note>> fetchNotes(String userId);
  Future<List<Note>> searchNotes(String query, String userId);
}
