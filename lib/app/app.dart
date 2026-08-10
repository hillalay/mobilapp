import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/auth_providers.dart';
import 'router.dart';

class MobilApp extends ConsumerWidget {
  const MobilApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Oturum açılınca senkronu başlatır, kapanınca durdurur.
    ref.watch(syncBootstrapProvider);

    final router = ref.watch(goRouterProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'MobilApp',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      routerConfig: router,
    );
  }
}
