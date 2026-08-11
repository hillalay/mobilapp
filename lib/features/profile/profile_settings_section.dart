import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../app/ui.dart';
import 'profile_controller.dart';

/// Onboarding'de verilen cevaplar burada görünür ve değiştirilebilir.
class ProfileSettingsSection extends ConsumerWidget {
  const ProfileSettingsSection({super.key});

  Future<void> _save(WidgetRef ref, UserProfile next) =>
      ref.read(profileProvider.notifier).setProfile(next);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final profile = ref.watch(profileProvider).value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Hedeflerin', style: AppTheme.display(15, c.ink, tracking: -0.01)),
        const SizedBox(height: 12),
        if (profile == null)
          const AppCard(child: Skeleton(height: 120, radius: 12))
        else
          AppCard(
            radius: 20,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Column(
              children: [
                _SettingRow(
                  label: 'Alan',
                  value: trackChoices[profile.track]!.$2,
                  onTap: () => _pick<Track>(
                    context,
                    title: 'Hangi alanda yarışıyorsun?',
                    options: trackChoices.entries
                        .map((e) => (e.key, e.value.$2))
                        .toList(),
                    selected: profile.track,
                    onSelected: (v) =>
                        _save(ref, profile.copyWith(track: v)),
                  ),
                ),
                _Divider(color: c.hairline),
                _SettingRow(
                  label: 'Günlük hedef',
                  value: profile.dailyGoalHours == null
                      ? 'Seçilmedi'
                      : goalHourChoices[profile.dailyGoalHours]!.$2,
                  onTap: () => _pick<int?>(
                    context,
                    title: 'Günde kaç saat hedefliyorsun?',
                    options: goalHourChoices.entries
                        .map((e) => (e.key as int?, e.value.$2))
                        .toList(),
                    selected: profile.dailyGoalHours,
                    onSelected: (v) =>
                        _save(ref, profile.copyWith(dailyGoalHours: v)),
                  ),
                ),
                _Divider(color: c.hairline),
                _SettingRow(
                  label: 'Hatırlatma',
                  value: reminderChoices[profile.reminderHour]!.$2,
                  onTap: () => _pick<int?>(
                    context,
                    title: 'Seni ne zaman dürtelim?',
                    options: reminderChoices.entries
                        .map((e) => (e.key, e.value.$2))
                        .toList(),
                    selected: profile.reminderHour,
                    // Hatırlatma "kapalı" seçilebilsin diye copyWith değil,
                    // doğrudan yeni profil kuruluyor (copyWith null'ı yok sayar).
                    onSelected: (v) => _save(
                      ref,
                      UserProfile(
                        track: profile.track,
                        dailyGoalHours: profile.dailyGoalHours,
                        reminderHour: v,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Future<void> _pick<T>(
    BuildContext context, {
    required String title,
    required List<(T, String)> options,
    required T selected,
    required void Function(T) onSelected,
  }) async {
    final chosen = await showModalBottomSheet<({T value})>(
      context: context,
      builder: (ctx) {
        final c = ctx.colors;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 18),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: Text(title,
                    style: AppTheme.display(19, c.ink, tracking: -0.02)),
              ),
              const SizedBox(height: 12),
              for (final option in options)
                ListTile(
                  title: Text(option.$2,
                      style: AppTheme.ui(15, c.ink, weight: FontWeight.w500)),
                  trailing: option.$1 == selected
                      ? Icon(Icons.check_rounded, color: c.brand)
                      : null,
                  onTap: () => Navigator.pop(ctx, (value: option.$1)),
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );

    if (chosen != null && chosen.value != selected) onSelected(chosen.value);
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            Expanded(child: Text(label, style: AppTheme.ui(14, c.ink))),
            Text(value,
                style: AppTheme.ui(13.5, c.inkMuted, weight: FontWeight.w700)),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right, size: 20, color: c.inkFaint),
          ],
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Divider(height: 1, thickness: 1, color: color),
      );
}
