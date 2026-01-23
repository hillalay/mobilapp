import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'stopwatch_controller.dart';
import '../topics/topic_providers.dart';

class StopwatchPage extends ConsumerWidget {
  const StopwatchPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(stopwatchProvider);
    final controller = ref.read(stopwatchProvider.notifier);
    final topicsAsync = ref.watch(filteredTopicsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kronometre'),
        actions: [
          if (state.isRunning || state.seconds > 0)
            IconButton(
              icon: const Icon(Icons.stop),
              tooltip: 'Durdur ve Kaydet',
              onPressed: () async {
                await controller.stop();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Çalışma kaydedildi!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Kronometre göstergesi
            Card(
              color: state.isRunning ? Colors.green.shade50 : null,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Text(
                      state.formattedTime,
                      style: TextStyle(
                        fontSize: 56,
                        fontWeight: FontWeight.w800,
                        color: state.isRunning ? Colors.green.shade700 : null,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (state.lesson != null)
                      Text(
                        '${state.lesson}${state.topic != null ? ' • ${state.topic}' : ''}',
                        style: const TextStyle(fontSize: 16),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Ders seçimi
            if (!state.isRunning) ...[
              topicsAsync.when(
                loading: () => const CircularProgressIndicator(),
                error: (e, _) => Text('Hata: $e'),
                data: (map) {
                  final lessons = map.keys.toList();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Ders Seç:', style: TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: state.lesson,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Ders seç (opsiyonel)',
                        ),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('Seçim yok')),
                          ...lessons.map((l) => DropdownMenuItem(value: l, child: Text(l))),
                        ],
                        onChanged: (value) {
                          controller.setLesson(value);
                          controller.setTopic(null);
                        },
                      ),

                      if (state.lesson != null) ...[
                        const SizedBox(height: 12),
                        const Text('Konu Seç:', style: TextStyle(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: state.topic,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: 'Konu seç (opsiyonel)',
                          ),
                          items: [
                            const DropdownMenuItem(value: null, child: Text('Seçim yok')),
                            ...(map[state.lesson] ?? [])
                                .map((t) => DropdownMenuItem(value: t, child: Text(t))),
                          ],
                          onChanged: controller.setTopic,
                        ),
                      ],
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),
            ],

            // Butonlar
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!state.isRunning)
                  FilledButton.icon(
                    onPressed: controller.start,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Başlat'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    ),
                  ),
                if (state.isRunning)
                  FilledButton.icon(
                    onPressed: controller.pause,
                    icon: const Icon(Icons.pause),
                    label: const Text('Duraklat'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      backgroundColor: Colors.orange,
                    ),
                  ),
                if (state.seconds > 0 && !state.isRunning) ...[
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: controller.reset,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Sıfırla'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}