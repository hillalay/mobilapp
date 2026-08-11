import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../app/ui.dart';
import '../dashboard/dashboard_providers.dart';
import 'topic_progress.dart';

/// Konu satırı — ana sayfa ve profildeki "Bugün yapılacaklar" aynı satırı
/// kullanıyor, ikisinde de aynı state'i gösteriyor.
class TopicRow extends StatelessWidget {
  const TopicRow({
    super.key,
    required this.topic,
    required this.done,
    required this.onTap,
  });

  final NextTopic topic;
  final bool done;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return AppCard(
      onTap: onTap,
      radius: AppRadius.row,
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
      child: Row(
        children: [
          AppCheckbox(checked: done, onTap: onTap),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  topic.topic,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.ui(14.5, done ? c.inkFaint : c.ink,
                          weight: FontWeight.w700)
                      .copyWith(
                    decoration: done ? TextDecoration.lineThrough : null,
                    decorationColor: c.inkFaint,
                  ),
                ),
                const SizedBox(height: 2),
                Text('${topic.subject} · ${topic.exam}',
                    style: AppTheme.ui(12, c.inkMuted)),
              ],
            ),
          ),
          if (topic.status == TopicStatus.repeat) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: c.brandSoft,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('Tekrar',
                  style: AppTheme.ui(11, c.brandText, weight: FontWeight.w700)),
            ),
          ],
        ],
      ),
    );
  }
}
