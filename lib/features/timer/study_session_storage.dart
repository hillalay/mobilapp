import 'package:hive/hive.dart';
import 'study_session.dart';

class StudySessionStorage {
  static const _boxName = 'study_sessions_box';

  Future<Box> _open() async => Hive.openBox(_boxName);

  Future<void> save(StudySession session) async {
    final box = await _open();
    await box.put(session.id, session.toMap());
  }

  Future<List<StudySession>> getAll() async {
    final box = await _open();
    final items = <StudySession>[];

    for (final k in box.keys) {
      final raw = box.get(k);
      if (raw == null) continue;
      try {
        items.add(StudySession.fromMap(Map<String, dynamic>.from(raw)));
      } catch (e) {
        // Bozuk veriyi atla
      }
    }

    items.sort((a, b) => b.startTime.compareTo(a.startTime));
    return items;
  }

  Future<StudySession?> getActive() async {
    final all = await getAll();
    try {
      return all.firstWhere((s) => s.isActive);
    } catch (_) {
      return null;
    }
  }

  Future<void> delete(String id) async {
    final box = await _open();
    await box.delete(id);
  }
}