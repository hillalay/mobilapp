import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mobilapp/core/sync_engine.dart';
import 'package:mobilapp/features/timer/study_session_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  late Directory dir;
  late SyncEngine engine;

  setUp(() async {
    dir = Directory.systemTemp.createTempSync('sync_test');
    Hive.init(dir.path);
    await SyncEngine.openBoxes();

    // Oturum yok: push/pull erken döner, sadece yerel takip çalışır.
    engine = SyncEngine(SupabaseClient('http://localhost:54321', 'test-key'));
    await engine.start();
  });

  tearDown(() async {
    await engine.stop();
    await Hive.deleteFromDisk();
    try {
      dir.deleteSync(recursive: true);
    } catch (_) {}
  });

  Box dirty() => Hive.box('sync_dirty_box');

  test('yerel yazma kirli olarak işaretlenir', () async {
    await Hive.box(StudySessionStorage.boxName).put('abc', {'id': 'abc'});
    await Future<void>.delayed(Duration.zero);

    expect(dirty().get('study_sessions|abc'), isTrue);
  });

  test('silme de kirli olarak işaretlenir', () async {
    final box = Hive.box(StudySessionStorage.boxName);
    await box.put('abc', {'id': 'abc'});
    await Future<void>.delayed(Duration.zero);
    await dirty().clear();

    await box.delete('abc');
    await Future<void>.delayed(Duration.zero);

    expect(dirty().get('study_sessions|abc'), isTrue);
  });

  test('hasStartedFor: aynı oturumda true, stop sonrası ve başka kullanıcıda false',
      () async {
    // setUp() içinde start() çağrıldı; oturum yok, yani userId null.
    expect(engine.hasStartedFor(null), isTrue);
    expect(engine.hasStartedFor('baska-kullanici'), isFalse);

    await engine.stop();
    expect(engine.hasStartedFor(null), isFalse);
  });

  test('clearLocal tüm kutuları ve senkron durumunu temizler', () async {
    await Hive.box(StudySessionStorage.boxName).put('abc', {'id': 'abc'});
    await Future<void>.delayed(Duration.zero);

    await engine.clearLocal();

    expect(Hive.box(StudySessionStorage.boxName).isEmpty, isTrue);
    expect(dirty().isEmpty, isTrue);
  });
}
