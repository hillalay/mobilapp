import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mobilapp/features/timer/stopwatch_controller.dart';
import 'package:mobilapp/features/timer/study_session_storage.dart';

void main() {
  late Directory dir;

  setUp(() async {
    dir = Directory.systemTemp.createTempSync('mobilapp_test');
    Hive.init(dir.path);
    await Hive.openBox(StudySessionStorage.boxName);
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

  test('duraklatılmışken uygulama kapanırsa süre büyümez', () async {
    final c1 = ProviderContainer();
    c1.read(stopwatchProvider.notifier).start();
    await Future<void>.delayed(const Duration(milliseconds: 1100));
    c1.read(stopwatchProvider.notifier).pause();
    c1.dispose();

    await Future<void>.delayed(const Duration(milliseconds: 2100));

    final c2 = ProviderContainer();
    addTearDown(c2.dispose);
    final restored = c2.read(stopwatchProvider);
    expect(restored.isRunning, isFalse);
    expect(restored.seconds, 1);
  });
}
