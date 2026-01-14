import 'package:innervoices/models/note.dart';

abstract class NoteRepository {
  Future<void> addNote(Note note);
  Future<void> updateNote(Note note);
  Future<void> deleteNote(String noteId);
  Future<List<Note>> fetchNotes();
}
