import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../topics/topic_progress.dart';
import '../topics/topic_progress_providers.dart';
import '../timer/daily_study_stats_providers.dart';
import 'dashboard_summary.dart';
import '../topics/my_topics_providers.dart';

final dashboardSummaryProvider = FutureProvider<DashboardSummary>((ref) async {
  final progressMap = await ref.watch(topicProgressMapProvider.future);
  return DashboardSummary.fromProgressMap(progressMap);
});

///  Dashboard "Toplam Soru" kartı sadece manualQuestions toplamından beslenecek
final dashboardTotalQuestionsProvider = FutureProvider<int>((ref) async {
  final storage = ref.read(dailyStatsStorageProvider);
  return storage.loadTotalManualQuestions();
});

/// Ana sayfadaki "Sıradaki konular" satırları.
class NextTopic {
  const NextTopic({
    required this.subject,
    required this.topic,
    required this.exam,
    required this.status,
  });

  final String subject;
  final String topic;
  final String exam; // TYT / AYT
  final TopicStatus status;

  bool get isDone => status == TopicStatus.done;

  /// `topic_progress` Hive anahtarıyla aynı biçim.
  String get key => '$subject::$topic';
}

/// Konu adları uydurulmaz: `assets/data/curriculum.json` + `topic_progress`.
/// Sıra: önce çalışılmakta olanlar, sonra hiç başlanmamışlar, en sonda bitenler.
///
/// TYT ve AYT ayrı ayrı okunuyor — `mergedTopicsProvider` ikisini tek anahtar
/// altında birleştirdiği için satır altındaki `ders · sınav` bilgisi kaybolurdu.
final nextTopicsProvider = FutureProvider<List<NextTopic>>((ref) async {
  final myTopics = await ref.watch(myTopicsProvider.future);
  final progress = await ref.watch(topicProgressMapProvider.future);

  final all = myTopics.map((mt) {
    final subject = mt.subject ?? '';
    return NextTopic(
      subject: subject,
      topic: mt.topic,
      exam: mt.exam,
      status: progress[mt.progressKey]?.status ?? TopicStatus.notStarted,
    );
  }).toList();

  int rank(TopicStatus s) =>switch(s){
    TopicStatus.inProgress => 0,
    TopicStatus.repeat => 1,
    TopicStatus.notStarted => 2,
    TopicStatus.done => 3,
  };
  all.sort((a, b) => rank(a.status).compareTo(rank(b.status)));
  return all;
});


/// Konu işaretlemesinin iyimser (optimistic) durumu.
///
/// Ana sayfa ve profildeki "Bugün yapılacaklar" aynı konuları gösteriyor;
/// state burada tutulduğu için birinde işaretlenen konu diğerinde de işaretli
/// görünüyor. UI hemen değişir, yazma arkada olur, hata olursa geri alınır.
final topicCheckProvider =
    NotifierProvider<TopicCheckNotifier, Map<String, bool>>(
  TopicCheckNotifier.new,
);

class TopicCheckNotifier extends Notifier<Map<String, bool>> {
  @override
  Map<String, bool> build() => const {};

  /// Görünen işaretli durumu: iyimser değer varsa o, yoksa kayıttaki.
  bool isDone(NextTopic topic) => state[topic.key] ?? topic.isDone;

  Future<void> toggle(NextTopic topic) async {
    final next = !isDone(topic);
    state = {...state, topic.key: next};

    try {
      await ref.read(topicProgressStorageProvider).put(
            TopicProgress(
              subject: topic.subject.isEmpty ? 'Genel' : topic.subject,
              topic: topic.topic,
              status: next ? TopicStatus.done : TopicStatus.notStarted,
              lastStudiedAt: DateTime.now(),
            ),
          );
      if (ref.mounted) ref.invalidate(topicProgressMapProvider);
    } catch (_) {
      state = {...state}..remove(topic.key);
      rethrow;
    }
  }
}
