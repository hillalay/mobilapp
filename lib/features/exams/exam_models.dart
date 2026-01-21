enum ExamKind { general, branch }
enum ExamType { tyt, ayt }

class BranchExamResult {
  final String lesson; // Matematik
  final List<String> topics; // seçilen konular
  final int correct;
  final int wrong;
  final int blank;

  const BranchExamResult({
    required this.lesson,
    required this.topics,
    required this.correct,
    required this.wrong,
    required this.blank,
  });

  double get net => correct - (wrong / 4.0);

  Map<String, dynamic> toMap() => {
        'lesson': lesson,
        'topics': topics,
        'correct': correct,
        'wrong': wrong,
        'blank': blank,
      };

  static BranchExamResult fromMap(Map<String, dynamic> map) => BranchExamResult(
        lesson: map['lesson'] as String,
        topics: List<String>.from(map['topics'] as List),
        correct: (map['correct'] ?? 0) as int,
        wrong: (map['wrong'] ?? 0) as int,
        blank: (map['blank'] ?? 0) as int,
      );
}

class GeneralExamResult {
  final ExamType type; // TYT/AYT
  final Map<String, double> netsBySection; // Türkçe, Mat, Fen...
  final List<String> wrongTopics;

  const GeneralExamResult({
    required this.type,
    required this.netsBySection,
    required this.wrongTopics,
  });

  Map<String, dynamic> toMap() => {
        'type': type.name,
        'netsBySection': netsBySection,
        'wrongTopics': wrongTopics,
      };

  static GeneralExamResult fromMap(Map<String, dynamic> map) => GeneralExamResult(
        type: ExamType.values.byName(map['type'] as String),
        netsBySection: Map<String, double>.from(
          (map['netsBySection'] as Map).map((k, v) => MapEntry(k.toString(), (v as num).toDouble())),
        ),
        wrongTopics: List<String>.from(map['wrongTopics'] as List),
      );
}

class ExamEntry {
  final String id; // timestamp string
  final DateTime createdAt;
  final String name;
  final ExamKind kind;

  final BranchExamResult? branch;
  final GeneralExamResult? general;

  const ExamEntry({
    required this.id,
    required this.createdAt,
    required this.name,
    required this.kind,
    this.branch,
    this.general,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'createdAt': createdAt.toIso8601String(),
        'name': name,
        'kind': kind.name,
        'branch': branch?.toMap(),
        'general': general?.toMap(),
      };

  static ExamEntry fromMap(Map<String, dynamic> map) => ExamEntry(
        id: map['id'] as String,
        createdAt: DateTime.parse(map['createdAt'] as String),
        name: map['name'] as String,
        kind: ExamKind.values.byName(map['kind'] as String),
        branch: map['branch'] == null
            ? null
            : BranchExamResult.fromMap(Map<String, dynamic>.from(map['branch'])),
        general: map['general'] == null
            ? null
            : GeneralExamResult.fromMap(Map<String, dynamic>.from(map['general'])),
      );
}
