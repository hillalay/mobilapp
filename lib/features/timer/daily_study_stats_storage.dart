import 'package:hive/hive.dart';
import 'daily_study_stats.dart';

class DailyStudyStatsStorage {
  static const _boxName = 'daily_study_stats_box';

  Future<Box> _open() async => Hive.openBox(_boxName);

  String _dayKey(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  Future<DailyStudyStats> getOrCreate(DateTime date) async {
    final box = await _open();
    final key = _dayKey(date);
    final raw = box.get(key);
    if (raw == null) {
      final empty = DailyStudyStats(dayKey: key, totalSeconds: 0, manualQuestions: 0);
      await box.put(key, empty.toMap());
      return empty;
    }
    return DailyStudyStats.fromMap(Map<String, dynamic>.from(raw));
  }

  Future<void> addSeconds({
    required DateTime date,
    required int seconds,
  }) async {
    if (seconds == 0) return;

    final box = await _open();
    final key = _dayKey(date);

    final current = await getOrCreate(date);

    final newTotal = current.totalSeconds + seconds;
    if (newTotal < 0) {
      final updated = current.copyWith(totalSeconds: 0);
      await box.put(key, updated.toMap());
      return;
    }

    final updated = current.copyWith(totalSeconds: newTotal);
    await box.put(key, updated.toMap());
  }

  // Manuel süre ekleme/çıkarma
  Future<void> addManualMinutes({
    required DateTime date,
    required int minutes,
  }) async {
    await addSeconds(date: date, seconds: minutes * 60);
  }

  /// ✅ Manuel soru ekleme/çıkarma (dashboard toplam soru buradan gelecek)
  Future<void> addManualQuestions({
    required DateTime date,
    required int questions,
  }) async {
    if (questions == 0) return;

    final box = await _open();
    final key = _dayKey(date);

    final current = await getOrCreate(date);

    final newTotal = current.manualQuestions + questions;
    final clamped = newTotal < 0 ? 0 : newTotal;

    final updated = current.copyWith(manualQuestions: clamped);
    await box.put(key, updated.toMap());
  }

  Future<DailyStudyStats?> load(DateTime date) async {
    final box = await _open();
    final key = _dayKey(date);
    final raw = box.get(key);
    if (raw == null) return null;
    return DailyStudyStats.fromMap(Map<String, dynamic>.from(raw));
  }

  // Son 7 gün (grafik için)
  Future<List<DailyStudyStats>> loadLastWeek() async {
    final box = await _open();
    final result = <DailyStudyStats>[];

    for (int i = 6; i >= 0; i--) {
      final date = DateTime.now().subtract(Duration(days: i));
      final key = _dayKey(date);
      final raw = box.get(key);

      if (raw != null) {
        result.add(DailyStudyStats.fromMap(Map<String, dynamic>.from(raw)));
      } else {
        result.add(DailyStudyStats(dayKey: key, totalSeconds: 0, manualQuestions: 0));
      }
    }

    return result;
  }

  /// ✅ TOPLAM SORU: sadece manualQuestions birikimi
  Future<int> loadTotalManualQuestions() async {
    final box = await _open();
    int sum = 0;

    for (final k in box.keys) {
      final raw = box.get(k);
      if (raw == null) continue;

      final map = Map<String, dynamic>.from(raw);
      sum += (map['manualQuestions'] as int?) ?? 0;
    }

    return sum;
  }
}
