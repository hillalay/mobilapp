import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';

import 'dashboard_providers.dart';
import '../timer/daily_study_stats_providers.dart';
import '../timer/daily_study_stats_storage.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  final _manualHoursController = TextEditingController();
  final _manualMinutesController = TextEditingController();

  @override
  void dispose() {
    _manualHoursController.dispose();
    _manualMinutesController.dispose();
    super.dispose();
  }

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

    await ref
        .read(dailyStatsStorageProvider)
        .addManualMinutes(date: DateTime.now(), minutes: finalMinutes);

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
  }

  @override
  Widget build(BuildContext context) {
    final summaryAsync = ref.watch(dashboardSummaryProvider);
    final todayAsync = ref.watch(todayStatsProvider);

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
                // İstatistik kartları
                todayAsync.when(
                  loading: () => Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          title: 'Bugün',
                          value: '0sa 0dk',
                          icon: Icons.today_outlined,
                          variant: _CardVariant.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          title: 'Toplam Soru',
                          value: '${s.totalQuestions}',
                          icon: Icons.edit_note_outlined,
                          variant: _CardVariant.neutral,
                        ),
                      ),
                    ],
                  ),
                  error: (e, _) => Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          title: 'Bugün',
                          value: '0sa 0dk',
                          icon: Icons.today_outlined,
                          variant: _CardVariant.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          title: 'Toplam Soru',
                          value: '${s.totalQuestions}',
                          icon: Icons.edit_note_outlined,
                          variant: _CardVariant.neutral,
                        ),
                      ),
                    ],
                  ),
                  data: (stats) {
                    String fmt(int seconds) {
                      final h = seconds ~/ 3600;
                      final m = (seconds % 3600) ~/ 60;
                      if (h == 0) return '${m}dk';
                      return '${h}sa ${m}dk';
                    }

                    return Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            title: 'Bugün',
                            value: fmt(stats?.totalSeconds ?? 0),
                            icon: Icons.today_outlined,
                            variant: _CardVariant.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            title: 'Toplam Soru',
                            value: '${s.totalQuestions}',
                            icon: Icons.edit_note_outlined,
                            variant: _CardVariant.neutral,
                          ),
                        ),
                      ],
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

                // ✅ YENİ: Haftalık Grafik + Manuel Süre Ekleme
                const Text(
                  'Son 7 Gün',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                _buildWeeklyChartWithManualInput(),

                const SizedBox(height: 24),

                // ✅ Hızlı Erişim Bölümü
                const Text(
                  'Hızlı Erişim',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),

                // Kronometre
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.timer, color: Colors.green),
                    title: const Text('Kronometre'),
                    subtitle: const Text('Çalışma süresini ölç'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/timer'),
                  ),
                ),
                const SizedBox(height: 8),

                // Denemeler
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.quiz, color: Colors.blue),
                    title: const Text('Denemeler'),
                    subtitle: const Text('TYT/AYT denemeleri'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/exams'),
                  ),
                ),
                const SizedBox(height: 8),

                // Konular
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.book, color: Colors.orange),
                    title: const Text('Konular'),
                    subtitle: const Text('Konu takibi'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/topics'),
                  ),
                ),

                const SizedBox(height: 24),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Not: Şimdilik bu özet "konu progress" üzerinden hesaplanıyor.',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWeeklyChartWithManualInput() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Manuel Süre Ekleme
            const Row(
              children: [
                Icon(Icons.add_circle_outline, color: Colors.green, size: 18),
                SizedBox(width: 6),
                Text(
                  'Manuel Süre Ekle',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
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
                    decoration: const InputDecoration(
                      labelText: 'Saat',
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _manualMinutesController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Dakika',
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _addOrSubtractTime(isAdd: true),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Ekle'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _addOrSubtractTime(isAdd: false),
                    icon: const Icon(Icons.remove, size: 18),
                    label: const Text('Çıkar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 16),

            // Grafik
            FutureBuilder(
              future: ref.read(dailyStatsStorageProvider).loadLastWeek(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final weekData = snapshot.data!;
                final totalWeekSeconds = weekData.fold(
                  0,
                  (int sum, day) => sum + day.totalSeconds,
                );

                if (totalWeekSeconds == 0) {
                  return Padding(
                    padding: const EdgeInsets.all(40),
                    child: Center(
                      child: Text(
                        'Henüz veri yok',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ),
                  );
                }

                return Column(
                  children: [
                    SizedBox(
                      height: 200,
                      child: PieChart(
                        PieChartData(
                          sectionsSpace: 2,
                          centerSpaceRadius: 60,
                          sections: _buildPieChartSections(weekData),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: List.generate(7, (i) {
                        final day = weekData[i];
                        final hours = day.totalSeconds ~/ 3600;
                        final minutes = (day.totalSeconds % 3600) ~/ 60;
                        final dayName = _getDayName(i);

                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: _getColorForDay(i),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '$dayName: ${hours}s ${minutes}dk',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        );
                      }),
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

  List<PieChartSectionData> _buildPieChartSections(List weekData) {
    return List.generate(7, (i) {
      final seconds = weekData[i].totalSeconds;
      if (seconds == 0) return null;

      return PieChartSectionData(
        value: seconds.toDouble(),
        title: '${seconds ~/ 3600}s',
        color: _getColorForDay(i),
        radius: 50,
        titleStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).whereType<PieChartSectionData>().toList();
  }

  Color _getColorForDay(int index) {
    final colors = [
      Colors.blue.shade400,
      Colors.green.shade400,
      Colors.orange.shade400,
      Colors.purple.shade400,
      Colors.pink.shade400,
      Colors.teal.shade400,
      Colors.indigo.shade400,
    ];
    return colors[index % colors.length];
  }

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
                  Text(
                    title,
                    style: TextStyle(fontSize: 12, color: palette.subtle),
                  ),
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