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

  test('fingerprint içerik karşılaştırır, referans değil', () {
    final a = {
      'id': 'abc',
      'durationSeconds': 60,
      'nested': {'x': [1, 2]},
    };
    final b = {
      'id': 'abc',
      'durationSeconds': 60,
      'nested': {'x': [1, 2]},
    };

    // Tuzağı belgele: aynı içerikte iki ayrı Map birbirine == değildir.
    // push() bu karşılaştırmayı düz == ile yapsaydı hiçbir kirli işaret
    // temizlenmez, her push aynı satırları tekrar gönderirdi.
    expect(a == b, isFalse);
    expect(SyncEngine.fingerprint(a), SyncEngine.fingerprint(b));

    // Hive Map<dynamic, dynamic> döndürür; tip farkı parmak izini bozmamalı.
    final hiveStyle = <dynamic, dynamic>{
      'id': 'abc',
      'durationSeconds': 60,
      'nested': <dynamic, dynamic>{
        'x': <dynamic>[1, 2],
      },
    };
    expect(SyncEngine.fingerprint(hiveStyle), SyncEngine.fingerprint(a));

    // İçerik değiştiyse parmak izi de değişmeli: kirli işaret korunacak.
    expect(
      SyncEngine.fingerprint({...a, 'durationSeconds': 120}),
      isNot(SyncEngine.fingerprint(a)),
    );

    // Silinmiş kayıt (null) kendisiyle eşleşir, dolu kayıtla eşleşmez.
    expect(SyncEngine.fingerprint(null), SyncEngine.fingerprint(null));
    expect(SyncEngine.fingerprint(null), isNot(SyncEngine.fingerprint(a)));
  });

  test('fingerprint Hive üzerinden okunan değeri de doğru ayırt eder', () async {
    final box = Hive.box(StudySessionStorage.boxName);

    await box.put('abc', {'id': 'abc', 'durationSeconds': 60});
    final sent = SyncEngine.fingerprint(box.get('abc'));

    // Değişmemiş değerin ikinci okuması aynı parmak izini vermeli
    // (aksi hâlde kirli işaret hiç silinmez).
    expect(SyncEngine.fingerprint(box.get('abc')), sent);

    // Push sürerken üzerine yazılmış değer farklı parmak izi vermeli
    // (aksi hâlde yeni yazma push edilmeden kirli işareti silinir).
    await box.put('abc', {'id': 'abc', 'durationSeconds': 120});
    expect(SyncEngine.fingerprint(box.get('abc')), isNot(sent));
  });

  test('clearLocal tüm kutuları ve senkron durumunu temizler', () async {
    await Hive.box(StudySessionStorage.boxName).put('abc', {'id': 'abc'});
    await Future<void>.delayed(Duration.zero);

    await engine.clearLocal();

    expect(Hive.box(StudySessionStorage.boxName).isEmpty, isTrue);
    expect(dirty().isEmpty, isTrue);
  });
}
