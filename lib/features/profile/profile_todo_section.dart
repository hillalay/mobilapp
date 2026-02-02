import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'todo_controller.dart';
import 'notes_card.dart';

class ProfileTodoSection extends ConsumerStatefulWidget {
  const ProfileTodoSection({super.key});

  @override
  ConsumerState<ProfileTodoSection> createState() => _ProfileTodoSectionState();
}

class _ProfileTodoSectionState extends ConsumerState<ProfileTodoSection> {
  // TODO input
  final _todoCtrl = TextEditingController();

  // Daily note input (NOTES kartı için)
  late final TextEditingController _noteCtrl;

  @override
  void initState() {
    super.initState();
    _noteCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _todoCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(profileTodoProvider);
    final c = ref.read(profileTodoProvider.notifier);

    if (s.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    // State -> Controller senkronu (cursor zıplamasını önler)
    if (_noteCtrl.text != s.dailyNote) {
      _noteCtrl.value = _noteCtrl.value.copyWith(
        text: s.dailyNote,
        selection: TextSelection.collapsed(offset: s.dailyNote.length),
        composing: TextRange.empty,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ✅ Eski TextField yerine NotesCard
        NotesCard(
          controller: _noteCtrl,
          onChanged: c.setDailyNote,
          title: 'NOTES',
          hintText: 'Bugün için kendime not...',
        ),

        const SizedBox(height: 30),

        const Text('TODO', style: TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),

        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _todoCtrl,
                decoration: const InputDecoration(
                  hintText: 'Yeni görev…',
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (v) async {
                  await c.addTodo(v);
                  _todoCtrl.clear();
                },
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: () async {
                await c.addTodo(_todoCtrl.text);
                _todoCtrl.clear();
              },
              child: const Text('Ekle'),
            ),
          ],
        ),

        const SizedBox(height: 10),

        ...s.todos.map(
          (t) => Card(
            child: ListTile(
              leading: Checkbox(
                value: t.done,
                onChanged: (_) => c.toggle(t.id),
              ),
              title: Text(
                t.text,
                style: TextStyle(
                  decoration: t.done ? TextDecoration.lineThrough : null,
                  fontWeight: FontWeight.w600,
                ),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => c.remove(t.id),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
