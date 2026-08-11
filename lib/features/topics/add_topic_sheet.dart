import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../exams/exam_models.dart';
import 'my_topic.dart';
import 'my_topics_providers.dart';
import 'topic_providers.dart';

Future<void> showAddTopicSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => const _AddTopicSheet(),
  );
}

enum _Mode { curriculum, custom }

class _AddTopicSheet extends ConsumerStatefulWidget {
  const _AddTopicSheet();

  @override
  ConsumerState<_AddTopicSheet> createState() => _AddTopicSheetState();
}

class _AddTopicSheetState extends ConsumerState<_AddTopicSheet> {
  _Mode _mode = _Mode.curriculum;
  ExamType _exam = ExamType.tyt;
  final _search = TextEditingController();
  final _selected = <String>{}; // '$subject::$topic'

  final _customTopic = TextEditingController();
  final _customSubject = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    _customTopic.dispose();
    _customSubject.dispose();
    super.dispose();
  }

  Future<void> _addSelectedFromCurriculum() async {
    final storage = ref.read(myTopicsStorageProvider);
    final examLabel = _exam == ExamType.tyt ? 'TYT' : 'AYT';

    for (final key in _selected) {
      final sep = key.indexOf('::');
      final subject = key.substring(0, sep);
      final topic = key.substring(sep + 2);
      await storage.add(MyTopic(
        id: '$subject::$topic::$examLabel',
        subject: subject,
        topic: topic,
        exam: examLabel,
        createdAt: DateTime.now(),
      ));
    }
    if (mounted) ref.invalidate(myTopicsProvider);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _addCustom() async {
    final topic = _customTopic.text.trim();
    if (topic.isEmpty) return;

    final storage = ref.read(myTopicsStorageProvider);
    await storage.add(MyTopic(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      subject: _customSubject.text.trim().isEmpty
          ? null
          : _customSubject.text.trim(),
      topic: topic,
      exam: 'custom',
      createdAt: DateTime.now(),
    ));
    if (mounted) ref.invalidate(myTopicsProvider);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Padding(
      padding: EdgeInsets.only(
        left: 22,
        right: 22,
        top: 18,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 22,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Konu ekle', style: AppTheme.display(21, c.ink, tracking: -0.02)),
          const SizedBox(height: 14),

          SegmentedButton<_Mode>(
            segments: const [
              ButtonSegment(value: _Mode.curriculum, label: Text('Müfredattan seç')),
              ButtonSegment(value: _Mode.custom, label: Text('Kendi konumu yaz')),
            ],
            selected: {_mode},
            onSelectionChanged: (s) => setState(() => _mode = s.first),
          ),
          const SizedBox(height: 16),

          if (_mode == _Mode.curriculum)
            _CurriculumPicker(
              exam: _exam,
              onExamChanged: (e) => setState(() => _exam = e),
              search: _search,
              selected: _selected,
              onToggle: (key) => setState(() {
                if (_selected.contains(key)) {
                  _selected.remove(key);
                } else {
                  _selected.add(key);
                }
              }),
            )
          else
            _CustomTopicForm(
              topicController: _customTopic,
              subjectController: _customSubject,
            ),

          const SizedBox(height: 16),
          FilledButton(
            onPressed: _mode == _Mode.curriculum
                ? (_selected.isEmpty ? null : _addSelectedFromCurriculum)
                : _addCustom,
            child: Text(_mode == _Mode.curriculum
                ? 'Seçilenleri ekle (${_selected.length})'
                : 'Ekle'),
          ),
        ],
      ),
    );
  }
}

class _CurriculumPicker extends ConsumerWidget {
  const _CurriculumPicker({
    required this.exam,
    required this.onExamChanged,
    required this.search,
    required this.selected,
    required this.onToggle,
  });

  final ExamType exam;
  final ValueChanged<ExamType> onExamChanged;
  final TextEditingController search;
  final Set<String> selected;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final topicsAsync =
        exam == ExamType.tyt ? ref.watch(tytTopicsProvider) : ref.watch(aytTopicsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SegmentedButton<ExamType>(
          segments: const [
            ButtonSegment(value: ExamType.tyt, label: Text('TYT')),
            ButtonSegment(value: ExamType.ayt, label: Text('AYT')),
          ],
          selected: {exam},
          onSelectionChanged: (s) => onExamChanged(s.first),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: search,
          decoration: InputDecoration(
            hintText: 'Konu ara...',
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
          onChanged: (_) => (context as Element).markNeedsBuild(),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 360,
          child: topicsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Hata: $e')),
            data: (topics) {
              final query = search.text.trim().toLowerCase();
              final subjects = topics.keys.toList()..sort();

              return ListView(
                children: subjects.map((subject) {
                  final matches = topics[subject]!
                      .where((t) =>
                          query.isEmpty ||
                          t.toLowerCase().contains(query) ||
                          subject.toLowerCase().contains(query))
                      .toList();
                  if (matches.isEmpty) return const SizedBox.shrink();

                  return ExpansionTile(
                    title: Text(subject,
                        style: AppTheme.ui(14, c.ink, weight: FontWeight.w700)),
                    initiallyExpanded: query.isNotEmpty,
                    children: matches.map((topic) {
                      final key = '$subject::$topic';
                      return CheckboxListTile(
                        value: selected.contains(key),
                        onChanged: (_) => onToggle(key),
                        title: Text(topic, style: AppTheme.ui(13.5, c.ink)),
                        dense: true,
                        controlAffinity: ListTileControlAffinity.leading,
                      );
                    }).toList(),
                  );
                }).toList(),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _CustomTopicForm extends StatelessWidget {
  const _CustomTopicForm({
    required this.topicController,
    required this.subjectController,
  });

  final TextEditingController topicController;
  final TextEditingController subjectController;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: topicController,
          decoration: InputDecoration(
            labelText: 'Konu (zorunlu)',
            hintText: 'örn. İntegral tekrar et',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: subjectController,
          decoration: InputDecoration(
            labelText: 'Ders (opsiyonel)',
            hintText: 'örn. Matematik',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ],
    );
  }
}