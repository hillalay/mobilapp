class TodoItem {
  final String id;
  final String text;
  final bool done;

  const TodoItem({required this.id, required this.text, required this.done});

  TodoItem copyWith({String? id, String? text, bool? done}) => TodoItem(
        id: id ?? this.id,
        text: text ?? this.text,
        done: done ?? this.done,
      );

  Map<String, dynamic> toJson() => {'id': id, 'text': text, 'done': done};

  static TodoItem fromJson(Map<String, dynamic> json) => TodoItem(
        id: json['id'] as String,
        text: json['text'] as String,
        done: json['done'] as bool,
      );
}
