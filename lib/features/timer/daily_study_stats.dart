class DailyStudyStats {
  final String dayKey; // "2026-02-03"
  final int totalSeconds;

  const DailyStudyStats({
    required this.dayKey,
    required this.totalSeconds,
  });

  DailyStudyStats copyWith({
    int? totalSeconds,
  }) {
    return DailyStudyStats(
      dayKey: dayKey,
      totalSeconds: totalSeconds ?? this.totalSeconds,
    );
  }

  String get formattedTime {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    return '${hours}s ${minutes}dk';
  }

  Map<String, dynamic> toMap() => {
        'dayKey': dayKey,
        'totalSeconds': totalSeconds,
      };

  static DailyStudyStats fromMap(Map<String, dynamic> map) {
    return DailyStudyStats(
      dayKey: map['dayKey'] as String,
      totalSeconds: (map['totalSeconds'] ?? 0) as int,
    );
  }
}