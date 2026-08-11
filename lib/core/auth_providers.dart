import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../features/dashboard/dashboard_providers.dart';
import '../features/exams/exam_providers.dart';
import '../features/profile/profile_controller.dart';
import '../features/timer/daily_study_stats_providers.dart';
import '../features/timer/stopwatch_controller.dart';
import '../features/timer/study_session_providers.dart';
import '../features/topics/topic_progress_providers.dart';
import 'supabase_config.dart';
import 'sync_engine.dart';

/// Supabase yapılandırılmamışsa null: uygulama tamamen yerel çalışır.
final supabaseClientProvider = Provider<SupabaseClient?>((ref) {
  return SupabaseConfig.isConfigured ? Supabase.instance.client : null;
});

final authChangesProvider = StreamProvider<AuthState>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) return const Stream.empty();
  return client.auth.onAuthStateChange;
});

final currentUserProvider = Provider<User?>((ref) {
  ref.watch(authChangesProvider);
  return ref.watch(supabaseClientProvider)?.auth.currentUser;
});

/// Giriş ekranı yalnızca Supabase yapılandırılmışsa ve oturum yoksa gösterilir.
final requiresLoginProvider = Provider<bool>((ref) {
  return SupabaseConfig.isConfigured && ref.watch(currentUserProvider) == null;
});

final syncEngineProvider = Provider<SyncEngine?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) return null;

  final engine = SyncEngine(client);
  ref.onDispose(engine.stop);
  return engine;
});

/// Oturum açıldığında senkronu başlatır, kapandığında durdurur.
/// [MobilApp] tarafından izleniyor.
final syncBootstrapProvider = Provider<void>((ref) {
  final engine = ref.watch(syncEngineProvider);
  if (engine == null) {
    // En sık karşılaşılan durum: --dart-define verilmeden çalıştırmak.
    debugPrint('[sync] devre dışı: Supabase yapılandırılmamış '
        '(--dart-define-from-file=env.json verildi mi?)');
    return;
  }

  final user = ref.watch(currentUserProvider);
  if (user == null) {
    debugPrint('[sync] başlatılmadı: oturum açık değil, giriş bekleniyor');
    engine.stop();
    return;
  }

  debugPrint('[sync] başlatılıyor: kullanıcı ${user.id}');

  // İlk çekme bitince Hive'dan okuyan her şey tazelenir.
  engine.start().then((_) {
    ref.invalidate(profileProvider);
    ref.invalidate(stopwatchProvider);
    ref.invalidate(studySessionsProvider);
    ref.invalidate(activeSessionProvider);
    ref.invalidate(todayStatsProvider);
    ref.invalidate(examsProvider);
    ref.invalidate(topicProgressMapProvider);
    ref.invalidate(dashboardSummaryProvider);
    ref.invalidate(dashboardTotalQuestionsProvider);
  });
});
