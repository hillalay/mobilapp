import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mobilapp/features/timer/daily_study_stats_storage.dart';

void main() {
  late Directory dir;
  late DailyStudyStatsStorage storage;

  setUp(() async {
    dir = Directory.systemTemp.createTempSync('daily_stats_test');
    Hive.init(dir.path);
    await Hive.openBox(DailyStudyStatsStorage.boxName);
    storage = DailyStudyStatsStorage();
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    try {
      dir.deleteSync(recursive: true);
    } catch (_) {}
  });

  test('eşzamanlı addSeconds çağrıları kaybolmaz', () async {
    // Kilit olmadan bunlar aynı kaydı okuyup birbirinin üstüne yazıyordu.
    await Future.wait([
      for (var i = 0; i < 10; i++)
        storage.addSeconds(date: DateTime(2026, 8, 21), seconds: 60),
    ]);

    final day = await storage.load(DateTime(2026, 8, 21));
    expect(day?.totalSeconds, 600);
  });

  test('kronometre ve manuel giriş çakışsa da ikisi de yazılır', () async {
    final date = DateTime(2026, 8, 21);
    await Future.wait([
      storage.addSeconds(date: date, seconds: 300, fromStopwatch: true),
      storage.addManualMinutes(date: date, minutes: 30),
    ]);

    final day = await storage.load(date);
    expect(day?.totalSeconds, 300 + 1800);
    // Manuel süre liderlik tablosuna girmiyor.
    expect(day?.stopwatchSeconds, 300);
  });

  test('addSecondsSpan gece yarısını iki güne böler', () async {
    await storage.addSecondsSpan(
      start: DateTime(2026, 8, 21, 23, 50),
      end: DateTime(2026, 8, 22, 0, 10),
      fromStopwatch: true,
    );

    expect((await storage.load(DateTime(2026, 8, 21)))?.stopwatchSeconds, 600);
    expect((await storage.load(DateTime(2026, 8, 22)))?.stopwatchSeconds, 600);
  });

  test('addSecondsSpan birden çok günü aşan aralığı dağıtır', () async {
    await storage.addSecondsSpan(
      start: DateTime(2026, 8, 21, 22),
      end: DateTime(2026, 8, 23, 2),
      fromStopwatch: true,
    );

    expect((await storage.load(DateTime(2026, 8, 21)))?.totalSeconds, 2 * 3600);
    expect((await storage.load(DateTime(2026, 8, 22)))?.totalSeconds, 24 * 3600);
    expect((await storage.load(DateTime(2026, 8, 23)))?.totalSeconds, 2 * 3600);
  });

  test('ters aralık hiçbir şey yazmaz', () async {
    await storage.addSecondsSpan(
      start: DateTime(2026, 8, 21, 10),
      end: DateTime(2026, 8, 21, 9),
    );
    expect(await storage.load(DateTime(2026, 8, 21)), isNull);
  });
}
