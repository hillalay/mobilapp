import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'topic_providers.dart';
import 'topic_progress.dart';
import 'topic_progress_providers.dart';

class TopicsPage extends ConsumerWidget {
  const TopicsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topicsAsync = ref.watch(filteredTopicsProvider);
    final progressAsync = ref.watch(topicProgressMapProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Konu Takibi')),
      body: topicsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Hata: $e')),
        data: (topics) {
          return progressAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Hata: $e')),
            data: (progressMap) {
              return ListView(
                children: topics.entries.map((entry) {
                  final subject = entry.key;
                  final topicList = entry.value;

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
                          ref: ref,
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
    required WidgetRef ref,
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

    final colors=_chipColors(context, status);

    return Chip(
      label: Text(
        text,
        style: TextStyle(
          color: colors.fg,
          fontWeight: FontWeight.w600,
          ),
        ),
      backgroundColor: colors.bg,
      side:BorderSide(color:colors.border),
      visualDensity: VisualDensity.compact,
      padding:const EdgeInsets.symmetric(horizontal:6),
    );
  }
  _ChipPalette _chipColors(BuildContext context, TopicStatus s) {
    final scheme = Theme.of(context).colorScheme;

    switch (s) {
      case TopicStatus.notStarted:
        // gri / nötr
        return _ChipPalette(
          bg: scheme.surfaceContainerHighest,
          fg: scheme.onSurface,
          border: scheme.outlineVariant,
        );
      case TopicStatus.inProgress:
        // mavi ton (info)
        return _ChipPalette(
          bg: scheme.primaryContainer,
          fg: scheme.onPrimaryContainer,
          border: scheme.primary,
        );
      case TopicStatus.done:
        // yeşil ton (success) - theme’de yok, secondary ile güvenli ilerleyelim
        return _ChipPalette(
          bg: Colors.green.shade100,
          fg: Colors.green.shade900,
          border: Colors.green.shade600,
        );
      case TopicStatus.repeat:
        // turuncu/sarı ton (warning) - tertiary ile güvenli
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
            value: status,
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
