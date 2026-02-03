import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../topics/topic_providers.dart';
import 'exam_models.dart';
import 'exam_providers.dart';

/// Branş denemesi düzenleme sayfası
class ExamBranchEditPage extends ConsumerStatefulWidget {
  const ExamBranchEditPage({
    super.key,
    required this.exam,
  });

  final ExamEntry exam;

  @override
  ConsumerState<ExamBranchEditPage> createState() => _ExamBranchEditPageState();
}

class _ExamBranchEditPageState extends ConsumerState<ExamBranchEditPage> {
  late final TextEditingController nameCtrl;
  late final TextEditingController correctCtrl;
  late final TextEditingController wrongCtrl;
  late final TextEditingController blankCtrl;

  final selectedTopics = <String>{};

  //TYT/AYT seçimi

  @override
  void initState() {
    super.initState();
    
    // ✅ Mevcut değerleri yükle
    final branch = widget.exam.branch!;
    
    nameCtrl = TextEditingController(text: widget.exam.name);
    correctCtrl = TextEditingController(text: branch.correct.toString());
    wrongCtrl = TextEditingController(text: branch.wrong.toString());
    blankCtrl = TextEditingController(text: branch.blank.toString());
    
    // Seçili konuları yükle
    selectedTopics.addAll(branch.topics);
  }

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
    final branch = widget.exam.branch!;
    final topicsAsync = ref.watch(mergedTopicsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Deneme Düzenle • ${branch.lesson}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            // ✅ Bilgi kartı
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Branş denemesi düzenleniyor',
                        style: TextStyle(
                          color: Colors.blue.shade900,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

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
                final topics = map[branch.lesson] ?? const <String>[];
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
                    onChanged: (_) => setState(() {}),
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
                    onChanged: (_) => setState(() {}),
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
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      labelText: 'Boş',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            _buildNetPreview(),

            const SizedBox(height: 16),

            // ✅ Güncelleme butonu
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: const Icon(Icons.check),
                label: const Text('Değişiklikleri Kaydet'),
                onPressed: () async {
                  final name = nameCtrl.text.trim();
                  if (name.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Deneme adı boş olamaz.')),
                    );
                    return;
                  }

                  if (selectedTopics.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('En az 1 konu seçmelisin.')),
                    );
                    return;
                  }

                  final correct = int.tryParse(correctCtrl.text.trim()) ?? 0;
                  final wrong = int.tryParse(wrongCtrl.text.trim()) ?? 0;
                  final blank = int.tryParse(blankCtrl.text.trim()) ?? 0;

                  // ✅ Mevcut denemeyi güncelle
                  final updatedEntry = ExamEntry(
                    id: widget.exam.id, // ✅ Aynı ID
                    createdAt: widget.exam.createdAt, // ✅ Aynı tarih
                    name: name,
                    kind: ExamKind.branch,
                    branch: BranchExamResult(
                      lesson: branch.lesson, // Ders değişmez
                      topics: selectedTopics.toList(),
                      correct: correct,
                      wrong: wrong,
                      blank: blank,
                    ),
                  );

                  // ✅ Update fonksiyonunu kullan
                  await ref.read(examStorageProvider).update(updatedEntry);
                  ref.invalidate(examsProvider);

                  if (context.mounted) {
                    context.pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Deneme güncellendi! ✅'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNetPreview() {
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