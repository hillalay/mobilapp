import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'daily_study_stats.dart';
import 'daily_study_stats_storage.dart';

final dailyStatsStorageProvider = Provider((ref) => DailyStudyStatsStorage());

final todayStatsProvider = FutureProvider<DailyStudyStats?>((ref) async {
  return ref.read(dailyStatsStorageProvider).load(DateTime.now());
});