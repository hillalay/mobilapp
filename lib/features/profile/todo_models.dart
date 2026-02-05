class TodoItem {
  final String id;
  final String text;
  final bool done;

  /// ✅ 24 saat kuralı için
  final DateTime createdAt;

  const TodoItem({
    required this.id,
    required this.text,
    required this.done,
    required this.createdAt,
  });

  TodoItem copyWith({String? id, String? text, bool? done, DateTime? createdAt}) => TodoItem(
        id: id ?? this.id,
        text: text ?? this.text,
        done: done ?? this.done,
        createdAt: createdAt ?? this.createdAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'done': done,
        'createdAt': createdAt.toIso8601String(),
      };

  static TodoItem fromJson(Map<String, dynamic> json) => TodoItem(
        id: json['id'] as String,
        text: json['text'] as String,
        done: (json['done'] as bool?) ?? false,
        // ✅ eski kayıtlarda createdAt yoksa patlamasın
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      );
}
