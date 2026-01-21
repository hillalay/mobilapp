import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../topics/topic_progress_providers.dart';
import 'dashboard_summary.dart';

final dashboardSummaryProvider = FutureProvider((ref) async {
  final progressMap = await ref.watch(topicProgressMapProvider.future);
  return DashboardSummary.fromProgressMap(progressMap);
});
