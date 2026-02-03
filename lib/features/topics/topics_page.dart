import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../exams/exam_models.dart'; // ExamType (tyt/ayt)
import 'topic_providers.dart';
import 'topic_progress.dart';
import 'topic_progress_providers.dart';

class TopicsPage extends ConsumerStatefulWidget {
  const TopicsPage({super.key});

  @override
  ConsumerState<TopicsPage> createState() => _TopicsPageState();
}

class _TopicsPageState extends ConsumerState<TopicsPage> {
  ExamType selected = ExamType.tyt;

  @override
  Widget build(BuildContext context) {
    final topicsAsync = selected == ExamType.tyt
        ? ref.watch(tytTopicsProvider)
        : ref.watch(aytTopicsProvider);

    final progressAsync = ref.watch(topicProgressMapProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Konu Takibi')),
      body: Column(
        children: [
          const SizedBox(height: 12),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SegmentedButton<ExamType>(
              segments: const [
                ButtonSegment(value: ExamType.tyt, label: Text('TYT')),
                ButtonSegment(value: ExamType.ayt, label: Text('AYT')),
              ],
              selected: {selected},
              onSelectionChanged: (s) => setState(() => selected = s.first),
            ),
          ),

          const SizedBox(height: 12),

          Expanded(
            child: topicsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Hata: $e')),
              data: (topics) {
                return progressAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Hata: $e')),
                  data: (progressMap) {
                    if (topics.isEmpty) {
                      return const Center(child: Text('Konu bulunamadı.'));
                    }

                    final subjects = topics.keys.toList()..sort();

                    return ListView(
                      children: subjects.map((subject) {
                        final topicList = topics[subject] ?? const <String>[];

                        return ExpansionTile(
                          title: Text(subject),
                          children: topicList.map((topic) {
                            final key = '$subject::$topic';
                            final p = progressMap[key] ??
                                TopicProgress(subject: subject, topic: topic);

                            return ListTile(
                              title: Text(topic),
                              subtitle: Text(_subtitle(p)),
                              trailing: _StatusChip(status: p.status),
                              onTap: () => _openProgressSheet(
                                context: context,
                                progress: p,
                              ),
                            );
                          }).toList(),
                        );
                      }).toList(),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _subtitle(TopicProgress p) {
    final min = p.studiedMinutes;
    final q = p.solvedQuestions;
    final status = _statusText(p.status);
    return '$status • $min dk • $q soru';
  }

  String _statusText(TopicStatus s) {
    switch (s) {
      case TopicStatus.notStarted:
        return 'Başlamadım';
      case TopicStatus.inProgress:
        return 'Çalışıyorum';
      case TopicStatus.done:
        return 'Bitti';
      case TopicStatus.repeat:
        return 'Tekrar';
    }
  }

  Future<void> _openProgressSheet({
    required BuildContext context,
    required TopicProgress progress,
  }) async {
    await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => _ProgressSheet(progress: progress),
    );

    // Sheet kapandıktan sonra listeyi yenile
    ref.invalidate(topicProgressMapProvider);
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final TopicStatus status;

  @override
  Widget build(BuildContext context) {
    final text = switch (status) {
      TopicStatus.notStarted => 'Başlamadım',
      TopicStatus.inProgress => 'Çalışıyorum',
      TopicStatus.done => 'Bitti',
      TopicStatus.repeat => 'Tekrar',
    };

    final colors = _chipColors(context, status);

    return Chip(
      label: Text(
        text,
        style: TextStyle(
          color: colors.fg,
          fontWeight: FontWeight.w600,
        ),
      ),
      backgroundColor: colors.bg,
      side: BorderSide(color: colors.border),
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.symmetric(horizontal: 6),
    );
  }

  _ChipPalette _chipColors(BuildContext context, TopicStatus s) {
    final scheme = Theme.of(context).colorScheme;

    switch (s) {
      case TopicStatus.notStarted:
        return _ChipPalette(
          bg: scheme.surfaceContainerHighest,
          fg: scheme.onSurface,
          border: scheme.outlineVariant,
        );
      case TopicStatus.inProgress:
        return _ChipPalette(
          bg: scheme.primaryContainer,
          fg: scheme.onPrimaryContainer,
          border: scheme.primary,
        );
      case TopicStatus.done:
        return _ChipPalette(
          bg: Colors.green.shade100,
          fg: Colors.green.shade900,
          border: Colors.green.shade600,
        );
      case TopicStatus.repeat:
        return _ChipPalette(
          bg: scheme.tertiaryContainer,
          fg: scheme.onTertiaryContainer,
          border: scheme.tertiary,
        );
    }
  }
}

class _ChipPalette {
  final Color bg;
  final Color fg;
  final Color border;
  const _ChipPalette({
    required this.bg,
    required this.fg,
    required this.border,
  });
}

class _ProgressSheet extends ConsumerStatefulWidget {
  const _ProgressSheet({required this.progress});
  final TopicProgress progress;

  @override
  ConsumerState<_ProgressSheet> createState() => _ProgressSheetState();
}

class _ProgressSheetState extends ConsumerState<_ProgressSheet> {
  late TopicStatus status;
  late TextEditingController minutesCtrl;
  late TextEditingController questionsCtrl;

  @override
  void initState() {
    super.initState();
    status = widget.progress.status;
    minutesCtrl =
        TextEditingController(text: widget.progress.studiedMinutes.toString());
    questionsCtrl =
        TextEditingController(text: widget.progress.solvedQuestions.toString());
  }

  @override
  void dispose() {
    minutesCtrl.dispose();
    questionsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final storage = ref.read(topicProgressStorageProvider);

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 8,
        bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${widget.progress.subject} • ${widget.progress.topic}',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          const SizedBox(height: 12),

          const Text('Durum'),
          const SizedBox(height: 6),
          DropdownButtonFormField<TopicStatus>(
            initialValue: status,
            items: const [
              DropdownMenuItem(
                value: TopicStatus.notStarted,
                child: Text('Başlamadım'),
              ),
              DropdownMenuItem(
                value: TopicStatus.inProgress,
                child: Text('Çalışıyorum'),
              ),
              DropdownMenuItem(
                value: TopicStatus.done,
                child: Text('Bitti'),
              ),
              DropdownMenuItem(
                value: TopicStatus.repeat,
                child: Text('Tekrar'),
              ),
            ],
            onChanged: (v) => setState(() => status = v!),
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: minutesCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Çalışma (dk)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: questionsCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Soru sayısı',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () async {
                final minutes = int.tryParse(minutesCtrl.text.trim()) ?? 0;
                final questions = int.tryParse(questionsCtrl.text.trim()) ?? 0;

                final updated = widget.progress.copyWith(
                  status: status,
                  studiedMinutes: minutes,
                  solvedQuestions: questions,
                  lastStudiedAt: DateTime.now(),
                );

                await storage.put(updated);

                if (mounted) Navigator.pop(context);
              },
              child: const Text('Kaydet'),
            ),
          ),
        ],
      ),
    );
  }
}
