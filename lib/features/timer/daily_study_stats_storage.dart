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
      final empty = DailyStudyStats(dayKey: key, totalSeconds: 0);
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

    // Negatif değer kontrolü - toplam süre negatif olmasın
    final newTotal = current.totalSeconds + seconds;
    if (newTotal < 0) {
      // Eğer çıkarılacak süre toplam süreden fazlaysa, sadece sıfırla
      final updated = current.copyWith(totalSeconds: 0);
      await box.put(key, updated.toMap());
      return;
    }

    final updated = current.copyWith(
      totalSeconds: newTotal,
    );

    await box.put(key, updated.toMap());
  }

  // Manuel süre ekleme/çıkarma (negatif değer çıkarma için)
  Future<void> addManualMinutes({
    required DateTime date,
    required int minutes,
  }) async {
    await addSeconds(date: date, seconds: minutes * 60);
  }

  Future<DailyStudyStats?> load(DateTime date) async {
    final box = await _open();
    final key = _dayKey(date);
    final raw = box.get(key);
    if (raw == null) return null;
    return DailyStudyStats.fromMap(Map<String, dynamic>.from(raw));
  }

  // Son 7 günün verilerini getir (grafik için)
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
        result.add(DailyStudyStats(dayKey: key, totalSeconds: 0));
      }
    }
    
    return result;
  }
}