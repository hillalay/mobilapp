import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../profile/profile_controller.dart';
import '../topics/curriculum_service.dart';
import '../topics/topic_providers.dart';
import 'exam_models.dart';
import 'exam_providers.dart';
import 'exam_general_form_controller.dart';

class ExamGeneralFormPage extends ConsumerStatefulWidget {
  const ExamGeneralFormPage({super.key, required this.type});
  final ExamType type;

  @override
  ConsumerState<ExamGeneralFormPage> createState() => _ExamGeneralFormPageState();
}

class _ExamGeneralFormPageState extends ConsumerState<ExamGeneralFormPage> {
  // Bir önceki build’deki sections listesi (değişti mi diye kıyaslayacağız)
  List<String> _lastSections = const [];

  List<String> _sectionsFor(ExamType type, UserProfile? profile) {
    if (type == ExamType.tyt) {
      return const ['Türkçe', 'Matematik', 'Sosyal', 'Fen'];
    }

    final track = profile?.track;
    switch (track) {
      case Track.mf:
        return const ['Matematik', 'Fizik', 'Kimya', 'Biyoloji'];
      case Track.tm:
        return const ['Edebiyat', 'Tarih', 'Coğrafya'];
      case Track.sozel:
        return const ['Edebiyat', 'Tarih', 'Coğrafya', 'Felsefe'];
      case Track.dil:
        return const ['Dil'];
      default:
        return const ['Matematik', 'Edebiyat', 'Tarih', 'Coğrafya'];
    }
  }

  Future<Map<String, List<String>>> _loadWrongTopicOptions(
    CurriculumService service,
    UserProfile? profile,
  ) async {
    final data = await service.load();

    if (widget.type == ExamType.tyt) {
      final raw = Map<String, dynamic>.from(data['tyt'] as Map);
      return raw.map((k, v) => MapEntry(k, List<String>.from(v as List)));
    }

    final ayt = Map<String, dynamic>.from(data['ayt'] as Map);
    final track = profile?.track?.name ?? 'mf';
    final raw = Map<String, dynamic>.from(ayt[track] as Map);
    return raw.map((k, v) => MapEntry(k, List<String>.from(v as List)));
  }

  int _parseInt(String s) => int.tryParse(s.trim()) ?? 0;

