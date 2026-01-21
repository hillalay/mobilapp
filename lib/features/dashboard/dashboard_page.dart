import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dashboard_providers.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(dashboardSummaryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: summaryAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Hata: $e')),
        data: (s) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      title: 'Toplam Çalışma',
                      value: s.totalHoursText,
                      icon: Icons.timer_outlined,
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
              const SizedBox(height: 24),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Not: Şimdilik bu özet “konu progress” üzerinden hesaplanıyor.',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    this.variant=_CardVariant.neutral,
  });

  final String title;
  final String value;
  final IconData icon;
  final _CardVariant variant;

  @override
  Widget build(BuildContext context) {
    final scheme=Theme.of(context).colorScheme;
    final palette=_paletteFor(scheme,variant);

    return Card(
      color: palette.bg,
      surfaceTintColor: palette.bg, // Material3 “tint” etkisini sabitler
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
                  Text(title, style: TextStyle(fontSize: 12, color: palette.subtle),
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
          subtle: scheme.onPrimaryContainer.withOpacity(0.8),
        );
      case _CardVariant.success:
        // ✅ kesin yeşil
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
