import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'exam_providers.dart';
import 'exam_models.dart';

class ExamsPage extends ConsumerStatefulWidget {
  const ExamsPage({super.key});

  @override
  ConsumerState<ExamsPage> createState() => _ExamsPageState();
}

class _ExamsPageState extends ConsumerState<ExamsPage> {
  static const int _pageSize = 15;
  int _pageIndex = 0; // 0 -> 1. sayfa

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
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Sil'),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _goToPage(int index, int pageCount) {
    final next = index.clamp(0, (pageCount - 1).clamp(0, pageCount));
    setState(() => _pageIndex = next);
  }

  @override
  Widget build(BuildContext context) {
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

          final total = items.length;
          final pageCount = (total / _pageSize).ceil();

          // Liste değiştiyse pageIndex taşmasın
          if (_pageIndex > pageCount - 1) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              setState(() => _pageIndex = (pageCount - 1).clamp(0, pageCount));
            });
          }

          final start = _pageIndex * _pageSize;
          final end = (start + _pageSize).clamp(0, total);
          final pageItems = items.sublist(start, end);

          return Column(
            children: [
              Expanded(
                child: ListView.separated(
                  itemCount: pageItems.length,
                  separatorBuilder: (_, __) => const Divider(height: 0),
                  itemBuilder: (_, i) {
                    final x = pageItems[i];

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
                      trailing: PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert),
                        onSelected: (value) async {
                          if (value == 'delete') {
                            final confirmed = await _showDeleteDialog(context, x.name);
                            if (!confirmed) return;

                            await ref.read(examStorageProvider).delete(x.id);
                            ref.invalidate(examsProvider);

                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('${x.name} silindi'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } else if (value == 'edit') {
                            if (x.kind == ExamKind.branch) {
                              context.push('/exams/branch/edit', extra: x);
                            } else {
                              context.push('/exams/general/edit', extra: x);
                            }
                          }
                        },
                        itemBuilder: (context) => const [
                          PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit, size: 20),
                                SizedBox(width: 8),
                                Text('Düzenle'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
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
                      onTap: () {
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
                ),
              ),

              // ✅ Pagination bar (‹ 1 2 3 ›)
              _PaginationBar(
                pageIndex: _pageIndex,
                pageCount: pageCount,
                onPageSelected: (idx) => _goToPage(idx, pageCount),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PaginationBar extends StatelessWidget {
  const _PaginationBar({
    required this.pageIndex,
    required this.pageCount,
    required this.onPageSelected,
  });

  final int pageIndex;
  final int pageCount;
  final ValueChanged<int> onPageSelected;

  @override
  Widget build(BuildContext context) {
    if (pageCount <= 1) return const SizedBox(height: 12);

    // küçük ekranda 1..N hepsini basmayalım: aktif sayfanın çevresini gösterelim
    final pages = <int>{0, pageCount - 1};

    pages.add(pageIndex);
    if (pageIndex - 1 >= 0) pages.add(pageIndex - 1);
    if (pageIndex + 1 <= pageCount - 1) pages.add(pageIndex + 1);

    final sorted = pages.toList()..sort();

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              tooltip: 'Önceki',
              onPressed: pageIndex == 0 ? null : () => onPageSelected(pageIndex - 1),
              icon: const Icon(Icons.chevron_left),
            ),
            const SizedBox(width: 6),

            ..._buildPageButtons(context, sorted),

            const SizedBox(width: 6),
            IconButton(
              tooltip: 'Sonraki',
              onPressed: pageIndex == pageCount - 1 ? null : () => onPageSelected(pageIndex + 1),
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildPageButtons(BuildContext context, List<int> pages) {
    final widgets = <Widget>[];
    int? prev;

    for (final p in pages) {
      if (prev != null && p - prev! > 1) {
        widgets.add(const Padding(
          padding: EdgeInsets.symmetric(horizontal: 6),
          child: Text('…'),
        ));
      }

      final isActive = p == pageIndex;

      widgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => onPageSelected(p),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isActive ? Theme.of(context).colorScheme.primaryContainer : null,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${p + 1}',
                style: TextStyle(
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      );

      prev = p;
    }

    return widgets;
  }
}