  bool _listEquals(List<String> a, List<String> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  void _ensureSectionsIfNeeded(List<String> sections) {
    if (_listEquals(_lastSections, sections)) return;

    _lastSections = List<String>.from(sections);

    // build sırasında state güncellemesi yapmamak için post-frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(generalExamFormProvider(widget.type).notifier).ensureSections(sections);
    });
  }

  @override
  Widget build(BuildContext context) {
    final curriculumService = ref.read(curriculumServiceProvider);
    final profileAsync = ref.watch(profileProvider);

    final formState = ref.watch(generalExamFormProvider(widget.type));
    final formCtrl = ref.read(generalExamFormProvider(widget.type).notifier);

    return Scaffold(
      appBar: AppBar(title: Text('Genel Deneme • ${widget.type.name.toUpperCase()}')),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Hata: $e')),
        data: (profile) {
          final sections = _sectionsFor(widget.type, profile);

          // ✅ Sadece sections değiştiğinde sync et
          _ensureSectionsIfNeeded(sections);

          final totalNet = formCtrl.totalNet();
          final isValid = formCtrl.isValid();

          return Padding(
            padding: const EdgeInsets.all(16),
            child: ListView(
              children: [
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Deneme adı',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: formCtrl.setName,
                ),
                const SizedBox(height: 12),

                Card(
                  child: ListTile(
                    title: const Text('Toplam Net'),
                    trailing: Text(
                      totalNet.toStringAsFixed(2),
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                const Text(
                  'Branş Sonuçları (D/Y)',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),

                for (final s in sections) ...[
                  _SectionDYCard(
                    title: s,
                    correct: formState.inputs[s]?.correct ?? 0,
                    wrong: formState.inputs[s]?.wrong ?? 0,
                    net: (formState.inputs[s]?.net ?? 0).toStringAsFixed(2),
                    onCorrectChanged: (v) => formCtrl.setCorrect(s, _parseInt(v)),
                    onWrongChanged: (v) => formCtrl.setWrong(s, _parseInt(v)),
                  ),
                  const SizedBox(height: 10),
                ],

                const SizedBox(height: 8),
                const Text(
                  'Yanlış yaptığın konuları seç',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),

                FutureBuilder<Map<String, List<String>>>(
                  future: _loadWrongTopicOptions(curriculumService, profile),
                  builder: (context, snap) {
                    if (!snap.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final options = snap.data!;

                    return Column(
                      children: options.entries.map((entry) {
                        final lesson = entry.key;
                        final topics = entry.value;

                        return ExpansionTile(
                          title: Text(lesson),
                          children: topics.map((t) {
                            final key = '$lesson • $t';
                            final checked = formState.wrongTopics.contains(key);
                            return CheckboxListTile(
                              value: checked,
                              title: Text(t),
                              onChanged: (_) => formCtrl.toggleWrongTopic(key),
                            );
                          }).toList(),
                        );
                      }).toList(),
                    );
                  },
                ),

                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: isValid
                        ? () async {
                            final nets = <String, double>{};
                            for (final e in formState.inputs.entries) {
                              nets[e.key] = e.value.net;
                            }

                            final entry = ExamEntry(
                              id: DateTime.now().millisecondsSinceEpoch.toString(),
                              createdAt: DateTime.now(),
                              name: formState.name.trim(),
                              kind: ExamKind.general,
                              general: GeneralExamResult(
                                type: widget.type,
                                netsBySection: nets,
                                wrongTopics: formState.wrongTopics.toList(),
                              ),
                            );

                            await ref.read(examStorageProvider).add(entry);
                            ref.invalidate(examsProvider);

                            if (context.mounted) Navigator.of(context).pop();
                          }
                        : null,
                    child: const Text('Kaydet'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SectionDYCard extends ConsumerStatefulWidget {
  final String title;
  final int correct;
  final int wrong;
  final String net;
  final ValueChanged<String> onCorrectChanged;
  final ValueChanged<String> onWrongChanged;

  const _SectionDYCard({
    required this.title,
    required this.correct,
    required this.wrong,
    required this.net,
    required this.onCorrectChanged,
    required this.onWrongChanged,
  });

  @override
  ConsumerState<_SectionDYCard> createState() => _SectionDYCardState();
}

class _SectionDYCardState extends ConsumerState<_SectionDYCard> {
  late final TextEditingController _correctCtrl;
  late final TextEditingController _wrongCtrl;

  @override
  void initState() {
    super.initState();
    _correctCtrl = TextEditingController(text: _intToText(widget.correct));
    _wrongCtrl = TextEditingController(text: _intToText(widget.wrong));
  }

  @override
  void didUpdateWidget(covariant _SectionDYCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Dışarıdaki state değiştiyse (ör. ensureSections / load vs), text’i güncelle
    // Ama kullanıcı yazarken cursor bozulmasın diye sadece gerçekten farklıysa güncelliyoruz.
    final newCorrectText = _intToText(widget.correct);
    if (_correctCtrl.text != newCorrectText) {
      _correctCtrl.value = _correctCtrl.value.copyWith(
        text: newCorrectText,
        selection: TextSelection.collapsed(offset: newCorrectText.length),
        composing: TextRange.empty,
      );
    }

    final newWrongText = _intToText(widget.wrong);
    if (_wrongCtrl.text != newWrongText) {
      _wrongCtrl.value = _wrongCtrl.value.copyWith(
        text: newWrongText,
        selection: TextSelection.collapsed(offset: newWrongText.length),
        composing: TextRange.empty,
      );
    }
  }

  @override
  void dispose() {
    _correctCtrl.dispose();
    _wrongCtrl.dispose();
    super.dispose();
  }

  String _intToText(int v) => v == 0 ? '' : v.toString();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.title, style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _correctCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Doğru',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: widget.onCorrectChanged,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _wrongCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Yanlış',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: widget.onWrongChanged,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Text('Net: ', style: TextStyle(fontWeight: FontWeight.w700)),
                Text(widget.net),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
