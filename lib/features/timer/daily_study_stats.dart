class DailyStudyStats {
  final String dayKey;
  final int totalSeconds;
  final int manualQuestions;

  const DailyStudyStats({
    required this.dayKey,
    required this.totalSeconds,
    this.manualQuestions = 0,
  });

  DailyStudyStats copyWith({
    String? dayKey,
    int? totalSeconds,
    int? manualQuestions,
  }) {
    return DailyStudyStats(
      dayKey: dayKey ?? this.dayKey,
      totalSeconds: totalSeconds ?? this.totalSeconds,
      manualQuestions: manualQuestions ?? this.manualQuestions,
    );
  }

  Map<String, dynamic> toMap() => {
        'dayKey': dayKey,
        'totalSeconds': totalSeconds,
        'manualQuestions': manualQuestions,
      };

  static DailyStudyStats fromMap(Map<String, dynamic> map) {
    return DailyStudyStats(
      dayKey: map['dayKey'] as String,
      totalSeconds: (map['totalSeconds'] as int?) ?? 0,
      manualQuestions: (map['manualQuestions'] as int?) ?? 0,
    );
  }
}
