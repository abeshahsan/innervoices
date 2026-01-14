part of 'note_bloc.dart';

@immutable
sealed class NoteState {}

final class NoteInitial extends NoteState {}

final class NoteLoading extends NoteState {}

final class NoteLoaded extends NoteState {
  final List<Note> notes;

  NoteLoaded(this.notes);
}

final class NoteError extends NoteState {
  final String message;

  NoteError(this.message);
}

final class NoteEmpty extends NoteState {}

final class NoteSearching extends NoteState {}

final class NoteSearchResults extends NoteState {
  final List<Note> results;

  NoteSearchResults(this.results);
}

final class NoteSearchError extends NoteState {
  final String message;

  NoteSearchError(this.message);
}
