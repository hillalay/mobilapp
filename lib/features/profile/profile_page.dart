import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth_providers.dart';
import 'avatar_section.dart';
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
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        actions: [
          if (user != null)
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Çıkış yap',
              onPressed: () => _signOut(context, ref),
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (user != null) ...[
                const AvatarSection(),
                const SizedBox(height: 24),
              ],

              // ✅ NOTES + TODO
              const ProfileTodoSection(),

              const SizedBox(height: 24),

              // ✅ ISI HARİTASI
              const HeatmapSection(topTopicsPerLesson: 10),
            ],
          ),
        ),
      ),
    );
  }
}
