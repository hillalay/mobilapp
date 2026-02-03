class StudySession {
  final String id;
  final DateTime startTime;
  final DateTime? endTime;
  final int durationSeconds;

  const StudySession({
    required this.id,
    required this.startTime,
    this.endTime,
    required this.durationSeconds,
  });

  bool get isActive => endTime == null;

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
      };

  static StudySession fromMap(Map<String, dynamic> map) => StudySession(
        id: map['id'] as String,
        startTime: DateTime.parse(map['startTime'] as String),
        endTime: map['endTime'] == null ? null : DateTime.parse(map['endTime'] as String),
        durationSeconds: (map['durationSeconds'] ?? 0) as int,
      );
}