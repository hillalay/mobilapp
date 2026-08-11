import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../app/ui.dart';
import '../../core/auth_providers.dart';
import 'avatar_section.dart';
import 'profile_settings_section.dart';
import 'profile_todo_section.dart';
import 'heatmap_section.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Çıkış yap'),
        content: const Text(
          'Bu cihazdaki veriler silinecek. Senkronlanmamış değişiklikler '
          'varsa kaybolabilir. Devam edilsin mi?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Çıkış yap'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final engine = ref.read(syncEngineProvider);
    // Önce bekleyenleri gönder, sonra yereli temizle: bir sonraki hesap
    // öncekinin verisini görmesin.
    await engine?.push();
    await engine?.stop();
    await engine?.clearLocal();
    await ref.read(supabaseClientProvider)?.auth.signOut();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 4, 22, 28),
          children: [
            if (user != null) ...[
              const IdentityCard(),
              const SizedBox(height: 24),
            ],

            const ProfileTodoSection(),
            const SizedBox(height: 24),

            const ProfileSettingsSection(),
            const SizedBox(height: 24),

            const HeatmapSection(),

            if (user != null) ...[
              const SizedBox(height: 24),
              AppCard(
                onTap: () => _signOut(context, ref),
                radius: 18,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.logout, size: 18, color: c.danger),
                    const SizedBox(width: 8),
                    Text('Çıkış yap',
                        style: AppTheme.ui(14, c.danger, weight: FontWeight.w700)),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
