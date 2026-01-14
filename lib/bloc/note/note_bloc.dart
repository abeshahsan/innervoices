import 'package:bloc/bloc.dart';
import 'package:innervoices/data/repositories/note_repository.dart';
import 'package:innervoices/models/note.dart';
import 'package:meta/meta.dart';

part 'note_event.dart';
part 'note_state.dart';

class NoteBloc extends Bloc<NoteEvent, NoteState> {
  final NoteRepository _noteRepository;

  NoteBloc(this._noteRepository) : super(NoteInitial()) {
    on<NoteEvent>((event, emit) async {
      if (event is LoadNotes) {
        emit(NoteLoading());
        try {
          final notes = await _noteRepository.fetchNotes();
          emit(NoteLoaded(notes));
        } catch (e) {
          emit(NoteError('Failed to load notes: $e'));
        }
      } else if (event is AddNote) {
        try {
          await _noteRepository.addNote(event.note);
          add(LoadNotes());
        } catch (e) {
          emit(NoteError('Failed to add note: $e'));
        }
      } else if (event is UpdateNote) {
        try {
          await _noteRepository.updateNote(event.note);
          add(LoadNotes());
        } catch (e) {
          emit(NoteError('Failed to update note: $e'));
        }
      } else if (event is DeleteNote) {
        try {
          await _noteRepository.deleteNote(event.noteId);
          add(LoadNotes());
        } catch (e) {
          emit(NoteError('Failed to delete note: $e'));
        }
      } else if (event is SearchNotes) {
        emit(NoteSearching());
        try {
          final allNotes = await _noteRepository.fetchNotes();
          final results = allNotes
              .where(
                (note) =>
                    note.title.contains(event.query) ||
                    note.content.contains(event.query),
              )
              .toList();
          emit(NoteSearchResults(results));
        } catch (e) {
          emit(NoteSearchError('Search failed: $e'));
        }
      }
    });
  }
}
