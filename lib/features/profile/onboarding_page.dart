import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'profile_controller.dart';

class OnboardingPage extends ConsumerWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Future<void> selectTrack(Track t) async {
      final profile = UserProfile(track: t);
      await ref.read(profileProvider.notifier).setProfile(profile);

      if (context.mounted) context.go('/dashboard');
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Kurulumu'),
        centerTitle: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Alanını seç:',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              'Sadece sınav öğrencileri için. Seçimini daha sonra ayarlardan değiştirebilirsin.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).hintColor,
                  ),
            ),
            const SizedBox(height: 16),

            _TrackButton(
              label: 'MF',
              icon: Icons.functions,
              onTap: () => selectTrack(Track.mf),
            ),
            const SizedBox(height: 10),

            _TrackButton(
              label: 'TM',
              icon: Icons.menu_book,
              onTap: () => selectTrack(Track.tm),
            ),
            const SizedBox(height: 10),

            _TrackButton(
              label: 'Sözel',
              icon: Icons.record_voice_over,
              onTap: () => selectTrack(Track.sozel),
            ),
            const SizedBox(height: 10),

            _TrackButton(
              label: 'Dil',
              icon: Icons.language,
              onTap: () => selectTrack(Track.dil),
            ),

            const Spacer(),

            // İstersen alt tarafa küçük bir not
            Text(
              'Seçimin yalnızca içerik ve analizleri kişiselleştirmek için kullanılır.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).hintColor,
                  ),
            ),
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }
}

class _TrackButton extends StatelessWidget {
  const _TrackButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context).dividerColor.withOpacity(.5),
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: Icon(
                  icon,
                  size: 18,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Theme.of(context).hintColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
