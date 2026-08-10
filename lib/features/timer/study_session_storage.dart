import 'package:hive/hive.dart';
import 'study_session.dart';

class StudySessionStorage {
  static const boxName = 'study_sessions_box';

  /// Kutu main() içinde açılıyor; okumalar senkron olsun ki kronometre
  /// ilk karede doğru değeri gösterebilsin (async yükleme = 00:00:00 flaşı).
  Box get _box => Hive.box(boxName);

  void save(StudySession session) {
    _box.put(session.id, session.toMap());
  }

  List<StudySession> getAll() {
    final items = <StudySession>[];

    for (final k in _box.keys) {
      final raw = _box.get(k);
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

  StudySession? getActive() {
    for (final s in getAll()) {
      if (s.isActive) return s;
    }
    return null;
  }

  void delete(String id) {
    _box.delete(id);
  }
}
