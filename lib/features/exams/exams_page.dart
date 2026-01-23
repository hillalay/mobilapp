import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'exam_providers.dart';
import 'exam_models.dart';

class ExamsPage extends ConsumerWidget {
  const ExamsPage({super.key});

  // ✅ Silme işlemi için dialog
  Future<bool> _showDeleteDialog(BuildContext context, String name) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Denemeyi Sil'),
            content: Text('$name denemesini silmek istediğine emin misin?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('İptal'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
                child: const Text('Sil'),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final examsAsync = ref.watch(examsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Denemeler'),
        actions: [
          IconButton(
            tooltip: 'TYT Analiz',
            onPressed: () => context.push('/exams/analytics', extra: ExamType.tyt),
            icon: const Icon(Icons.show_chart),
          ),
          IconButton(
            tooltip: 'AYT Analiz',
            onPressed: () => context.push('/exams/analytics', extra: ExamType.ayt),
            icon: const Icon(Icons.insights),
          ),
          IconButton(
            tooltip: 'Deneme Ekle',
            onPressed: () => context.push('/exams/new'),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: examsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Hata: $e')),
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('Henüz deneme yok. + ile ekle.'));
          }
          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 0),
            itemBuilder: (_, i) {
              final x = items[i];
              double totalNet = 0;
              if (x.general != null) {
                totalNet = x.general!.netsBySection.values.fold(0.0, (a, b) => a + b);
              }
              final subtitle = x.kind == ExamKind.branch
                  ? 'Branş • ${x.branch?.lesson ?? '-'} • Net: ${(x.branch?.net ?? 0).toStringAsFixed(2)} • Konu: ${x.branch?.topics.length ?? 0}'
                  : 'Genel • ${(x.general?.type.name ?? '-').toUpperCase()} • Toplam Net: ${totalNet.toStringAsFixed(2)} • Yanlış konu: ${x.general?.wrongTopics.length ?? 0}';

              return ListTile(
                title: Text(x.name),
                subtitle: Text(subtitle),
                // ✅ Sağ tarafa menü eklendi
                trailing: PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) async {
                    if (value == 'delete') {
                      // Silme onayı al
                      final confirmed = await _showDeleteDialog(context, x.name);
                      if (!confirmed) return;

                      // Sil
                      await ref.read(examStorageProvider).delete(x.id);
                      
                      // Listeyi yenile
                      ref.invalidate(examsProvider);
                      
                      // Başarı mesajı
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${x.name} silindi'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } else if (value == 'edit') {
                      // Düzenleme sayfasına git
                      if (x.kind == ExamKind.branch) {
                        // Branş denemesi düzenleme (henüz yapmadık)
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Branş denemesi düzenleme yakında eklenecek'),
                          ),
                        );
                      } else {
                        // Genel deneme düzenleme (henüz yapmadık)
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Genel deneme düzenleme yakında eklenecek'),
                          ),
                        );
                      }
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 20),
                          SizedBox(width: 8),
                          Text('Düzenle'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 20, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Sil', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
                // ✅ Tıklayınca detay göster (opsiyonel)
                onTap: () {
                  // Detay sayfası ekleyebilirsiniz
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Text(x.name),
                      content: Text(subtitle),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: const Text('Kapat'),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}