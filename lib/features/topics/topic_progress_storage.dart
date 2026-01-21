import 'package:hive/hive.dart';
import 'topic_progress.dart';

class TopicProgressStorage {
  static const _boxName = 'topic_progress_box';

  Future<Box> _open() async => Hive.openBox(_boxName);

  Future<TopicProgress?> get(String key) async {
    final box = await _open();
    final raw = box.get(key);
    if (raw == null) return null;
    return TopicProgress.fromMap(Map<String, dynamic>.from(raw));
  }

  Future<void> put(TopicProgress p) async {
    final box = await _open();
    await box.put(p.key(), p.toMap());
  }

  Future<Map<String, TopicProgress>> getAll() async {
    final box = await _open();
    final result = <String, TopicProgress>{};
    for (final k in box.keys) {
      final raw = box.get(k);
      if (raw == null) continue;
      result[k.toString()] =
          TopicProgress.fromMap(Map<String, dynamic>.from(raw));
    }
    return result;
  }

  Future<void> clearAll() async {
    final box = await _open();
    await box.clear();
  }
}
