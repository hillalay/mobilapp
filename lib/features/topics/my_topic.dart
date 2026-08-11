/// Öğrencinin kendi seçtiği/eklediği bir konu.
/// Curriculum'dan seçilmiş ya da tamamen özgür yazılmış olabilir.
class MyTopic {
  const MyTopic({
    required this.id,
    required this.topic,
    this.subject,
    this.exam = 'custom',
    required this.createdAt,
  });

  /// Curriculum'dan seçilenler: '$subject::$topic::$exam'
  /// Özgür konular: benzersiz bir string (örn. zaman damgası).
  final String id;

  final String topic;

  /// Opsiyonel — özgür konularda boş olabilir.
  final String? subject;

  /// 'TYT' / 'AYT' / 'custom'
  final String exam;

  final DateTime createdAt;

  Map<String, dynamic> toMap() => {
        'id': id,
        'topic': topic,
        'subject': subject,
        'exam': exam,
        'createdAt': createdAt.toIso8601String(),
      };

  static MyTopic fromMap(Map<String, dynamic> map) {
    return MyTopic(
      id: map['id'] as String,
      topic: map['topic'] as String,
      subject: map['subject'] as String?,
      exam: (map['exam'] as String?) ?? 'custom',
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  /// `topic_progress` ile aynı anahtar biçimi — subject boşsa 'Genel' kullanılır,
  /// TopicProgress.key() ile eşleşsin diye ('$subject::$topic').
  String get progressKey => '${subject ?? 'Genel'}::$topic';
}