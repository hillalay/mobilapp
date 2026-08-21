import 'dart:async';
import 'package:hive/hive.dart';
import 'daily_study_stats.dart';

class DailyStudyStatsStorage {
  static const boxName = 'daily_study_stats_box';

  /// Basit sıralı kilit: Hive senkron çalışsa da aradaki `await`'ler
  /// (özellikle _open()) eşzamanlı çağrıların birbirinin üstüne
  /// yazmasına izin veriyordu (B1). Tüm okuma/yazmalar bu kuyruktan
  /// sırayla geçer.
  Future<void> _queue = Future.value();

  Future<T> _synchronized<T>(Future<T> Function() action) {
    final completer = Completer<T>();
    _queue = _queue.then((_) async {
      try {
        completer.complete(await action());
      } catch (e, st) {
        completer.completeError(e, st);
      }
    });
    return completer.future;
  }

  Future<Box> _open() async => Hive.openBox(boxName);

  String _dayKey(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  // Kilit ALMADAN çalışan iç versiyon — addSeconds gibi kilitli metotların
  // içinden çağrılır, tekrar kilit almaya çalışıp kilitlenmeyi (deadlock)
  // önler.
  Future<DailyStudyStats> _getOrCreateUnlocked(Box box, DateTime date) async {
    final key = _dayKey(date);
    final raw = box.get(key);
    if (raw == null) {
      final empty = DailyStudyStats(dayKey: key, totalSeconds: 0, manualQuestions: 0);
      await box.put(key, empty.toMap());
      return empty;
    }
    return DailyStudyStats.fromMap(Map<String, dynamic>.from(raw));
  }

  Future<DailyStudyStats> getOrCreate(DateTime date) {
    return _synchronized(() async {
      final box = await _open();
      return _getOrCreateUnlocked(box, date);
    });
  }

  Future<void> addSeconds({
    required DateTime date,
    required int seconds,
    bool fromStopwatch = false,
  }) {
    if (seconds == 0) return Future.value();
    return _synchronized(() async {
      final box = await _open();
      final key = _dayKey(date);
      final current = await _getOrCreateUnlocked(box, date);

      final newTotal = current.totalSeconds + seconds;
      final newStopwatch =
          fromStopwatch ? current.stopwatchSeconds + seconds : current.stopwatchSeconds;

      final updated = current.copyWith(
        totalSeconds: newTotal < 0 ? 0 : newTotal,
        stopwatchSeconds: newStopwatch < 0 ? 0 : newStopwatch,
      );
      await box.put(key, updated.toMap());
    });
  }

  /// [start]-[end] aralığını gece yarısı sınırlarına göre böler, her günün
  /// payını doğru _dayKey'e yazar (B5). addSeconds zaten kilitli olduğu
  /// için burada ek kilide gerek yok.
  Future<void> addSecondsSpan({
    required DateTime start,
    required DateTime end,
    bool fromStopwatch = false,
  }) async {
    if (!end.isAfter(start)) return;
    var cursor = start;
    while (cursor.isBefore(end)) {
      final startOfNextDay = DateTime(cursor.year, cursor.month, cursor.day + 1);
      final segmentEnd = startOfNextDay.isBefore(end) ? startOfNextDay : end;
      final seconds = segmentEnd.difference(cursor).inSeconds;
      if (seconds > 0) {
        await addSeconds(date: cursor, seconds: seconds, fromStopwatch: fromStopwatch);
      }
      cursor = segmentEnd;
    }
  }

  Future<void> addManualMinutes({required DateTime date, required int minutes}) {
    return addSeconds(date: date, seconds: minutes * 60);
  }

  Future<void> addManualQuestions({required DateTime date, required int questions}) {
    if (questions == 0) return Future.value();
    return _synchronized(() async {
      final box = await _open();
      final key = _dayKey(date);
      final current = await _getOrCreateUnlocked(box, date);
      final newTotal = current.manualQuestions + questions;
      final updated = current.copyWith(manualQuestions: newTotal < 0 ? 0 : newTotal);
      await box.put(key, updated.toMap());
    });
  }

  Future<DailyStudyStats?> load(DateTime date) {
    return _synchronized(() async {
      final box = await _open();
      final raw = box.get(_dayKey(date));
      if (raw == null) return null;
      return DailyStudyStats.fromMap(Map<String, dynamic>.from(raw));
    });
  }

  Future<List<DailyStudyStats>> loadLastWeek() {
    return _synchronized(() async {
      final box = await _open();
      final result = <DailyStudyStats>[];
      for (int i = 6; i >= 0; i--) {
        final date = DateTime.now().subtract(Duration(days: i));
        final key = _dayKey(date);
        final raw = box.get(key);
        result.add(raw != null
            ? DailyStudyStats.fromMap(Map<String, dynamic>.from(raw))
            : DailyStudyStats(dayKey: key, totalSeconds: 0, manualQuestions: 0));
      }
      return result;
    });
  }

  Future<int> loadTotalSeconds() {
    return _synchronized(() async {
      final box = await _open();
      var sum = 0;
      for (final k in box.keys) {
        final raw = box.get(k);
        if (raw == null) continue;
        sum += (Map<String, dynamic>.from(raw)['totalSeconds'] as int?) ?? 0;
      }
      return sum;
    });
  }

  Future<int> loadTotalManualQuestions() {
    return _synchronized(() async {
      final box = await _open();
      var sum = 0;
      for (final k in box.keys) {
        final raw = box.get(k);
        if (raw == null) continue;
        sum += (Map<String, dynamic>.from(raw)['manualQuestions'] as int?) ?? 0;
      }
      return sum;
    });
  }
}