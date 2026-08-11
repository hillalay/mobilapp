import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../timer/daily_study_stats_providers.dart';
import 'dashboard_providers.dart';

enum Op { add, sub }

/// Hangi sayaç kartının parlayacağını çağırana bildirir.
class ManualEntryResult {
  const ManualEntryResult({required this.timeChanged, required this.questionsChanged});

  final bool timeChanged;
  final bool questionsChanged;
}

/// "Elle kayıt" bottom sheet'i. Eskiden dashboard gövdesinde duran formlar
/// buraya taşındı; `TextEditingController`'lar da sheet'in kendi state'inde.
Future<ManualEntryResult?> showManualEntrySheet(BuildContext context) {
  return showModalBottomSheet<ManualEntryResult>(
    context: context,
    isScrollControlled: true,
    builder: (_) => const _ManualEntrySheet(),
  );
}

class _ManualEntrySheet extends ConsumerStatefulWidget {
  const _ManualEntrySheet();

  @override
  ConsumerState<_ManualEntrySheet> createState() => _ManualEntrySheetState();
}

class _ManualEntrySheetState extends ConsumerState<_ManualEntrySheet> {
  final _hours = TextEditingController();
  final _minutes = TextEditingController();
  final _questions = TextEditingController();

  /// Tek segment iki alanı birlikte yönetir (eski `_timeOp` + `_qOp` birleşti).
  Op _op = Op.add;
  bool _saving = false;

  @override
  void dispose() {
    _hours.dispose();
    _minutes.dispose();
    _questions.dispose();
    super.dispose();
  }

  void _addMinutes(int delta) {
    final current = int.tryParse(_minutes.text) ?? 0;
    _minutes.text = '${current + delta}';
    setState(() {});
  }

  Future<void> _save() async {
    final h = int.tryParse(_hours.text) ?? 0;
    final m = int.tryParse(_minutes.text) ?? 0;
    final q = int.tryParse(_questions.text) ?? 0;

    final totalMinutes = (h * 60) + m;
    if (totalMinutes == 0 && q == 0) {
      Navigator.pop(context);
      return;
    }

    setState(() => _saving = true);
    final sign = _op == Op.add ? 1 : -1;
    final storage = ref.read(dailyStatsStorageProvider);
    final now = DateTime.now();

    if (totalMinutes != 0) {
      await storage.addManualMinutes(date: now, minutes: sign * totalMinutes);
      ref.invalidate(todayStatsProvider);
    }
    if (q != 0) {
      await storage.addManualQuestions(date: now, questions: sign * q);
      ref.invalidate(dashboardTotalQuestionsProvider);
    }

    if (!mounted) return;
    // SnackBar yok: geri bildirim ilgili sayaç kartının kısa parlamasıyla.
    Navigator.pop(
      context,
      ManualEntryResult(
        timeChanged: totalMinutes != 0,
        questionsChanged: q != 0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Padding(
      padding: EdgeInsets.only(
        left: 22,
        right: 22,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 22,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 10),
          Center(
            child: Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: c.checkboxBorder,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          const SizedBox(height: 18),

          Text('Elle kayıt', style: AppTheme.display(21, c.ink, tracking: -0.02)),
          const SizedBox(height: 4),
          Text(
            'Kronometre dışında çalıştığın süre ve çözdüğün soru.',
            style: AppTheme.ui(13, c.inkMuted),
          ),
          const SizedBox(height: 18),

          _OpSegment(value: _op, onChanged: (v) => setState(() => _op = v)),
          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(child: _NumberField(label: 'Saat', controller: _hours)),
              const SizedBox(width: 10),
              Expanded(child: _NumberField(label: 'Dakika', controller: _minutes)),
              const SizedBox(width: 10),
              Expanded(child: _NumberField(label: 'Soru', controller: _questions)),
            ],
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              for (final quick in const [(15, '+15dk'), (30, '+30dk'), (60, '+1sa')]) ...[
                if (quick.$1 != 15) const SizedBox(width: 8),
                _QuickChip(
                  label: quick.$2,
                  onTap: () => _addMinutes(quick.$1),
                ),
              ],
            ],
          ),
          const SizedBox(height: 18),

          FilledButton(
            onPressed: _saving ? null : _save,
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }
}

class _OpSegment extends StatelessWidget {
  const _OpSegment({required this.value, required this.onChanged});

  final Op value;
  final ValueChanged<Op> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: c.ink.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          for (final op in Op.values)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(op),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: value == op ? c.surface : Colors.transparent,
                    borderRadius: BorderRadius.circular(11),
                    boxShadow: value == op
                        ? [
                            BoxShadow(
                              color: c.ink.withValues(alpha: 0.08),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    op == Op.add ? 'Ekle' : 'Çıkar',
                    style: AppTheme.ui(
                      13,
                      value == op ? c.ink : c.inkMuted,
                      weight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({required this.label, required this.controller});

  final String label;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTheme.ui(11, c.inkFaint)),
          TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: AppTheme.display(22, c.ink, tracking: -0.02),
            decoration: const InputDecoration(
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              filled: false,
              isDense: true,
              contentPadding: EdgeInsets.zero,
              hintText: '0',
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickChip extends StatelessWidget {
  const _QuickChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: c.brandSoft,
          borderRadius: BorderRadius.circular(AppRadius.chip),
        ),
        child: Text(
          label,
          style: AppTheme.ui(12, c.brandText, weight: FontWeight.w700),
        ),
      ),
    );
  }
}
