import 'package:bloc/bloc.dart';
import 'package:innervoices/bloc/backup/backup_bloc.dart';
import 'package:innervoices/bloc/backup/backup_event.dart';
import 'package:innervoices/data/repositories/note_repository.dart';
import 'package:innervoices/models/note.dart';
import 'package:meta/meta.dart';

part 'note_event.dart';
part 'note_state.dart';

class NoteBloc extends Bloc<NoteEvent, NoteState> {
  final NoteRepository noteRepository;
  final BackupBloc backupBloc;
  final String userId;

  NoteBloc(this.noteRepository, this.userId, this.backupBloc)
    : super(NoteInitial()) {
    on<NoteEvent>((event, emit) async {
      if (event is LoadNotes) {
        emit(NoteLoading());
        try {
          final notes = await noteRepository.fetchNotes(userId);
          emit(NoteLoaded(notes));
        } catch (e) {
          emit(NoteError('Failed to load notes: $e'));
        }
      } else if (event is AddNote) {
        try {
          await noteRepository.addNote(event.note, userId);
          backupBloc.add(NotifyLocalChange());
          add(LoadNotes());
        } catch (e) {
          emit(NoteError('Failed to add note: $e'));
        }
      } else if (event is UpdateNote) {
        try {
          await noteRepository.updateNote(event.note);
          backupBloc.add(NotifyLocalChange());
          add(LoadNotes());
        } catch (e) {
          emit(NoteError('Failed to update note: $e'));
        }
      } else if (event is DeleteNote) {
        try {
          await noteRepository.deleteNote(event.noteId);
          backupBloc.add(NotifyLocalChange());
          add(LoadNotes());
        } catch (e) {
          emit(NoteError('Failed to delete note: $e'));
        }
      } else if (event is SearchNotes) {
        emit(NoteSearching());
        try {
          final results = await noteRepository.searchNotes(event.query, userId);
          emit(NoteSearchResults(results));
        } catch (e) {
          emit(NoteSearchError('Search failed: $e'));
        }
      }
    });
  }
}
