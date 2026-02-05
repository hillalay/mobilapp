import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';

import 'dashboard_providers.dart';
import '../timer/daily_study_stats_providers.dart';
import '../timer/daily_study_stats.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

enum Op { add, sub }

class _DashboardPageState extends ConsumerState<DashboardPage> {
  final _manualHoursController = TextEditingController();
  final _manualMinutesController = TextEditingController();
  final _manualQuestionsController = TextEditingController();

  Op _timeOp = Op.add;
  Op _qOp = Op.add;

  @override
  void dispose() {
    _manualHoursController.dispose();
    _manualMinutesController.dispose();
    _manualQuestionsController.dispose();
    super.dispose();
  }

  InputDecoration _modernDeco(String label) => InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      );

  Future<void> _addOrSubtractTime({required bool isAdd}) async {
    final hours = int.tryParse(_manualHoursController.text) ?? 0;
    final minutes = int.tryParse(_manualMinutesController.text) ?? 0;

    if (hours == 0 && minutes == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen saat veya dakika girin'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final totalMinutes = (hours * 60) + minutes;
    final finalMinutes = isAdd ? totalMinutes : -totalMinutes;

    await ref.read(dailyStatsStorageProvider).addManualMinutes(
          date: DateTime.now(),
          minutes: finalMinutes,
        );

    ref.invalidate(todayStatsProvider);

    _manualHoursController.clear();
    _manualMinutesController.clear();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isAdd
                ? '✓ $hours saat $minutes dakika eklendi!'
                : '✓ $hours saat $minutes dakika çıkarıldı!',
          ),
          backgroundColor: isAdd ? Colors.green : Colors.orange,
        ),
      );
    }

    setState(() {});
  }

  Future<void> _addOrSubtractQuestions({required bool isAdd}) async {
    final q = int.tryParse(_manualQuestionsController.text) ?? 0;

    if (q <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen soru sayısı girin'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final finalQ = isAdd ? q : -q;

    await ref.read(dailyStatsStorageProvider).addManualQuestions(
          date: DateTime.now(),
          questions: finalQ,
        );

    // ✅ toplam soru kartı anında güncellensin
    ref.invalidate(dashboardTotalQuestionsProvider);

    _manualQuestionsController.clear();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isAdd ? '✓ $q soru eklendi!' : '✓ $q soru çıkarıldı!'),
          backgroundColor: isAdd ? Colors.blue : Colors.orange,
        ),
      );
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final summaryAsync = ref.watch(dashboardSummaryProvider);
    final todayAsync = ref.watch(todayStatsProvider);
    final totalQAsync = ref.watch(dashboardTotalQuestionsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: summaryAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Hata: $e')),
        data: (s) => SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                todayAsync.when(
                  loading: () =>
                      _topRowCards(todayText: '0sa 0dk', totalQAsync: totalQAsync),
                  error: (e, _) =>
                      _topRowCards(todayText: '0sa 0dk', totalQAsync: totalQAsync),
                  data: (stats) {
                    String fmt(int seconds) {
                      final h = seconds ~/ 3600;
                      final m = (seconds % 3600) ~/ 60;
                      if (h == 0) return '${m}dk';
                      return '${h}sa ${m}dk';
                    }

                    return _topRowCards(
                      todayText: fmt(stats?.totalSeconds ?? 0),
                      totalQAsync: totalQAsync,
                    );
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        title: 'Bitti',
                        value: '${s.doneCount} konu',
                        icon: Icons.check_circle_outline,
                        variant: _CardVariant.success,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        title: 'Çalışıyorum',
                        value: '${s.inProgressCount} konu',
                        icon: Icons.play_circle_outline,
                        variant: _CardVariant.warning,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Son 7 Gün',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                _buildWeeklyCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _topRowCards({
    required String todayText,
    required AsyncValue<int> totalQAsync,
  }) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            title: 'Bugün',
            value: todayText,
            icon: Icons.today_outlined,
            variant: _CardVariant.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: totalQAsync.when(
            loading: () => const _StatCard(
              title: 'Toplam Soru',
              value: '…',
              icon: Icons.edit_note_outlined,
              variant: _CardVariant.neutral,
            ),
            error: (e, _) => const _StatCard(
              title: 'Toplam Soru',
              value: '0',
              icon: Icons.edit_note_outlined,
              variant: _CardVariant.neutral,
            ),
            data: (q) => _StatCard(
              title: 'Toplam Soru',
              value: '$q',
              icon: Icons.edit_note_outlined,
              variant: _CardVariant.neutral,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWeeklyCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✅ Süre Ekle/Çıkar
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.25),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.timer_outlined,
                          size: 18, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 8),
                      const Text('Çalışma Süresi',
                          style: TextStyle(fontWeight: FontWeight.w800)),
                      const Spacer(),
                      SegmentedButton<Op>(
                        segments: const [
                          ButtonSegment(value: Op.add, label: Text('Ekle')),
                          ButtonSegment(value: Op.sub, label: Text('Çıkar')),
                        ],
                        selected: {_timeOp},
                        onSelectionChanged: (s) => setState(() => _timeOp = s.first),
                        showSelectedIcon: false,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _manualHoursController,
                          keyboardType: TextInputType.number,
                          decoration: _modernDeco('Saat'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _manualMinutesController,
                          keyboardType: TextInputType.number,
                          decoration: _modernDeco('Dakika'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  FilledButton.icon(
                    onPressed: () => _addOrSubtractTime(isAdd: _timeOp == Op.add),
                    icon: const Icon(Icons.check),
                    label: const Text('Uygula'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ✅ Soru Ekle/Çıkar
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.25),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.edit_note_outlined,
                          size: 18, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 8),
                      const Text('Soru Sayısı',
                          style: TextStyle(fontWeight: FontWeight.w800)),
                      const Spacer(),
                      SegmentedButton<Op>(
                        segments: const [
                          ButtonSegment(value: Op.add, label: Text('Ekle')),
                          ButtonSegment(value: Op.sub, label: Text('Çıkar')),
                        ],
                        selected: {_qOp},
                        onSelectionChanged: (s) => setState(() => _qOp = s.first),
                        showSelectedIcon: false,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _manualQuestionsController,
                    keyboardType: TextInputType.number,
                    decoration: _modernDeco('Soru'),
                  ),
                  const SizedBox(height: 10),
                  FilledButton.icon(
                    onPressed: () => _addOrSubtractQuestions(isAdd: _qOp == Op.add),
                    icon: const Icon(Icons.check),
                    label: const Text('Uygula'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),
            const Divider(),
            const SizedBox(height: 14),

            FutureBuilder<List<DailyStudyStats>>(
              future: ref.read(dailyStatsStorageProvider).loadLastWeek(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final weekData = snapshot.data!;
                final totalWeekSeconds =
                    weekData.fold<int>(0, (sum, d) => sum + d.totalSeconds);

                if (totalWeekSeconds == 0) {
                  return const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(
                      child: Text('Henüz veri yok', style: TextStyle(color: Colors.grey)),
                    ),
                  );
                }

                final totalWeekQuestions =
                    weekData.fold<int>(0, (sum, d) => sum + d.manualQuestions);

                return Column(
                  children: [
                    SizedBox(
                      height: 220,
                      child: PieChart(
                        PieChartData(
                          sectionsSpace: 2,
                          centerSpaceRadius: 60,
                          sections: _buildPieChartSections(weekData),
                        ),
                      ),
                    ),

                    // ✅ Altta Pzt/Sal/Çar chipleri
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: List.generate(7, (i) {
                        final day = weekData[i];
                        final h = day.totalSeconds ~/ 3600;
                        final m = (day.totalSeconds % 3600) ~/ 60;
                        final dayName = _getDayName(i);
                        final timeText = h == 0 ? '${m}dk' : '${h}sa ${m}dk';

                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: _getColorForDay(i),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '$dayName • $timeText',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ),

                    const SizedBox(height: 12),

                    // ✅ Toplam soru
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      ),
                      child: Text(
                        'Son 7 Gün Toplam Soru: $totalWeekQuestions',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ✅ Dilimde saat/dk
  List<PieChartSectionData> _buildPieChartSections(List<DailyStudyStats> weekData) {
    return List.generate(7, (i) {
      final seconds = weekData[i].totalSeconds;
      if (seconds == 0) return null;

      final h = seconds ~/ 3600;
      final m = (seconds % 3600) ~/ 60;
      final title = h > 0 ? '${h}sa' : '${m}dk';

      return PieChartSectionData(
        value: seconds.toDouble(),
        title: title,
        color: _getColorForDay(i),
        radius: 50,
        titleStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      );
    }).whereType<PieChartSectionData>().toList();
  }

  Color _getColorForDay(int index) {
    final colors = [
      Colors.blueAccent,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.pink,
      Colors.teal,
      Colors.indigo,
    ];
    return colors[index % colors.length];
  }

  // ✅ Son 7 güne göre kayan gün adı (today bazlı)
  String _getDayName(int index) {
    final days = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
    final today = DateTime.now().weekday - 1;
    final dayIndex = (today - 6 + index) % 7;
    return days[dayIndex < 0 ? dayIndex + 7 : dayIndex];
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    this.variant = _CardVariant.neutral,
  });

  final String title;
  final String value;
  final IconData icon;
  final _CardVariant variant;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final palette = _paletteFor(scheme, variant);

    return Card(
      color: palette.bg,
      surfaceTintColor: palette.bg,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(icon, color: palette.fg),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 12, color: palette.subtle)),
                  const SizedBox(height: 6),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: palette.fg,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

_CardPalette _paletteFor(ColorScheme scheme, _CardVariant v) {
  switch (v) {
    case _CardVariant.neutral:
      return _CardPalette(
        bg: scheme.surfaceContainerHighest,
        fg: scheme.onSurface,
        subtle: scheme.onSurfaceVariant,
      );
    case _CardVariant.primary:
      return _CardPalette(
        bg: scheme.primaryContainer,
        fg: scheme.onPrimaryContainer,
        subtle: scheme.onPrimaryContainer.withValues(alpha: 0.8),
      );
    case _CardVariant.success:
      return _CardPalette(
        bg: Colors.green.shade100,
        fg: Colors.green.shade900,
        subtle: Colors.green.shade800,
      );
    case _CardVariant.warning:
      return _CardPalette(
        bg: Colors.blue.shade100,
        fg: const Color.fromARGB(255, 94, 128, 179),
        subtle: const Color.fromARGB(255, 88, 130, 177),
      );
  }
}

enum _CardVariant { neutral, primary, success, warning }

class _CardPalette {
  final Color bg;
  final Color fg;
  final Color subtle;

  const _CardPalette({
    required this.bg,
    required this.fg,
    required this.subtle,
  });
}
