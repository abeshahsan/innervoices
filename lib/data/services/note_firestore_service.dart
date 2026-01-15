import 'package:flutter/cupertino.dart';
import 'package:innervoices/models/note.dart';

class NoteFirestoreService {
  Future<List<Note>> fetchAllNotesForUser(String userId) async {
    // for now some mock data
    debugPrint('Fetching notes for user: $userId');
    return Future.delayed(const Duration(seconds: 1), () {
      return [
        Note(
          id: '1',
          title: 'First Note',
          content: 'This is the content of the first note.',
          lastEdited: DateTime.now().subtract(const Duration(days: 1)),
        ),
        Note(
          id: '2',
          title: 'Second Note',
          content: 'This is thecontent of the second note.',
          lastEdited: DateTime.now().subtract(const Duration(hours: 5)),
        ),
      ];
    });
  }

  Future<void> addNote(Note note) async {}

  Future<void> updateNote(Note note) async {}

  Future<void> deleteNote(String noteId) async {}
}
