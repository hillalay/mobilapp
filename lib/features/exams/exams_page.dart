import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'exam_providers.dart';
import 'exam_models.dart';

class ExamsPage extends ConsumerWidget {
  const ExamsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final examsAsync = ref.watch(examsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Denemeler'),
        actions: [
          IconButton(
            tooltip: 'TYT Analiz',
            onPressed: () => context.push('/exams/analytics', extra: ExamType.tyt),
            icon:const Icon(Icons.show_chart),
          ),
          IconButton(
            tooltip: 'AYT Analiz',
            onPressed: () => context.push('/exams/analytics', extra: ExamType.ayt),
            icon:const Icon(Icons.insights),
          ),
          IconButton(
            tooltip: 'Deneme Ekle',
            onPressed: () => context.push('/exams/new'),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: examsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Hata: $e')),
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('Henüz deneme yok. + ile ekle.'));
          }
          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 0),
            itemBuilder: (_, i) {
              final x = items[i];
              double totalNet=0;
              if (x.general !=null){
                totalNet = x.general!.netsBySection.values.fold(0.0, (a, b) => a + b);
              }
              final subtitle = x.kind == ExamKind.branch
              ? 'Branş • ${x.branch?.lesson ?? '-'} • Net: ${(x.branch?.net ?? 0).toStringAsFixed(2)} • Konu: ${x.branch?.topics.length ?? 0}'
              : 'Genel • ${(x.general?.type.name ?? '-').toUpperCase()} • Toplam Net: ${totalNet.toStringAsFixed(2)} • Yanlış konu: ${x.general?.wrongTopics.length ?? 0}';


              return ListTile(
                title: Text(x.name),
                subtitle: Text(subtitle),
              );
            },
          );
        },
      ),
    );
  }
}
