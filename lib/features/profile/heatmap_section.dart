import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ✅ Trend provider importu (heatmap değil!)
import 'wrong_topics_heatmap_provider.dart';

class HeatmapSection extends ConsumerWidget {
  const HeatmapSection({super.key, this.topTopicsPerLesson = 12});

  final int topTopicsPerLesson;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(wrongTopicsTrendLast10Provider);
    final theme = Theme.of(context);

    if (data.isEmpty) {
      return const Text('Henüz yanlış konu verisi yok.');
    }

    final lessons = data.keys.toList()..sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Isı Haritası • Son 10 TYT / AYT Denemesi',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 12),
        for (final lesson in lessons) ...[
          _LessonHeatCard(
            lesson: lesson,
            topicTrends: data[lesson]!, // ✅ Map<String, TopicTrend>
            topN: topTopicsPerLesson,
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _LessonHeatCard extends StatelessWidget {
  const _LessonHeatCard({
    required this.lesson,
    required this.topicTrends,
    required this.topN,
  });

  final String lesson;
  final Map<String, TopicTrend> topicTrends;
  final int topN;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final entries = topicTrends.entries.toList()
      ..sort((a, b) => b.value.current.compareTo(a.value.current));

    final shown = entries.take(topN).toList();
    final maxV = math.max(1, shown.isEmpty ? 1 : shown.first.value.current);

    Color heatColor(double t) {
      final a = theme.colorScheme.surfaceContainerHighest;
      final b = theme.colorScheme.primaryContainer;
      return Color.lerp(a, b, t.clamp(0.0, 1.0))!;
    }

    final totalCurrent = topicTrends.values.fold<int>(0, (a, b) => a + b.current);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Theme(
        // ✅ ExpansionTile içindeki divider çizgilerini kapatır (daha modern)
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          // ✅ sadece başlık kısmı görünsün
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),

          title: Text(
            lesson,
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          trailing: Text(
            'Toplam: $totalCurrent',
            style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w800),
          ),

          // ✅ Açılınca içerik gelsin
          children: [
            if (shown.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  'Bu derste yanlış konu yok.',
                  style: theme.textTheme.bodyMedium,
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final e in shown)
                    _HeatPill(
                      label: e.key,
                      trend: e.value,
                      color: heatColor(e.value.current / maxV),
                    ),
                ],
              ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Trend: (son 10) − (önceki 10)',
                style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeatPill extends StatelessWidget {
  const _HeatPill({
    required this.label,
    required this.trend,
    required this.color,
  });

  final String label;
  final TopicTrend trend;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final d = trend.delta;

    final IconData icon = d > 0
        ? Icons.trending_up // ❌ kötüleşiyor
        : d < 0
            ? Icons.trending_down // ✅ iyileşiyor
            : Icons.trending_flat;

    final String deltaText = d == 0 ? '0' : (d > 0 ? '+$d' : '$d');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 160),
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 10),

          // current yanlış sayısı
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '${trend.current}',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
          ),

          const SizedBox(width: 8),

          Icon(icon, size: 18),
          const SizedBox(width: 4),
          Text(
            deltaText,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
