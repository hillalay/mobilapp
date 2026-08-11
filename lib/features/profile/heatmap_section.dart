import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../app/ui.dart';
import 'wrong_topics_heatmap_provider.dart';

/// "Yanlış yoğunluğu" — ders × son 8 hafta ızgarası.
class HeatmapSection extends ConsumerWidget {
  const HeatmapSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final byLesson = ref.watch(wrongLessonsByWeekProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text('Yanlış yoğunluğu',
                  style: AppTheme.display(15, c.ink, tracking: -0.01)),
            ),
            Text('Son 8 hafta', style: AppTheme.ui(11.5, c.inkMuted)),
          ],
        ),
        const SizedBox(height: 12),
        AppCard(
          radius: 20,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: byLesson.isEmpty
              ? const EmptyState(
                  compact: true,
                  message: 'Deneme girdikçe hangi derste zorlandığın burada belirir.',
                )
              : _Grid(byLesson: byLesson),
        ),
      ],
    );
  }
}

class _Grid extends StatelessWidget {
  const _Grid({required this.byLesson});

  final Map<String, List<int>> byLesson;

  /// Ders adları uzun; 52px sütuna sığması için kısaltılıyor.
  static String _short(String lesson) =>
      lesson.length <= 8 ? lesson : '${lesson.substring(0, 7)}…';

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    final lessons = byLesson.keys.toList()..sort();
    final peak = byLesson.values
        .expand((row) => row)
        .fold<int>(0, (a, b) => a > b ? a : b);

    Color heat(int value) {
      if (value == 0) return AppColors.heat.first;
      // 0 dışındaki değerler rampanın 1..4 aralığına dağıtılır.
      final ratio = peak == 0 ? 0.0 : value / peak;
      final index = 1 + (ratio * (AppColors.heat.length - 2)).ceil();
      return AppColors.heat[index.clamp(1, AppColors.heat.length - 1)];
    }

    return Column(
      children: [
        for (var i = 0; i < lessons.length; i++) ...[
          if (i > 0) const SizedBox(height: 11),
          Row(
            children: [
              SizedBox(
                width: 52,
                child: Text(
                  _short(lessons[i]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.ui(11.5, c.inkMuted, weight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 8),
              for (var w = 0; w < heatmapWeeks; w++) ...[
                if (w > 0) const SizedBox(width: 4),
                Expanded(
                  child: Container(
                    height: 20,
                    decoration: BoxDecoration(
                      color: heat(byLesson[lessons[i]]![w]),
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }
}
