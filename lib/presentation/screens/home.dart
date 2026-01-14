import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:innervoices/bloc/note/note_bloc.dart';
import 'package:innervoices/bloc/user/user_bloc.dart';
import 'package:innervoices/presentation/widgets/appbar.dart';
import 'package:innervoices/presentation/widgets/drawer.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<UserBloc, UserState>(
      listener: (context, state) {
        if (state is UserError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        }
      },
      child: Scaffold(
        appBar: HomeAppbar(title: 'Inner Voices'),
        drawer: HomeDrawer(),
        body: BlocBuilder<NoteBloc, NoteState>(
          builder: (context, state) {
            if (state is NoteLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is NoteLoaded) {
              final notes = state.notes;
              return ListView.builder(
                itemCount: notes.length,
                itemBuilder: (context, index) {
                  final note = notes[index];
                  return ListTile(
                    title: Text(note.title),
                    subtitle: Text(note.content),
                  );
                },
              );
            } else if (state is NoteError) {
              return Center(child: Text(state.message));
            } else {
              return const Center(child: Text('No notes available.'));
            }
          },
        ),
      ),
    );
  }
}
