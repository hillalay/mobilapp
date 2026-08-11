import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mobilapp/app/router.dart';
import 'package:mobilapp/app/theme.dart';
import 'package:mobilapp/core/sync_engine.dart';
import 'package:mobilapp/features/profile/profile_controller.dart';
import 'package:mobilapp/features/profile/profile_storage.dart';

/// Bildirilen hata: onboarding her açılışta çıkıyordu.
void main() {
  late Directory dir;

  setUp(() async {
    dir = Directory.systemTemp.createTempSync('router_test');
    Hive.init(dir.path);
    await SyncEngine.openBoxes();
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    try {
      dir.deleteSync(recursive: true);
    } catch (_) {}
  });

  Future<ProviderContainer> pumpApp(WidgetTester tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          theme: AppTheme.light,
          routerConfig: container.read(goRouterProvider),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    return container;
  }

  testWidgets('profil yoksa onboarding açılır', (tester) async {
    await pumpApp(tester);
    expect(find.text('ADIM 1 / 3'), findsOneWidget);
  });

  testWidgets('profil kayıtlıysa onboarding açılmaz', (tester) async {
    // Hive gerçek dosya I/O yapıyor; testWidgets gövdesi fake-async içinde
    // olduğu için runAsync olmadan bu future hiç tamamlanmaz.
    await tester.runAsync(
      () => ProfileStorage().save(const UserProfile(track: Track.mf)),
    );

    await pumpApp(tester);

    expect(find.text('ADIM 1 / 3'), findsNothing);
    expect(find.text('Sıradaki konular'), findsOneWidget);
  });

  testWidgets('profil yenilenince onboardinge geri düşmez', (tester) async {
    await tester.runAsync(
      () => ProfileStorage().save(const UserProfile(track: Track.tm)),
    );
    final container = await pumpApp(tester);

    // Açılışta senkron çekmesi tam olarak bunu yapıyor.
    container.invalidate(profileProvider);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('ADIM 1 / 3'), findsNothing);
    expect(find.text('Sıradaki konular'), findsOneWidget);
  });
}
