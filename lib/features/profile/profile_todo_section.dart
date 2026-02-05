import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'todo_controller.dart';

class ProfileTodoSection extends ConsumerStatefulWidget {
  const ProfileTodoSection({super.key});

  @override
  ConsumerState<ProfileTodoSection> createState() => _ProfileTodoSectionState();
}

class _ProfileTodoSectionState extends ConsumerState<ProfileTodoSection> {
  final _todoCtrl = TextEditingController();

  @override
  void dispose() {
    _todoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(profileTodoProvider);
    final c = ref.read(profileTodoProvider.notifier);
    final theme = Theme.of(context);

    if (s.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Başlık
        Text(
          'Bugün yapılacaklar',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),

        // TODO input
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

        // TODO list
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
