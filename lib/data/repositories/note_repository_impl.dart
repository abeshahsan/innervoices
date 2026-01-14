import 'package:innervoices/data/repositories/note_repository.dart';
import 'package:innervoices/data/services/note_firestore_service.dart';
import 'package:innervoices/models/note.dart';

class NoteRepositoryImpl extends NoteRepository {
  final NoteFirestoreService firestoreService;

  NoteRepositoryImpl({required this.firestoreService});

  @override
  Future<void> addNote(Note note) async {
    await firestoreService.addNote(note);
  }

  @override
  Future<void> updateNote(Note note) async {
    await firestoreService.updateNote(note);
  }

  @override
  Future<void> deleteNote(String noteId) async {
    await firestoreService.deleteNote(noteId);
  }

  @override
  Future<List<Note>> fetchNotes() async {
    return await firestoreService.fetchAllNotes(
      'userId',
    ); // Replace 'userId' with actual user ID when available
  }
}
