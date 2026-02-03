import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../topics/topic_providers.dart';
import 'exam_models.dart';
import 'exam_providers.dart';

class ExamBranchFormPage extends ConsumerStatefulWidget {
  const ExamBranchFormPage({super.key, required this.lesson});
  final String lesson;

  @override
  ConsumerState<ExamBranchFormPage> createState() => _ExamBranchFormPageState();
}

class _ExamBranchFormPageState extends ConsumerState<ExamBranchFormPage> {
  final nameCtrl = TextEditingController();
  final correctCtrl = TextEditingController(text: '0');
  final wrongCtrl = TextEditingController(text: '0');
  final blankCtrl = TextEditingController(text: '0');

  final selectedTopics = <String>{};

  @override
  void dispose() {
    nameCtrl.dispose();
    correctCtrl.dispose();
    wrongCtrl.dispose();
    blankCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topicsAsync = ref.watch(mergedTopicsProvider);

    return Scaffold(
      appBar: AppBar(title: Text('Branş Denemesi • ${widget.lesson}')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Deneme adı',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            const Text('Konular (çoklu seç)'),
            const SizedBox(height: 8),

            topicsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Hata: $e'),
              data: (map) {
                final topics = map[widget.lesson] ?? const <String>[];
                if (topics.isEmpty) {
                  return const Text('Bu ders için konu bulunamadı.');
                }

                return Column(
                  children: topics.map((t) {
                    final checked = selectedTopics.contains(t);
                    return CheckboxListTile(
                      value: checked,
                      title: Text(t),
                      onChanged: (v) {
                        setState(() {
                          if (v == true) {
                            selectedTopics.add(t);
                          } else {
                            selectedTopics.remove(t);
                          }
                        });
                      },
                    );
                  }).toList(),
                );
              },
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: correctCtrl,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}), // ✅ net anlık güncellensin
                    decoration: const InputDecoration(
                      labelText: 'Doğru',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: wrongCtrl,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}), // ✅
                    decoration: const InputDecoration(
                      labelText: 'Yanlış',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: blankCtrl,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}), // ✅
                    decoration: const InputDecoration(
                      labelText: 'Boş',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            _builderNetPreview(),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () async {
                  final name = nameCtrl.text.trim();
                  if (name.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Deneme adı boş olamaz.')),
                    );
                    return;
                  }

                  final correct = int.tryParse(correctCtrl.text.trim()) ?? 0;
                  final wrong = int.tryParse(wrongCtrl.text.trim()) ?? 0;
                  final blank = int.tryParse(blankCtrl.text.trim()) ?? 0;

                  final entry = ExamEntry(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    createdAt: DateTime.now(),
                    name: name,
                    kind: ExamKind.branch,
                    branch: BranchExamResult(
                      lesson: widget.lesson,
                      topics: selectedTopics.toList(),
                      correct: correct,
                      wrong: wrong,
                      blank: blank,
                    ),
                  );

                  await ref.read(examStorageProvider).add(entry);
                  ref.invalidate(examsProvider);

                  if (context.mounted) context.pop(); // geri
                },
                child: const Text('Kaydet'),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _builderNetPreview() {
    final c = int.tryParse(correctCtrl.text.trim()) ?? 0;
    final w = int.tryParse(wrongCtrl.text.trim()) ?? 0;
    final net = c - (w / 4.0);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Net', style: TextStyle(fontWeight: FontWeight.w600)),
            Text(
              net.toStringAsFixed(2),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}
