import '../topics/topic_progress.dart';

class DashboardSummary {
  final int totalMinutes;
  final int totalQuestions;
  final int doneCount;
  final int inProgressCount;

  const DashboardSummary({
    required this.totalMinutes,
    required this.totalQuestions,
    required this.doneCount,
    required this.inProgressCount,
  });

  String get totalHoursText {
    final h = totalMinutes ~/ 60;
    final m = totalMinutes % 60;
    if (h == 0) return '$m dk';
    return '$h sa $m dk';
  }

  static DashboardSummary fromProgressMap(Map<String, TopicProgress> map) {
    int minutes = 0;
    int questions = 0;
    int done = 0;
    int inProg = 0;

    for (final p in map.values) {
      minutes += p.studiedMinutes;
      questions += p.solvedQuestions;
      if (p.status == TopicStatus.done) done++;
      if (p.status == TopicStatus.inProgress) inProg++;
    }

    return DashboardSummary(
      totalMinutes: minutes,
      totalQuestions: questions,
      doneCount: done,
      inProgressCount: inProg,
    );
  }
}
