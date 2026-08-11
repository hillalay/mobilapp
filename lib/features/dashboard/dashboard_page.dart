import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../app/ui.dart';
import '../../core/auth_providers.dart';
import '../timer/daily_study_stats.dart';
import '../timer/daily_study_stats_providers.dart';
import '../topics/topic_row.dart';
import 'dashboard_providers.dart';
import 'manual_entry_sheet.dart';
import '../topics/add_topic_sheet.dart';

const _maxTopicRows = 3;

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  /// SnackBar yerine: kaydedilen sayaç kartı 400ms parlar.
  bool _flashTime = false;
  bool _flashQuestions = false;

  Future<void> _openManualSheet() async {
    final result = await showManualEntrySheet(context);
    if (result == null || !mounted) return;

    setState(() {
      _flashTime = result.timeChanged;
      _flashQuestions = result.questionsChanged;
    });
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (mounted) {
      setState(() {
        _flashTime = false;
        _flashQuestions = false;
      });
    }
  }

  Future<void> _toggleTopic(NextTopic t) async {
    try {
      await ref.read(topicCheckProvider.notifier).toggle(t);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Konu kaydedilemedi, tekrar dene.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final topicsAsync = ref.watch(nextTopicsProvider);
    final checks = ref.watch(topicCheckProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 6, 22, 24),
          children: [
            _Greeting(topicsAsync: topicsAsync),
            const SizedBox(height: 20),
            _CounterRow(
              flashTime: _flashTime,
              flashQuestions: _flashQuestions,
              onAdd: _openManualSheet,
            ),
            const SizedBox(height: 26),

            Row(
              children: [
                Expanded(
                  child: Text('Sıradaki konular',
                      style: AppTheme.display(16, c.ink, tracking: -0.01)),
                ),
                GestureDetector(
                  onTap: () => showAddTopicSheet(context),
                  behavior: HitTestBehavior.opaque,
                  child: Padding(padding: const EdgeInsets.only(right: 14),
                    child: Text('Ekle',
                        style: AppTheme.ui(12, c.brandText, weight: FontWeight.w700)),
                  ),
                ),
                GestureDetector(
                  onTap: () => context.go('/topics'),
                  behavior: HitTestBehavior.opaque,
                  child: Text('Tümü',
                      style: AppTheme.ui(12, c.brandText, weight: FontWeight.w700)),
                ),
              ],
            ),
            const SizedBox(height: 12),

            topicsAsync.when(
              loading: () => Column(
                children: [
                  for (var i = 0; i < _maxTopicRows; i++) ...[
                    if (i > 0) const SizedBox(height: 9),
                    const Skeleton(height: 62, radius: AppRadius.row),
                  ],
                ],
              ),
              error: (e, _) => AppCard(
                child: ErrorLine(
                  message: 'Konular yüklenemedi.',
                  onRetry: () => ref.invalidate(nextTopicsProvider),
                ),
              ),
              data: (topics) {
                if (topics.isEmpty) {
                  return AppCard(
                    child: EmptyState(
                      compact: true,
                      message: 'Henüz konu eklemedin.',
                      actionLabel: 'Konu ekle ',
                      onAction: () => showAddTopicSheet(context),
                    ),
                  );
                }

                final rows = topics; 
                return Column(
                  children: [
                    for (var i = 0; i < rows.length; i++) ...[
                      if (i > 0) const SizedBox(height: 9),
                      TopicRow(
                        topic: rows[i],
                        done: checks[rows[i].key] ?? rows[i].isDone,
                        onTap: () => _toggleTopic(rows[i]),
                      ),
                    ],
                  ],
                );
              },
            ),
            const SizedBox(height: 22),

            const _WeeklyCard(),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _Greeting extends ConsumerWidget {
  const _Greeting({required this.topicsAsync});

  final AsyncValue<List<NextTopic>> topicsAsync;

  static const _months = [
    'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
    'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık',
  ];
  static const _weekdays = [
    'Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final now = DateTime.now();
    final dateText =
        '${_weekdays[now.weekday - 1]}, ${now.day} ${_months[now.month - 1]}';

    final name = ref.watch(currentUserProvider)?.userMetadata?['username'] as String?;
    final suffix = (name == null || name.isEmpty) ? '' : ', $name';

    final rows = topicsAsync.value;
    final String title;
    if (rows == null || rows.isEmpty) {
      title = 'Bugüne konu\nseçmedin';
    } else {
      final checks = ref.watch(topicCheckProvider);
      final remaining =
          rows.where((t) => !(checks[t.key] ?? t.isDone)).length;
      title = remaining > 0
          ? 'Bugün $remaining konu\nkaldı$suffix'
          : 'Bugün her şey\ntamam$suffix';
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(dateText, style: AppTheme.ui(14, c.inkMuted)),
              const SizedBox(height: 4),
              Text(title, style: AppTheme.display(30, c.ink).copyWith(
                letterSpacing: -0.9,
              )),
            ],
          ),
        ),
        const SizedBox(width: 8),
        const Mascot(size: 74, period: Duration(milliseconds: 4500)),
      ],
    );
  }
}

class _CounterRow extends ConsumerWidget {
  const _CounterRow({
    required this.flashTime,
    required this.flashQuestions,
    required this.onAdd,
  });

  final bool flashTime;
  final bool flashQuestions;
  final VoidCallback onAdd;

