import 'package:hive/hive.dart';
import 'my_topic.dart';

class MyTopicsStorage {
  static const boxName = 'my_topics_box';

  Future<Box> _open() async => Hive.openBox(boxName);

  Future<void> add(MyTopic topic) async {
    final box = await _open();
    await box.put(topic.id, topic.toMap());
  }

  Future<void> remove(String id) async {
    final box = await _open();
    await box.delete(id);
  }

  Future<List<MyTopic>> getAll() async {
    final box = await _open();
    final result = <MyTopic>[];
    for (final k in box.keys) {
      final raw = box.get(k);
      if (raw == null) continue;
      result.add(MyTopic.fromMap(Map<String, dynamic>.from(raw)));
    }
    // En yeni eklenen üstte.
    result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return result;
  }

  Future<void> clearAll() async {
    final box = await _open();
    await box.clear();
  }
}