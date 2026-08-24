import 'package:flutter/foundation.dart';
import '../../core/services/notification_service.dart';
import '../../data/models/note_model.dart';
import '../../data/repositories/note_repository.dart';

class NotesProvider extends ChangeNotifier {
  final NoteRepository _noteRepo;
  final NotificationService _notificationService;

  NotesProvider({
    NoteRepository? noteRepo,
    NotificationService? notificationService,
  })  : _noteRepo = noteRepo ?? NoteRepository(),
        _notificationService = notificationService ?? NotificationService();

  List<NoteModel> _notes = [];
  bool _loading = false;
  String _activeCategory = 'class'; // class, reminders, general
  String _searchQuery = '';
  String? _error;

  List<NoteModel> get notes => _notes;
  bool get loading => _loading;
  String get activeCategory => _activeCategory;
  String get searchQuery => _searchQuery;
  String? get error => _error;

  List<NoteModel> get filteredNotes {
    return _notes.where((note) {
      // Category filter
      bool matchesCategory = true;
      if (_activeCategory == 'class') {
        matchesCategory = note.type == 'group' || note.type == 'student';
      } else if (_activeCategory == 'reminders') {
        matchesCategory = note.reminderEnabled;
      } else if (_activeCategory == 'general') {
        matchesCategory = note.type == 'general' || (note.type != 'group' && note.type != 'student' && !note.reminderEnabled);
      }

      // Search filter
      bool matchesSearch = true;
      if (_searchQuery.isNotEmpty) {
        matchesSearch = note.content.toLowerCase().contains(_searchQuery.toLowerCase());
      }

      return matchesCategory && matchesSearch;
    }).toList();
  }

  int get classNotesCount => _notes.where((n) => n.type == 'group' || n.type == 'student').length;
  int get remindersNotesCount => _notes.where((n) => n.reminderEnabled).length;
  int get generalNotesCount => _notes.where((n) => n.type == 'general' || (n.type != 'group' && n.type != 'student' && !n.reminderEnabled)).length;

  Future<void> loadNotes({bool silent = false}) async {
    if (!silent) {
      _loading = true;
      _error = null;
      notifyListeners();
    }

    try {
      _notes = await _noteRepo.getAll();
      _loading = false;
      notifyListeners();
    } catch (e) {
      _loading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  void setCategory(String category) {
    if (_activeCategory != category) {
      _activeCategory = category;
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    if (_searchQuery == query) return;
    _searchQuery = query;
    notifyListeners();
  }

  Future<bool> addNote(NoteModel note) async {
    try {
      await _noteRepo.insert(note);
      if (note.reminderEnabled && note.reminderTime != null) {
        _scheduleNoteReminder(note);
      }
      _notes.insert(0, note);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateNote(NoteModel note) async {
    try {
      await _noteRepo.update(note);
      if (note.reminderEnabled && note.reminderTime != null) {
        _scheduleNoteReminder(note);
      } else {
        _cancelNoteReminder(note);
      }
      final idx = _notes.indexWhere((n) => n.id == note.id);
      if (idx != -1) {
        _notes[idx] = note;
        notifyListeners();
      } else {
        await loadNotes(silent: true);
      }
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteNote(String id) async {
    try {
      final note = _notes.where((n) => n.id == id).firstOrNull;
      if (note != null && note.reminderEnabled) {
        _cancelNoteReminder(note);
      }
      await _noteRepo.delete(id);
      _notes.removeWhere((n) => n.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> togglePin(String id) async {
    try {
      final index = _notes.indexWhere((n) => n.id == id);
      if (index != -1) {
        final note = _notes[index];
        final updated = note.copyWith(isPinned: !note.isPinned);
        _notes[index] = updated;
        notifyListeners();
        await _noteRepo.update(updated);
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void _scheduleNoteReminder(NoteModel note) {
    if (note.reminderTime == null) return;
    final notifId = note.id.hashCode.abs();
    _notificationService.scheduleNotification(
      id: notifId,
      title: 'تذكير بملاحظة 📝',
      body: note.content.length > 80 ? '${note.content.substring(0, 80)}...' : note.content,
      scheduledDate: note.reminderTime!,
    );
  }

  void _cancelNoteReminder(NoteModel note) {
    final notifId = note.id.hashCode.abs();
    _notificationService.cancelNotification(notifId);
  }
}
