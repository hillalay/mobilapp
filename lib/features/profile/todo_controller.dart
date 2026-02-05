import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'todo_models.dart';
import 'todo_storage.dart';

class ProfileTodoState {
  final List<TodoItem> todos;
  final String dailyNote;
  final bool loading;

  const ProfileTodoState({
    required this.todos,
    required this.dailyNote,
    required this.loading,
  });

  ProfileTodoState copyWith({List<TodoItem>? todos, String? dailyNote, bool? loading}) {
    return ProfileTodoState(
      todos: todos ?? this.todos,
      dailyNote: dailyNote ?? this.dailyNote,
      loading: loading ?? this.loading,
    );
  }

  static const empty = ProfileTodoState(todos: [], dailyNote: '', loading: true);
}

final todoStorageProvider = Provider<TodoStorage>((ref) => TodoStorage());

final profileTodoProvider =
    NotifierProvider<ProfileTodoController, ProfileTodoState>(ProfileTodoController.new);

class ProfileTodoController extends Notifier<ProfileTodoState> {
  static const _ttl = Duration(hours: 24);

  @override
  ProfileTodoState build() {
    state = ProfileTodoState.empty;
    _init();
    return state;
  }

  String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  bool _isExpired(TodoItem t, DateTime now) {
    return now.difference(t.createdAt) > _ttl;
  }

  Future<void> _init() async {
    final storage = ref.read(todoStorageProvider);
    final today = _todayKey();

    final loadedTodos = await storage.loadTodos();

    // ✅ 24 saatten eski olanları temizle
    final now = DateTime.now();
    final freshTodos = loadedTodos.where((t) => !_isExpired(t, now)).toList(growable: false);

    // ✅ temizlik yaptıysak kalıcı olarak storage'a da yaz
    if (freshTodos.length != loadedTodos.length) {
      await storage.saveTodos(freshTodos);
    }

    final note = await storage.loadDailyNote(todayKey: today);

    state = state.copyWith(todos: freshTodos, dailyNote: note, loading: false);
  }

  Future<void> addTodo(String text) async {
    final t = text.trim();
    if (t.isEmpty) return;

    final item = TodoItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: t,
      done: false,
      createdAt: DateTime.now(), // ✅
    );

    final next = [item, ...state.todos];
    state = state.copyWith(todos: next);
    await ref.read(todoStorageProvider).saveTodos(next);
  }

  Future<void> toggle(String id) async {
    final next = state.todos
        .map((e) => e.id == id ? e.copyWith(done: !e.done) : e)
        .toList(growable: false);
    state = state.copyWith(todos: next);
    await ref.read(todoStorageProvider).saveTodos(next);
  }

  Future<void> remove(String id) async {
    final next = state.todos.where((e) => e.id != id).toList(growable: false);
    state = state.copyWith(todos: next);
    await ref.read(todoStorageProvider).saveTodos(next);
  }

  Future<void> setDailyNote(String note) async {
    state = state.copyWith(dailyNote: note);
    await ref.read(todoStorageProvider).saveDailyNote(note, todayKey: _todayKey());
  }
}
