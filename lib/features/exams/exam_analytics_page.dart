import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'exam_models.dart';
import 'exam_analytics_providers.dart';

class ExamAnalyticsPage extends ConsumerWidget {
  const ExamAnalyticsPage({super.key, required this.type});
  final ExamType type;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = type == ExamType.tyt
        ? ref.watch(tytGeneralExamsProvider)
        : ref.watch(aytGeneralExamsProvider);

    if (list.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text('Analiz • ${type.name.toUpperCase()}')),
        body: const Center(child: Text('Henüz bu türde genel deneme yok.')),
      );
    }

    final latest = list.first.general!;
    final latestName = list.first.name;


    // Ortalama netleri hesapla
    final avg = <String, double>{};
    final counts = <String, int>{};

    for (final e in list) {
      final nets = e.general!.netsBySection;
      for (final entry in nets.entries) {
        avg[entry.key] = (avg[entry.key] ?? 0) + entry.value;
        counts[entry.key] = (counts[entry.key] ?? 0) + 1;
      }
    }
    for (final k in avg.keys) {
      avg[k] = avg[k]! / (counts[k] ?? 1);
    }
    
    final computedMax = [
      ...latest.netsBySection.values,
      ...avg.values,
      ].fold<double>(0.0, (m, v) => v > m ? v : m);

    final maxNet = (computedMax < 1.0) ? 1.0 : computedMax;


    return Scaffold(
      appBar: AppBar(title: Text('Analiz • ${type.name.toUpperCase()}')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Son deneme: $latestName',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          const SizedBox(height: 12),

          const Text('Son Deneme Branş Netleri', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),

          ...latest.netsBySection.entries.map((e) {
            return _NetBarRow(
              label: e.key,
              value: e.value,
              maxValue: maxNet,
            );
          }),

          const SizedBox(height: 18),
          const Divider(),
          const SizedBox(height: 12),

          const Text('Ortalama Netler', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),

          ...avg.entries.map((e) {
            return _NetBarRow(
              label: e.key,
              value: e.value,
              maxValue: maxNet,
              suffix: ' ort.',
            );
          }),

          const SizedBox(height: 18),
          Card(
            child: ListTile(
              title: const Text('Toplam Deneme Sayısı'),
              trailing: Text(list.length.toString()),
            ),
          ),
        ],
      ),
    );
  }
}

class _NetBarRow extends StatelessWidget {
  const _NetBarRow({
    required this.label,
    required this.value,
    required this.maxValue,
    this.suffix = '',
  });

  final String label;
  final double value;
  final double maxValue;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    final ratio = (value / maxValue).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600))),
              Text('${value.toStringAsFixed(2)}$suffix'),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 10,
            ),
          ),
        ],
      ),
    );
  }
}
