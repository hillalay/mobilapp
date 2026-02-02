import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'todo_models.dart';

class TodoStorage {
  static const _kTodosKey = 'profile_todos_v1';
  static const _kDailyNoteKey = 'profile_daily_note_v1';
  static const _kDailyNoteDateKey = 'profile_daily_note_date_v1';

  Future<List<TodoItem>> loadTodos() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(_kTodosKey);
    if (raw == null || raw.isEmpty) return const [];
    final list = (jsonDecode(raw) as List).cast<Map>();
    return list.map((e) => TodoItem.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  Future<void> saveTodos(List<TodoItem> items) async {
    final sp = await SharedPreferences.getInstance();
    final raw = jsonEncode(items.map((e) => e.toJson()).toList());
    await sp.setString(_kTodosKey, raw);
  }

  /// Bugüne özel not: gün değişince otomatik sıfırlayabilmek için tarih saklıyoruz.
  Future<String> loadDailyNote({required String todayKey}) async {
    final sp = await SharedPreferences.getInstance();
    final savedDate = sp.getString(_kDailyNoteDateKey);
    if (savedDate != todayKey) {
      await sp.setString(_kDailyNoteDateKey, todayKey);
      await sp.setString(_kDailyNoteKey, '');
      return '';
    }
    return sp.getString(_kDailyNoteKey) ?? '';
  }

  Future<void> saveDailyNote(String note, {required String todayKey}) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kDailyNoteDateKey, todayKey);
    await sp.setString(_kDailyNoteKey, note);
  }
}
