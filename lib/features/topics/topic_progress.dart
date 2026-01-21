enum TopicStatus { notStarted, inProgress, done, repeat }

class TopicProgress {
  final String subject; // "Matematik"
  final String topic;   // "Fonksiyonlar"
  final TopicStatus status;
  final int solvedQuestions;
  final int studiedMinutes;
  final DateTime? lastStudiedAt;

  const TopicProgress({
    required this.subject,
    required this.topic,
    this.status = TopicStatus.notStarted,
    this.solvedQuestions = 0,
    this.studiedMinutes = 0,
    this.lastStudiedAt,
  });

  TopicProgress copyWith({
    TopicStatus? status,
    int? solvedQuestions,
    int? studiedMinutes,
    DateTime? lastStudiedAt,
  }) {
    return TopicProgress(
      subject: subject,
      topic: topic,
      status: status ?? this.status,
      solvedQuestions: solvedQuestions ?? this.solvedQuestions,
      studiedMinutes: studiedMinutes ?? this.studiedMinutes,
      lastStudiedAt: lastStudiedAt ?? this.lastStudiedAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'subject': subject,
        'topic': topic,
        'status': status.name,
        'solvedQuestions': solvedQuestions,
        'studiedMinutes': studiedMinutes,
        'lastStudiedAt': lastStudiedAt?.toIso8601String(),
      };

  static TopicProgress fromMap(Map<String, dynamic> map) {
    return TopicProgress(
      subject: map['subject'] as String,
      topic: map['topic'] as String,
      status: TopicStatus.values.byName(map['status'] as String),
      solvedQuestions: (map['solvedQuestions'] ?? 0) as int,
      studiedMinutes: (map['studiedMinutes'] ?? 0) as int,
      lastStudiedAt: (map['lastStudiedAt'] as String?) == null
          ? null
          : DateTime.parse(map['lastStudiedAt'] as String),
    );
  }

  /// Hive key (unique)
  String key() => '$subject::$topic';
}
