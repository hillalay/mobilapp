import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mobilapp/features/timer/daily_study_stats_providers.dart';
import 'package:mobilapp/features/timer/daily_study_stats_storage.dart';
import 'package:mobilapp/features/timer/stopwatch_controller.dart';
import 'package:mobilapp/features/timer/study_session_storage.dart';

void main() {
  late Directory dir;

  setUp(() async {
    dir = Directory.systemTemp.createTempSync('mobilapp_test');
    Hive.init(dir.path);
    await Hive.openBox(StudySessionStorage.boxName);
    await Hive.openBox(DailyStudyStatsStorage.boxName);
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    try {
      dir.deleteSync(recursive: true);
    } catch (_) {}
  });

  test('duraklatılan süre sayılmaz', () async {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    final sw = c.read(stopwatchProvider.notifier);

    sw.start();
    await Future<void>.delayed(const Duration(milliseconds: 2100));
    sw.pause();
    final atPause = c.read(stopwatchProvider).seconds;
    expect(atPause, 2);

    // Duraklatılmışken geçen süre birikmemeli
    await Future<void>.delayed(const Duration(milliseconds: 2100));
    expect(c.read(stopwatchProvider).seconds, atPause);

    sw.start();
    await Future<void>.delayed(const Duration(milliseconds: 1100));
    expect(c.read(stopwatchProvider).seconds, 3);
  });

  test('uygulama kapanıp açılınca süre kaldığı yerden gelir', () async {
    final c1 = ProviderContainer();
    c1.read(stopwatchProvider.notifier).start();
    await Future<void>.delayed(const Duration(milliseconds: 2100));
    c1.dispose(); // uygulama öldürüldü

    final c2 = ProviderContainer();
    addTearDown(c2.dispose);
    final restored = c2.read(stopwatchProvider); // ilk kare, async bekleme yok
    expect(restored.isRunning, isTrue);
    expect(restored.seconds, greaterThanOrEqualTo(2));
  });

  test('kronometre kaydedilince stopwatchSeconds artar', () async {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    final stats = c.read(dailyStatsStorageProvider);

    c.read(stopwatchProvider.notifier).start();
    await Future<void>.delayed(const Duration(milliseconds: 2100));
    await c.read(stopwatchProvider.notifier).stop();

    final today = await stats.load(DateTime.now());
    expect(today!.stopwatchSeconds, 2);
    expect(today.totalSeconds, 2);
  });

  test('manuel süre eklemek stopwatchSeconds\'a dokunmaz', () async {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    final stats = c.read(dailyStatsStorageProvider);

    // Önce kronometreyle 2 sn kaydet
    c.read(stopwatchProvider.notifier).start();
    await Future<void>.delayed(const Duration(milliseconds: 2100));
    await c.read(stopwatchProvider.notifier).stop();

    // Sonra dashboard'dan elle 30 dk ekle
    await stats.addManualMinutes(date: DateTime.now(), minutes: 30);

    final today = await stats.load(DateTime.now());
    expect(today!.stopwatchSeconds, 2, reason: 'manuel giriş sıralamaya girmemeli');
    expect(today.totalSeconds, 2 + 30 * 60);
  });

  test('kısmi yazma sonrası stop() aynı süreyi ikinci kez saymaz', () async {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    final sw = c.read(stopwatchProvider.notifier);
    final stats = c.read(dailyStatsStorageProvider);

    // 2 sn çalış, duraklat -> pause() kısmi yazma yapıyor
    sw.start();
    await Future<void>.delayed(const Duration(milliseconds: 2100));
    await sw.pause();

    final afterPause = await stats.load(DateTime.now());
    expect(afterPause!.stopwatchSeconds, 2, reason: 'duraklatınca yazılmalı');

    // 1 sn daha çalış, kaydet -> yalnızca kalan 1 sn eklenmeli
    sw.start();
    await Future<void>.delayed(const Duration(milliseconds: 1100));
    await sw.stop();

    final afterStop = await stats.load(DateTime.now());
    expect(afterStop!.stopwatchSeconds, 3,
        reason: 'toplam 3 sn; kısmi yazılan 2 sn tekrar sayılmamalı');
    expect(afterStop.totalSeconds, 3);
  });

  test('duraklatıp hemen kaydetmek süreyi çiftlemez', () async {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    final sw = c.read(stopwatchProvider.notifier);
    final stats = c.read(dailyStatsStorageProvider);

    sw.start();
    await Future<void>.delayed(const Duration(milliseconds: 2100));
    await sw.pause();
    await sw.stop();

    final today = await stats.load(DateTime.now());
    expect(today!.stopwatchSeconds, 2);
  });

  test('kısmi yazma flushedSeconds\'ı Hive\'a işler', () async {
    final c1 = ProviderContainer();
    final sw = c1.read(stopwatchProvider.notifier);

    sw.start();
    await Future<void>.delayed(const Duration(milliseconds: 2100));
    await sw.pause();
    c1.dispose(); // uygulama öldürüldü

    // Yeniden açılışta flushedSeconds korunmalı, yoksa stop() baştan sayar.
    final c2 = ProviderContainer();
    addTearDown(c2.dispose);
    expect(c2.read(stopwatchProvider).session?.flushedSeconds, 2);

    await c2.read(stopwatchProvider.notifier).stop();
    final today = await c2.read(dailyStatsStorageProvider).load(DateTime.now());
    expect(today!.stopwatchSeconds, 2, reason: 'yeniden açılışta da çiftlenmemeli');
  });

  test('duraklatılmışken uygulama kapanırsa süre büyümez', () async {
    final c1 = ProviderContainer();
    c1.read(stopwatchProvider.notifier).start();
    await Future<void>.delayed(const Duration(milliseconds: 1100));
    await c1.read(stopwatchProvider.notifier).pause();
    c1.dispose();

    await Future<void>.delayed(const Duration(milliseconds: 2100));

    final c2 = ProviderContainer();
    addTearDown(c2.dispose);
    final restored = c2.read(stopwatchProvider);
    expect(restored.isRunning, isFalse);
    expect(restored.seconds, 1);
  });
}
