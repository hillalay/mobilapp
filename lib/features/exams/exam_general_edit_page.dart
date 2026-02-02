import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../profile/profile_controller.dart';
import '../topics/curriculum_service.dart';
import '../topics/curriculum_providers.dart';
import 'exam_models.dart';
import 'exam_providers.dart';
import 'exam_general_form_controller.dart';

/// Genel deneme düzenleme sayfası
class ExamGeneralEditPage extends ConsumerStatefulWidget {
  const ExamGeneralEditPage({
    super.key,
    required this.exam,
  });

  final ExamEntry exam;

  @override
  ConsumerState<ExamGeneralEditPage> createState() => _ExamGeneralEditPageState();
}

class _ExamGeneralEditPageState extends ConsumerState<ExamGeneralEditPage> {
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
    final type = widget.exam.general!.type;

    if (type == ExamType.tyt) {
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final type = widget.exam.general!.type;
      ref.read(generalExamFormProvider(type).notifier).ensureSections(sections);
    });
  }

  @override
  void initState() {
    super.initState();
    
    // ✅ Mevcut deneme verilerini form'a yükle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      
      final general = widget.exam.general!;
      final type = general.type;
      final formCtrl = ref.read(generalExamFormProvider(type).notifier);
      
      // İsmi set et
      formCtrl.setName(widget.exam.name);
      
      // Netlerden doğru/yanlış hesapla ve set et
      for (final entry in general.netsBySection.entries) {
        final section = entry.key;
        final net = entry.value;
        
        // Net'ten doğru hesapla (varsayılan: yanlış = 0)
        // Gerçek değerleri bilmiyoruz, sadece net var
        // O yüzden kullanıcı tekrar girecek veya net'i doğru olarak kabul edebiliriz
        final correct = net.round();
        formCtrl.setCorrect(section, correct);
        formCtrl.setWrong(section, 0);
      }
      
      // Yanlış konuları set et
      for (final topic in general.wrongTopics) {
        formCtrl.toggleWrongTopic(topic);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final curriculumService = ref.read(curriculumServiceProvider);
    final profileAsync = ref.watch(profileProvider);
    
    final type = widget.exam.general!.type;
    final formState = ref.watch(generalExamFormProvider(type));
    final formCtrl = ref.read(generalExamFormProvider(type).notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text('Deneme Düzenle • ${type.name.toUpperCase()}'),
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Hata: $e')),
        data: (profile) {
          final sections = _sectionsFor(type, profile);
          _ensureSectionsIfNeeded(sections);

          final totalNet = formCtrl.totalNet();
          final isValid = formCtrl.isValid();

          return Padding(
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
                            'Mevcut deneme düzenleniyor',
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
                  controller: TextEditingController(text: formState.name)
                    ..selection = TextSelection.collapsed(offset: formState.name.length),
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

                // ✅ Güncelleme butonu
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    icon: const Icon(Icons.check),
                    label: const Text('Değişiklikleri Kaydet'),
                    onPressed: isValid
                        ? () async {
                            final nets = <String, double>{};
                            for (final e in formState.inputs.entries) {
                              nets[e.key] = e.value.net;
                            }

                            // ✅ Mevcut denemeyi güncelle (yeni oluşturma)
                            final updatedEntry = ExamEntry(
                              id: widget.exam.id, // ✅ Aynı ID
                              createdAt: widget.exam.createdAt, // ✅ Aynı tarih
                              name: formState.name.trim(),
                              kind: ExamKind.general,
                              general: GeneralExamResult(
                                type: type,
                                netsBySection: nets,
                                wrongTopics: formState.wrongTopics.toList(),
                              ),
                            );

                            // ✅ Update fonksiyonunu kullan
                            await ref.read(examStorageProvider).update(updatedEntry);
                            ref.invalidate(examsProvider);

                            if (context.mounted) {
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Deneme güncellendi! ✅'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          }
                        : null,
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