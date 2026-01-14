part of 'note_bloc.dart';

@immutable
sealed class NoteEvent {}

class LoadNotes extends NoteEvent {}

class AddNote extends NoteEvent {
  final Note note;

  AddNote(this.note);
}

class UpdateNote extends NoteEvent {
  final Note note;

  UpdateNote(this.note);
}

class DeleteNote extends NoteEvent {
  final String noteId;

  DeleteNote(this.noteId);
}

class SearchNotes extends NoteEvent {
  final String query;

  SearchNotes(this.query);
}
