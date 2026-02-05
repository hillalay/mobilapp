import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../topics/topic_progress_providers.dart';
import '../timer/daily_study_stats_providers.dart';
import 'dashboard_summary.dart';

final dashboardSummaryProvider = FutureProvider<DashboardSummary>((ref) async {
  final progressMap = await ref.watch(topicProgressMapProvider.future);
  return DashboardSummary.fromProgressMap(progressMap);
});

/// ✅ Dashboard "Toplam Soru" kartı sadece manualQuestions toplamından beslenecek
final dashboardTotalQuestionsProvider = FutureProvider<int>((ref) async {
  final storage = ref.read(dailyStatsStorageProvider);
  return storage.loadTotalManualQuestions();
});