  static String fmt(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    if (h == 0) return '${m}dk';
    return '${h}sa ${m}dk';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final todayAsync = ref.watch(todayStatsProvider);
    final totalQAsync = ref.watch(dashboardTotalQuestionsProvider);

    return Row(
      children: [
        Expanded(
          child: _CounterCard(
            label: 'Bugün',
            value: todayAsync.maybeWhen(
              data: (s) => fmt(s?.totalSeconds ?? 0),
              orElse: () => '—',
            ),
            dark: true,
            flash: flashTime,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _CounterCard(
            label: 'Soru',
            value: totalQAsync.maybeWhen(
              data: (q) => '$q',
              orElse: () => '—',
            ),
            dark: false,
            flash: flashQuestions,
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: onAdd,
          behavior: HitTestBehavior.opaque,
          child: Container(
            width: 62,
            height: 74,
            decoration: BoxDecoration(
              color: c.brand,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(Icons.add_rounded, size: 26, color: c.brandInk),
          ),
        ),
      ],
    );
  }
}

class _CounterCard extends StatelessWidget {
  const _CounterCard({
    required this.label,
    required this.value,
    required this.dark,
    required this.flash,
  });

  final String label;
  final String value;
  final bool dark;
  final bool flash;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;

    final bg = dark ? (isDarkTheme ? c.surface : c.ink) : c.surface;
    // Koyu temada kart zemini de koyu; değeri `background` ile yazmak
    // siyah üstüne siyah demek olurdu.
    final valueColor = dark && !isDarkTheme ? c.background : c.ink;
    final labelColor = dark ? const Color(0xFF9C948B) : c.inkMuted;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 74,
      // Dikey 15 padding'de etiket + 24px değer 74'e sığmıyor (2px taşma).
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: flash ? c.brandSoft : bg,
        borderRadius: BorderRadius.circular(20),
        border: dark ? null : Border.all(color: c.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label,
              style: AppTheme.ui(11.5, flash ? c.brandText : labelColor)),
          const SizedBox(height: 2),
          // Değer asla iki satıra bölünmez.
          Text(
            value,
            softWrap: false,
            overflow: TextOverflow.visible,
            style: AppTheme.display(
              24,
              flash ? c.brandText : valueColor,
              tracking: -0.02,
            ),
          ),
        ],
      ),
    );
  }
}

class _WeeklyCard extends ConsumerStatefulWidget {
  const _WeeklyCard();

  @override
  ConsumerState<_WeeklyCard> createState() => _WeeklyCardState();
}

class _WeeklyCardState extends ConsumerState<_WeeklyCard> {
  late Future<List<DailyStudyStats>> _future =
      ref.read(dailyStatsStorageProvider).loadLastWeek();

  /// Açılış animasyonu: çubuklar alttan yukarı büyür.
  bool _grown = false;

  void _reload() {
    setState(() {
      _grown = false;
      _future = ref.read(dailyStatsStorageProvider).loadLastWeek();
    });
  }

  /// Bugün en sağda: eski `_getDayName` mantığıyla aynı.
  String _dayName(int index) {
    const days = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
    final today = DateTime.now().weekday - 1;
    final dayIndex = (today - 6 + index) % 7;
    return days[dayIndex < 0 ? dayIndex + 7 : dayIndex];
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return AppCard(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
      child: FutureBuilder<List<DailyStudyStats>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return ErrorLine(
              message: 'Haftalık veri yüklenemedi.',
              onRetry: _reload,
            );
          }
          if (!snapshot.hasData) {
            return const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Skeleton(height: 16, width: 90),
                SizedBox(height: 18),
                Skeleton(height: 78, radius: 7),
              ],
            );
          }

          final week = snapshot.data!;
          final total = week.fold<int>(0, (a, b) => a + b.totalSeconds);
          if (total == 0) {
            return EmptyState(
              compact: true,
              message: 'İlk çalışmanı kaydet, hafta burada dolmaya başlasın.',
              actionLabel: 'Elle kayıt ekle',
              onAction: () => showManualEntrySheet(context),
            );
          }

          // Büyüme animasyonunu ilk kareden sonra tetikle.
          if (!_grown) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _grown = true);
            });
          }

          final maxSeconds =
              week.map((d) => d.totalSeconds).reduce((a, b) => a > b ? a : b);
          final totalH = total ~/ 3600;
          final totalM = (total % 3600) ~/ 60;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text('Son 7 gün',
                        style: AppTheme.display(14, c.ink, tracking: -0.01)),
                  ),
                  Text('${totalH}sa ${totalM}dk',
                      style: AppTheme.ui(12, c.inkMuted)),
                ],
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 78,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (var i = 0; i < week.length; i++) ...[
                      if (i > 0) const SizedBox(width: 9),
                      Expanded(
                        child: AnimatedFractionallySizedBox(
                          duration: Duration(milliseconds: 600 + i * 70),
                          curve: const Cubic(.2, .8, .2, 1),
                          alignment: Alignment.bottomCenter,
                          heightFactor: _grown && maxSeconds > 0
                              ? (week[i].totalSeconds / maxSeconds)
                                  .clamp(0.03, 1.0)
                              : 0.03,
                          child: Container(
                            decoration: BoxDecoration(
                              color: i == week.length - 1 ? c.brand : c.barTrack,
                              borderRadius: BorderRadius.circular(7),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  for (var i = 0; i < week.length; i++) ...[
                    if (i > 0) const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        _dayName(i),
                        textAlign: TextAlign.center,
                        style: AppTheme.ui(
                          10,
                          i == week.length - 1 ? c.ink : c.inkFaint,
                          weight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
