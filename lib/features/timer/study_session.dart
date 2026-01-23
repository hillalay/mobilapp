class StudySession {
  final String id;
  final DateTime startTime;
  final DateTime? endTime;
  final int durationSeconds;
  final String? lesson;
  final String? topic;

  const StudySession({
    required this.id,
    required this.startTime,
    this.endTime,
    required this.durationSeconds,
    this.lesson,
    this.topic,
  });

  bool get isActive => endTime == null;

  Map<String, dynamic> toMap() => {
        'id': id,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime?.toIso8601String(),
        'durationSeconds': durationSeconds,
        'lesson': lesson,
        'topic': topic,
      };

  static StudySession fromMap(Map<String, dynamic> map) => StudySession(
        id: map['id'] as String,
        startTime: DateTime.parse(map['startTime'] as String),
        endTime: map['endTime'] == null ? null : DateTime.parse(map['endTime'] as String),
        durationSeconds: (map['durationSeconds'] ?? 0) as int,
        lesson: map['lesson'] as String?,
        topic: map['topic'] as String?,
      );
}