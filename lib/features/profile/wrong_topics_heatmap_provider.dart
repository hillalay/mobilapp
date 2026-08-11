import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../exams/exam_models.dart';
import '../exams/exam_providers.dart';

class TopicTrend {
  TopicTrend({
    required this.current,
    required this.previous,
  });

  final int current;  // son 10’daki yanlış sayısı
  final int previous; // önceki 10’daki yanlış sayısı

  int get delta => current - previous;
}

typedef TrendMap = Map<String /*lesson*/, Map<String /*topic*/, TopicTrend>>;

/// Ders × hafta ızgarası: son 8 hafta, her hücre o hafta o dersten çıkan
/// yanlış sayısı. Son eleman içinde bulunulan hafta.
///
/// `wrongTopicsTrendLast10Provider` konu bazlı ve hafta boyutu yok; profil
/// ısı haritası zaman ekseni istediği için aynı kaynaktan (examsProvider)
/// ayrıca türetiliyor.
const heatmapWeeks = 8;

final wrongLessonsByWeekProvider = Provider<Map<String, List<int>>>((ref) {
  final async = ref.watch(examsProvider);

  return async.maybeWhen(
    data: (items) {
      final now = DateTime.now();
      final out = <String, List<int>>{};

      for (final e in items) {
        if (e.kind != ExamKind.general || e.general == null) continue;

        final weeksAgo = now.difference(e.createdAt).inDays ~/ 7;
        if (weeksAgo < 0 || weeksAgo >= heatmapWeeks) continue;
        final slot = heatmapWeeks - 1 - weeksAgo; // en yeni sağda

        for (final key in e.general!.wrongTopics) {
          final lesson = key.split('•').first.trim();
          if (lesson.isEmpty) continue;
          final row = out.putIfAbsent(lesson, () => List.filled(heatmapWeeks, 0));
          row[slot]++;
        }
      }

      return out;
    },
    orElse: () => <String, List<int>>{},
  );
});

/// SADECE GENERAL TYT/AYT üzerinden:
/// Son 10 deneme vs önceki 10 deneme trend
final wrongTopicsTrendLast10Provider = Provider<TrendMap>((ref) {
  final async = ref.watch(examsProvider);

  return async.maybeWhen(
    data: (items) {
      // 1) Sadece GENERAL (TYT/AYT) denemeler
      final generals = items
          .where((e) => e.kind == ExamKind.general && e.general != null)
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt)); // yeni -> eski

      final current = generals.take(10).toList();
      final previous = generals.skip(10).take(10).toList();

      Map<String, Map<String, int>> countWrongTopics(List<ExamEntry> list) {
        final res = <String, Map<String, int>>{};
        void inc(String lesson, String topic) {
          final byTopic = res.putIfAbsent(lesson, () => <String, int>{});
          byTopic[topic] = (byTopic[topic] ?? 0) + 1;
        }

        for (final e in list) {
          for (final key in e.general!.wrongTopics) {
            final parts = key.split('•').map((s) => s.trim()).toList();
            if (parts.length >= 2) {
              final lesson = parts.first;
              final topic = parts.sublist(1).join(' • ');
              inc(lesson, topic);
            }
          }
        }
        return res;
      }

      final curMap = countWrongTopics(current);
      final prevMap = countWrongTopics(previous);

      // 2) Birleştir: lesson/topic union
      final out = <String, Map<String, TopicTrend>>{};
      final lessons = {...curMap.keys, ...prevMap.keys};

      for (final lesson in lessons) {
        final curTopics = curMap[lesson] ?? const <String, int>{};
        final prevTopics = prevMap[lesson] ?? const <String, int>{};

        final topics = {...curTopics.keys, ...prevTopics.keys};
        final byTopic = <String, TopicTrend>{};

        for (final topic in topics) {
          byTopic[topic] = TopicTrend(
            current: curTopics[topic] ?? 0,
            previous: prevTopics[topic] ?? 0,
          );
        }

        out[lesson] = byTopic;
      }

      return out;
    },
    orElse: () => <String, Map<String, TopicTrend>>{},
  );
});
