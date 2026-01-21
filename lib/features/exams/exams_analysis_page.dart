import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'exam_models.dart';
import 'exam_providers.dart';

class ExamsAnalysisPage extends ConsumerWidget {
  const ExamsAnalysisPage({super.key});

  double _generalTotalNet(ExamEntry e) {
    final g = e.general;
    if (g == null) return 0;
    return g.netsBySection.values.fold(0.0, (a, b) => a + b);
  }

  DateTime _startOfWeek(DateTime d) {
    // Pazartesi başlangıç
    final diff = d.weekday - DateTime.monday;
    final start = DateTime(d.year, d.month, d.day).subtract(Duration(days: diff));
    return DateTime(start.year, start.month, start.day);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final examsAsync = ref.watch(examsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Deneme Analizi')),
      body: examsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Hata: $e')),
        data: (items) {
          final generals = items.where((e) => e.kind == ExamKind.general).toList();
          if (generals.isEmpty) {
            return const Center(child: Text('Henüz genel deneme yok.'));
          }

          final now = DateTime.now();
          final weekStart = _startOfWeek(now);
          final monthStart = DateTime(now.year, now.month, 1);

          // Bu hafta / bu ay özet
          final thisWeek = generals.where((e) => e.createdAt.isAfter(weekStart) || e.createdAt.isAtSameMomentAs(weekStart)).toList();
          final thisMonth = generals.where((e) => e.createdAt.isAfter(monthStart) || e.createdAt.isAtSameMomentAs(monthStart)).toList();

          double weekNet = thisWeek.fold(0.0, (a, e) => a + _generalTotalNet(e));
          double monthNet = thisMonth.fold(0.0, (a, e) => a + _generalTotalNet(e));

          // Haftalara göre grupla
          final Map<DateTime, List<ExamEntry>> byWeek = {};
          for (final e in generals) {
            final s = _startOfWeek(e.createdAt);
            byWeek.putIfAbsent(s, () => []).add(e);
          }
          final weekKeys = byWeek.keys.toList()..sort((a, b) => b.compareTo(a));

          // Aylara göre grupla
          final Map<DateTime, List<ExamEntry>> byMonth = {};
          for (final e in generals) {
            final s = DateTime(e.createdAt.year, e.createdAt.month, 1);
            byMonth.putIfAbsent(s, () => []).add(e);
          }
          final monthKeys = byMonth.keys.toList()..sort((a, b) => b.compareTo(a));

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _SummaryCard(
                title: 'Bu Hafta',
                count: thisWeek.length,
                totalNet: weekNet,
                avgNet: thisWeek.isEmpty ? 0 : weekNet / thisWeek.length,
              ),
              const SizedBox(height: 12),
              _SummaryCard(
                title: 'Bu Ay',
                count: thisMonth.length,
                totalNet: monthNet,
                avgNet: thisMonth.isEmpty ? 0 : monthNet / thisMonth.length,
              ),

              const SizedBox(height: 20),
              const Text('Haftalık Geçmiş', style: TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),

              ...weekKeys.map((k) {
                final list = byWeek[k]!;
                final total = list.fold(0.0, (a, e) => a + _generalTotalNet(e));
                final avg = total / list.length;
                return Card(
                  child: ListTile(
                    title: Text('${k.day}.${k.month}.${k.year} haftası'),
                    subtitle: Text('Deneme: ${list.length} • Toplam Net: ${total.toStringAsFixed(2)} • Ortalama: ${avg.toStringAsFixed(2)}'),
                  ),
                );
              }),

              const SizedBox(height: 20),
              const Text('Aylık Geçmiş', style: TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),

              ...monthKeys.map((k) {
                final list = byMonth[k]!;
                final total = list.fold(0.0, (a, e) => a + _generalTotalNet(e));
                final avg = total / list.length;
                return Card(
                  child: ListTile(
                    title: Text('${k.month}.${k.year}'),
                    subtitle: Text('Deneme: ${list.length} • Toplam Net: ${total.toStringAsFixed(2)} • Ortalama: ${avg.toStringAsFixed(2)}'),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.count,
    required this.totalNet,
    required this.avgNet,
  });

  final String title;
  final int count;
  final double totalNet;
  final double avgNet;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Deneme: $count'),
                Text('Toplam Net: ${totalNet.toStringAsFixed(2)}'),
                Text('Ort: ${avgNet.toStringAsFixed(2)}'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
