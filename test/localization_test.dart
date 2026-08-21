import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

/// MaterialApp'e eklenen delegate'lerin gerçekten Türkçe metin ürettiğini
/// doğrular. Hatırlatma saati seçicisi bu diyalogu kullanıyor.
void main() {
  Widget wrap(Widget child) => MaterialApp(
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('tr')],
        home: child,
      );

  testWidgets('showTimePicker Türkçe İptal/Tamam gösterir', (tester) async {
    await tester.pumpWidget(wrap(
      Builder(
        builder: (context) => TextButton(
          onPressed: () => showTimePicker(
            context: context,
            initialTime: const TimeOfDay(hour: 7, minute: 30),
            builder: (ctx, child) => MediaQuery(
              data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
              child: child!,
            ),
          ),
          child: const Text('ac'),
        ),
      ),
    ));

    await tester.tap(find.text('ac'));
    await tester.pumpAndSettle();

    expect(find.text('İptal'), findsOneWidget);
    expect(find.text('Tamam'), findsOneWidget);
    // 24 saatlik kadran: AM/PM seçici hiç çizilmemeli.
    expect(find.text('AM'), findsNothing);
    expect(find.text('PM'), findsNothing);
  });

  testWidgets('cihaz dili İngilizce olsa da tr çözülür', (tester) async {
    tester.platformDispatcher.localesTestValue = const [Locale('en', 'US')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);

    late BuildContext ctx;
    await tester.pumpWidget(wrap(Builder(builder: (c) {
      ctx = c;
      return const SizedBox();
    })));

    expect(Localizations.localeOf(ctx), const Locale('tr'));
    expect(MaterialLocalizations.of(ctx).cancelButtonLabel, 'İptal');
  });
}
