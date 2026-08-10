class DailyStudyStats {
  final String dayKey;

  /// Manuel girişler + kronometre. Dashboard bunu gösteriyor.
  final int totalSeconds;

  /// Yalnızca kronometreyle ölçülen süre. Liderlik tablosu bunu kullanıyor;
  /// manuel "Süre Ekle" akışı bu alana dokunmaz.
  final int stopwatchSeconds;

  final int manualQuestions;

  const DailyStudyStats({
    required this.dayKey,
    required this.totalSeconds,
    this.stopwatchSeconds = 0,
    this.manualQuestions = 0,
  });

  DailyStudyStats copyWith({
    String? dayKey,
    int? totalSeconds,
    int? stopwatchSeconds,
    int? manualQuestions,
  }) {
    return DailyStudyStats(
      dayKey: dayKey ?? this.dayKey,
      totalSeconds: totalSeconds ?? this.totalSeconds,
      stopwatchSeconds: stopwatchSeconds ?? this.stopwatchSeconds,
      manualQuestions: manualQuestions ?? this.manualQuestions,
    );
  }

  Map<String, dynamic> toMap() => {
        'dayKey': dayKey,
        'totalSeconds': totalSeconds,
        'stopwatchSeconds': stopwatchSeconds,
        'manualQuestions': manualQuestions,
      };

  static DailyStudyStats fromMap(Map<String, dynamic> map) {
    return DailyStudyStats(
      dayKey: map['dayKey'] as String,
      totalSeconds: (map['totalSeconds'] as int?) ?? 0,
      // Alan eklenmeden önce yazılmış kayıtlarda yok.
      stopwatchSeconds: (map['stopwatchSeconds'] as int?) ?? 0,
      manualQuestions: (map['manualQuestions'] as int?) ?? 0,
    );
  }
}
