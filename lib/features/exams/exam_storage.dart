import 'package:hive/hive.dart';
import 'exam_models.dart';

class ExamStorage {
  static const _boxName = 'exams_box';

  Future<Box> _open() async => Hive.openBox(_boxName);

  Future<void> add(ExamEntry entry) async {
    final box = await _open();
    await box.put(entry.id, entry.toMap());
  }

  Future<List<ExamEntry>> getAll() async {
    final box = await _open();
    final items = <ExamEntry>[];

    for (final k in box.keys) {
      final raw = box.get(k);
      if (raw == null) continue;
      items.add(ExamEntry.fromMap(Map<String, dynamic>.from(raw)));
    }

    // en yeni üstte
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  Future<void> clearAll() async {
    final box = await _open();
    await box.clear();
  }
}
