class StudySession {
  final String id;
  final DateTime startTime;
  final DateTime? endTime;

  /// Duraklamalar hariç, o ana kadar birikmiş süre.
  final int durationSeconds;

  /// Son "Başlat/Devam" anı. null ise kronometre duraklatılmış demektir.
  final DateTime? resumedAt;

  /// Günlük istatistiklere şu ana kadar yazılmış saniye. Kronometre çalışırken
  /// dakikada bir kısmi yazma yapılıyor; `stop()` yalnızca kalanı ekleyebilsin
  /// diye burada tutuluyor. Hive'a yazılıyor ki uygulama kapanıp açılsa da
  /// aynı süre iki kez sayılmasın.
  final int flushedSeconds;

  const StudySession({
    required this.id,
    required this.startTime,
    this.endTime,
    required this.durationSeconds,
    this.resumedAt,
    this.flushedSeconds = 0,
  });

  bool get isActive => endTime == null;

  bool get isRunning => endTime == null && resumedAt != null;

  /// Tek doğruluk kaynağı: birikmiş süre + (çalışıyorsa) devam ettirmeden bu yana geçen süre.
  /// Duvar saatinden hesaplandığı için uygulama kapansa da doğru kalır.
  int get elapsedSeconds {
    if (!isRunning) return durationSeconds;
    return durationSeconds + DateTime.now().difference(resumedAt!).inSeconds;
  }

  String get formattedDuration {
    final hours = durationSeconds ~/ 3600;
    final minutes = (durationSeconds % 3600) ~/ 60;
    return '${hours}s ${minutes}dk';
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime?.toIso8601String(),
        'durationSeconds': durationSeconds,
        'resumedAt': resumedAt?.toIso8601String(),
        'flushedSeconds': flushedSeconds,
      };

  static StudySession fromMap(Map<String, dynamic> map) => StudySession(
        id: map['id'] as String,
        startTime: DateTime.parse(map['startTime'] as String),
        endTime: map['endTime'] == null ? null : DateTime.parse(map['endTime'] as String),
        durationSeconds: (map['durationSeconds'] ?? 0) as int,
        resumedAt:
            map['resumedAt'] == null ? null : DateTime.parse(map['resumedAt'] as String),
        flushedSeconds: (map['flushedSeconds'] ?? 0) as int,
      );
}
