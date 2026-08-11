import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mobilapp/app/theme.dart';
import 'package:mobilapp/features/dashboard/dashboard_page.dart';
import 'package:mobilapp/features/dashboard/dashboard_providers.dart';
import 'package:mobilapp/features/topics/topic_progress.dart';
import 'package:mobilapp/features/topics/topic_progress_providers.dart';
import 'package:mobilapp/features/profile/onboarding_page.dart';
import 'package:mobilapp/features/profile/profile_controller.dart';
import 'package:mobilapp/features/profile/profile_page.dart';
import 'package:mobilapp/features/profile/profile_storage.dart';
import 'package:mobilapp/features/timer/daily_study_stats_storage.dart';
import 'package:mobilapp/features/topics/topic_progress_storage.dart';
import 'package:mobilapp/features/exams/exam_storage.dart';

/// Yeniden yazılan üç ekranın gerçekten çizildiğini doğrular; analiz
/// yakalamadığı çalışma zamanı düzen hatalarını yakalar.
void main() {
  late Directory dir;

  setUp(() async {
    dir = Directory.systemTemp.createTempSync('screens_test');
    Hive.init(dir.path);
    for (final box in [
      ProfileStorage.boxName,
      DailyStudyStatsStorage.boxName,
      TopicProgressStorage.boxName,
      ExamStorage.boxName,
    ]) {
      await Hive.openBox(box);
    }
    await ProfileStorage().save(
      const UserProfile(track: Track.mf, dailyGoalHours: 4, reminderHour: 20),
    );
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    try {
      dir.deleteSync(recursive: true);
    } catch (_) {}
  });

  Future<void> pump(WidgetTester tester, Widget screen) async {
    // Tasarım 390×844 (iPhone 14/15) üzerinde çizildi; dar ekran taşmaları
    // ancak bu boyutta ortaya çıkar.
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(theme: AppTheme.light, home: screen),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  testWidgets('onboarding çizilir ve adımlar ilerler', (tester) async {
    await pump(tester, const OnboardingPage());

    expect(find.text('ADIM 1 / 3'), findsOneWidget);
    expect(find.text('Hangi alanda yarışıyorsun?'), findsOneWidget);
    expect(find.text('MF · Sayısal'), findsOneWidget);

    await tester.tap(find.text('MF · Sayısal'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('ADIM 2 / 3'), findsOneWidget);
    expect(find.text('Günde kaç saat hedefliyorsun?'), findsOneWidget);

    await tester.tap(find.text('4 saat'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('ADIM 3 / 3'), findsOneWidget);
    expect(find.text('Hatırlatma istemiyorum'), findsOneWidget);
  });

  testWidgets('ana sayfa çizilir', (tester) async {
    await pump(tester, const DashboardPage());

    expect(find.text('Sıradaki konular'), findsOneWidget);
    expect(find.text('Bugün'), findsOneWidget);
    expect(find.text('Soru'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('konu işareti ana sayfa ile profil arasında paylaşılıyor', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // Profildeki satır da ana sayfadaki satır da aynı notifier'ı çağırıyor;
    // durum tek yerde tutulduğu için iki ekran da aynı işareti gösterir.
    const topic = NextTopic(
      subject: 'Matematik',
      topic: 'Türev',
      exam: 'AYT',
      status: TopicStatus.notStarted,
    );

    expect(container.read(topicCheckProvider)[topic.key], isNull);

    await container.read(topicCheckProvider.notifier).toggle(topic);

    expect(container.read(topicCheckProvider)[topic.key], isTrue);

    final saved = await container.read(topicProgressMapProvider.future);
    expect(saved[topic.key]?.status, TopicStatus.done);
  });

  testWidgets('profil çizilir', (tester) async {
    await pump(tester, const ProfilePage());

    expect(find.text('Bugün yapılacaklar'), findsOneWidget);
    expect(find.text('Yanlış yoğunluğu'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
