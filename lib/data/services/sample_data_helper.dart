import 'package:innervoices/models/note.dart';
import 'package:innervoices/data/repositories/note_repository.dart';

class SampleDataHelper {
  static Future<void> insertSampleNotes(
    NoteRepository repository,
    String userId,
  ) async {
    final sampleNotes = [
      Note(
        id: '',
        title: 'Welcome to Inner Voices',
        content:
            'This is your first note! You can edit or delete it anytime. Start writing your thoughts, ideas, and daily reflections here.',
        lastEdited: DateTime.now().subtract(const Duration(days: 3)),
      ),
      Note(
        id: '',
        title: 'Daily Reflection',
        content:
            'Today was a productive day. I managed to complete all my tasks and even had time to relax. Feeling grateful for the small wins.',
        lastEdited: DateTime.now().subtract(const Duration(days: 2)),
      ),
      Note(
        id: '',
        title: 'Project Ideas',
        content:
            '1. Build a habit tracker\n2. Create a personal finance app\n3. Develop a meditation timer\n4. Design a recipe organizer',
        lastEdited: DateTime.now().subtract(const Duration(days: 1)),
      ),
      Note(
        id: '',
        title: 'Book Notes',
        content:
            'Atomic Habits by James Clear - Key takeaway: Small changes lead to remarkable results. Focus on systems, not goals.',
        lastEdited: DateTime.now().subtract(const Duration(hours: 12)),
      ),
      Note(
        id: '',
        title: 'Meeting Notes',
        content:
            'Team meeting at 2 PM\n- Discuss Q1 goals\n- Review project timeline\n- Assign tasks to team members',
        lastEdited: DateTime.now().subtract(const Duration(hours: 5)),
      ),
      Note(
        id: '',
        title: 'Quick Reminder',
        content:
            'Don\'t forget to call mom this weekend. Also need to pick up groceries and schedule dentist appointment.',
        lastEdited: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      Note(
        id: '',
        title: 'Inspiration',
        content:
            '"The only way to do great work is to love what you do." - Steve Jobs\n\nThis quote resonates with me today.',
        lastEdited: DateTime.now().subtract(const Duration(minutes: 30)),
      ),
    ];

    for (final note in sampleNotes) {
      await repository.addNote(note, userId);
    }
  }
}
