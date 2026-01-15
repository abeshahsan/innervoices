import 'package:innervoices/data/repositories/note_repository.dart';
import 'package:innervoices/data/services/note_realm_service.dart';
import 'package:innervoices/models/note.dart';

class NoteRepositoryRealm extends NoteRepository {
  final NoteRealmService noteRealmService;

  NoteRepositoryRealm({required this.noteRealmService});

  @override
  Future<void> addNote(Note note, String userId) async {
    await noteRealmService.addNote(note, userId);
  }

  @override
  Future<void> updateNote(Note note) async {
    await noteRealmService.updateNote(note);
  }

  @override
  Future<void> deleteNote(String noteId) async {
    await noteRealmService.deleteNote(noteId);
  }

  @override
  Future<List<Note>> fetchNotes(String userId) async {
    return await noteRealmService.getNotes(userId);
  }

  @override
  Future<List<Note>> searchNotes(String query, String userId) async {
    return await noteRealmService.searchNotes(query, userId);
  }
}
