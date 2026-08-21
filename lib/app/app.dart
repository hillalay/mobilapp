import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/auth_providers.dart';
import '../features/profile/study_reminder_notifications.dart';
import 'router.dart';
import 'theme.dart';

class MobilApp extends ConsumerWidget {
  const MobilApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Oturum açılınca senkronu başlatır, kapanınca durdurur.
    ref.watch(syncBootstrapProvider);

    // Profildeki hatırlatma saatiyle günlük bildirimi eşitler (açılış dahil).
    ref.watch(studyReminderBootstrapProvider);

    final router = ref.watch(goRouterProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'MobilApp',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      // Material'in hazır diyalogları (saat/tarih seçici, AlertDialog
      // butonları) cihaz diline göre İngilizce açılıyordu. Uygulama tek dilli
      // olduğu için desteklenen tek yerel ayar tr: cihaz dili ne olursa olsun
      // Flutter buna düşer.
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('tr')],
      routerConfig: router,
    );
  }
}
