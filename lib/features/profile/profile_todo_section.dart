import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../app/ui.dart';
import 'todo_controller.dart';
import 'todo_models.dart';


class ProfileTodoSection extends ConsumerStatefulWidget {
  const ProfileTodoSection({super.key});

  @override
  ConsumerState<ProfileTodoSection> createState() => _ProfileTodoSectionState();
}

class _ProfileTodoSectionState extends ConsumerState<ProfileTodoSection> {
  /// "+ Görev ekle" satırı dokununca yerinde TextField'a dönüşüyor.
  bool _adding = false;
  final _controller = TextEditingController();
  final _focus = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _controller.text.trim();
    _controller.clear();
    if (text.isNotEmpty) {
      await ref.read(profileTodoProvider.notifier).addTodo(text);
    }
    if (mounted) setState(() => _adding = false);
  }

  
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final state = ref.watch(profileTodoProvider);
  

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Bugün yapılacaklar',
            style: AppTheme.display(15, c.ink, tracking: -0.01)),
        const SizedBox(height: 12),


        if (state.loading)
          const Column(
            children: [
              Skeleton(height: 48, radius: 16),
              SizedBox(height: 8),
              Skeleton(height: 48, radius: 16),
            ],
          )
        else ...[
          for (final todo in state.todos) ...[
            _TodoRow(
              key: ValueKey(todo.id),
              todo: todo,
              onToggle: () => ref.read(profileTodoProvider.notifier).toggle(todo.id),
              onDismissed: () =>
                  ref.read(profileTodoProvider.notifier).remove(todo.id),
            ),
            const SizedBox(height: 8),
          ],
          _AddRow(
            adding: _adding,
            controller: _controller,
            focus: _focus,
            onStart: () {
              setState(() => _adding = true);
              WidgetsBinding.instance
                  .addPostFrameCallback((_) => _focus.requestFocus());
            },
            onSubmit: _submit,
          ),
        ],
      ],
    );
  }
}

class _TodoRow extends StatelessWidget {
  const _TodoRow({
    super.key,
    required this.todo,
    required this.onToggle,
    required this.onDismissed,
  });

  final TodoItem todo;
  final VoidCallback onToggle;
  final VoidCallback onDismissed;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Dismissible(
      key: ValueKey('dismiss-${todo.id}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismissed(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 18),
        decoration: BoxDecoration(
          color: c.danger.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(Icons.delete_outline, color: c.danger, size: 20),
      ),
      child: AppCard(
        onTap: onToggle,
        radius: 16,
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
        child: Row(
          children: [
            AppCheckbox(checked: todo.done, size: 22, onTap: onToggle),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                todo.text,
                style: AppTheme.ui(14, todo.done ? c.inkFaint : c.ink,
                        weight: FontWeight.w500)
                    .copyWith(
                  decoration: todo.done ? TextDecoration.lineThrough : null,
                  decorationColor: c.inkFaint,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddRow extends StatelessWidget {
  const _AddRow({
    required this.adding,
    required this.controller,
    required this.focus,
    required this.onStart,
    required this.onSubmit,
  });

  final bool adding;
  final TextEditingController controller;
  final FocusNode focus;
  final VoidCallback onStart;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    if (adding) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: c.brand),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                focusNode: focus,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => onSubmit(),
                onTapOutside: (_) => onSubmit(),
                style: AppTheme.ui(14, c.ink, weight: FontWeight.w500),
                decoration: InputDecoration(
                  hintText: 'Ne yapacaksın?',
                  hintStyle: AppTheme.ui(14, c.inkFaint),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            IconButton(
              onPressed: onSubmit,
              icon: Icon(Icons.check_rounded, color: c.brand, size: 20),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: onStart,
      behavior: HitTestBehavior.opaque,
      child: CustomPaint(
        painter: _DashedBorder(color: c.checkboxBorder, radius: 16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
          alignment: Alignment.centerLeft,
          child: Row(
            children: [
              Icon(Icons.add_rounded, size: 18, color: c.inkMuted),
              const SizedBox(width: 8),
              Text('Görev ekle', style: AppTheme.ui(14, c.inkMuted)),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashedBorder extends CustomPainter {
  _DashedBorder({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );

    // Kesikli çizgi: yolu 6px çizip 5px atlayarak dolaşıyoruz.
    final path = Path()..addRRect(rrect);
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(
          metric.extractPath(distance, distance + 6),
          paint,
        );
        distance += 11;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorder oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}
