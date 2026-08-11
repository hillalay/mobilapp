import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mobilapp/features/profile/profile_controller.dart';
import 'package:mobilapp/features/profile/profile_storage.dart';

void main() {
  late Directory dir;
  late ProfileStorage storage;

  setUp(() async {
    dir = Directory.systemTemp.createTempSync('profile_test');
    Hive.init(dir.path);
    await Hive.openBox(ProfileStorage.boxName);
    storage = ProfileStorage();
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    try {
      dir.deleteSync(recursive: true);
    } catch (_) {}
  });

  test('yeni alanlar kaydedilip geri okunur', () async {
    await storage.save(const UserProfile(
      track: Track.tm,
      dailyGoalHours: 4,
      reminderHour: 20,
    ));

    final loaded = await storage.load();
    expect(loaded!.track, Track.tm);
    expect(loaded.dailyGoalHours, 4);
    expect(loaded.reminderHour, 20);
  });

  test('hatırlatma istemeyen kullanıcıda reminderHour null kalır', () async {
    await storage.save(const UserProfile(track: Track.mf, dailyGoalHours: 8));

    final loaded = await storage.load();
    expect(loaded!.dailyGoalHours, 8);
    expect(loaded.reminderHour, isNull);
  });

  test('alanlar eklenmeden önce yazılmış kayıt hâlâ okunur', () async {
    // Eski sürümün yazdığı biçim: sadece track.
    await Hive.box(ProfileStorage.boxName).put('profile', {'track': 'sozel'});

    final loaded = await storage.load();
    expect(loaded, isNotNull);
    expect(loaded!.track, Track.sozel);
    expect(loaded.dailyGoalHours, isNull);
    expect(loaded.reminderHour, isNull);
  });
}
